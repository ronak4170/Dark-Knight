extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -360.0
@export var max_jumps: int = 2
@export var double_jump_velocity: float = -300.0

@export var max_hp := 10
var hp: int
var invulnerable := false

@export var attack_damage: int = 1
@export var attack_active_time: float = 0.12

# tweak these so the hitbox sits in front of player
@export var hitbox_x_offset: float = 30.0
@export var hitbox_y_offset: float = -10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox

@export var footstep_left: AudioStream
@export var footstep_right: AudioStream

@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayerDarkLevel

var last_run_frame := -1

var animated_locked: bool = false
var direction: Vector2 = Vector2.ZERO
var jumps_left: int
var is_attacking: bool = false
var combo_step: int = 0
var queue_attacks: int = 0
var was_on_floor: bool = false
var is_defending: bool = false
var dead: bool = false

var _attack_running: bool = false
var hitstunned: bool = false

# --- HIT FLASH / INVULN VISUALS ---
@export var hurt_flash_time: float = 0.12
@export var invuln_time: float = 0.5
@export var blink_interval: float = 0.08

var _base_modulate: Color

# --- RESPAWN ---
var respawn_point: Vector2 = Vector2.ZERO

@onready var sword_sound := get_node_or_null("SwordSound") as AudioStreamPlayer2D
@onready var tilemap = get_parent().get_node("TileMap")


func _ready() -> void:
	add_to_group("player")
	add_to_group("player_group")
	hp = max_hp
	was_on_floor = is_on_floor()
	jumps_left = max_jumps

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = true

	_base_modulate = animated_sprite.modulate

	Global.reset_memory()
	# count fragments in this level
	await get_tree().process_frame  # wait for all nodes to be ready
	Global.memory_total = get_tree().get_nodes_in_group("memory_fragment").size()
	print("Total fragments in level: ", Global.memory_total)
	
	# Save respawn point
	var spawn = get_tree().get_first_node_in_group("spawn_point")
	if spawn:
		respawn_point = spawn.global_position
	else:
		respawn_point = global_position


func _physics_process(delta: float) -> void:
	# dead: just fall + slide (no input)
	if dead:
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		_update_attack_hitbox_position()
		update_facing_direction()
		return

	# hitstun: brief lockout (still gravity)
	if hitstunned:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0.0, speed)
		move_and_slide()
		_update_attack_hitbox_position()
		update_facing_direction()
		return

	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# defend (hold)
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
		move_and_slide()
		update_facing_direction()
		return

	# jump / double jump
	if Input.is_action_just_pressed("jump") and jumps_left > 0 and not is_defending:
		if jumps_left == max_jumps:
			jump()
		else:
			double_jump()
		jumps_left -= 1

	# attack input
	if Input.is_action_just_pressed("attack"):
		handle_attack_input()

	# movement
	if is_attacking:
		velocity.x = 0
	else:
		direction = Input.get_vector("left", "right", "up", "down")
		if direction.x != 0 and animated_sprite.animation != "jump_end":
			velocity.x = direction.x * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

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
	_update_attack_hitbox_position()

	# check spike tiles
	_check_spike_collision()


func _check_spike_collision() -> void:
	if dead or invulnerable:
		return
	if not tilemap:
		return
	var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	for offset in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var tile_data = tilemap.get_cell_tile_data(0, tile_pos + offset)
		if tile_data and tile_data.get_custom_data("is_spike"):
			instant_die()
			return


func _update_attack_hitbox_position() -> void:
	var dir := 1.0
	if animated_sprite.flip_h:
		dir = -1.0
	attack_hitbox.position = Vector2(hitbox_x_offset * dir, hitbox_y_offset)


func update_animation() -> void:
	if is_defending or hitstunned or dead:
		return

	if not animated_locked:
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


func handle_attack_input() -> void:
	if hitstunned or dead:
		return

	if is_attacking:
		if combo_step + queue_attacks < 3:
			queue_attacks += 1
		return

	# start combo
	is_attacking = true
	animated_locked = true
	combo_step = 1
	queue_attacks = 0
	animated_sprite.play("attack_1")
	if sword_sound:
		sword_sound.play()
	_start_attack_hit_once()


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_defending or hitstunned or dead:
		return

	if animated_sprite.animation == "jump_end" or animated_sprite.animation == "jump_start":
		animated_locked = false
		return

	if animated_sprite.animation.begins_with("attack_"):
		if queue_attacks > 0 and combo_step < 3:
			queue_attacks -= 1
			combo_step += 1
			animated_sprite.play("attack_%d" % combo_step)
			_start_attack_hit_once()
		else:
			is_attacking = false
			combo_step = 0
			queue_attacks = 0
			animated_locked = false


func _start_attack_hit_once() -> void:
	if _attack_running:
		return
	_attack_running = true
	_do_attack_hit()


func _do_attack_hit() -> void:
	attack_hitbox.monitoring = true

	await get_tree().physics_frame

	var areas := attack_hitbox.get_overlapping_areas()
	var bodies := attack_hitbox.get_overlapping_bodies()

	for a in areas:
		var n: Node = a
		var steps := 0
		while n != null and steps < 6:
			if n.has_method("take_damage"):
				n.take_damage(attack_damage)
				break
			n = n.get_parent()
			steps += 1

	for b in bodies:
		if b.has_method("take_damage"):
			b.take_damage(attack_damage)

	await get_tree().create_timer(attack_active_time).timeout
	attack_hitbox.monitoring = false
	_attack_running = false


func take_damage(amount: int) -> void:
	if invulnerable or is_defending or dead:
		return

	hp -= amount
	print("Player took damage! HP:", hp)

	invulnerable = true

	# interrupt attacks
	is_attacking = false
	_attack_running = false
	attack_hitbox.monitoring = false
	queue_attacks = 0
	combo_step = 0

	# short hit pause
	hitstunned = true
	animated_locked = true
	velocity.x = 0

	# red flash
	if animated_sprite:
		animated_sprite.modulate = Color(1, 0.25, 0.25, 1)
	await get_tree().create_timer(hurt_flash_time).timeout
	if animated_sprite:
		animated_sprite.modulate = _base_modulate

	# regain control
	hitstunned = false
	animated_locked = false

	# blink while invulnerable
	var elapsed := 0.0
	while elapsed < invuln_time and not dead:
		if animated_sprite:
			animated_sprite.visible = false
		await get_tree().create_timer(blink_interval).timeout
		if animated_sprite:
			animated_sprite.visible = true
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval * 2.0

	# restore visuals
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate = _base_modulate

	invulnerable = false

	if hp <= 0:
		die()


func instant_die() -> void:
	if dead or invulnerable:
		return
	hp = 0
	die()


func die() -> void:
	if dead:
		return
	dead = true

	is_attacking = false
	is_defending = false
	animated_locked = true
	invulnerable = true
	hitstunned = false

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false

	velocity = Vector2.ZERO

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished

	print("PLAYER DIED")

	await get_tree().create_timer(1.0).timeout
	_respawn()


func _respawn() -> void:
	# reset position
	global_position = respawn_point

	# reset all states
	dead = false
	invulnerable = false
	hitstunned = false
	animated_locked = false
	is_attacking = false
	is_defending = false
	_attack_running = false
	combo_step = 0
	queue_attacks = 0

	# reset stats
	hp = max_hp
	velocity = Vector2.ZERO
	jumps_left = max_jumps

	# reset hitbox
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = true

	# reset visuals
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate = _base_modulate
		animated_sprite.play("idle")

	print("PLAYER RESPAWNED")

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
		elif frame == 3:
			_play_footstep(footstep_right)

	last_run_frame = frame
	
func _play_footstep(sound: AudioStream) -> void:
	if footstep_player == null or sound == null:
		return

	footstep_player.stream = sound
	footstep_player.play()

func is_dead() -> bool:
	return dead
