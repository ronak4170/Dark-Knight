extends Area2D

@export var fragment_id: String = "fragment_1"

var collected: bool = false

func _ready():
	add_to_group("memory_fragment")
	
	# make sure monitoring is ON
	monitoring = true
	monitorable = true
	
	body_entered.connect(_on_body_entered)
	
	# scale down
	scale = Vector2(0.3, 0.3)
	
	# floating animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 8, 1.0)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 1.0)\
		.set_trans(Tween.TRANS_SINE)
	
	print("Fragment ready - groups: ", get_groups())

func _on_body_entered(body):
	# this debug line will tell us exactly what's happening
	print("Something entered fragment: ", body.name, " | groups: ", body.get_groups())
	
	if collected:
		return
		
	if body.is_in_group("player_group") or body.is_in_group("player"):
		_collect()

func _collect():
	if collected:
		return
	collected = true
	print("MEMORY COLLECTED!")
	
	Global.collect_memory()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.15)\
		.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
