@abstract
class_name AimView
extends ModeView

# the view owns hit shapes since it decides where and how big targets are drawn.
# points are global, a click or a relax touch is a zero length path
@abstract func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool
# the way autoplay swipes through a note, views that care about slash direction override it
func slash_direction(_note: AimNote) -> Vector2: return Vector2.RIGHT

@abstract func is_following(slider: SliderNote, point: Vector2, progress: float) -> bool
