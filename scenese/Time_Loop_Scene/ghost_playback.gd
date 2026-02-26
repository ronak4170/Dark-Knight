extends Node

var recording := []
var playback_index := 0
@onready var controller = get_parent()

func _ready():
	controller.is_ghost = true
	
	var sprite = controller.get_node("AnimatedSprite2D")
	sprite.modulate = Color(1, 1, 1, 0.75) 

func _physics_process(delta):

	if playback_index < recording.size():
		controller.input_data = recording[playback_index]
		playback_index += 1
	else:
		controller.input_data = {}

	controller.process_frame(delta)
