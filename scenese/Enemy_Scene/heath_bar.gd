extends Node2D

@onready var bar = $TextureProgressBar
@onready var label = $Label

func _ready():
	if bar == null:
		push_error("HealthBar: TextureProgressBar not found")
		return
	
	bar.min_value = 0
	bar.max_value = 200
	bar.value = 200
	
	# Give it color without needing textures
	bar.tint_progress = Color(0.0, 0.9, 0.0)  # green fill
	bar.tint_under = Color(0.3, 0.0, 0.0)     # dark red background
	
	if label != null:
		label.text = "200 / 200"

func update_health(current : int, maximum : int):
	if bar == null:
		return
	
	bar.max_value = maximum
	bar.value = current
	
	var percent = float(current) / float(maximum)
	
	if percent > 0.5:
		bar.tint_progress = Color(0.0, 0.9, 0.0)   # green
	elif percent > 0.25:
		bar.tint_progress = Color(1.0, 0.8, 0.0)   # yellow
	else:
		bar.tint_progress = Color(0.9, 0.0, 0.0)   # red
	
	if label != null:
		label.text = str(current) + " / " + str(maximum)
