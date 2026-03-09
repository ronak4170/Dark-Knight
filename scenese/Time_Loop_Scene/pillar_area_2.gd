extends Area2D

signal torch_placed
signal body_holding(duration)
signal body_left

var has_torch := false
var nearby_bodies := []

@onready var prompt_label = $Label

func _ready():
	prompt_label.visible = false

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	nearby_bodies.append(body)
	if not body.is_ghost and not has_torch and body.carrying_torch:
		prompt_label.visible = true
		await get_tree().create_timer(2.0).timeout
		prompt_label.visible = false

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	nearby_bodies.erase(body)
	prompt_label.visible = false
	if nearby_bodies.is_empty():
		emit_signal("body_left")

func _process(delta):
	if not has_torch:
		for body in nearby_bodies:
			if body.input_data.get("interact", false) and body.carrying_torch:
				body.carrying_torch = false
				has_torch = true
				prompt_label.visible = false
				emit_signal("torch_placed")
				break
		return

	if not nearby_bodies.is_empty():
		emit_signal("body_holding", 999.0)
	else:
		emit_signal("body_left")

func reset():
	has_torch = false
	prompt_label.visible = false
