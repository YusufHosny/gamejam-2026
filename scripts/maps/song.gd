class_name Song
extends Resource

# bpm and first beat come from tools/music/process.py

@export var stream: AudioStream
@export var bpm := 120.0
@export var first_beat_s := 0.0
@export var beats_per_bar := 4

func apply_to(map: Map) -> void:
	map.music = stream
	map.bpm = bpm
	map.first_beat_s = first_beat_s
	map.beats_per_bar = beats_per_bar

func fits(map: Map) -> bool: return first_beat_s + map.duration_s() < stream.get_length()
