extends Area2D

@export var player_path: NodePath
@export_file("*.tscn") var next_level_scene: String

var player: CharacterBody2D
var transitioning := false

func _ready() -> void:
	player = get_node_or_null(player_path) as CharacterBody2D

	if player == null:
		push_error("DoorExit: player_path is wrong.")
		return

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if transitioning:
		return

	if body == player:
		transitioning = true
		get_tree().change_scene_to_file(next_level_scene)
