extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Instr_2.show_instruction("Use Space to jump / press space twice to double jump")
	Music.play_track(preload("res://audio/level2.ogg"))
