extends Node2D

func _ready():
	$Instr_2.show_instruction("Use Space to jump / press space twice to double jump")
	DialogueManager.show_dialogue_balloon(preload("res://scenese/Level_1_Scene/Level1.dialogue"), "start")
