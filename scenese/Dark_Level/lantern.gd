extends Node2D

@onready var light = $PointLight2D
@onready var area = $Area2D

func _ready():
	light.enabled = true
	light.energy = 0.0
	light.color = Color(1.0, 0.7, 0.2)  # warm orange-yellow
	
	# connect ONLY this lantern's own area signals
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player_group"):
		_fade_light(1.5)

func _on_body_exited(body):
	if body.is_in_group("player_group"):
		_fade_light(0.0)

func _fade_light(target_energy: float):
	var tween = create_tween()
	tween.tween_property(light, "energy", target_energy, 0.8)
