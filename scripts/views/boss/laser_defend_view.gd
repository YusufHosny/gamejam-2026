class_name LaserDefendView
extends ModeView

# f3: lasers fly at the heart from four sides, the lightsaber blocks the side you press

const DIRECTIONS: Array[Vector2] = [Vector2.LEFT, Vector2.DOWN, Vector2.UP, Vector2.RIGHT] # lanes ← ↓ ↑ →, the side a laser comes from
const HEART := Vector2(576, 360)
const HEART_SIZE := 22.0
const BLOCK_DIST := 64.0 # the saber sits this far out from the heart
const LASER_SPEED := 900.0
const LASER_LENGTH := 170.0
const LASER_WIDTH := 22.0
const SABER_LENGTH := 150.0
const TURN := 22.0 # how fast the saber swings to a new side
const SPARK_S := 0.25
const HURT_S := 0.35
const BUTTON_SIZE := 120.0
const BUTTON_Y := 100.0
const KEY_DIST := 230.0

@export var laser: Texture2D
@export var saber: Texture2D
@export var button: Texture2D

var _side := Vector2.UP
var _angle := Vector2.UP.angle()
var _spark_ms := -100000
var _spark_side := Vector2.UP
var _hurt_ms := -100000

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	mode.judged.connect(_on_judged)

func _on_judged(result: HitResult) -> void:
	if result.is_miss():
		_hurt_ms = Time.get_ticks_msec()
		return
	_spark_ms = Time.get_ticks_msec()
	_spark_side = DIRECTIONS[(result.note as LaneNote).lane]

# the saber follows the last lane pressed, the mode does the judging
func _process(delta: float) -> void:
	super(delta)
	for lane in DIRECTIONS.size():
		if Input.is_action_just_pressed(FourDMode.LANES[lane]): _side = DIRECTIONS[lane]
	_angle = lerp_angle(_angle, _side.angle(), minf(1.0, TURN * delta))

func _draw() -> void:
	var now := _now()
	var ms := Time.get_ticks_msec()
	BossArena.draw(self, now)
	var bob := Vector2(0, sin(now * 3.0) * 6.0)
	draw_texture_rect(button, BossArena.button_rect(button, Vector2(HEART.x, BUTTON_Y) + bob, BUTTON_SIZE), false)
	_draw_keys()
	for note: LaneNote in mode.pending():
		var side := DIRECTIONS[note.lane]
		var tip := HEART + side * (BLOCK_DIST + (note.time - now) * LASER_SPEED)
		if tip.distance_to(HEART) > 900: continue
		_draw_glow(laser, tip + side * LASER_LENGTH / 2, side.angle(), Vector2(LASER_LENGTH, LASER_WIDTH))
	var hurt := clampf(1.0 - (ms - _hurt_ms) / (HURT_S * 1000), 0.0, 1.0)
	_draw_heart(Color(0.9, 0.1, 0.15).lerp(Color.WHITE, hurt))
	var facing := Vector2.from_angle(_angle)
	_draw_glow(saber, HEART + facing * BLOCK_DIST, _angle, Vector2(SABER_LENGTH * saber.get_width() / saber.get_height(), SABER_LENGTH))
	var spark := clampf(1.0 - (ms - _spark_ms) / (SPARK_S * 1000), 0.0, 1.0)
	if spark > 0.0:
		draw_circle(HEART + _spark_side * BLOCK_DIST, 30.0 * (1.5 - spark), Color(1, 0.9, 0.9, spark * 0.8), true, -1, true)

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

func _draw_keys() -> void:
	var font := ThemeDB.fallback_font
	for lane in DIRECTIONS.size():
		var event: InputEvent = GameConfig.keybinds[FourDMode.LANES[lane]][0]
		var label := OS.get_keycode_string(event.physical_keycode) if event is InputEventKey else "?"
		var at := HEART + DIRECTIONS[lane] * KEY_DIST
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, at + Vector2(-width / 2, 7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.35))
