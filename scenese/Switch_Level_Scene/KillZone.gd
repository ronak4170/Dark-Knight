# KillZone.gd
extends Area2D

@export var player_path: NodePath
@export var respawn_point_path: NodePath

var player: CharacterBody2D
var respawn_point: Marker2D

func _ready() -> void:
	player = get_node_or_null(player_path) as CharacterBody2D
	respawn_point = get_node_or_null(respawn_point_path) as Marker2D

	if player == null:
		push_error("KillZone: player_path is wrong")
		return
	if respawn_point == null:
		push_error("KillZone: respawn_point_path is wrong")
		return

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == player:
		player.global_position = respawn_point.global_position
		player.velocity = Vector2.ZERO

		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.reset_smoothing()

		for sw_path in ["../Switch1-Area", "../Switch2-Area", "../Switch3-Area", "../Switch4-Area"]:
			var sw := get_node_or_null(sw_path)
			if sw and sw.has_method("reset_to_default"):
				sw.call("reset_to_default")

		var puzzle := get_node_or_null("../SwitchPuzzle")
		if puzzle and puzzle.has_method("reset_puzzle"):
			puzzle.call("reset_puzzle")
