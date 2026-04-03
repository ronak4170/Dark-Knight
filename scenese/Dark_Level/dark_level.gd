extends Node2D

@export var level_music: AudioStream
@onready var player = $dark_player
@onready var cutscene_trigger = $CutsceneTrigger
@onready var memory_fragment = $memory_fragment
@onready var flash_rect = $Cinematic/FlashRect
@onready var cutscene_image = $Cinematic/CutsceneImage
@onready var bat = $Bat 
var bat_spawn_position: Vector2

var first_dialogue = preload("res://scenese/Dark_Level/Dialogue/first.dialogue")
var second_dialogue = preload("res://scenese/Dark_Level/Dialogue/second.dialogue")
var orb_dialogue = preload("res://scenese/Dark_Level/Dialogue/orb_collect.dialogue")

var dialogue_running := false
var orb_touched := false



func _ready() -> void:
	Music.play_music(level_music)
	flash_rect.color = Color(1, 0, 0, 0)
	cutscene_image.modulate.a = 0.0
	cutscene_trigger.body_entered.connect(_on_cutscene_trigger)
	memory_fragment.body_entered.connect(_on_orb_touched)
	player.respawned.connect(_on_player_respawned)
	# Store original bat position
	bat_spawn_position = bat.global_position
	await get_tree().create_timer(0.5).timeout
	await play_dialogue(first_dialogue, "first")

func _on_player_respawned() -> void:
	orb_touched = false
	dialogue_running = false
	cutscene_image.modulate.a = 0.0
	flash_rect.color = Color(1, 0, 0, 0)
	cutscene_trigger.monitoring = true
	# Reset bat position and state
	if is_instance_valid(bat):
		bat.global_position = bat_spawn_position
		bat.velocity = Vector2.ZERO
		bat.dead = false
		bat.can_attack = true
		bat.hitstunned = false
		bat.hp = bat.max_hp
		bat.anim.play("fly")
	await get_tree().create_timer(0.5).timeout
	await play_dialogue(first_dialogue, "first")
	
func _on_cutscene_trigger(body: Node) -> void:
	if not body.is_in_group("player") and not body.is_in_group("player_group"):
		return
	cutscene_trigger.monitoring = false
	player.can_move = false
	player.velocity = Vector2.ZERO
	player.animated_sprite.play("idle")

	await _flash_red(8, 0.2)

	_screen_shake(0.4, 8.0)
	var fade_in = create_tween()
	fade_in.tween_property(cutscene_image, "modulate:a", 0.6, 1.5)
	await fade_in.finished

	await play_dialogue(second_dialogue, "second")

	var fade_out = create_tween()
	fade_out.tween_property(cutscene_image, "modulate:a", 0.0, 1.5)
	await fade_out.finished

	player.can_move = true
	player.animated_locked = false
	player.animated_sprite.play("idle")

func _flash_red(times: int, interval: float) -> void:
	for i in range(times):
		var flash_in = create_tween()
		flash_in.tween_property(flash_rect, "color:a", 0.5, interval)
		await flash_in.finished
		var flash_out = create_tween()
		flash_out.tween_property(flash_rect, "color:a", 0.0, interval)
		await flash_out.finished

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
	
func _screen_shake(duration: float, strength: float) -> void:
	var camera = player.get_node("Camera2D")
	var original_pos = camera.offset
	var elapsed := 0.0
	while elapsed < duration:
		camera.offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	camera.offset = original_pos
