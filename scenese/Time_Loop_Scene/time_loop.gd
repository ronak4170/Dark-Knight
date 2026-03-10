extends Node2D
@export var level_music: AudioStream

func _ready():
	Music.play_music(level_music)
	DialogueManager.show_dialogue_balloon(preload("res://scenese/Time_Loop_Scene/Level5.dialogue"), "start")
