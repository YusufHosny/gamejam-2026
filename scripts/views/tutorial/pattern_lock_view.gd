class_name PatternLockView
extends CircleAimView

const GRID_CENTER := Vector2(576, 380)
const GRID_STEP := 80.0
const PATTERN: Array[int] = [0, 1, 2, 4, 6, 7, 8] # a Z across the 3x3 grid
const DOT_RADIUS := 10.0
const SLIDE_S := 1.2

@export var phone: Texture2D
@export var hint := "Click and hold the slider, then follow the ball"

static func dot(index: int) -> Vector2:
	return GRID_CENTER + Vector2(index % 3 - 1, index / 3 - 1) * GRID_STEP

static func pattern_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in PATTERN: points.append(dot(index))
	return points

# the phone is pulled up from below, the backdrop's on its own canvas layer so it stays put
func _ready() -> void:
	super()
	position.y = get_viewport_rect().size.y
	create_tween().tween_property(self, "position:y", 0.0, SLIDE_S).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	TutorialUi.phone(self, phone, Color(0.16, 0.2, 0.3))
	TutorialUi.label(self, TutorialUi.SCREEN.position + Vector2(TutorialUi.SCREEN.size.x / 2, 60), "12:00", 48, Color.WHITE)
	TutorialUi.label(self, TutorialUi.SCREEN.position + Vector2(TutorialUi.SCREEN.size.x / 2, 104), "draw your pattern", 16, Color(1, 1, 1, 0.6))
	for i in 9: draw_circle(dot(i), DOT_RADIUS, Color(1, 1, 1, 0.5), true, -1, true)
	super()
	TutorialUi.hint(self, hint)

# a pattern line instead of a slider track, lit up to the ball
func _draw_body(slider: SliderNote, progress: float, alpha: float) -> void:
	draw_polyline(slider.points(), Color(color, 0.25 * alpha), 8, true)
	if progress > 0.0: draw_polyline(_traced(slider, progress), color, 8, true)

func _traced(slider: SliderNote, progress: float) -> PackedVector2Array:
	var points := slider.points()
	var ball := slider.ball_at(progress)
	var traced := PackedVector2Array([points[0]])
	var total := 0.0
	for i in points.size() - 1: total += points[i].distance_to(points[i + 1])
	var walked := 0.0
	for i in points.size() - 1:
		walked += points[i].distance_to(points[i + 1])
		if walked > slider.path_t(progress) * total: break
		traced.append(points[i + 1])
	traced.append(ball)
	return traced
