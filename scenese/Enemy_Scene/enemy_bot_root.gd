extends Node2D

@export var level_music: AudioStream
@export var next_scene: String = "res://scenese/Final/final.tscn"

@onready var player = $player
@onready var boss = $Boss
@onready var camera = $player/Camera2D

var first_dialogue = preload("res://scenese/Enemy_Scene/Dialogue/first.dialogue")
var second_dialogue = preload("res://scenese/Enemy_Scene/Dialogue/second.dialogue")
var third_dialogue = preload("res://scenese/Enemy_Scene/Dialogue/third.dialogue")

var dialogue_running := false
var half_health_cutscene_done := false
var final_cutscene_done := false

var player_spawn: Vector2
var boss_spawn: Vector2

var input_canvas: CanvasLayer = null
var input_box: LineEdit = null
var player_answered_correctly := false
var input_confirmed := false

func _ready() -> void:
	Music.play_music(level_music)
	player_spawn = player.global_position
	boss_spawn = boss.global_position
	boss.can_act = false
	player.can_move = false
	boss.half_health_reached.connect(_on_half_health_reached)
	boss.boss_defeated.connect(_on_boss_defeated)
	await get_tree().create_timer(0.5).timeout
	await _play_opening_cutscene()

func _play_opening_cutscene() -> void:
	camera.top_level = true
	var original_zoom = camera.zoom
	var midpoint = (player.global_position + boss.global_position) / 2.0
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "global_position", midpoint, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.parallel().tween_property(camera, "zoom", original_zoom * 0.6, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await zoom_tween.finished

	await play_dialogue(first_dialogue, "first")

	var return_tween = create_tween()
	return_tween.tween_property(camera, "zoom", original_zoom, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await return_tween.finished
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.offset = Vector2.ZERO

	player.can_move = true
	player.animated_locked = false
	boss.can_act = true
	boss.attack_timer.start()
	boss.teleport_timer.start()

func _on_half_health_reached() -> void:
	if half_health_cutscene_done:
		return
	half_health_cutscene_done = true

	boss.can_act = false
	boss.attack_timer.stop()
	boss.teleport_timer.stop()
	player.can_move = false
	player.velocity = Vector2.ZERO

	player.global_position = player_spawn
	boss.global_position = boss_spawn
	
	player.is_attacking = false
	player.is_defending = false
	player.animated_locked = false
	player.animated_sprite.play("idle")
	boss.is_attacking = false
	boss.animated_sprite.play("idle")

	camera.top_level = true
	var original_zoom = camera.zoom
	var midpoint = (player.global_position + boss.global_position) / 2.0
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "global_position", midpoint, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.parallel().tween_property(camera, "zoom", original_zoom * 0.6, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await zoom_tween.finished

	await play_dialogue(second_dialogue, "second")

	var return_tween = create_tween()
	return_tween.tween_property(camera, "zoom", original_zoom, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await return_tween.finished
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.offset = Vector2.ZERO

	boss.enter_phase_two_buffed(player_answered_correctly)
	if player_answered_correctly:
		player.attack_damage = int(player.attack_damage * 2.0)
		player.health = min(player.health + 20, player.max_health)
		if player.attack_hitbox:
			player.attack_hitbox.set("damage", player.attack_damage)

	player.can_move = true
	player.animated_locked = false

# Called by Dialogue Manager via "do show_input_box()" in second.dialogue
func show_input_box() -> void:
	await _show_input_box()

func _show_input_box() -> void:
	input_confirmed = false

	input_canvas = CanvasLayer.new()
	input_canvas.layer = 10
	add_child(input_canvas)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -50)
	input_canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "What are you?"
	label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label)

	input_box = LineEdit.new()
	input_box.placeholder_text = "Type your answer..."
	input_box.custom_minimum_size = Vector2(400, 40)
	input_box.add_theme_font_size_override("font_size", 18)
	vbox.add_child(input_box)

	var confirm_button = Button.new()
	confirm_button.text = "Confirm"
	confirm_button.pressed.connect(_on_input_confirmed)
	vbox.add_child(confirm_button)

	input_box.grab_focus()

	# Wait until player confirms
	while not input_confirmed:
		if not is_inside_tree():
			return
		await get_tree().process_frame

func _on_input_confirmed() -> void:
	if input_box == null:
		return
	var answer = input_box.text.strip_edges()
	player_answered_correctly = answer.to_lower() == "murderer"
	input_confirmed = true
	if input_canvas:
		input_canvas.queue_free()
		input_canvas = null

func _on_boss_defeated() -> void:
	if final_cutscene_done:
		return
	final_cutscene_done = true
	boss.can_act = false
	if boss.attack_timer:
		boss.attack_timer.stop()
	if boss.teleport_timer:
		boss.teleport_timer.stop()
	player.can_move = false
	player.velocity = Vector2.ZERO
	await _play_final_cutscene()

func _play_final_cutscene() -> void:
	camera.top_level = true
	var original_zoom = camera.zoom
	var midpoint = (player.global_position + boss.global_position) / 2.0
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "global_position", midpoint, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.parallel().tween_property(camera, "zoom", original_zoom * 0.6, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await zoom_tween.finished

	await play_dialogue(third_dialogue, "third")

	# Fade to black
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)
	var fade_tween = create_tween()
	fade_tween.tween_property(fade, "color:a", 1.0, 1.5)
	await fade_tween.finished

	get_tree().change_scene_to_file(next_scene)

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title, [self])
	await DialogueManager.dialogue_ended
	dialogue_running = false
