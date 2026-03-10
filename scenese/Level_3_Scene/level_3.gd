extends Node2D

@export var level_music: AudioStream
# Called when the node enters the scene tree for the first time.
func _ready():
	Music.play_music(level_music)
	$instr_3.show_instruction("Use L-shift to defend. Use LMB to attack ")
	#DialogueManager.show_dialogue_balloon(preload("res://scenese/Level_1_Scene/Level1.dialogue"), "start")
