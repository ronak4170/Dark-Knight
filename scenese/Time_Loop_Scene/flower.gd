extends Area2D

signal purified
signal unpurified

var nearby_bodies := []
var is_active := false

@onready var prompt_label = $Label

func _ready():
	prompt_label.visible = false

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	nearby_bodies.append(body)
	if not body.is_ghost:
		prompt_label.visible = true
		await get_tree().create_timer(2.0).timeout
		prompt_label.visible = false

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	nearby_bodies.erase(body)
	prompt_label.visible = false
	if nearby_bodies.is_empty() and is_active:
		is_active = false
		emit_signal("unpurified")

func _process(_delta):
	if is_active or nearby_bodies.is_empty():
		return
	for body in nearby_bodies:
		if body.input_data.get("interact", false):
			is_active = true
			prompt_label.visible = false
			emit_signal("purified")
			break
