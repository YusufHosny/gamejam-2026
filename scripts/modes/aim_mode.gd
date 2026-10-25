@abstract
class_name AimMode
extends ModeHandler

# shared by aim + click and slash, hit shapes come from the view

var cursor: VirtualCursor

# the slider currently running, held or not, for views to draw
func sliding() -> SliderNote: return null

# whether the running slider is held and followed right now
func tracking() -> bool: return false

func _is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	return (view as AimView).is_hit(note, from, to)

func _is_following(slider: SliderNote, point: Vector2, progress: float) -> bool:
	return (view as AimView).is_following(slider, point, progress)
