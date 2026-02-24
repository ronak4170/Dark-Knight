extends AnimatableBody2D

@export var speed: float = 120.0
@export var move_distance: float = 150.0
@export var start_offset: float = 0.0
@export var horizontal: bool = false  # ADD THIS — check it in Inspector for horizontal

var direction: int = 1
var start_position: Vector2
var traveled: float = 0.0

func _ready():
	start_position = global_position
	traveled = start_offset

func _physics_process(delta):
	var move_amount = speed * delta * direction
	traveled += abs(move_amount)

	if traveled >= move_distance:
		traveled = 0.0
		direction *= -1

	if horizontal:
		move_and_collide(Vector2(move_amount, 0))  # moves left and right
	else:
		move_and_collide(Vector2(0, move_amount))  # moves up and down
