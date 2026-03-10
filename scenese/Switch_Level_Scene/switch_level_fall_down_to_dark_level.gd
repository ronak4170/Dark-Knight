extends Node2D
@export var level_music: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Music.play_music(level_music)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
