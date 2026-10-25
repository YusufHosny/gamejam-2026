class_name MapStep
extends RunStep

@export var map: Map
@export var fade_in_s := 0.0 # starts from fade_color, for after a cutscene that fades out
@export var fade_color := Color.BLACK # match what the step before ends on
@export var pre_roll_s := 0.0 # silence before the music starts, the first segment's view and banner already show

func _init(_map: Map = null, _timed := true) -> void:
	map = _map
	timed = _timed

func length_s() -> float: return pre_roll_s + map.duration_s()
