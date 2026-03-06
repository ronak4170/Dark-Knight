extends Area2D

signal checkpoint_activated

var player_nearby := false
var activated := false

@onready var prompt_label = $Label

func _ready():
	prompt_label.visible = false
	monitoring = false

func _on_body_entered(body):
	if body.is_in_group("player") and not body.is_ghost and not activated:
		player_nearby = true
		prompt_label.visible = true
		await get_tree().create_timer(2.0).timeout
		prompt_label.visible = false

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		prompt_label.visible = false

func _process(_delta):
	if player_nearby and not activated and Input.is_action_just_pressed("interact"):
		activated = true
		prompt_label.visible = false
		emit_signal("checkpoint_activated")
