extends Node2D

@export var level_music: AudioStream
@onready var player = $player3
@onready var bat1 = $Bat
@onready var bat2 = $"Bat2"
@onready var memory_fragment = $memory_fragment

var first_dialogue = preload("res://scenese/Level_3_Scene/Dialogue/first.dialogue")
var second_dialogue = preload("res://scenese/Level_3_Scene/Dialogue/second.dialogue")
var orb_dialogue = preload("res://scenese/Level_3_Scene/Dialogue/orb_collect.dialogue")

var dialogue_running := false
var bat1_killed := false
var bat2_killed := false
var orb_touched := false

func _ready():
	Music.play_music(level_music)
	$instr_3.show_instruction("Use L-shift to defend. Use J,K and L to attack ")
	
	bat2.hide()
	bat2.process_mode = Node.PROCESS_MODE_DISABLED
	
	memory_fragment.body_entered.connect(_on_orb_touched)
	bat1.tree_exited.connect(_on_bat1_killed)

func _on_bat1_killed() -> void:
	if bat1_killed:
		return
	bat1_killed = true
	await play_dialogue(first_dialogue, "first")
	# Bat2 appears after first dialogue
	bat2.show()
	bat2.process_mode = Node.PROCESS_MODE_INHERIT
	bat2.tree_exited.connect(_on_bat2_killed)

func _on_bat2_killed() -> void:
	if bat2_killed:
		return
	bat2_killed = true
	# Lock player and zoom camera
	player.can_move = false
	player.velocity = Vector2.ZERO
	player.animated_sprite.play("idle")
	var camera = player.get_node("Camera2D")
	var original_zoom = camera.zoom
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", original_zoom * 1.8, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	await zoom_tween.finished
	await play_dialogue(second_dialogue, "second")
	# Unlock player and zoom back out
	player.can_move = true
	player.animated_locked = false
	player.is_attacking = false
	player.animated_sprite.play("idle")
	var zoom_out = create_tween()
	zoom_out.tween_property(camera, "zoom", original_zoom, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_orb_touched(body: Node) -> void:
	if not body.is_in_group("player") or orb_touched:
		return
	orb_touched = true
	while dialogue_running:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	await play_dialogue(orb_dialogue, "orb_collect")

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title)
	await DialogueManager.dialogue_ended
	dialogue_running = false
