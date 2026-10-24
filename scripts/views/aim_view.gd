@abstract
class_name AimView
extends ModeView

# the view owns hit shapes since it decides where and how big targets are drawn.
# points are global, a click is a zero length path
@abstract func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool
