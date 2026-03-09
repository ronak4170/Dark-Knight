extends Node

@onready var player = $"../player_time_loop"
@onready var orb_spot = $"../Orb_spot"
@onready var memory_fragment = $"../memory_fragment"

var dialogue_resource = preload("res://scenese/Level_1_Scene/level1.dialogue")
var orb_spotted := false
var orb_touched := false

func _ready():
	player.set_process(false)
	player.set_physics_process(false)
	orb_spot.body_entered.connect(_on_orb_spotted)
	memory_fragment.body_entered.connect(_on_orb_touched)
	await get_tree().create_timer(1.0).timeout
	start_opening_dialogue()

func start_opening_dialogue():
	player.set_process(true)
	player.set_physics_process(true)
	var balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	await balloon.dialogue_finished

func _on_orb_spotted(body):
	if not body.is_in_group("player") or body.is_ghost or orb_spotted:
		return
	orb_spotted = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, "orb_spotted")

func _on_orb_touched(body):
	if not body.is_in_group("player") or body.is_ghost or orb_touched:
		return
	orb_touched = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, "orb_touched")
