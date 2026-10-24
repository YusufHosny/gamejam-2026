class_name AlignCaptchaView
extends ModeView

# c2: each lane hit nudges a jigsaw piece of the picture, a full combo lands it in its hole

const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT] # lanes ← ↓ ↑ →
const ARROW_ANGLES: Array[float] = [-PI / 2, PI, 0.0, PI / 2]
const STEP := 14.0 # px per nudge
const PICTURE_SIZE := 300.0
const PIECE_SIZE := 72.0
const KNOB := 13.0
const TARGET := Vector2(0.64, 0.46) # piece centre within the picture
const ARROW := 22.0
const EASE := 14.0

@export var picture: Texture2D
@export var target := "into place"

var _offset := Vector2i.ZERO # in nudges, zero is aligned
var _shown := Vector2.ZERO
var _pressed_ms: Array[int] = [-100000, -100000, -100000, -100000]

# starts as far off as the whole map's moves undo
func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	for note: LaneNote in mode.segment.notes: _offset -= DIRECTIONS[note.lane]
	_shown = Vector2(_offset)
	mode.judged.connect(_on_judged)

func _on_judged(result: HitResult) -> void:
	if result.is_miss(): return
	var lane := (result.note as LaneNote).lane
	_offset += DIRECTIONS[lane]
	_pressed_ms[lane] = Time.get_ticks_msec()

func _process(delta: float) -> void:
	super(delta)
	_shown = _shown.lerp(Vector2(_offset), minf(1.0, EASE * delta))

func _draw() -> void:
	CaptchaFrame.draw(self)
	CaptchaFrame.draw_header(self, "Slide the puzzle piece", target, "Arrow keys only, no dragging allowed.")
	_draw_puzzle()
	_draw_lanes(_now())

# --- Puzzle ---
func _picture_rect() -> Rect2:
	var content := CaptchaFrame.content()
	return Rect2(content.get_center() - Vector2.ONE * PICTURE_SIZE / 2, Vector2.ONE * PICTURE_SIZE)

func _draw_puzzle() -> void:
	var picture_rect := _picture_rect()
	if picture != null: draw_texture_rect(picture, picture_rect, false)
	var home := picture_rect.position + TARGET * PICTURE_SIZE - Vector2.ONE * PIECE_SIZE / 2
	var shape := _piece_shape()
	var uvs := PackedVector2Array()
	for point in shape: uvs.append((home + point - picture_rect.position) / PICTURE_SIZE)
	draw_colored_polygon(_moved(shape, home), Color(0, 0, 0, 0.55))
	var piece := _moved(shape, home + _shown * STEP)
	draw_colored_polygon(_moved(shape, home + _shown * STEP + Vector2(3, 4)), Color(0, 0, 0, 0.35)) # drop shadow
	draw_colored_polygon(piece, Color.WHITE, uvs, picture)
	var aligned := _offset == Vector2i.ZERO
	piece.append(piece[0])
	draw_polyline(piece, Color(0.2, 0.8, 0.4) if aligned else Color.WHITE, 3, true)

# a square with knobs on its top and right edges, origin at the top left
func _piece_shape() -> PackedVector2Array:
	var s := PIECE_SIZE
	var points := PackedVector2Array([Vector2.ZERO])
	points.append_array(_arc(Vector2(s / 2, 0), PI, TAU))
	points.append(Vector2(s, 0))
	points.append_array(_arc(Vector2(s, s / 2), -PI / 2, PI / 2))
	points.append_array([Vector2(s, s), Vector2(0, s)])
	return points

func _arc(center: Vector2, from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13: points.append(center + Vector2.from_angle(lerpf(from, to, i / 12.0)) * KNOB)
	return points

static func _moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point in points: moved.append(point + by)
	return moved

# --- Lanes ---
func _draw_lanes(now: float) -> void:
	LaneColumn.draw_panel(self)
	for lane in DIRECTIONS.size():
		_draw_arrow(LaneColumn.receptor(lane), lane, Color(LaneColumn.COLORS[lane], LaneColumn.lit(lane, _pressed_ms[lane])), Color(0.8, 0.82, 0.88))
		LaneColumn.draw_key(self, lane)
	for note: LaneNote in mode.pending():
		var y := LaneColumn.y(note, now)
		if y < LaneColumn.TOP + ARROW: break
		_draw_arrow(Vector2(LaneColumn.x(note.lane), y), note.lane, LaneColumn.COLORS[note.lane], Color.WHITE)

func _draw_arrow(center: Vector2, lane: int, fill: Color, outline: Color) -> void:
	var s := ARROW
	var shape := PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(s * 0.42, 0), Vector2(s * 0.42, s), Vector2(-s * 0.42, s), Vector2(-s * 0.42, 0), Vector2(-s, 0)])
	var points := PackedVector2Array()
	for point in shape: points.append(center + point.rotated(ARROW_ANGLES[lane]))
	if fill.a > 0.0: draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, outline, 2.5, true)
