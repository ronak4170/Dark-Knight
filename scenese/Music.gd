extends Node

@onready var bgm: AudioStreamPlayer = $BGM

func play_track(stream: AudioStream, volume_db := 0.0):
	if bgm.stream == stream and bgm.playing:
		return

	bgm.stop()
	bgm.stream = stream
	bgm.volume_db = volume_db
	bgm.play()

func stop_music():
	if bgm.playing:
		bgm.stop()
