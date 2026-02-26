extends Node

var recording := []
@onready var controller = get_parent()

func collect_input():
	return {
		"move": Input.get_vector("left","right","up","down"),
		"jump": Input.is_action_just_pressed("jump"),
		"attack": Input.is_action_just_pressed("attack"),
		"defend": Input.is_action_pressed("defend")
	}

func _physics_process(delta):

	var frame_input = collect_input()
	recording.append(frame_input)

	controller.input_data = frame_input
	controller.process_frame(delta)
