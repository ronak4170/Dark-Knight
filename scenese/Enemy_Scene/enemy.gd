extends CharacterBody2D

# -------------------------------------------------------
# EXPORTS
# -------------------------------------------------------

@export var speed              : float = 90.0
@export var detection_range    : float = 400.0   # circular radius for spotting player
@export var gravity            : float = 900.0
@export var max_health         : int   = 100
@export var attack_damage      : int   = 10
@export var attack_cooldown    : float = 1.0

# Attack ranges use ACTUAL 2D distance now, not just horizontal
@export var attack_range_close : float = 55.0    # attack_1 (must be touching basically)
@export var attack_range_mid   : float = 85.0    # attack_1 + attack_2
@export var attack_range_far   : float = 120.0   # all 3 — entry point from chase

# Jump
@export var jump_strength      : float = -400.0
@export var chase_jump_chance  : float = 0.35
@export var chase_jump_delay   : float = 2.0

# Dodge
@export var dodge_speed        : float = 220.0
@export var dodge_cooldown     : float = 1.8
@export var dodge_chance       : float = 0.6

@export var knockback_force    : float = 280.0
@export var knockback_up       : float = 120.0

# -------------------------------------------------------
# STATES
# -------------------------------------------------------

enum State { IDLE, PATROL, CHASE, ATTACK, DODGE, HIT, DEATH }
var current_state : State = State.IDLE

# -------------------------------------------------------
# VARS
# -------------------------------------------------------

var player                          : CharacterBody2D = null
var player_in_detection_zone        : bool            = false  # set by Area2D signal
var health                          : int             = 0
var attack_timer                    : float           = 0.0
var is_attacking                    : bool            = false
var has_hit_this_swing              : bool            = false
var is_dead                         : bool            = false
var facing_direction                : int             = 1
var is_in_hit_stun                  : bool            = false

var dodge_cooldown_timer            : float           = 0.0
var dodge_direction                 : int             = 1
var is_dodging                      : bool            = false
var dodge_grace_timer               : float           = 0.0

var chase_jump_timer                : float           = 0.0
var current_attack                  : String          = ""

var state_change_buffer             : float           = 0.0
const STATE_BUFFER                  : float           = 0.2

var attack_hitbox_original_position : Vector2
var hit_stun_timer                  : float           = 0.0

# -------------------------------------------------------
# NODES
# -------------------------------------------------------

@onready var sprite           : AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox    : Area2D           = $AttackHitbox
@onready var hurtbox          : Area2D           = $Hurtbox
@onready var detection_area   : Area2D           = $DetectionArea  # NEW: circular detection

# -------------------------------------------------------
# READY
# -------------------------------------------------------

func _ready() -> void:
	add_to_group("enemy")
	health = max_health

	player = get_tree().get_first_node_in_group("player")

	# Force one-shot animations
	for anim in ["attack_1", "attack_2", "attack_3", "hit", "death", "jump"]:
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

	# NEW: Detection area setup
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)

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
	dodge_grace_timer    = maxf(0.0, dodge_grace_timer - delta)
	hit_stun_timer       = maxf(0.0, hit_stun_timer - delta)

	# Dodge landing
	if is_dodging and is_on_floor() and dodge_grace_timer <= 0.0:
		is_dodging           = false
		dodge_cooldown_timer = dodge_cooldown
		_on_dodge_landed()
		return

	# Hit stun blocks everything
	if is_in_hit_stun:
		if hit_stun_timer <= 0.0:
			is_in_hit_stun = false
			_resume_after_hit()
		move_and_slide()
		return

	# Safety net
	if is_attacking and not sprite.is_playing():
		is_attacking        = false
		has_hit_this_swing  = false
		current_attack      = ""
		_disable_attack_hitbox()

	# Get ACTUAL 2D distance, not just horizontal
	var actual_dist : float = global_position.distance_to(player.global_position)

	match current_state:
		State.IDLE:   _state_idle(actual_dist)
		State.CHASE:  _state_chase(actual_dist)
		State.ATTACK: _state_attack(actual_dist)
		State.DODGE:  _state_dodge()

	move_and_slide()

# -------------------------------------------------------
# STATES
# -------------------------------------------------------

func _state_idle(distance: float) -> void:
	velocity.x = 0
	_play_animation("idle")
	
	# Only chase if player is in detection zone (Area2D confirms it)
	if player_in_detection_zone:
		_face_player()
		current_state = State.CHASE


func _state_chase(distance: float) -> void:

	# Lost player (exited detection area)
	if not player_in_detection_zone:
		velocity.x = 0
		current_state = State.IDLE
		return

	# Close enough to attack
	if distance <= attack_range_far and state_change_buffer <= 0.0:
		velocity.x = 0
		state_change_buffer = STATE_BUFFER
		current_state = State.ATTACK
		return

	_face_player()
	velocity.x = facing_direction * speed

	# Random hop
	if is_on_floor() and chase_jump_timer <= 0.0:
		chase_jump_timer = chase_jump_delay + randf_range(0.0, 1.5)
		if randf() < chase_jump_chance:
			_do_jump()
			return

	_play_animation("run" if is_on_floor() else "jump")


func _state_attack(distance: float) -> void:
	velocity.x = 0

	if not is_attacking:
		_face_player()

	# Player escaped
	if distance > attack_range_far * 1.5 and not is_attacking and state_change_buffer <= 0.0:
		current_attack      = ""
		state_change_buffer = STATE_BUFFER
		current_state       = State.CHASE
		return

	if is_attacking:
		return

	if attack_timer > 0.0:
		_play_animation("idle")
		return

	# Build attack pool
	var available : Array[String] = []
	if distance <= attack_range_close:
		available.append("attack_1")
	if distance <= attack_range_mid:
		available.append("attack_2")
	if distance <= attack_range_far:
		available.append("attack_3")

	if available.is_empty():
		state_change_buffer = STATE_BUFFER
		current_state       = State.CHASE
		return

	_commit_attack(available[randi() % available.size()])


func _commit_attack(attack_name: String) -> void:
	is_attacking       = true
	has_hit_this_swing = false
	current_attack     = attack_name
	attack_timer       = attack_cooldown

	_play_animation(attack_name)

	if attack_hitbox:
		attack_hitbox.monitoring  = true
		attack_hitbox.monitorable = true
		# Check already-overlapping bodies
		for body in attack_hitbox.get_overlapping_bodies():
			_on_attack_hit(body)


func _state_dodge() -> void:
	if not is_on_floor():
		velocity.x = dodge_direction * dodge_speed
		_play_animation("jump")


func _on_dodge_landed() -> void:
	_face_player()
	_resume_after_hit()


func _resume_after_hit() -> void:
	if not player:
		current_state = State.IDLE
		return
	
	var dist := global_position.distance_to(player.global_position)
	if player_in_detection_zone and dist <= attack_range_far:
		current_state = State.ATTACK
	elif player_in_detection_zone:
		current_state = State.CHASE
	else:
		current_state = State.IDLE

# -------------------------------------------------------
# DAMAGE / DEATH
# -------------------------------------------------------

func take_damage(damage: int) -> void:
	if is_dead:
		return

	health -= damage

	# Knockback
	var kb_dir : int = -facing_direction
	if player:
		kb_dir = sign(global_position.x - player.global_position.x)
		if kb_dir == 0:
			kb_dir = -facing_direction

	velocity.x = kb_dir * knockback_force
	velocity.y = -knockback_up

	hit_stun_timer = 0.35
	is_in_hit_stun = true
	is_attacking   = false
	has_hit_this_swing = false
	current_attack = ""
	current_state  = State.HIT
	_disable_attack_hitbox()
	_play_animation("hit")

	if health <= 0:
		_die()
		return

	# Try dodge
	if dodge_cooldown_timer <= 0.0 and not is_dodging and randf() < dodge_chance:
		_start_dodge_jump()


func _start_dodge_jump() -> void:
	if player:
		dodge_direction = -sign(player.global_position.x - global_position.x)
		if dodge_direction == 0:
			dodge_direction = 1
	else:
		dodge_direction = -facing_direction

	is_attacking       = false
	has_hit_this_swing = false
	current_attack     = ""
	is_in_hit_stun     = false
	is_dodging         = true
	dodge_grace_timer  = 0.12
	current_state      = State.DODGE
	facing_direction   = dodge_direction

	_disable_attack_hitbox()
	_apply_facing()

	velocity.y = jump_strength
	velocity.x = dodge_direction * dodge_speed
	_play_animation("jump")


func _do_jump() -> void:
	velocity.y = jump_strength
	_play_animation("jump")


func _die() -> void:
	is_dead            = true
	is_in_hit_stun     = false
	is_dodging         = false
	is_attacking       = false
	has_hit_this_swing = false
	current_attack     = ""
	current_state      = State.DEATH
	velocity.x         = 0

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
		is_attacking       = false
		has_hit_this_swing = false
		current_attack     = ""
		_disable_attack_hitbox()
		return

	match anim:
		"hit":
			is_in_hit_stun = false
			_resume_after_hit()
		"death":
			queue_free()

# -------------------------------------------------------
# DETECTION AREA SIGNALS (NEW)
# -------------------------------------------------------

func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_detection_zone = true


func _on_detection_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_detection_zone = false

# -------------------------------------------------------
# HITBOX SIGNALS
# -------------------------------------------------------

func _on_attack_hit(body: Node2D) -> void:
	if has_hit_this_swing:
		return
	if not is_attacking:
		return
	if body.is_in_group("player"):
		# Double-check distance
		var dist := global_position.distance_to(body.global_position)
		if dist <= attack_range_far + 20.0:
			has_hit_this_swing = true
			if body.has_method("take_damage"):
				body.take_damage(attack_damage, facing_direction)


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
	var diff : float = player.global_position.x - global_position.x
	if absf(diff) > 5.0 and not is_in_hit_stun and not is_attacking:
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
