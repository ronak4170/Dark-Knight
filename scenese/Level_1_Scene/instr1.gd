extends Node2D

@export var default_duration := 2.5
@export var offset := Vector2(10, 80) 

@onready var panel = $Panel
@onready var label = $Panel/Label

# show instruction near player 
func show_instruction(text: String, duration: float = -1):
	if duration <= 0:
		duration = default_duration

	label.text = text
	panel.visible = true
	panel.modulate.a = 0 

	# position above player
	var player = get_tree().get_root().get_node("Level1/player") 
	global_position = player.global_position + offset

	var fade_time = 0.3
	var timer = 0.0
	while timer < fade_time:
		panel.modulate.a = timer / fade_time
		timer += get_process_delta_time()
		await get_tree().process_frame
	
	panel.modulate.a = 1.0 


	await get_tree().create_timer(duration).timeout

	timer = 0.0
	while timer < fade_time:
		panel.modulate.a = 1.0 - (timer / fade_time)
		timer += get_process_delta_time()
		await get_tree().process_frame

	panel.visible = false
