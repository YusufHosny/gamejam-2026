class_name AimNote
extends Note

@export var position: Vector2
@export var new_combo := false # start of new "circle counter"

func _init(_beat := 0.0, _position := Vector2.ZERO) -> void:
	super(_beat)
	position = _position
