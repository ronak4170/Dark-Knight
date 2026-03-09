# fragileTilePlayer.gd
extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -360.0
@export var double_jump_velocity: float = -300.0
@export var max_jumps: int = 2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var footstep_left: AudioStream
@export var footstep_right: AudioStream

@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayerFallDownToDarkLevel

@onready var jump_sound = $jump_sound
@onready var double_jump_sound = $double_jump_sound

var last_run_frame := -1

var direction: Vector2 = Vector2.ZERO
var jumps_left: int = 0
var animated_locked: bool = false
var was_on_floor: bool = false

func _ready() -> void:
	if not is_in_group("player"):
		add_to_group("player")

	was_on_floor = is_on_floor()
	jumps_left = max_jumps


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Horizontal movement
	direction = Input.get_vector("left", "right", "up", "down")
	if direction.x != 0 and animated_sprite.animation != "jump_end":
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Jump / Double jump
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		if jumps_left == max_jumps:
			jump_sound.play()
			jump()
		else:
			double_jump()
			double_jump_sound.play()
		if jumps_left == max_jumps:
			velocity.y = jump_velocity
		else:
			velocity.y = double_jump_velocity
		
		jumps_left -= 1

	var prev_on_floor := was_on_floor
	move_and_slide()

	var on_floor_now := is_on_floor()
	was_on_floor = on_floor_now

	# Reset jumps when grounded
	if on_floor_now:
		jumps_left = max_jumps

	# Landing animation when you touch ground after being in air
	if on_floor_now and not prev_on_floor:
		land()

	update_animation()
	_handle_run_footsteps()
	update_facing_direction()

func jump() -> void:
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animated_locked = true

func double_jump() -> void:
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_start")
	animated_locked = true

func land() -> void:
	animated_sprite.play("jump_end")
	animated_locked = true

func update_animation() -> void:
	if animated_locked:
		return

	if not is_on_floor():
		animated_sprite.play("jump_loop")
	else:
		if direction.x != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

func update_facing_direction() -> void:
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func _on_animated_sprite_2d_animation_finished() -> void:
	# Unlock after jump transitions
	if animated_sprite.animation == "jump_start" or animated_sprite.animation == "jump_end":
		animated_locked = false
		
func _handle_run_footsteps() -> void:
	if animated_sprite.animation != "run":
		last_run_frame = -1
		return

	if not is_on_floor():
		last_run_frame = -1
		return

	var frame := animated_sprite.frame

	if frame != last_run_frame:
		if frame == 0:
			_play_footstep(footstep_left)
		elif frame == 4:
			_play_footstep(footstep_right)

	last_run_frame = frame
	
func _play_footstep(sound: AudioStream) -> void:
	if footstep_player == null or sound == null:
		return

	footstep_player.stream = sound
	footstep_player.play()
