extends CanvasLayer

@export var show_time: float = 2.5  

func show_instruction(text: String, duration: float = -1):
	if duration <= 0:
		duration = show_time
	$Panel/Label.text = text
	$Panel.visible = true
	await get_tree().create_timer(duration).timeout
	$Panel.visible = false
