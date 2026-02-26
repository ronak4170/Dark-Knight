extends Node2D

func _ready():
	print("Level 1 _ready ran")
	$Instr_1.show_instruction("Press A/D to move")
	#Music.play_track(preload("res://audio/level1.ogg"))
	print("Music singleton is:", Music)
	
	
func _on_lvl_1_2_body_entered(PhysicsBody2D) -> void:
	$Instr_1.show_instruction("Press E to move to the next level")
