extends CharacterBody2D

# =============================
# EXPORTS
# =============================
@export var speed : float = 300.0
@export var jump_velocity = -360.0
@export var max_jumps : int = 2
@export var double_jump_velocity : float = -300.0
@export var max_health : int = 100
@export var attack_damage : int = 15
@export var knockback_friction : float = 800.0
@export var footstep_left: AudioStream
@export var footstep_right: AudioStream
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayerTimeLoop

var last_run_frame := -1

# =============================
# STATE
# =============================
var input_data := {}
var is_ghost : bool = false

var animated_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var jumps_left : int
var is_attacking : bool = false
var combo_step : int = 0
var queue_attacks : int = 0
var was_on_floor : bool = false
var is_defending : bool = false
var is_dead : bool = false
var health : int
var invincible : bool = false
var invincible_duration : float = 0.5
var invincible_timer : float = 0.0
var knockback_velocity : Vector2 = Vector2.ZERO
var carrying_torch : bool = false

# =============================
# NODES
# =============================
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_hitbox = $AttackHitbox

# =============================
# INIT
# =============================
func _ready():
	add_to_group("player")

	health = max_health
	was_on_floor = is_on_floor()
	jumps_left = max_jumps

	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.set("damage", attack_damage)

# =============================
# MAIN FRAME LOGIC
# =============================
func process_frame(delta):

	if is_dead:
		return

	# Invincibility (player only)
	if invincible and not is_ghost:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
			animated_sprite.modulate = Color(1,1,1,1)
		else:
			animated_sprite.modulate = Color(1,1,1,0.5 + 0.5 * sin(invincible_timer * 30))

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Direction
	direction = input_data.get("move", Vector2.ZERO)

	# Jump
	if not is_defending and input_data.get("jump", false) and jumps_left > 0:
		if jumps_left == max_jumps:
			jump()
		else:
			double_jump()
		jumps_left -= 1

	# Defend
	if input_data.get("defend", false) and is_on_floor():
		is_defending = true
		animated_locked = true
		if animated_sprite.animation != "defend":
			animated_sprite.play("defend")
	else:
		if is_defending:
			is_defending = false
			animated_locked = false

	if is_defending:
		velocity.x = 0
		move_and_slide()
		update_facing_direction()
		return

	# Attack
	if input_data.get("attack", false):
		handle_attack_input()

	# Horizontal movement
	if knockback_velocity.x != 0:
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, knockback_friction * delta)
		velocity.x = knockback_velocity.x
	elif is_attacking:
		velocity.x = 0
	else:
		velocity.x = direction.x * speed

	if knockback_velocity.y != 0:
		velocity.y = knockback_velocity.y
		knockback_velocity.y = 0

	var prev_on_floor := was_on_floor

	move_and_slide()

	var on_floor_now := is_on_floor()
	was_on_floor = on_floor_now

	if on_floor_now:
		jumps_left = max_jumps

	if on_floor_now and not prev_on_floor:
		if velocity.y > 100:
			land()
		else:
			animated_locked = false

	update_animation()
	_handle_run_footsteps()
	update_facing_direction()

# =============================
# DAMAGE
# =============================
func take_damage(damage: int, knockback_dir: int = 0):
	if is_ghost:
		return

	if is_dead or invincible or is_defending:
		return

	health -= damage
	invincible = true
	invincible_timer = invincible_duration
	animated_sprite.modulate = Color(1,0.3,0.3,1)

	if knockback_dir != 0:
		knockback_velocity.x = knockback_dir * 280.0
		knockback_velocity.y = -150.0

	if health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	animated_locked = true
	animated_sprite.play("death")

func _on_animated_sprite_2d_animation_finished():
	if is_dead and animated_sprite.animation == "death":
		if not is_ghost:
			get_tree().reload_current_scene()
		return

	if animated_sprite.animation == "jump_end" or animated_sprite.animation == "jump_start":
		animated_locked = false
		return

	if animated_sprite.animation.begins_with("attack_"):
		if queue_attacks > 0 and combo_step < 3:
			queue_attacks -= 1
			combo_step += 1
			animated_sprite.play("attack_%d" % combo_step)
			enable_attack_hitbox()
		else:
			is_attacking = false
			combo_step = 0
			queue_attacks = 0
			animated_locked = false

# =============================
# ATTACK
# =============================
func handle_attack_input():
	if not is_attacking:
		is_attacking = true
		animated_locked = true
		combo_step = 1
		queue_attacks = 0
		animated_sprite.play("attack_1")
		enable_attack_hitbox()
		return
	if combo_step + queue_attacks < 3:
		queue_attacks += 1

func enable_attack_hitbox():
	if attack_hitbox:
		await get_tree().create_timer(0.2).timeout
		if is_attacking:
			attack_hitbox.monitoring = true
			await get_tree().create_timer(0.3).timeout
			attack_hitbox.monitoring = false

# =============================
# ANIMATION
# =============================
func update_animation():
	if is_defending or is_dead:
		return
	if not animated_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		elif direction.x != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func jump():
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animated_locked = true

func land():
	animated_sprite.play("jump_end")
	animated_locked = true

func double_jump():
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_start")
	animated_locked = true
	
func _handle_run_footsteps() -> void:
	if animated_sprite.animation != "run":
		last_run_frame = -1
		return

	if not is_on_floor():
		last_run_frame = -1
		return

	var frame = animated_sprite.frame

	if frame != last_run_frame:
		if frame == 0:
			_play_footstep(footstep_left)
		elif frame == 3:
			_play_footstep(footstep_right)

	last_run_frame = frame
	
func _play_footstep(sound: AudioStream) -> void:
	if footstep_player == null or sound == null:
		return

	footstep_player.stream = sound
	footstep_player.play()
