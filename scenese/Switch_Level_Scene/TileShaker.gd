extends Node2D

@export var amplitude := 2.0   # pixels
@export var speed := 40.0      # shake speed

var base_pos: Vector2
var t := 0.0

func _ready() -> void:
	base_pos = global_position

func _process(delta: float) -> void:
	t += delta * speed
	# small deterministic jitter (no random = stable pixel look)
	var x = sin(t) * amplitude
	var y = cos(t * 1.3) * (amplitude * 0.5)
	global_position = base_pos + Vector2(round(x), round(y))
