extends Area2D

@export var switch_puzzle_path: NodePath
@export var hint_label_path: NodePath
@export var popup_panel_path: NodePath
@export var popup_label_path: NodePath

@export var fade_time: float = 0.15

var player_in_range := false
var hint_label: Label
var popup_panel: Control
var popup_label: Label
var puzzle: Node
var hint_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	puzzle = get_node_or_null(switch_puzzle_path)
	hint_label = get_node_or_null(hint_label_path) as Label
	popup_panel = get_node_or_null(popup_panel_path) as Control
	popup_label = get_node_or_null(popup_label_path) as Label

	if hint_label:
		hint_label.visible = false
		var c := hint_label.modulate
		c.a = 0.0
		hint_label.modulate = c

	if popup_panel:
		popup_panel.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_show_statue_text()

func _show_statue_text() -> void:
	if popup_panel == null or popup_label == null:
		return

	var solved := false
	if puzzle and "solved" in puzzle:
		solved = puzzle.solved

	if solved:
		popup_label.text = "Thou be cautious!"
	else:
		popup_label.text = "Thou shalt not pass — the switches are not aligned."

	popup_panel.visible = true

	# auto-hide after 2 seconds (optional)
	await get_tree().create_timer(2.0).timeout
	if popup_panel:
		popup_panel.visible = false

func _fade_hint(show: bool) -> void:
	if hint_label == null:
		return

	if hint_tween and hint_tween.is_running():
		hint_tween.kill()

	if show:
		hint_label.visible = true

	var end_a := 1.0 if show else 0.0
	hint_tween = create_tween()
	hint_tween.tween_property(hint_label, "modulate:a", end_a, fade_time)

	if not show:
		hint_tween.tween_callback(func(): hint_label.visible = false)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		_fade_hint(true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		_fade_hint(false)
		if popup_panel:
			popup_panel.visible = false
