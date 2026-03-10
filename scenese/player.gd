extends CharacterBody2D

@export var speed : float = 300.0
@export var jump_velocity = -360.0
@export var max_jumps : int = 2
@export var double_jump_velocity : float = -300.0
@export var max_health : int = 100
@export var attack_damage : int = 15

@export var knockback_friction : float = 800.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_hitbox = $AttackHitbox
@export var footstep_left: AudioStream
@export var footstep_right: AudioStream

@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayerFinalLevel

var last_run_frame := -1

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
var low_health_notified : bool = false

var attack_safety_timer : float = 0.0
var attack_safety_limit : float = 2.0

var knockback_velocity : Vector2 = Vector2.ZERO

var warning_label : Label = null
var warning_timer : float = 0.0
var warning_visible : bool = false

func _ready():
	if not is_in_group("player"):
		add_to_group("player")

	health = max_health
	was_on_floor = is_on_floor()
	jumps_left = max_jumps

	if attack_hitbox:
		if not attack_hitbox.is_in_group("player_attack"):
			attack_hitbox.add_to_group("player_attack")
		attack_hitbox.monitoring = false
		attack_hitbox.set("damage", attack_damage)

	setup_warning_label()

func setup_warning_label():
	warning_label = Label.new()
	warning_label.text = "⚠ LOW HEALTH ⚠"
	warning_label.add_theme_font_size_override("font_size", 24)
	warning_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	warning_label.position = Vector2(-80, -120)
	warning_label.visible = false
	add_child(warning_label)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Safety reset — force clears stuck attack state after 2 seconds
	if is_attacking:
		attack_safety_timer += delta
		if attack_safety_timer >= attack_safety_limit:
			reset_attack_state()
	else:
		attack_safety_timer = 0.0

	# Flash warning label
	if warning_visible:
		warning_timer -= delta
		if warning_timer <= 0:
			warning_visible = false
			warning_label.visible = false
		else:
			warning_label.modulate.a = 0.5 + 0.5 * sin(warning_timer * 10)

	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
			animated_sprite.modulate = Color(1, 1, 1, 1)
		else:
			animated_sprite.modulate = Color(1, 1, 1, 0.5 + 0.5 * sin(invincible_timer * 30))

	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_defending and Input.is_action_just_pressed("jump") and jumps_left > 0:
		if jumps_left == max_jumps:
			jump()
		else:
			double_jump()
		jumps_left -= 1

	if Input.is_action_pressed("defend") and is_on_floor():
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
		knockback_velocity = Vector2.ZERO
		move_and_slide()
		update_facing_direction()
		check_deadly_tile()
		return

	if Input.is_action_just_pressed("attack"):
		handle_attack_input()

	if knockback_velocity.x != 0:
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, knockback_friction * delta)
		velocity.x = knockback_velocity.x
	elif is_attacking:
		velocity.x = 0
	else:
		direction = Input.get_vector("left", "right", "up", "down")
		if direction.x != 0 and animated_sprite.animation != "jump_end":
			velocity.x = direction.x * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

	if knockback_velocity.y != 0:
		velocity.y = knockback_velocity.y
		knockback_velocity.y = 0

	var prev_on_floor := was_on_floor

	move_and_slide()
	check_deadly_tile()

	var on_floor_now := is_on_floor()
	was_on_floor = on_floor_now

	if on_floor_now:
		jumps_left = max_jumps

	if on_floor_now and not prev_on_floor:
		if velocity.y > 100:
			land()
		else:
			animated_locked = false

	if knockback_velocity.x == 0:
		update_animation()
		_handle_run_footsteps()
		update_facing_direction()

func reset_attack_state():
	is_attacking = false
	combo_step = 0
	queue_attacks = 0
	animated_locked = false
	attack_safety_timer = 0.0
	if attack_hitbox:
		attack_hitbox.monitoring = false

func take_damage(damage: int, knockback_dir: int = 0) -> void:
	if is_dead or invincible or is_defending:
		if is_defending:
			print("Player blocked!")
		return

	health -= damage
	invincible = true
	invincible_timer = invincible_duration

	# Reset attack state so knockback never leaves player frozen
	reset_attack_state()

	animated_sprite.modulate = Color(1, 0.3, 0.3, 1)

	if knockback_dir != 0:
		knockback_velocity.x = knockback_dir * 280.0
		knockback_velocity.y = -150.0

	if health <= max_health * 0.3 and not low_health_notified:
		low_health_notified = true
		show_low_health_warning()

	if health <= 0:
		die()

func show_low_health_warning():
	if warning_label == null:
		return
	warning_label.visible = true
	warning_visible = true
	warning_timer = 3.0

func check_deadly_tile():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is TileMap:
			var tilemap : TileMap = collider
			var tile_pos = tilemap.local_to_map(collision.get_position())
			var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
			if tile_data and tile_data.get_custom_data("deadly"):
				die()
				return

func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	reset_attack_state()
	animated_sprite.modulate = Color(1, 1, 1, 1)
	animated_sprite.play("death")

func update_animation():
	if is_defending or is_dead:
		return
	if not animated_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		else:
			if direction.x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")

func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
		if attack_hitbox:
			attack_hitbox.position.x = abs(attack_hitbox.position.x)
	elif direction.x < 0:
		animated_sprite.flip_h = true
		if attack_hitbox:
			attack_hitbox.position.x = -abs(attack_hitbox.position.x)

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

func handle_attack_input():
	if not is_attacking:
		is_attacking = true
		animated_locked = true
		attack_safety_timer = 0.0
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

func _on_animated_sprite_2d_animation_finished():
	if is_dead and animated_sprite.animation == "death":
		await get_tree().process_frame
		get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)
		return

	if is_defending:
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
			reset_attack_state()

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var knockback_dir = 1 if body.global_position.x > global_position.x else -1
		body.take_damage(attack_damage, knockback_dir)

func apply_external_push(x_force: float, y_force: float) -> void:
	velocity.x += x_force
	velocity.y += y_force
	
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
