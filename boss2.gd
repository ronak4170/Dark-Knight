extends CharacterBody2D

# -----------------------------------
# EXPORTS
# -----------------------------------

@export var max_health : int = 200
@export var teleport_positions : Array[Vector2]
@export var gravity : float = 980.0

# Multiple spell types
@export var normal_spell : PackedScene
@export var fast_spell : PackedScene
@export var homing_spell : PackedScene
@export var heavy_spell : PackedScene
@export var attack_sound_1: AudioStream
@export var attack_sound_2: AudioStream
@export var attack_sound_3: AudioStream



# -----------------------------------
# VARIABLES
# -----------------------------------

var current_health : int
var phase : int = 1
var spell_speed_multiplier : float = 1.0
var damage_multiplier : float = 1.0
var attack_pattern_index : int = 0
var is_attacking : bool = false

@onready var attack_timer = $AttackTimer
@onready var teleport_timer = $TeleportTimer
@onready var spell_spawn = $SpellSpawn
@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSFX

var health_bar = null

# -----------------------------------
# READY
# -----------------------------------

func _ready():
	current_health = max_health

	if has_node("HealthBar"):
		health_bar = $HealthBar
		update_health_bar()

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	attack_timer.start()

	teleport_timer.wait_time = 5.0
	teleport_timer.start()

	animated_sprite.play("idle")

# -----------------------------------
# HEALTH BAR HELPER
# -----------------------------------

func update_health_bar():
	if health_bar != null and health_bar.has_method("update_health"):
		health_bar.update_health(current_health, max_health)

# -----------------------------------
# PHYSICS (GRAVITY + FACING)
# -----------------------------------

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

	if player == null:
		return

	animated_sprite.flip_h = player.global_position.x > global_position.x

	if health_bar != null:
		health_bar.scale.x = sign(scale.x)

# -----------------------------------
# ANIMATION
# -----------------------------------

func _on_animation_finished():
	if animated_sprite.animation == "Attack":
		is_attacking = false
		animated_sprite.play("idle")

func play_attack_animation():
	is_attacking = true
	animated_sprite.play("Attack")

# -----------------------------------
# DAMAGE SYSTEM
# -----------------------------------

func take_damage(amount : int, knockback_dir : int = 0) -> void:
	current_health -= amount
	update_health_bar()

	if current_health <= max_health * 0.5 and phase == 1:
		enter_phase_two()

	if current_health <= 0:
		die()

func enter_phase_two():
	phase = 2
	spell_speed_multiplier = 1.7
	damage_multiplier = 1.5
	attack_timer.wait_time = 0.8

# -----------------------------------
# ATTACK LOGIC
# -----------------------------------

func _on_attack_timer_timeout():
	play_attack_animation()

	match attack_pattern_index:
		0:
			cast_circle_pattern()
		1:
			cast_spread_pattern()
		2:
			cast_fast_burst()
		3:
			cast_homing_attack()
		4:
			cast_heavy_shot()
		5:
			cast_spiral_attack()

	attack_pattern_index = (attack_pattern_index + 1) % 6

# -----------------------------------
# SPELL PATTERNS
# -----------------------------------

func cast_circle_pattern():
	play_attack_sound(attack_sound_1)
	var bullet_count = 12
	for i in bullet_count:
		var angle = i * (TAU / bullet_count)
		spawn_specific_spell(normal_spell, Vector2.RIGHT.rotated(angle))

func cast_spread_pattern():
	if player == null:
		return
	play_attack_sound(attack_sound_1)
	var base_direction = (player.global_position - spell_spawn.global_position).normalized()
	for i in range(-2, 3):
		var spread = base_direction.rotated(deg_to_rad(i * 15))
		spawn_specific_spell(normal_spell, spread)

func cast_fast_burst():
	if player == null:
		return
	play_attack_sound(attack_sound_3)
	var direction = (player.global_position - spell_spawn.global_position).normalized()
	for i in 5:
		spawn_specific_spell(fast_spell, direction)
		await get_tree().create_timer(0.1).timeout

func cast_homing_attack():
	spawn_specific_spell(homing_spell)

func cast_heavy_shot():
	play_attack_sound(attack_sound_2)
	spawn_specific_spell(heavy_spell)

func cast_spiral_attack():
	play_attack_sound(attack_sound_1)
	var bullets = 20
	for i in bullets:
		var angle = i * (TAU / bullets)
		spawn_specific_spell(normal_spell, Vector2.RIGHT.rotated(angle))

# -----------------------------------
# SPELL SPAWNING
# -----------------------------------

func spawn_specific_spell(scene : PackedScene, dir : Vector2 = Vector2.ZERO):
	if scene == null or spell_spawn == null:
		return

	var spell = scene.instantiate()
	get_parent().add_child(spell)
	spell.global_position = spell_spawn.global_position

	if dir == Vector2.ZERO and player != null:
		dir = (player.global_position - spell_spawn.global_position).normalized()

	spell.direction = dir.normalized()
	spell.speed *= spell_speed_multiplier
	spell.damage = int(spell.damage * damage_multiplier)

# -----------------------------------
# TELEPORT SYSTEM
# -----------------------------------

func _on_teleport_timer_timeout():
	if teleport_positions.is_empty():
		return

	var random_pos = teleport_positions.pick_random()
	global_position = random_pos

# -----------------------------------
# DEATH
# -----------------------------------

func die():
	attack_timer.stop()
	teleport_timer.stop()

	$CollisionShape2D.disabled = true
	animated_sprite.play("death")

	await animated_sprite.animation_finished

	queue_free()
	
	
func play_attack_sound(sound: AudioStream) -> void:
	if attack_sfx == null or sound == null:
		return

	attack_sfx.stream = sound
	attack_sfx.play()
