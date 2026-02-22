extends CharacterBody2D

@export var min_speed: float = 150.0
@export var max_speed: float = 500.0
@export var accel: float = 1800.0

@export var hover_height: float = 40.0
@export var stop_distance: float = 8.0
@export var attack_distance: float = 12.0

@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0

@export var max_hp: int = 3
var hp: int

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var player: Node2D = null
var can_attack: bool = true
var dead: bool = false
var attacking: bool = false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hp = max_hp
	add_to_group("enemy")
	
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
		anim.play("fly") # guarantees playing = true

func _physics_process(delta: float) -> void:
	if dead:
		return

	if player == null or not is_instance_valid(player):
		player = get_player()

	if player == null:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		move_and_slide()
		return
		
	#  if no player, just slow down
	if player == null:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		move_and_slide()
		return

	#  STOP EVERYTHING if player is dead
	if player.has_method("is_dead") and player.is_dead():
		can_attack = false
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
			if anim.animation != "fly" or not anim.is_playing():
				anim.play("fly")
		move_and_slide()
		return
		
	# Move to a point above the player's head
	var hover_point: Vector2 = player.global_position + Vector2(0.0, -hover_height)
	var to_hover: Vector2 = hover_point - global_position
	var dist: float = to_hover.length()

	# Arrive behavior (no overshoot)
	if dist > stop_distance:
		var t: float = clamp(dist / 300.0, 0.0, 1.0)
		var desired_speed: float = lerp(min_speed, max_speed, t)
		var desired_vel: Vector2 = to_hover.normalized() * desired_speed
		velocity = velocity.move_toward(desired_vel, accel * delta)

		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
			if anim.animation != "fly" or not anim.is_playing():
				anim.play("fly")
	else:
		# Snap exactly to hover point so it doesn't drift past
		global_position = hover_point
		velocity = Vector2.ZERO

		# Attack when positioned correctly above player
		if dist <= attack_distance:
			try_attack()
			
	var moving := velocity.length() > 5.0
	if anim and anim.sprite_frames:
		if moving and anim.sprite_frames.has_animation("fly"):
			if anim.animation != "fly" or not anim.is_playing():
				anim.play("fly")

	move_and_slide()


func try_attack() -> void:
	if dead or not can_attack:
		return
	if player == null or not is_instance_valid(player):
		return

	#  don't attack dead player
	if player.has_method("is_dead") and player.is_dead():
		return

	can_attack = false
	attacking = true
	
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		attacking = true
	else:
		# if no attack anim, just don't get stuck
		await get_tree().physics_frame
			
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

	# cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	attacking = false

	#  force fly after attack
	if not dead and anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
		anim.play("fly")

func take_damage(amount: int) -> void:
	if dead:
		return

	hp -= amount
	print("BAT TOOK DAMAGE! HP:", hp)

	if hp <= 0:
		die()


func die() -> void:
	if dead:
		return

	dead = true
	can_attack = false
	velocity = Vector2.ZERO

	# Disable hitbox so it stops interacting
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false

	# Play death animation if it exists
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("die"):
		anim.play("die")
		await anim.animation_finished

	print("BAT DIED")
	queue_free()


func get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
