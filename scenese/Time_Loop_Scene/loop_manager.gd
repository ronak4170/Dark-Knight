extends Node

signal loop_reset

@onready var player = $"../player_time_loop"
@onready var ghosts_container = $"../Ghosts"
@export var ghost_scene : PackedScene
var spawn_position : Vector2
var loop_duration := 8
var timer := 0.0

func _ready():
	while not player.is_on_floor():
		await get_tree().physics_frame
	await get_tree().physics_frame
	spawn_position = player.global_position

func _physics_process(delta):
	timer += delta
	if timer >= loop_duration:
		end_loop()

func end_loop():
	emit_signal("loop_reset")
	timer = 0.0
	if ghosts_container.get_child_count() > 0:
		ghosts_container.get_child(0).queue_free()
	var loop_copy = player.get_node("Loop").recording.duplicate(true)
	player.velocity = Vector2.ZERO
	reset_player_state(player)
	player.global_position = spawn_position

	var ghost = ghost_scene.instantiate()
	ghosts_container.add_child(ghost)
	ghost.get_node("GhostPlayback").recording = loop_copy
	ghost.set_deferred("global_position", spawn_position)
	player.get_node("Loop").recording.clear()

func reset_player_state(p):
	p.carrying_torch = false
	p.is_attacking = false
	p.combo_step = 0
	p.queue_attacks = 0
	p.animated_locked = false
	p.is_defending = false
	p.knockback_velocity = Vector2.ZERO
	p.invincible = false
	p.invincible_timer = 0.0
	p.jumps_left = p.max_jumps
	p.animated_sprite.modulate = Color(1, 1, 1, 1)
	p.animated_sprite.play("idle")
	if p.attack_hitbox:
		p.attack_hitbox.monitoring = false
