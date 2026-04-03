extends Node

@export var tilemap_path: NodePath
@export var pillar_layer_index: int
@export var switch_nodes: Array[NodePath] = []

# target combo: 1 open, 2 open, 3 closed, 4 open
var target := { 1: true, 2: true, 3: false, 4: true }
var current := {}
var solved := false

func _ready() -> void:
	var tm := get_node(tilemap_path) as TileMap
	if tm == null:
		push_error("SwitchPuzzle: tilemap_path is wrong.")
		return

	# Start blocked
	tm.set_layer_enabled(pillar_layer_index, true)

	# Connect to each switch
	for p in switch_nodes:
		var sw := get_node_or_null(p)
		if sw == null:
			push_error("SwitchPuzzle: bad switch node path: %s" % str(p))
			continue
		if not sw.has_signal("state_changed"):
			push_error("SwitchPuzzle: switch has no signal 'state_changed': %s" % sw.name)
			continue
		sw.state_changed.connect(_on_switch_state_changed)

	# IMPORTANT: pull initial states AFTER connections are made
	call_deferred("_pull_initial_states")

func _pull_initial_states() -> void:
	for p in switch_nodes:
		var sw := get_node_or_null(p)
		if sw == null:
			continue
		# assumes your switch script has: var is_open := false and @export var switch_id
		current[sw.switch_id] = sw.is_open

	_check_solution()

func _on_switch_state_changed(switch_id: int, is_open: bool) -> void:
	current[switch_id] = is_open
	_check_solution()

func _check_solution() -> void:
	for id in target.keys():
		if not current.has(id):
			return

	for id in target.keys():
		if current[id] != target[id]:
			solved = false
			_set_pillar(true)
			return

	solved = true
	_set_pillar(false)

func _set_pillar(blocking: bool) -> void:
	var tm := get_node(tilemap_path) as TileMap
	tm.set_layer_enabled(pillar_layer_index, blocking)
	
func reset_puzzle() -> void:
	solved = false
	_set_pillar(true)
	current.clear()
	call_deferred("_pull_initial_states")
