extends Node2D

@export var level_music: AudioStream

var one_dialogue = preload("res://scenese/Switch_Level_Scene/Dialogue/one.dialogue")
var dialogue_running := false

func _ready() -> void:
	Music.play_music(level_music)
	await get_tree().create_timer(0.5).timeout
	await play_dialogue(one_dialogue, "one")

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title)
	await DialogueManager.dialogue_ended
	dialogue_running = false
