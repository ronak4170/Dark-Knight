extends Node2D

@onready var player = $player
@onready var orb_spot = $Orb_spot
@onready var memory_fragment = $memory_fragment
@onready var instr_1 = $Instr_1

var dialogue_resource = preload("res://scenese/Level_1_Scene/Level1.dialogue")

var opening_done := false
var orb_spotted := false
var orb_touched := false
var dialogue_running := false

func _ready() -> void:
	print("Level 1 _ready ran")

	player.can_move = false

	orb_spot.body_entered.connect(_on_orb_spotted)
	memory_fragment.body_entered.connect(_on_orb_touched)

	start_intro_sequence()


func start_intro_sequence() -> void:
	print("Starting intro_locked")
	await play_dialogue("intro_locked")

	print("intro_locked finished -> unlocking player")
	player.can_move = true
	opening_done = true

	instr_1.show_instruction("Press A/D to move")

	# Small delay so the unlock clearly happens first
	await get_tree().process_frame

	print("Starting intro_moving")
	play_dialogue("intro_moving")


func play_dialogue(title: String) -> void:
	if dialogue_running:
		print("Dialogue already running, skipped: ", title)
		return

	dialogue_running = true
	print("Showing dialogue: ", title)
	DialogueManager.show_dialogue_balloon(dialogue_resource, title)
	await DialogueManager.dialogue_ended
	print("Dialogue ended: ", title)
	dialogue_running = false


func _on_orb_spotted(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not opening_done:
		return
	if orb_spotted:
		return
	if dialogue_running:
		return

	orb_spotted = true
	play_dialogue("orb_spotted")


func _on_orb_touched(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not opening_done:
		return
	if orb_touched:
		return
	if dialogue_running:
		return

	orb_touched = true
	play_dialogue("orb_touched")


func _on_lvl_1_2_body_entered(body: PhysicsBody2D) -> void:
	if body.is_in_group("player"):
		instr_1.show_instruction("Press E to move to the next level")
