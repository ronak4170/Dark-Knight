extends CharacterBody2D

# -------------------------------------------------------
# EXPORTS — tune in Inspector
# -------------------------------------------------------

@export var speed              : float = 90.0
@export var detection_range    : float = 400.0
@export var gravity            : float = 900.0
@export var max_health         : int   = 100
@export var attack_damage      : int   = 10
@export var attack_cooldown    : float = 0.7

# --- ATTACK RANGES ---
# Think of these as how far away the enemy can reach with each attack.
# attack_3 is the entry point — enemy starts attacking when player is within this distance.
# DO NOT set these below 60. Your collision shapes prevent getting closer than ~35-40px.
@export var attack_range_close : float = 20.0    # attack_1 only fires this close
@export var attack_range_mid   : float = 20.0   # attack_1 + attack_2 available
@export var attack_range_far   : float = 20.0   # all 3 available — also entry threshold

# Jump
@export var jump_strength      : float = -380.0
@export var chase_jump_chance  : float = 0.3
@export var chase_jump_delay   : float = 2.0

# Dodge
@export var dodge_speed        : float = 180.0
@export var dodge_cooldown     : float = 2.5
@export var dodge_chance       : float = 0.8

# -------------------------------------------------------
# STATE MACHINE
# -------------------------------------------------------

enum State { IDLE, CHASE, ATTACK, DODGE, HIT, DEATH }
var current_state : State = State.IDLE

# -------------------------------------------------------
# VARS
# -------------------------------------------------------

var player                          : CharacterBody2D = null
var health                          : int             = 0
var attack_timer                    : float           = 0.0
var is_attacking                    : bool            = false
var is_dead                         : bool            = false
var facing_direction                : int             = 1
var is_in_hit_stun                  : bool            = false

var dodge_cooldown_timer            : float           = 0.0
var dodge_direction                 : int             = 1
var is_dodging                      : bool            = false

var chase_jump_timer                : float           = 0.0
var current_attack                  : String          = ""

# Prevent rapid CHASE <-> ATTACK flickering at the boundary
var state_change_buffer             : float           = 0.0
const STATE_CHANGE_BUFFER_TIME      : float           = 0.15

var attack_hitbox_original_position : Vector2

# -------------------------------------------------------
# NODES
# -------------------------------------------------------

@onready var sprite        : AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox : Area2D           = $AttackHitbox
@onready var hurtbox       : Area2D           = $Hurtbox

# -------------------------------------------------------
# READY
# -------------------------------------------------------

func _ready() -> void:
	add_to_group("enemy")
	health = max_health

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Enemy: no node in group 'player' found!")

	# Force one-shot — without this, animation_finished never fires
	for anim in ["attack_1", "attack_2", "attack_3", "hit", "death", "jump_start", "jump_end"]:
		if sprite.sprite_frames.has_animation(anim):
			sprite.sprite_frames.set_animation_loop(anim, false)

	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)

	if attack_hitbox:
		attack_hitbox.monitoring  = false
		attack_hitbox.monitorable = false
		attack_hitbox.body_entered.connect(_on_attack_hit)
		attack_hitbox_original_position = attack_hitbox.position

	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

# -------------------------------------------------------
# PHYSICS
# -------------------------------------------------------

func _physics_process(delta: float) -> void:

	if is_dead:
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	if player == null:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Timers
	attack_timer         = maxf(0.0, attack_timer - delta)
	dodge_cooldown_timer = maxf(0.0, dodge_cooldown_timer - delta)
	chase_jump_timer     = maxf(0.0, chase_jump_timer - delta)
	state_change_buffer  = maxf(0.0, state_change_buffer - delta)

	# Dodge landing
	if is_dodging and is_on_floor():
		is_dodging           = false
		dodge_cooldown_timer = dodge_cooldown
		_on_dodge_landed()
		return

	# Hit stun
	if is_in_hit_stun:
		velocity.x = 0
		move_and_slide()
		return

	# Safety net: animation ended without signal (e.g. was looping)
	if is_attacking and not sprite.is_playing():
		is_attacking   = false
		current_attack = ""
		_disable_attack_hitbox()

	var h_dist : float = absf(player.global_position.x - global_position.x)

	match current_state:
		State.IDLE:   _state_idle(h_dist)
		State.CHASE:  _state_chase(h_dist)
		State.ATTACK: _state_attack(h_dist)
		State.DODGE:  _state_dodge()

	move_and_slide()

# -------------------------------------------------------
# STATES
# -------------------------------------------------------

func _state_idle(distance: float) -> void:
	velocity.x = 0
	_play_animation("idle")
	if distance <= detection_range:
		_face_player()
		current_state = State.CHASE


func _state_chase(distance: float) -> void:

	if distance > detection_range:
		velocity.x = 0
		current_state = State.IDLE
		return

	# Enter attack state — only when buffer allows (prevents flickering)
	if distance <= attack_range_far and state_change_buffer <= 0.0:
		velocity.x = 0
		state_change_buffer = STATE_CHANGE_BUFFER_TIME
		current_state = State.ATTACK
		return

	_face_player()
	velocity.x = facing_direction * speed

	# Random hop while chasing
	if is_on_floor() and chase_jump_timer <= 0.0:
		chase_jump_timer = chase_jump_delay + randf_range(0.0, 1.5)
		if randf() < chase_jump_chance:
			_do_jump()
			return

	_play_animation("run" if is_on_floor() else "jump_loop")


func _state_attack(distance: float) -> void:
	velocity.x = 0

	# Face player every frame when not swinging
	# This is what makes the enemy react when player jumps behind it
	if not is_attacking:
		_face_player()

	# Player ran away past a safe buffer — go chase, but only when not mid-swing
	# Buffer is bigger here to stop flickering: 1.6x rather than 1.4x
	if distance > attack_range_far * 1.6 and not is_attacking and state_change_buffer <= 0.0:
		current_attack      = ""
		state_change_buffer = STATE_CHANGE_BUFFER_TIME
		current_state       = State.CHASE
		return

	# Mid-swing — do nothing, let animation finish
	if is_attacking:
		return

	# Waiting for cooldown
	if attack_timer > 0.0:
		_play_animation("idle")
		return

	# Build available attacks based on actual current distance
	var available : Array[String] = []

	if distance <= attack_range_close:
		available.append("attack_1")
	if distance <= attack_range_mid:
		available.append("attack_2")
	if distance <= attack_range_far:
		available.append("attack_3")

	# Player somehow got just out of range mid-cooldown — chase
	if available.is_empty():
		state_change_buffer = STATE_CHANGE_BUFFER_TIME
		current_state       = State.CHASE
		return

	_commit_attack(available[randi() % available.size()])


func _commit_attack(attack_name: String) -> void:
	is_attacking   = true
	current_attack = attack_name
	attack_timer   = attack_cooldown

	_play_animation(attack_name)

	if attack_hitbox:
		attack_hitbox.monitoring  = true
		attack_hitbox.monitorable = true


func _state_dodge() -> void:
	if not is_on_floor():
		velocity.x = dodge_direction * dodge_speed
		_play_animation("jump_loop")


func _on_dodge_landed() -> void:
	_face_player()
	if player:
		var h_dist := absf(player.global_position.x - global_position.x)
		if h_dist <= attack_range_far:
			current_state = State.ATTACK
		elif h_dist <= detection_range:
			current_state = State.CHASE
		else:
			current_state = State.IDLE
	else:
		current_state = State.IDLE

# -------------------------------------------------------
# DAMAGE / DEATH
# -------------------------------------------------------

func take_damage(damage: int) -> void:
	if is_dead:
		return

	health -= damage

	if health <= 0:
		_die()
		return

	if dodge_cooldown_timer <= 0.0 and not is_dodging and randf() < dodge_chance:
		_start_dodge_jump()
	else:
		_enter_hit_stun()


func _enter_hit_stun() -> void:
	is_attacking   = false
	current_attack = ""
	is_in_hit_stun = true
	current_state  = State.HIT
	velocity.x     = 0
	_disable_attack_hitbox()
	_play_animation("hit")


func _start_dodge_jump() -> void:
	if player:
		dodge_direction = -signi(int(player.global_position.x) - int(global_position.x))
		if dodge_direction == 0:
			dodge_direction = 1
	else:
		dodge_direction = -facing_direction

	is_attacking     = false
	current_attack   = ""
	is_in_hit_stun   = false
	is_dodging       = true
	current_state    = State.DODGE
	facing_direction = dodge_direction

	_disable_attack_hitbox()
	_apply_facing()

	velocity.y = jump_strength
	velocity.x = dodge_direction * dodge_speed

	_play_animation("jump_start" if sprite.sprite_frames.has_animation("jump_start") else "jump_loop")


func _do_jump() -> void:
	velocity.y = jump_strength
	_play_animation("jump_start" if sprite.sprite_frames.has_animation("jump_start") else "jump_loop")


func _die() -> void:
	is_dead        = true
	is_in_hit_stun = false
	is_dodging     = false
	is_attacking   = false
	current_attack = ""
	current_state  = State.DEATH
	velocity.x     = 0

	_disable_attack_hitbox()

	if hurtbox:
		hurtbox.monitoring  = false
		hurtbox.monitorable = false

	_play_animation("death")

# -------------------------------------------------------
# ANIMATION CALLBACKS
# -------------------------------------------------------

func _on_animation_finished() -> void:
	var anim : String = sprite.animation

	if anim.begins_with("attack_"):
		is_attacking   = false
		current_attack = ""
		_disable_attack_hitbox()
		return

	match anim:
		"hit":
			is_in_hit_stun = false
			if player:
				var h_dist := absf(player.global_position.x - global_position.x)
				if h_dist <= attack_range_far:
					current_state = State.ATTACK
				elif h_dist <= detection_range:
					current_state = State.CHASE
				else:
					current_state = State.IDLE
			else:
				current_state = State.IDLE

		"jump_start":
			_play_animation("jump_loop")

		"jump_end":
			_play_animation("idle")

		"death":
			queue_free()

# -------------------------------------------------------
# HITBOX SIGNALS
# -------------------------------------------------------

func _on_attack_hit(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		var damage : int = 10
		if "damage" in area:
			damage = area.damage
		take_damage(damage)

# -------------------------------------------------------
# HELPERS
# -------------------------------------------------------

func _face_player() -> void:
	if player == null:
		return
	# Use a threshold so tiny differences don't flicker the direction
	var diff : float = player.global_position.x - global_position.x
	if absf(diff) > 2.0:
		facing_direction = 1 if diff > 0 else -1
	_apply_facing()


func _apply_facing() -> void:
	sprite.flip_h = (facing_direction < 0)
	if attack_hitbox:
		attack_hitbox.position.x = facing_direction * absf(attack_hitbox_original_position.x)


func _disable_attack_hitbox() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring  = false
		attack_hitbox.monitorable = false


func _play_animation(anim_name: String) -> void:
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)
