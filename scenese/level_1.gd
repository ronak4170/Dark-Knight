extends Node2D

func _ready():
	$Node2d.show_instruction("Press A/D to move")
	
	
func _on_lvl_1_2_body_entered(PhysicsBody2D) -> void:
	$Node2d.show_instruction("Press E to move to the next level")
