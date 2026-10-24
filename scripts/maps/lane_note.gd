class_name LaneNote
extends Note

@export_range(0, 3) var lane: int

func _init(_beat := 0.0, _lane := 0) -> void:
	super(_beat)
	lane = _lane
