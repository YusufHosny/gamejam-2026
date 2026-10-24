class_name FruitCaptchaView
extends AimView

# c3: apples are thrown up from below the board and peak on their beat, a slash halves them

const FRUIT_SIZE := 80.0
const HIT_RADIUS := 42.0
const ENTRY_MARGIN := 60.0 # apples start this far below the board
const RING_SCALE := 1.6
const HALF_SPREAD := 150.0 # px/s the halves fly apart
const FALL := 1400.0 # px/s² once sliced
const SPIN := 3.0
const SLICED_S := 0.9
const JUICE_S := 0.6
const BOARD := Color(0.42, 0.27, 0.15)
const PLANK := Color(0.33, 0.2, 0.1)

@export var fruits: Array[Fruit] = []
@export var juice: Texture2D
@export var target := "apples"

class Slice:
	var position: Vector2
	var velocity: Vector2
	var angle: float # direction of the slash
	var born_ms: int

	func _init(_position: Vector2, _velocity: Vector2, _angle: float, _born_ms: int) -> void:
		position = _position
		velocity = _velocity
		angle = _angle
		born_ms = _born_ms

var _fruit: Dictionary[AimNote, Fruit] = {}
var _drift: Dictionary[AimNote, float] = {} # px/s sideways
var _gravity: Dictionary[AimNote, float] = {} # tuned so each apple enters as its ring appears
var _slices: Dictionary[AimNote, Slice] = {}
var _missed: Dictionary[AimNote, bool] = {}
var _cut_angle: Dictionary[AimNote, float] = {} # from the slash that hit, see is_hit

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	var entry_y := CaptchaFrame.content().end.y + ENTRY_MARGIN
	var approach := GameConfig.approach_time_s
	for i in mode.segment.notes.size():
		var note := mode.segment.notes[i] as AimNote
		_fruit[note] = fruits[i % fruits.size()]
		_drift[note] = ((i * 37) % 7 - 3) * 14.0
		_gravity[note] = 2.0 * (entry_y - note.position.y) / (approach * approach)
	mode.judged.connect(_on_judged)

# remembers the slash direction so the halves split along it
func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	var at := _position(note, _now())
	var hit := Geometry2D.get_closest_point_to_segment(at, to_local(from), to_local(to)).distance_to(at) <= HIT_RADIUS
	if hit: _cut_angle[note] = (to - from).angle()
	return hit

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

func _on_judged(result: HitResult) -> void:
	var note := result.note as AimNote
	if result.is_miss():
		_missed[note] = true
		return
	var now := _now()
	_slices[note] = Slice.new(_position(note, now), _velocity(note, now), _cut_angle.get(note, 0.0), Time.get_ticks_msec())

func _position(note: AimNote, at: float) -> Vector2:
	var dt := at - note.time
	return note.position + Vector2(_drift[note] * dt, 0.5 * _gravity[note] * dt * dt)

func _velocity(note: AimNote, at: float) -> Vector2:
	return Vector2(_drift[note], _gravity[note] * (at - note.time))

func _draw() -> void:
	var now := _now()
	var ms := Time.get_ticks_msec()
	CaptchaFrame.draw(self)
	_draw_board()
	for note in _slices: _draw_juice(note, _slices[note], ms)
	for note in _missed: _draw_fruit(_fruit[note].whole, _position(note, now), 0.0, 0.5)
	var approach := GameConfig.approach_time_s
	for note: AimNote in mode.pending():
		var until := note.time - now
		if until > approach: break
		var at := _position(note, now)
		_draw_fruit(_fruit[note].whole, at, 0.0, 1.0)
		if until > 0: draw_arc(at, HIT_RADIUS * (1.0 + RING_SCALE * until / approach), 0, TAU, 48, Color(1, 1, 1, 1.0 - until / approach), 3, true)
	for note in _slices: _draw_halves(_fruit[note], _slices[note], ms)
	CaptchaFrame.draw_edges(self) # apples fly in from behind the footer
	CaptchaFrame.draw_header(self, "Slash all the", target, "Swipe through each one as it peaks.")

func _draw_board() -> void:
	var board := CaptchaFrame.content()
	draw_rect(board, BOARD)
	for i in range(1, 5):
		var y := board.position.y + board.size.y * i / 5.0
		draw_line(Vector2(board.position.x, y), Vector2(board.end.x, y), PLANK, 3)

func _draw_fruit(texture: Texture2D, center: Vector2, rotation: float, alpha: float) -> void:
	CircleSkin.draw_centered(self, texture, center, FRUIT_SIZE, Color(1, 1, 1, alpha), rotation)

# the cut runs along the slash, each half flies off its own side and falls
func _draw_halves(fruit: Fruit, slice: Slice, ms: int) -> void:
	var s := (ms - slice.born_ms) / 1000.0
	if s > SLICED_S: return
	var rotation := slice.angle - PI / 2
	var drop := slice.position + slice.velocity * s + Vector2(0, 0.5 * FALL * s * s)
	var apart := Vector2.RIGHT.rotated(rotation) * HALF_SPREAD * s
	var alpha := 1.0 - s / SLICED_S
	_draw_fruit(fruit.left, drop - apart, rotation - SPIN * s, alpha)
	_draw_fruit(fruit.right, drop + apart, rotation + SPIN * s, alpha)

func _draw_juice(note: AimNote, slice: Slice, ms: int) -> void:
	var s := (ms - slice.born_ms) / 1000.0
	if s > JUICE_S or juice == null: return
	var color := _fruit[note].juice_color
	CircleSkin.draw_centered(self, juice, slice.position, FRUIT_SIZE * (1.0 + s), Color(color, color.a * (1.0 - s / JUICE_S)), slice.angle)
