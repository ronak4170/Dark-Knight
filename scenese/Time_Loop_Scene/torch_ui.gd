extends CanvasLayer

@onready var label = $Label

func _ready():
	if label:
		label.text = "🔥 0"
	else:
		push_error("TorchUI: Label node not found")

func set_count(value: int):
	if label:
		label.text = "🔥 " + str(value)

func update_display(value: int):
	if label:
		label.text = "🔥 " + str(value)
