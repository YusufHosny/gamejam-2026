@abstract
class_name AimMode
extends ModeHandler

# shared by aim + click and slash, hit shapes come from the view

var cursor: VirtualCursor

func _is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	return (view as AimView).is_hit(note, from, to)
