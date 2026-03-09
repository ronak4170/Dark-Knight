extends Area2D

signal torch_picked_up

var has_torch := true
var nearby_bodies := []

@onready var prompt_label = $Label

func _ready():
	prompt_label.visible = false

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	nearby_bodies.append(body)
	if not body.is_ghost and has_torch and not body.carrying_torch:
		prompt_label.visible = true
		await get_tree().create_timer(2.0).timeout
		prompt_label.visible = false

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	nearby_bodies.erase(body)
	prompt_label.visible = false

func _process(_delta):
	if not has_torch:
		return
	for body in nearby_bodies:
		if body.input_data.get("interact", false) and not body.carrying_torch:
			pick_up(body)
			break

func pick_up(body):
	has_torch = false
	prompt_label.visible = false
	body.carrying_torch = true
	emit_signal("torch_picked_up")

func respawn():
	has_torch = true
