class_name MapStep
extends RunStep

@export var map: Map

func _init(_map: Map = null, _timed := true) -> void:
	map = _map
	timed = _timed

func length_s() -> float: return map.duration_s()
