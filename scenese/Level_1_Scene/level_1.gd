extends Node2D

@onready var player = $player
@onready var orb_spot = $Orb_spot
@onready var memory_fragment = $memory_fragment
@onready var instr_1 = $Instr_1

var intro_dialogue = preload("res://scenese/Level_1_Scene/Dialogue/intro.dialogue")
var moving_dialogue = preload("res://scenese/Level_1_Scene/Dialogue/move.dialogue")
var orb_spot_dialogue = preload("res://scenese/Level_1_Scene/Dialogue/orb_spot.dialogue")
var orb_collect_dialogue = preload("res://scenese/Level_1_Scene/Dialogue/orb_collect.dialogue")

var opening_done := false
var intro_done := false
var orb_spotted := false
var orb_touched := false
var dialogue_running := false

func _ready() -> void:
	player.can_move = false
	player.animated_locked = true
	player.animated_sprite.play("revive")
	player.animated_sprite.speed_scale = 0.5
	orb_spot.body_entered.connect(_on_orb_spotted)
	memory_fragment.body_entered.connect(_on_orb_touched)
	start_intro_sequence()

func start_intro_sequence() -> void:
	var camera = player.get_node("Camera2D")
	var original_zoom = Vector2(5.5, 5.5)

	# Zoom in while revive is already playing
	camera.zoom = Vector2(8.0, 8.0)

	# Wait for revive to finish
	await player.animated_sprite.animation_finished
	player.animated_sprite.speed_scale = 1.0
	player.animated_locked = false

	# Zoom out dramatically
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", original_zoom, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	await zoom_tween.finished

	# Frozen dialogue
	await play_dialogue(intro_dialogue, "intro_locked")

	# Unlock player
	player.can_move = true
	opening_done = true
	instr_1.show_instruction("Press A/D to move")

	await get_tree().create_timer(1.0).timeout
	await play_dialogue(moving_dialogue, "intro_moving")
	intro_done = true

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title)
	await DialogueManager.dialogue_ended
	dialogue_running = false

func _on_orb_spotted(body: Node) -> void:
	if not body.is_in_group("player") or not intro_done or orb_spotted or dialogue_running:
		return
	orb_spotted = true
	await play_dialogue(orb_spot_dialogue, "orb_spot")

func _on_orb_touched(body: Node) -> void:
	if not body.is_in_group("player") or not intro_done or orb_touched:
		return
	orb_touched = true
	while dialogue_running:
		await get_tree().process_frame
	await play_dialogue(orb_collect_dialogue, "orb_collect")

func _on_lvl_1_2_body_entered(body: PhysicsBody2D) -> void:
	if body.is_in_group("player"):
		instr_1.show_instruction("Press E to move to the next level")


func _on_orb_spot_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
