extends Node

@export var tilemap_path: NodePath
@export var player_path: NodePath
@export var fragile_layer: int = 0

@export var warn_time: float = 0.25
@export var fall_time: float = 0.65
@export var respawn_time: float = 2.0

@export var shake_amount: float = 3.0

# Adjust depending on tile size (we’ll tune this)
@export var foot_y_offset: float = 18.0

@export var fragile_tile_sound: AudioStream
@onready var fragile_sound_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var tilemap: TileMap
var player: CharacterBody2D

# Keeps track of tiles currently breaking or respawning
var active_cells := {}

func _ready() -> void:
	tilemap = get_node_or_null(tilemap_path) as TileMap
	player = get_node_or_null(player_path) as CharacterBody2D

	if tilemap == null:
		push_error("FragileTileManager: tilemap_path is invalid.")
	if player == null:
		push_error("FragileTileManager: player_path is invalid.")

func _physics_process(_delta: float) -> void:
	
	if tilemap == null or player == null:
		return

	# Get position slightly below player's center (feet)
	var feet_y := 0.0
	var col := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		feet_y = (col.shape.size.y / 2.0) - 1.0
	elif col and col.shape is CapsuleShape2D:
		feet_y = (col.shape.height / 2.0) - 1.0
	else:
		feet_y = foot_y_offset # fallback

	var foot_position := player.global_position + Vector2(0, feet_y)

	# Convert world position to tilemap cell
	var local_pos := tilemap.to_local(foot_position)
	var cell := tilemap.local_to_map(local_pos)

	# Check if fragile tile exists at this cell
	var source_id := tilemap.get_cell_source_id(fragile_layer, cell)

	if source_id == -1:
		return

	# Prevent retriggering same tile
	if active_cells.has(cell):
		return

	active_cells[cell] = true
	_break_tile(cell)

func _break_tile(cell: Vector2i) -> void:
	# Save tile data for respawn
	var source_id := tilemap.get_cell_source_id(fragile_layer, cell)
	var atlas_coords := tilemap.get_cell_atlas_coords(fragile_layer, cell)
	var alt_tile := tilemap.get_cell_alternative_tile(fragile_layer, cell)

	# Play fragile tile sound immediately
	if fragile_sound_player and fragile_tile_sound:
		fragile_sound_player.stream = fragile_tile_sound
		fragile_sound_player.play()

	# Trigger camera shake
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam and cam.has_method("shake"):
		cam.call("shake", shake_amount)

	# Warning delay
	await get_tree().create_timer(warn_time).timeout

	# Fall delay (after warning)
	await get_tree().create_timer(max(0.0, fall_time - warn_time)).timeout

	# Remove fragile tile (collision disappears)
	tilemap.erase_cell(fragile_layer, cell)

	# Respawn after delay
	await get_tree().create_timer(respawn_time).timeout
	tilemap.set_cell(fragile_layer, cell, source_id, atlas_coords, alt_tile)

	active_cells.erase(cell)
