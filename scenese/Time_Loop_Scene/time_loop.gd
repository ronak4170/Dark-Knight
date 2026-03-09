extends Node2D

func _ready():
	DialogueManager.show_dialogue_balloon(preload("res://scenese/Time_Loop_Scene/Level5.dialogue"), "start")
