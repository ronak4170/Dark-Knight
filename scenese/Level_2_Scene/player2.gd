extends CharacterBody2D

@export var speed : float = 300.0
@export var jump_velocity = -360.0
@export var max_jumps : int = 2
@export var double_jump_velocity : float = -300.0
@export var max_health : int = 100
@export var attack_damage : int = 15

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_hitbox = $AttackHitbox

@onready var jump_sound: AudioStreamPlayer2D = $jump_sound
@onready var double_jump_sound: AudioStreamPlayer2D = $double_jump_sound

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

func _ready():
	if not is_in_group("player"):
		add_to_group("player")
	
	print("Player groups: ", get_groups())
	

	health = max_health
	was_on_floor = is_on_floor()
	jumps_left = max_jumps
	
	if attack_hitbox:
		if not attack_hitbox.is_in_group("player_attack"):
			attack_hitbox.add_to_group("player_attack")
		attack_hitbox.monitoring = false
		attack_hitbox.set("damage", attack_damage)
		print("AttackHitbox groups: ", attack_hitbox.get_groups())

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
			animated_sprite.modulate.a = 1.0
		else:
			animated_sprite.modulate.a = 0.5 + 0.5 * sin(invincible_timer * 30)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_defending and Input.is_action_just_pressed("jump") and jumps_left > 0:
		if jumps_left == max_jumps:
			jump_sound.play()
			jump()
		else:
			double_jump_sound.play()
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
		move_and_slide()
		update_facing_direction()
		check_deadly_tile()
		return
	
	if Input.is_action_just_pressed("attack"):
		handle_attack_input()
	
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
	
	update_animation()
	update_facing_direction()

func take_damage(damage: int):
	if is_dead or invincible or is_defending:
		if is_defending:
			print("Player blocked the attack!")
		return
	
	health -= damage
	invincible = true
	invincible_timer = invincible_duration
	animated_sprite.modulate = Color(1, 0.3, 0.3, 1)
	print("Player took ", damage, " damage! Health: ", health, "/", max_health)
	
	if health <= 0:
		die()

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
	animated_locked = true
	animated_sprite.play("death")
	print("Player died!")

func update_animation():
	
	if is_defending or is_dead or is_attacking:
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

func handle_attack_input():
	if not is_attacking:
		is_attacking = true
		animated_locked = true
		combo_step = 1
		queue_attacks = 0
		animated_sprite.play("attack_1")
		print("Player attacking! Combo step: ", combo_step)
		enable_attack_hitbox()
		return
	if combo_step + queue_attacks < 3:
		queue_attacks += 1
		print("Attack queued! Queue: ", queue_attacks)

func enable_attack_hitbox():
	if attack_hitbox:
		await get_tree().create_timer(0.2).timeout
		if is_attacking:
			attack_hitbox.monitoring = true
			print("Player attack hitbox ENABLED")
			await get_tree().create_timer(0.3).timeout
			attack_hitbox.monitoring = false
			print("Player attack hitbox DISABLED")

func _on_animated_sprite_2d_animation_finished():
	if is_dead and animated_sprite.animation == "death":
		await get_tree().process_frame
		get_tree().reload_current_scene()
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
			print("Combo continues! Step: ", combo_step)
			enable_attack_hitbox()
		else:
			is_attacking = false
			combo_step = 0
			queue_attacks = 0
			animated_locked = false
			print("Combo finished!")

func _on_hitbox_body_entered(body: Node2D) -> void:
	pass
