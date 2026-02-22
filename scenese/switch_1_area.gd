extends Area2D

signal state_changed(switch_id: int, is_open: bool)

@export var tilemap_path: NodePath
@export var switch_id: int = 1
@export var closed_index: int
@export var open_index: int

@export var hint_label_path: NodePath  # drag your HintLabel here in inspector

var player_in_range := false
var is_open := false
var hint_label: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if hint_label_path != NodePath():
		hint_label = get_node(hint_label_path) as Label
		if hint_label:
			hint_label.visible = false

	var tm := get_node(tilemap_path) as TileMap
	tm.set_layer_enabled(closed_index, true)
	tm.set_layer_enabled(open_index, false)
	is_open = false

	emit_signal("state_changed", switch_id, is_open)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		toggle()

func toggle():
	is_open = !is_open
	var tm := get_node(tilemap_path) as TileMap
	tm.set_layer_enabled(closed_index, not is_open)
	tm.set_layer_enabled(open_index, is_open)
	emit_signal("state_changed", switch_id, is_open)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if hint_label:
			hint_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if hint_label:
			hint_label.visible = false
