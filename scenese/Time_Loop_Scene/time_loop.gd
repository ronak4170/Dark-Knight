extends Node2D

@export var level_music: AudioStream

@onready var player = $player_time_loop
@onready var loop_manager = $LoopManager
@onready var puzzle_manager = $PuzzleManager
@onready var camera = $player_time_loop/Camera2D
@onready var ghosts_container = $Ghosts
@onready var checkpoint = $Checkpoint

# Dialogue resources
var loop1_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/loop1.dialogue")
var loop1cont_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/loop1cont.dialogue")
var loop2_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/loop2.dialogue")
var loop3_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/loop3.dialogue")
var checkpoint1_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/checkpoint1.dialogue")
var checkpoint2_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/checkpoint2.dialogue")
var cutscene_dialogue = preload("res://scenese/Time_Loop_Scene/Dialogue/cutscene.dialogue")

# State
var loop_count_before_checkpoint: int = 0
var loop_count_after_checkpoint: int = 0
var checkpoint_activated: bool = false
var dialogue_running: bool = false
var cutscene_done: bool = false

func _ready() -> void:
	Music.play_music(level_music)
	loop_manager.loop_reset.connect(_on_loop_reset)
	puzzle_manager.connect("puzzle_solved_signal", _on_puzzle_solved)
	await get_tree().create_timer(0.5).timeout
	await _handle_loop_start()

func _on_checkpoint_activated_signal() -> void:
	on_checkpoint_activated()
	
func _on_loop_reset() -> void:
	if checkpoint_activated:
		loop_count_after_checkpoint += 1
	else:
		loop_count_before_checkpoint += 1
	# Wait for any currently running dialogue to finish first
	while dialogue_running:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await _handle_loop_start()

func _handle_loop_start() -> void:
	if checkpoint_activated:
		match loop_count_after_checkpoint:
			0:  
				player.can_move = false
				player.animated_sprite.play("idle")
				await play_dialogue(checkpoint1_dialogue, "checkpoint1")
				player.can_move = true
				player.animated_locked = false
			1:  
				await play_dialogue(checkpoint2_dialogue, "checkpoint2")
			_:
				pass
	else:
		match loop_count_before_checkpoint:
			0:
				player.can_move = false
				player.animated_sprite.play("idle")
				var original_zoom = camera.zoom
				var zoom_tween = create_tween()
				zoom_tween.tween_property(camera, "zoom", original_zoom * 1.5, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
				await zoom_tween.finished
				await play_dialogue(loop1_dialogue, "loop1")
				var zoom_out = create_tween()
				zoom_out.tween_property(camera, "zoom", original_zoom, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
				await zoom_out.finished
				player.can_move = true
				player.animated_locked = false
				await play_dialogue(loop1cont_dialogue, "loop1cont")
			1:
				await play_dialogue(loop2_dialogue, "loop2")
			2:
				await play_dialogue(loop3_dialogue, "loop3")
			_:
				pass

func _on_puzzle_solved() -> void:
	print("PUZZLE SOLVED SIGNAL RECEIVED")
	if cutscene_done:
		return
	cutscene_done = true
	await get_tree().create_timer(0.5).timeout
	await _play_final_cutscene()

func on_checkpoint_activated() -> void:
	print("CHECKPOINT ACTIVATED")
	checkpoint_activated = true
	loop_count_after_checkpoint = 0
	await get_tree().create_timer(0.3).timeout
	await _handle_loop_start()

func _play_final_cutscene() -> void:
	player.can_move = false
	player.animated_sprite.play("idle")

	var ghost = ghosts_container.get_child(0) if ghosts_container.get_child_count() > 0 else null

	camera.top_level = true
	var target_pos: Vector2
	if ghost:
		target_pos = (player.global_position + ghost.global_position) / 2.0
	else:
		target_pos = player.global_position

	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "global_position", target_pos, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.parallel().tween_property(camera, "zoom", Vector2(3.0, 3.0), 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await zoom_tween.finished

	_start_pulse()
	await play_dialogue(cutscene_dialogue, "cutscene")
	_stop_pulse()

	# Zoom back out first
	var return_tween = create_tween()
	return_tween.tween_property(camera, "zoom", Vector2(5.5, 5.5), 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await return_tween.finished

	# Reset camera back to player properly
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.offset = Vector2.ZERO

	player.can_move = true
	player.animated_locked = false
	player.animated_sprite.play("idle")

var pulse_active: bool = false

func _start_pulse() -> void:
	pulse_active = true
	_do_pulse()

func _stop_pulse() -> void:
	pulse_active = false
	camera.offset = Vector2.ZERO

func _do_pulse() -> void:
	if not pulse_active:
		return
	var tween = create_tween()
	tween.tween_property(camera, "offset", Vector2(0, -4), 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "offset", Vector2(0, 0), 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_do_pulse()

func play_dialogue(resource: DialogueResource, title: String) -> void:
	if dialogue_running:
		return
	dialogue_running = true
	DialogueManager.show_dialogue_balloon(resource, title)
	await DialogueManager.dialogue_ended
	dialogue_running = false
