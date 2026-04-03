extends Node

signal puzzle_solved_signal

@onready var tilemap = $"../TileMap_loop"
@onready var flower = $"../Flower"
@onready var checkpoint = $"../Checkpoint"
@onready var loop_manager = $"../LoopManager"
@onready var torch_area1 = $"../TorchArea1"
@onready var torch_area2 = $"../TorchArea2"
@onready var torch_area3 = $"../TorchArea3"
@onready var pillar_area1 = $"../PillarArea1"
@onready var pillar_area2 = $"../PillarArea2"
@onready var torch_ui = $"../TorchUI"
@onready var camera = $"../player_time_loop/Camera2D"
@onready var player = $"../player_time_loop"
@onready var level = get_parent()

const HIDDEN_CLIFF = 5
const RED_FLOWER = 3
const PINK_FLOWER = 4
const PILLAR = 6
const PILLAR_TORCH1 = 14
const PILLAR_TORCH2 = 15
const DOOR_BROKEN = 9
const DOOR_ORIGINAL = 7
const BLACK_LAYER = 8
const BRIDGE_TORCH = 11
const BRIDGE_ONETORCH = 12
const BRIDGE_TWOTORCH = 13
const BRIDGE = 10

var cliff_tween : Tween
var cliff_permanent := false
var torch_count := 0
var bridge_torches_permanent := false
var phase2_active := false
var phase2_torch_count := 0
var pillar1_timer := 0.0
var pillar2_timer := 0.0
var puzzle_solved := false

func _ready():
	tilemap.set_layer_modulate(HIDDEN_CLIFF, Color(1,1,1,0))
	tilemap.set_layer_modulate(PINK_FLOWER, Color(1,1,1,0))
	tilemap.set_layer_modulate(RED_FLOWER, Color(1,1,1,1))
	tilemap.set_layer_enabled(HIDDEN_CLIFF, false)
	tilemap.set_layer_modulate(PILLAR_TORCH1, Color(1,1,1,0))
	tilemap.set_layer_modulate(PILLAR_TORCH2, Color(1,1,1,0))
	tilemap.set_layer_modulate(DOOR_ORIGINAL, Color(1,1,1,0))
	tilemap.set_layer_modulate(BLACK_LAYER, Color(1,1,1,0))
	tilemap.set_layer_enabled(DOOR_ORIGINAL, false)
	tilemap.set_layer_enabled(BLACK_LAYER, false)
	# Hide left bridge torch until phase 2
	tilemap.set_layer_modulate(BRIDGE_TORCH, Color(1,1,1,0))
	tilemap.set_layer_enabled(BRIDGE_TORCH, false)
	torch_area1.monitoring = false
	torch_area3.monitoring = false
	torch_area3.visible = false
	flower.purified.connect(_on_purified)
	flower.unpurified.connect(_on_unpurified)
	checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)
	torch_area1.torch_picked_up.connect(_on_torch_picked_up.bind(1))
	torch_area2.torch_picked_up.connect(_on_torch_picked_up.bind(2))
	torch_area3.torch_picked_up.connect(_on_phase2_torch_picked_up.bind(3))
	pillar_area1.torch_placed.connect(_on_torch_placed.bind(1))
	pillar_area2.torch_placed.connect(_on_torch_placed.bind(2))
	pillar_area1.body_holding.connect(_on_pillar1_held)
	pillar_area2.body_holding.connect(_on_pillar2_held)
	pillar_area1.body_left.connect(_on_pillar_released)
	pillar_area2.body_left.connect(_on_pillar_released)
	loop_manager.loop_reset.connect(_on_loop_reset)
	torch_ui.set_count(0)

func _on_purified():
	if cliff_tween:
		cliff_tween.kill()
	cliff_tween = create_tween()
	tilemap.set_layer_enabled(HIDDEN_CLIFF, true)
	cliff_tween.tween_method(
		func(a): tilemap.set_layer_modulate(RED_FLOWER, Color(1,1,1,a)),
		1.0, 0.0, 0.5
	)
	cliff_tween.parallel().tween_method(
		func(a): tilemap.set_layer_modulate(PINK_FLOWER, Color(1,1,1,a)),
		0.0, 1.0, 0.5
	)
	cliff_tween.tween_method(
		func(a): tilemap.set_layer_modulate(HIDDEN_CLIFF, Color(1,1,1,a)),
		0.0, 1.0, 0.5
	)
	cliff_tween.tween_callback(func():
		checkpoint.monitoring = true
	)

func _on_unpurified():
	if cliff_permanent:
		return
	if cliff_tween:
		cliff_tween.kill()
	cliff_tween = create_tween()
	cliff_tween.tween_method(
		func(a): tilemap.set_layer_modulate(PINK_FLOWER, Color(1,1,1,a)),
		1.0, 0.0, 0.5
	)
	cliff_tween.parallel().tween_method(
		func(a): tilemap.set_layer_modulate(RED_FLOWER, Color(1,1,1,a)),
		0.0, 1.0, 0.5
	)
	cliff_tween.tween_method(
		func(a): tilemap.set_layer_modulate(HIDDEN_CLIFF, Color(1,1,1,a)),
		1.0, 0.0, 0.5
	)
	cliff_tween.tween_callback(func():
		tilemap.set_layer_enabled(HIDDEN_CLIFF, false)
		checkpoint.monitoring = false
	)

func _on_checkpoint_activated():
	cliff_permanent = true
	if cliff_tween:
		cliff_tween.kill()
	tilemap.set_layer_modulate(HIDDEN_CLIFF, Color(1,1,1,1))
	tilemap.set_layer_modulate(PINK_FLOWER, Color(1,1,1,1))
	tilemap.set_layer_modulate(RED_FLOWER, Color(1,1,1,0))
	loop_manager.spawn_position = checkpoint.global_position + Vector2(30, -100)
	level.on_checkpoint_activated()
	
func _on_torch_picked_up(torch_num: int):
	if puzzle_solved or bridge_torches_permanent:
		return
	torch_count += 1
	torch_ui.set_count(torch_count)
	if torch_num == 1:
		tilemap.set_layer_enabled(BRIDGE_ONETORCH, false)
	else:
		tilemap.set_layer_enabled(BRIDGE_TWOTORCH, false)

func _on_phase2_torch_picked_up(torch_num: int):
	if puzzle_solved:
		return
	phase2_torch_count += 1
	torch_ui.set_count(phase2_torch_count)
	if torch_num == 1:
		tilemap.set_layer_enabled(BRIDGE_ONETORCH, false)  # right torch picked up
	else:
		tilemap.set_layer_enabled(BRIDGE_TORCH, false)     # left torch picked up

func _on_loop_reset():
	if puzzle_solved:
		return
	if torch_count >= 2 and not bridge_torches_permanent:
		bridge_torches_permanent = true
		phase2_active = true
		# Disconnect phase 1 signal and reconnect to phase 2 function
		torch_area1.torch_picked_up.disconnect(_on_torch_picked_up)
		torch_area1.torch_picked_up.connect(_on_phase2_torch_picked_up.bind(1))
		# Reveal left bridge torch
		tilemap.set_layer_enabled(BRIDGE_TORCH, true)
		tilemap.set_layer_modulate(BRIDGE_TORCH, Color(1,1,1,1))
		# Restore right bridge torch
		tilemap.set_layer_enabled(BRIDGE_ONETORCH, true)
		tilemap.set_layer_modulate(BRIDGE_ONETORCH, Color(1,1,1,1))
		# Disable ground torch permanently
		tilemap.set_layer_enabled(BRIDGE_TWOTORCH, false)
		# Enable phase 2 torch areas
		torch_area1.monitoring = true
		torch_area1.respawn()
		torch_area3.monitoring = true
		torch_area3.visible = true
		torch_area3.respawn()
		torch_area2.monitoring = false
	torch_count = 0
	phase2_torch_count = 0
	torch_ui.set_count(0)
	if not bridge_torches_permanent:
		tilemap.set_layer_enabled(BRIDGE_ONETORCH, true)
		tilemap.set_layer_enabled(BRIDGE_TWOTORCH, true)
		torch_area1.monitoring = true
		torch_area2.monitoring = true
		torch_area1.respawn()
		torch_area2.respawn()
		pillar1_timer = 0.0
		pillar2_timer = 0.0
		tilemap.set_layer_modulate(PILLAR_TORCH1, Color(1,1,1,0))
		tilemap.set_layer_modulate(PILLAR_TORCH2, Color(1,1,1,0))
		pillar_area1.reset()
		pillar_area2.reset()
	else:
		# Phase 2 reset — respawn both bridge torches
		tilemap.set_layer_enabled(BRIDGE_TORCH, true)
		tilemap.set_layer_modulate(BRIDGE_TORCH, Color(1,1,1,1))
		tilemap.set_layer_enabled(BRIDGE_ONETORCH, true)
		tilemap.set_layer_modulate(BRIDGE_ONETORCH, Color(1,1,1,1))
		torch_area1.monitoring = true
		torch_area1.respawn()
		torch_area3.monitoring = true
		torch_area3.respawn()
		pillar1_timer = 0.0
		pillar2_timer = 0.0
		tilemap.set_layer_modulate(PILLAR_TORCH1, Color(1,1,1,0))
		tilemap.set_layer_modulate(PILLAR_TORCH2, Color(1,1,1,0))
		pillar_area1.reset()
		pillar_area2.reset()

func _on_torch_placed(pillar_num: int):
	if pillar_num == 1:
		tilemap.set_layer_modulate(PILLAR_TORCH1, Color(1,1,1,1))
	else:
		tilemap.set_layer_modulate(PILLAR_TORCH2, Color(1,1,1,1))

func _on_pillar1_held(duration: float):
	pillar1_timer = duration
	_check_solve()

func _on_pillar2_held(duration: float):
	pillar2_timer = duration
	_check_solve()

func _on_pillar_released():
	pillar1_timer = 0.0
	pillar2_timer = 0.0

func _check_solve():
	if puzzle_solved:
		return
	if not phase2_active:
		return
	if pillar_area1.has_torch and pillar_area2.has_torch:
		solve_puzzle()

func solve_puzzle():
	puzzle_solved = true
	tilemap.set_layer_enabled(BRIDGE, false)
	tilemap.set_layer_enabled(DOOR_ORIGINAL, true)
	tilemap.set_layer_enabled(BLACK_LAYER, true)
	tilemap.set_layer_modulate(DOOR_ORIGINAL, Color(1,1,1,1))
	tilemap.set_layer_modulate(BLACK_LAYER, Color(1,1,1,1))
	loop_manager.stop_loops()
	emit_signal("puzzle_solved_signal")
	#pan_camera_to_gate()

func pan_camera_to_gate():
	var gate_position = Vector2(1000, 500)
	var tween = create_tween()
	camera.top_level = true
	tween.tween_property(camera, "global_position", gate_position, 1.5)
	tween.tween_callback(func():
		tilemap.set_layer_enabled(DOOR_ORIGINAL, true)
		tilemap.set_layer_enabled(BLACK_LAYER, true)
	)
	tween.tween_method(
		func(a): tilemap.set_layer_modulate(DOOR_BROKEN, Color(1,1,1,a)),
		1.0, 0.0, 0.8
	)
	tween.parallel().tween_method(
		func(a): tilemap.set_layer_modulate(DOOR_ORIGINAL, Color(1,1,1,a)),
		0.0, 1.0, 0.8
	)
	tween.parallel().tween_method(
		func(a): tilemap.set_layer_modulate(BLACK_LAYER, Color(1,1,1,a)),
		0.0, 1.0, 0.8
	)
	tween.tween_interval(0.5)
	tween.tween_property(camera, "global_position", player.global_position, 1.5)
	tween.tween_callback(func():
		camera.top_level = false
	)
