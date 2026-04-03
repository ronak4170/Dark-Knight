extends CharacterBody2D

@export var min_speed: float = 150.0
@export var max_speed: float = 500.0
@export var accel: float = 1800.0

@export var hover_height: float = 40.0
@export var stop_distance: float = 8.0
@export var attack_distance: float = 12.0

@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var attack_hit_delay: float = 0.12  # tweak to match hit frame

@export var max_hp: int = 3
var hp: int

@export var hurt_time: float = 0.18

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


@onready var bat_attack_sound: AudioStreamPlayer2D = $BatAttackSound

var player: Node2D = null
var can_attack: bool = true
var dead: bool = false
var attacking: bool = false
var hitstunned: bool = false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hp = max_hp
	add_to_group("enemy")

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
		anim.play("fly")


func _physics_process(delta: float) -> void:
	if dead:
		return

	# hurt pause (smooth slow-down)
	if hitstunned:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		move_and_slide()
		return

	# find player
	if player == null or not is_instance_valid(player):
		player = get_player()

	# no player: slow down
	if player == null:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		_play_fly_if_exists()
		move_and_slide()
		return

	# stop everything if player dead
	if player.has_method("is_dead") and player.is_dead():
		can_attack = false
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		_play_fly_if_exists()
		move_and_slide()
		return

	# move to hover above player
	var hover_point: Vector2 = player.global_position + Vector2(0.0, -hover_height)
	var to_hover: Vector2 = hover_point - global_position
	var dist: float = to_hover.length()

	if dist > stop_distance:
		var t: float = clamp(dist / 300.0, 0.0, 1.0)
		var desired_speed: float = lerp(min_speed, max_speed, t)
		var desired_vel: Vector2 = to_hover.normalized() * desired_speed
		velocity = velocity.move_toward(desired_vel, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		if dist <= attack_distance:
			try_attack()

	# animation
	if velocity.length() > 5.0:
		_play_fly_if_exists()

	move_and_slide()


func _play_fly_if_exists() -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
		if anim.animation != "fly" or not anim.is_playing():
			anim.play("fly")


func try_attack() -> void:
	if dead or hitstunned or not can_attack:
		return
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("is_dead") and player.is_dead():
		return

	can_attack = false
	attacking = true

	# play attack anim (or fallback wait)
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
	else:
		await get_tree().physics_frame

	# play bat sound (independent of anim)
	if bat_attack_sound and bat_attack_sound.stream:
		bat_attack_sound.pitch_scale = randf_range(0.95, 1.05)
		bat_attack_sound.play()

	# sync damage to "hit" moment
	await get_tree().create_timer(attack_hit_delay).timeout

	# if got hurt/died during delay, cancel
	if dead or hitstunned:
		attacking = false
		return

	if player and is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(attack_damage)

	# cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	attacking = false

	if not dead and not hitstunned:
		_play_fly_if_exists()


func take_damage(amount: int) -> void:
	if dead:
		return

	hp -= amount
	print("BAT TOOK DAMAGE! HP:", hp)

	hitstunned = true
	can_attack = false
	attacking = false

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Bat-Hurt"):
		anim.play("Bat-Hurt")

	await get_tree().create_timer(hurt_time).timeout

	hitstunned = false

	if hp <= 0:
		die()
		return

	can_attack = true
	_play_fly_if_exists()


func die() -> void:
	if dead:
		return

	dead = true
	can_attack = false
	velocity = Vector2.ZERO

	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false

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
