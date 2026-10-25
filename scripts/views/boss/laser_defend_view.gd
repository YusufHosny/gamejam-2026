class_name LaserDefendView
extends ModeView

# f3: the button fires lasers at four slots in front of the heart, the lightsaber blocks the slot you press.
# slots run left to right like the keys: left outer, left inner, right inner, right outer

const SLOT_X: Array[float] = [-210.0, -80.0, 80.0, 210.0] # from the heart, one per lane
const SLOT_Y := 380.0
const HEART := Vector2(576, 470)
const HEART_SIZE := 22.0
const SOURCE := Vector2(576, 100) # where the button fires from
const LASER_SPEED := 520.0
const LASER_LENGTH := 150.0
const LASER_WIDTH := 22.0
const WARN_S := 0.35 # a faint aim line before each shot leaves the button
const SABER_LENGTH := 150.0
const FOLLOW := 26.0 # how fast the saber moves to a new slot
const SPARK_S := 0.25
const HURT_S := 0.35
const BUTTON_SIZE := 120.0
const SLOT_RADIUS := 26.0

@export var laser: Texture2D
@export var saber: Texture2D
@export var button: Texture2D

var _lane := 1
var _saber_at := Vector2.ZERO
var _saber_angle := 0.0
var _lit_ms: Array[int] = [-100000, -100000, -100000, -100000]
var _spark_ms := -100000
var _spark_lane := 0
var _hurt_ms := -100000

static func slot(lane: int) -> Vector2: return Vector2(HEART.x + SLOT_X[lane], SLOT_Y)

# from the button to the slot, the way that lane's lasers travel
static func beam(lane: int) -> Vector2: return (slot(lane) - SOURCE).normalized()

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	_saber_at = slot(_lane)
	_saber_angle = beam(_lane).angle()
	mode.judged.connect(_on_judged)

func _on_judged(result: HitResult) -> void:
	if result.is_miss():
		_hurt_ms = Time.get_ticks_msec()
		return
	_spark_ms = Time.get_ticks_msec()
	_spark_lane = (result.note as LaneNote).lane

# the saber follows the last lane pressed, the mode does the judging
func _process(delta: float) -> void:
	super(delta)
	for lane in SLOT_X.size():
		if Input.is_action_just_pressed(FourDMode.LANES[lane]):
			_lane = lane
			_lit_ms[lane] = Time.get_ticks_msec()
	var follow := minf(1.0, FOLLOW * delta)
	_saber_at = _saber_at.lerp(slot(_lane), follow)
	_saber_angle = lerp_angle(_saber_angle, beam(_lane).angle(), follow)

func _draw() -> void:
	var now := _now()
	var ms := Time.get_ticks_msec()
	BossArena.draw(self, now)
	draw_texture_rect(button, BossArena.button_rect(button, SOURCE + Vector2(0, sin(now * 3.0) * 6.0), BUTTON_SIZE), false)
	_draw_slots(ms)
	for note: LaneNote in mode.pending(): _draw_laser(note, now)
	var hurt := clampf(1.0 - (ms - _hurt_ms) / (HURT_S * 1000), 0.0, 1.0)
	_draw_heart(Color(0.9, 0.1, 0.15).lerp(Color.WHITE, hurt))
	_draw_glow(saber, _saber_at, _saber_angle, Vector2(SABER_LENGTH * saber.get_width() / saber.get_height(), SABER_LENGTH))
	var spark := clampf(1.0 - (ms - _spark_ms) / (SPARK_S * 1000), 0.0, 1.0)
	if spark > 0.0: draw_circle(slot(_spark_lane), 30.0 * (1.5 - spark), Color(1, 0.9, 0.9, spark * 0.8), true, -1, true)

# shoots from the button and reaches its slot on the beat, a faint aim line warns first
func _draw_laser(note: LaneNote, now: float) -> void:
	var target := slot(note.lane)
	var path := target - SOURCE
	var travelled := path.length() - (note.time - now) * LASER_SPEED
	if travelled < -WARN_S * LASER_SPEED: return
	if travelled < 0.0:
		var warn := 1.0 + travelled / (WARN_S * LASER_SPEED)
		draw_line(SOURCE, target, Color(1, 0.2, 0.25, 0.35 * warn), 2, true)
		return
	var along := path.normalized()
	var head := SOURCE + along * travelled
	var length := minf(LASER_LENGTH, travelled)
	_draw_glow(laser, head - along * length / 2, along.angle(), Vector2(length, LASER_WIDTH))

func _draw_slots(ms: int) -> void:
	var font := ThemeDB.fallback_font
	for lane in SLOT_X.size():
		var at := slot(lane)
		var lit := clampf(1.0 - (ms - _lit_ms[lane]) / 150.0, 0.0, 1.0)
		if Input.is_action_pressed(FourDMode.LANES[lane]): lit = maxf(lit, 0.4)
		draw_circle(at, SLOT_RADIUS, Color(1, 0.3, 0.35, 0.08 + 0.3 * lit), true, -1, true)
		draw_arc(at, SLOT_RADIUS, 0, TAU, 40, Color(1, 1, 1, 0.25 + 0.5 * lit), 2, true)
		var event: InputEvent = GameConfig.keybinds[FourDMode.LANES[lane]][0]
		var label := OS.get_keycode_string(event.physical_keycode) if event is InputEventKey else "?"
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, at + Vector2(-width / 2, SLOT_RADIUS + 26), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.45))

# centred on `at`, rotated so a horizontal texture points along `angle`, a vertical one stands across it
func _draw_glow(texture: Texture2D, at: Vector2, angle: float, size: Vector2) -> void:
	draw_set_transform(at, angle)
	draw_texture_rect(texture, Rect2(-size / 2, size), false)
	draw_set_transform(Vector2.ZERO)

# an undertale style soul
func _draw_heart(color: Color) -> void:
	var s := HEART_SIZE
	var points := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		points.append(HEART + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * s / 16)
	draw_colored_polygon(points, color)
