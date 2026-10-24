class_name AdsView
extends AimView

# a1: popup ads open on their beat, a slash cuts the window in two. missed ones stay open

const POP_S := 0.12
const APPROACH_GROW := 22.0
const SPREAD := 160.0 # px/s the halves fly apart
const FALL := 1500.0
const SPIN := 2.5
const CUT_S := 0.8
const ACCENT := Color(1.0, 0.85, 0.2)

@export var windows: Array[Texture2D] = []
@export var icons: Array[Texture2D] = []

class Piece:
	var points: PackedVector2Array # around its own centroid
	var uvs: PackedVector2Array
	var center: Vector2
	var push: Vector2 # away from the cut
	var spin: float

	func _init(_points: PackedVector2Array, _uvs: PackedVector2Array, _center: Vector2, _push: Vector2, _spin: float) -> void:
		points = _points
		uvs = _uvs
		center = _center
		push = _push
		spin = _spin

class Cut:
	var texture: Texture2D
	var pieces: Array[Piece]
	var born_ms: int

	func _init(_texture: Texture2D, _pieces: Array[Piece], _born_ms: int) -> void:
		texture = _texture
		pieces = _pieces
		born_ms = _born_ms

var _window: Dictionary[AimNote, Texture2D] = {}
var _missed: Array[AimNote] = []
var _cuts: Array[Cut] = []
var _slash: Dictionary[AimNote, Vector2] = {} # slash direction of the hit, see is_hit

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	for i in mode.segment.notes.size():
		_window[mode.segment.notes[i] as AimNote] = windows[(i * 7) % windows.size()]
	mode.judged.connect(_on_judged)

func _rect(note: AimNote) -> Rect2:
	var size := _window[note].get_size()
	return Rect2(note.position - size / 2, size)

# remembers the slash direction so the window splits along it
func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	var rect := _rect(note)
	var a := to_local(from)
	var b := to_local(to)
	var hit := rect.has_point(a) or rect.has_point(b) or _crosses(rect, a, b)
	if hit: _slash[note] = (b - a).normalized()
	return hit

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

static func _crosses(rect: Rect2, a: Vector2, b: Vector2) -> bool:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null: return true
	return false

func _on_judged(result: HitResult) -> void:
	var note := result.note as AimNote
	if result.is_miss(): _missed.append(note)
	else: _cuts.append(_cut(note, _slash.get(note, Vector2.RIGHT)))

# the window rect split by a line through its centre along the slash
func _cut(note: AimNote, along: Vector2) -> Cut:
	var rect := _rect(note)
	var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var side := along.orthogonal()
	var far := rect.size.length()
	var pieces: Array[Piece] = []
	for flip in [-1.0, 1.0]:
		var half := PackedVector2Array([
			note.position - along * far, note.position + along * far,
			note.position + along * far + side * flip * far, note.position - along * far + side * flip * far,
		])
		for polygon in Geometry2D.intersect_polygons(corners, half):
			var centroid := Vector2.ZERO
			for point in polygon: centroid += point
			centroid /= polygon.size()
			var points := PackedVector2Array()
			var uvs := PackedVector2Array()
			for point in polygon:
				points.append(point - centroid)
				uvs.append((point - rect.position) / rect.size)
			pieces.append(Piece.new(points, uvs, centroid, side * flip, SPIN * flip))
	return Cut.new(_window[note], pieces, Time.get_ticks_msec())

func _draw() -> void:
	var now := _now()
	Desktop.draw(self, icons)
	for note in _missed: draw_texture_rect(_window[note], _rect(note), false)
	var approach := GameConfig.approach_time_s
	var pending := mode.pending()
	for i in range(pending.size() - 1, -1, -1): # the next ad on top
		var note := pending[i] as AimNote
		var until := note.time - now
		if until > approach: continue
		var shown := approach - until
		var rect := _rect(note)
		var pop := clampf(shown / POP_S, 0.0, 1.0)
		var scaled := Rect2(note.position - rect.size * (0.6 + 0.4 * pop) / 2, rect.size * (0.6 + 0.4 * pop))
		draw_texture_rect(_window[note], scaled, false)
		if until > 0:
			var closing := until / approach
			draw_rect(rect.grow(APPROACH_GROW * closing), Color(ACCENT, 1.0 - closing * 0.5), false, 4)
	_draw_cuts()

func _draw_cuts() -> void:
	var ms := Time.get_ticks_msec()
	_cuts.assign(_cuts.filter(func(c: Cut): return ms - c.born_ms < CUT_S * 1000))
	for cut in _cuts:
		var s := (ms - cut.born_ms) / 1000.0
		var alpha := 1.0 - s / CUT_S
		for piece in cut.pieces:
			var at := piece.center + piece.push * SPREAD * s + Vector2(0, 0.5 * FALL * s * s)
			draw_set_transform(at, piece.spin * s)
			draw_colored_polygon(piece.points, Color(1, 1, 1, alpha), piece.uvs, cut.texture)
		draw_set_transform(Vector2.ZERO)
