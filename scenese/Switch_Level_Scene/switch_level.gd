extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	DialogueManager.show_dialogue_balloon(preload("res://scenese/Switch_Level_Scene/Level4.dialogue"), "start")
