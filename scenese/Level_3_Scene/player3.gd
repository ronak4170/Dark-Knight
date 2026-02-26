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


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	was_on_floor = is_on_floor()
	jumps_left = max_jumps

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = true


func _physics_process(delta: float) -> void:
	if dead:
		velocity += get_gravity() * delta
		move_and_slide()
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
	update_facing_direction()
	_update_attack_hitbox_position()


func _update_attack_hitbox_position() -> void:
	# keep the hitbox in front of the player
	var dir := 1.0
	if animated_sprite.flip_h:
		dir = -1.0
	attack_hitbox.position = Vector2(hitbox_x_offset * dir, hitbox_y_offset)


func update_animation() -> void:
	if is_defending:
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
	_start_attack_hit_once()


func _on_animated_sprite_2d_animation_finished() -> void:
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
			_start_attack_hit_once()
		else:
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
	print("==== ATTACK START ====")

	attack_hitbox.monitoring = true

	# IMPORTANT: wait for physics to update overlaps
	await get_tree().physics_frame

	var areas := attack_hitbox.get_overlapping_areas()
	var bodies := attack_hitbox.get_overlapping_bodies()

	print("Areas count:", areas.size())
	print("Bodies count:", bodies.size())

	for a in areas:
		print("HIT AREA:", a.name, " parent:", a.get_parent().name)

		# walk up parents to find script that has take_damage
		var n: Node = a
		var steps := 0
		while n != null and steps < 6:
			if n.has_method("take_damage"):
				print(">>> DAMAGE TARGET:", n.name)
				n.take_damage(attack_damage)
				break
			n = n.get_parent()
			steps += 1

	for b in bodies:
		print("HIT BODY:", b.name)
		if b.has_method("take_damage"):
			print(">>> DAMAGE TARGET:", b.name)
			b.take_damage(attack_damage)

	await get_tree().create_timer(attack_active_time).timeout
	attack_hitbox.monitoring = false
	_attack_running = false

	print("==== ATTACK END ====")




func take_damage(amount: int) -> void:
	if invulnerable or is_defending:
		return

	hp -= amount
	print("Player took damage! HP:", hp)

	invulnerable = true
	await get_tree().create_timer(0.5).timeout
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

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false

	velocity = Vector2.ZERO

	if animated_sprite and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished

	print("PLAYER DIED")

	# wait before restarting
	await get_tree().create_timer(2.0).timeout
	
	get_tree().reload_current_scene()
	
func is_dead() -> bool:
	return dead
