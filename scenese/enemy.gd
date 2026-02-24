extends CharacterBody2D

# -------------------------------------------------------
# EXPORTS
# -------------------------------------------------------

@export var speed              : float = 90.0
@export var detection_range    : float = 400.0
@export var gravity            : float = 900.0
@export var max_health         : int   = 100
@export var attack_damage      : int   = 10
@export var attack_cooldown    : float = 1.2

@export var attack_range_close : float = 80.0
@export var attack_range_mid   : float = 130.0
@export var attack_range_far   : float = 180.0

@export var hit_stun_time      : float = 0.35

# -------------------------------------------------------
# STATES
# -------------------------------------------------------

enum State { IDLE, CHASE, ATTACK, HIT, DEATH }
var current_state : State = State.IDLE

# -------------------------------------------------------
# VARIABLES
# -------------------------------------------------------

var player : CharacterBody2D = null
var health : int = 0

var attack_timer : float = 0.0
var is_attacking : bool = false
var has_hit_this_swing : bool = false
var is_dead : bool = false

var facing_direction : int = 1
var attack_hitbox_original_position : Vector2

var hit_stun_timer : float = 0.0
var is_in_hit_stun : bool = false

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

	# Force one-shot animations
	for anim in ["attack_1", "attack_2", "attack_3", "hit", "death"]:
		if sprite.sprite_frames.has_animation(anim):
			sprite.sprite_frames.set_animation_loop(anim, false)

	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)

	if attack_hitbox:
		attack_hitbox.monitoring = false
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
	attack_timer = maxf(0.0, attack_timer - delta)
	hit_stun_timer = maxf(0.0, hit_stun_timer - delta)

	# Hit stun
	if is_in_hit_stun:
		if hit_stun_timer <= 0.0:
			is_in_hit_stun = false
			current_state = State.CHASE
		move_and_slide()
		return

	var distance : float = absf(player.global_position.x - global_position.x)

	match current_state:
		State.IDLE:
			_state_idle(distance)
		State.CHASE:
			_state_chase(distance)
		State.ATTACK:
			_state_attack(distance)

	move_and_slide()

# -------------------------------------------------------
# STATES
# -------------------------------------------------------

func _state_idle(distance: float) -> void:
	velocity.x = 0
	_play_animation("idle")

	if distance <= detection_range:
		current_state = State.CHASE


func _state_chase(distance: float) -> void:

	if distance > detection_range:
		velocity.x = 0
		current_state = State.IDLE
		return

	if distance <= attack_range_far:
		velocity.x = 0
		current_state = State.ATTACK
		return

	_face_player()
	velocity.x = facing_direction * speed
	_play_animation("run")


func _state_attack(distance: float) -> void:

	velocity.x = 0

	if distance > attack_range_far:
		current_state = State.CHASE
		return

	if is_attacking:
		return

	if attack_timer > 0.0:
		_play_animation("idle")
		return

	var available : Array[String] = []

	if distance <= attack_range_close:
		available.append("attack_1")
	if distance <= attack_range_mid:
		available.append("attack_2")
	if distance <= attack_range_far:
		available.append("attack_3")

	if available.is_empty():
		current_state = State.CHASE
		return

	_commit_attack(available[randi() % available.size()])

# -------------------------------------------------------
# ATTACK
# -------------------------------------------------------

func _commit_attack(anim_name: String) -> void:
	is_attacking = true
	has_hit_this_swing = false
	attack_timer = attack_cooldown

	_play_animation(anim_name)

	if attack_hitbox:
		attack_hitbox.monitoring = true
		attack_hitbox.monitorable = true

		for body in attack_hitbox.get_overlapping_bodies():
			_on_attack_hit(body)


func _on_attack_hit(body: Node2D) -> void:

	if has_hit_this_swing:
		return

	if not is_attacking:
		return

	if body.is_in_group("player"):
		has_hit_this_swing = true
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)

# -------------------------------------------------------
# DAMAGE
# -------------------------------------------------------

func take_damage(amount: int) -> void:

	if is_dead:
		return

	health -= amount

	if health <= 0:
		_die()
		return

	is_in_hit_stun = true
	hit_stun_timer = hit_stun_time
	current_state = State.HIT
	_play_animation("hit")


func _die() -> void:
	is_dead = true
	current_state = State.DEATH
	velocity.x = 0

	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false

	if hurtbox:
		hurtbox.monitoring = false
		hurtbox.monitorable = false

	_play_animation("death")

# -------------------------------------------------------
# ANIMATION END
# -------------------------------------------------------

func _on_animation_finished() -> void:

	var anim = sprite.animation

	if anim.begins_with("attack_"):
		is_attacking = false
		has_hit_this_swing = false
		_disable_attack_hitbox()
		return

	if anim == "death":
		queue_free()

# -------------------------------------------------------
# HURTBOX
# -------------------------------------------------------

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		var damage : int = 10
		if "damage" in area:
			damage = area.damage
		take_damage(damage)

# -------------------------------------------------------
# FACING
# -------------------------------------------------------

func _face_player() -> void:
	if player == null:
		return

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
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false


func _play_animation(anim_name: String) -> void:
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)