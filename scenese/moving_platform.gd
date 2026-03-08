extends AnimatableBody2D

@export var speed: float = 120.0
@export var move_distance: float = 150.0
@export var start_offset: float = 0.0
@export var horizontal: bool = false  # Check this in Inspector for horizontal movement

var direction: int = 1
var start_position: Vector2
var traveled: float = 0.0

func _ready():
	start_position = global_position
	traveled = start_offset

	# Apply initial offset position
	if horizontal:
		global_position.x += start_offset
	else:
		global_position.y += start_offset


func _physics_process(delta):
	var move_amount = speed * delta * direction

	# Move platform manually (DO NOT use move_and_collide)
	if horizontal:
		global_position.x += move_amount
	else:
		global_position.y += move_amount

	traveled += abs(move_amount)

	# Reverse direction when reaching move distance
	if traveled >= move_distance:
		traveled = 0.0
		direction *= -1
