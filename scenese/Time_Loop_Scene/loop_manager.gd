extends Node

@onready var player = $"../player_time_loop"
@onready var ghosts_container = $"../Ghosts"
@export var ghost_scene : PackedScene

var loop_duration := 5.0
var timer := 0.0
var spawn_position : Vector2

func _ready():
	spawn_position = player.global_position
	
func _physics_process(delta):
	timer += delta
	if timer >= loop_duration:
		end_loop()

func end_loop():
	timer = 0.0

	if ghosts_container.get_child_count() > 0:
		ghosts_container.get_child(0).queue_free()

	var loop_copy = player.get_node("Loop").recording.duplicate(true)

	var ghost = ghost_scene.instantiate()
	ghost.global_position = player.global_position
	ghost.get_node("GhostPlayback").recording = loop_copy

	ghosts_container.add_child(ghost)

	player.get_node("Loop").recording.clear()
	player.global_position = spawn_position
	player.velocity = Vector2.ZERO
