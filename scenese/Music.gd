extends Node

@onready var player: AudioStreamPlayer = $BGM

var current_track: AudioStream = null

func play_music(track: AudioStream) -> void:
	if track == null:
		return

	# if same music is already playing, do nothing
	if player.stream == track and player.playing:
		return

	player.stream = track
	player.play()

func stop_music() -> void:
	player.stop()
	current_track = null
