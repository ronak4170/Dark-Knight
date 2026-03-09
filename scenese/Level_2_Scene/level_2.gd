extends Node2D

@onready var memory_fragment = $memory_fragment
@onready var instr_2 = $Instr_2

var move_dialogue = preload("res://scenese/Level_2_Scene/Dialogue/move.dialogue")
var orb_dialogue = preload("res://scenese/Level_2_Scene/Dialogue/orb_collect.dialogue")

var orb_touched := false
var dialogue_running := false

func _ready() -> void:
	
	$Instr_2.show_instruction("Use Space to jump / press space twice to double jump")
	# Start move dialogue at level start
	await get_tree().create_timer(0.5).timeout
	await play_dialogue(move_dialogue, "move")

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title)
	await DialogueManager.dialogue_ended
	dialogue_running = false
