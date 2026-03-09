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

# --- HIT FLASH / INVULN VISUALS (no hurt animation) ---
@export var hurt_flash_time: float = 0.12
@export var invuln_time: float = 0.5
@export var blink_interval: float = 0.08

var _base_modulate: Color


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	was_on_floor = is_on_floor()
	jumps_left = max_jumps

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = true

	_base_modulate = animated_sprite.modulate

@onready var jump_sound = $jump_sound
@onready var double_jump_sound = $double_jump_sound

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
		velocity.x = move_toward(velocity.x, 0.0, speed) # smooth stop
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

	# attack input
	if Input.is_action_just_pressed("attack_1"):
		start_attack(1)

	if Input.is_action_just_pressed("attack_2"):
		start_attack(2)

	if Input.is_action_just_pressed("attack_3"):
		start_attack(3)
	
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
	update_facing_direction()
	_update_attack_hitbox_position()


func _update_attack_hitbox_position() -> void:
	# keep the hitbox in front of the player
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

func start_attack(num: int) -> void:
	if hitstunned or dead or is_attacking:
		return

	is_attacking = true
	animated_locked = true
	combo_step = num

	animated_sprite.play("attack_%d" % num)

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
		is_attacking = false
		combo_step = 0
		queue_attacks = 0
		animated_locked = false


func _start_attack_hit_once() -> void:
	# prevents multiple hits spamming in the same attack animation
	if _attack_running:
		return
	_attack_running = true
	_do_attack_hit()


func _do_attack_hit() -> void:
	attack_hitbox.monitoring = true

	# IMPORTANT: wait for physics to update overlaps
	await get_tree().physics_frame

	var areas := attack_hitbox.get_overlapping_areas()
	var bodies := attack_hitbox.get_overlapping_bodies()

	for a in areas:
		# walk up parents to find script that has take_damage
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

	# invulnerability immediately
	invulnerable = true

	# interrupt attacks
	is_attacking = false
	_attack_running = false
	attack_hitbox.monitoring = false
	queue_attacks = 0
	combo_step = 0

	# short hit pause (smooth)
	hitstunned = true
	animated_locked = true
	velocity.x = 0

	# red flash
	if animated_sprite:
		animated_sprite.modulate = Color(1, 0.25, 0.25, 1)
	await get_tree().create_timer(hurt_flash_time).timeout
	if animated_sprite:
		animated_sprite.modulate = _base_modulate

	# regain control fast
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

	# wait before restarting
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func is_dead() -> bool:
	return dead

@onready var sword_sound := get_node_or_null("SwordSound") as AudioStreamPlayer2D
