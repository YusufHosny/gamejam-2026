class_name CircleAimView
extends AimView

const RADIUS := 48.0
const FOLLOW_RADIUS := RADIUS * 2.0
const APPROACH_SCALE := 2.0 # ring starts at RADIUS * (1 + APPROACH_SCALE)
const BORDER_WIDTH := 4.0
const NUMBER_SIZE := 36
const LINK_WIDTH := 3.0
const LINK_DASH := 10.0

@export var color := Color.WHITE

var _numbers: Dictionary[AimNote, int] = {} # combo number per note

func _ready() -> void:
	var number := 0
	for note: AimNote in mode.segment.notes:
		number = 1 if note.new_combo or number == 0 else number + 1
		_numbers[note] = number

func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	var closest := Geometry2D.get_closest_point_to_segment(note.position, to_local(from), to_local(to))
	return closest.distance_to(note.position) <= RADIUS

func is_following(slider: SliderNote, point: Vector2, progress: float) -> bool:
	return to_local(point).distance_to(slider.ball_at(progress)) <= FOLLOW_RADIUS

func _draw() -> void:
	var now := _now()
	_draw_links(now)
	var sliding := (mode as AimMode).sliding()
	if sliding != null:
		var progress := sliding.progress_at(now)
		_draw_body(sliding, progress, 1.0)
		_draw_ball(sliding, progress)
	var pending := mode.pending()
	for i in range(pending.size() - 1, -1, -1): # reversed so the next note is on top
		var note := pending[i] as AimNote
		var alpha := _fade_in(note, now)
		if alpha <= 0.0: continue
		if note is SliderNote: _draw_body(note, 0.0, alpha)
		_draw_head(note, alpha)
		var until := note.time - now
		if until > 0:
			var ring := RADIUS * (1.0 + APPROACH_SCALE * until / GameConfig.approach_time_s)
			draw_arc(note.position, ring, 0, TAU, 64, Color(color, alpha), 3, true)

func _fade_in(note: AimNote, now: float) -> float:
	return 1.0 - clampf((note.time - now) / GameConfig.approach_time_s, 0.0, 1.0)

# --- Notes ---
func _draw_head(note: AimNote, alpha: float) -> void:
	draw_circle(note.position, RADIUS - BORDER_WIDTH / 2, Color(color.darkened(0.25), 0.9 * alpha), true, -1, true)
	draw_arc(note.position, RADIUS, 0, TAU, 64, Color(Color.WHITE, alpha), BORDER_WIDTH, true)
	var font := ThemeDB.fallback_font
	var text := str(_numbers[note])
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
	var lift := (font.get_ascent(NUMBER_SIZE) - font.get_descent(NUMBER_SIZE)) / 2
	draw_string(font, note.position + Vector2(-width / 2, lift), text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, Color(Color.WHITE, alpha))

# one filled polygon plus an outline, so overlapping strokes never double up the alpha
func _draw_body(slider: SliderNote, progress: float, alpha: float) -> void:
	var points := slider.points()
	for polygon in Geometry2D.offset_polyline(points, RADIUS - BORDER_WIDTH / 2, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
		draw_colored_polygon(polygon, Color(color.darkened(0.75), 0.85 * alpha))
	for polygon in Geometry2D.offset_polyline(points, RADIUS, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, Color(Color.WHITE, alpha), BORDER_WIDTH, true)
	if slider.turns_left(progress) > 0: _draw_reverse_arrow(slider, progress, alpha)

# chevron on the end the ball turns back at next, pointing back along the path
func _draw_reverse_arrow(slider: SliderNote, progress: float, alpha: float) -> void:
	var points := slider.points()
	var out := slider.heading_out(progress)
	var tip := points[-1] if out else points[0]
	var back := ((points[-2] if out else points[1]) - tip).normalized()
	var side := back.orthogonal() * RADIUS * 0.35
	var apex := tip + back * RADIUS * 0.25
	var tail := tip - back * RADIUS * 0.15
	draw_polyline(PackedVector2Array([tail + side, apex, tail - side]), Color(Color.WHITE, alpha), 5, true)

func _draw_ball(slider: SliderNote, progress: float) -> void:
	var ball := slider.ball_at(progress)
	draw_arc(ball, FOLLOW_RADIUS, 0, TAU, 64, Color(color, 0.5), 3, true)
	draw_circle(ball, RADIUS * 0.75, color, true, -1, true)
	draw_arc(ball, RADIUS * 0.75, 0, TAU, 48, Color.WHITE, 3, true)

# --- Links ---
# dashed line from where each note ends to the next head, shown while the next one approaches
func _draw_links(now: float) -> void:
	var notes := mode.segment.notes
	for i in notes.size() - 1:
		var next := notes[i + 1] as AimNote
		if now >= next.time: continue
		var alpha := _fade_in(next, now)
		if alpha <= 0.0: continue
		var start := _end_point(notes[i] as AimNote)
		var gap := next.position - start
		if gap.length() < RADIUS * 3: continue
		var trim := gap.normalized() * RADIUS * 1.2
		draw_dashed_line(start + trim, next.position - trim, Color(Color.WHITE, 0.5 * alpha), LINK_WIDTH, LINK_DASH, true, true)

func _end_point(note: AimNote) -> Vector2:
	if note is SliderNote: return (note as SliderNote).ball_at(1.0)
	return note.position
