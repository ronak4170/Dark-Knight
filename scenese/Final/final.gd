extends Node2D

var orb_dialogue = preload("res://scenese/Final/Dialgoue/orb_collect.dialogue")
var dialogue_running := false

func _ready() -> void:
	add_to_group("final_level")

func _process(delta: float) -> void:
	pass

func on_orb_collected() -> void:
	await play_dialogue(orb_dialogue, "orb_collect")

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title)
	await DialogueManager.dialogue_ended
	dialogue_running = false
