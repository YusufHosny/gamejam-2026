class_name ShieldBreakView
extends AimView

# f2: the cursor is a shield, the angry button rains arrows down two lanes at the heart, slash the shield through each one as it reaches the guard line

const CENTER := Vector2(576, 110)
const BUTTON_SIZE := 150.0
const HEART := Vector2(576, 500)
const HEART_SIZE := 26.0
const LANE_X: Array[float] = [-110.0, 110.0] # from the middle, left lane then right
const GUARD_Y := 380.0 # arrows reach this line on their beat
const HIT_RADIUS := 70.0 # a slash has to pass this close to the arrow's tip
const ARROW_LEAD_S := 1.1 # arrows drop from the button this long before their beat
const ARROW_LENGTH := 80.0
const ARROW_WIDTH := 7.0
const ARROW_HEAD := 24.0
const LANE_COLORS: Array[Color] = [Color(0.35, 0.85, 1.0), Color(1.0, 0.6, 0.2)]
const SHIELD_HEIGHT := 110.0
const DEFLECT_S := 0.45
const HURT_S := 0.4
const MISS := Color(1.0, 0.25, 0.25)

@export var button: Texture2D
@export var shields: Array[Texture2D] = [] # the first one is the player's shield

var _deflected: Array[Array] = [] # [lane, ms] of blocked arrows spinning away
var _hurt_ms := -100000

# a note sits on its lane's guard line, so the map carries the lane as the swipe's side
static func note_at(swipe: int) -> Vector2: return Vector2(HEART.x + LANE_X[0 if swipe < 0 else 1], GUARD_Y)

static func lane(note: AimNote) -> int: return 0 if note.position.x < HEART.x else 1

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS # the shield is drawn well under its size
	mode.judged.connect(_on_judged)

func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(note.position, to_local(from), to_local(to)).distance_to(note.position) <= HIT_RADIUS

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

# autoplay swipes down then up through the guard line, each swipe starting where the last ended, so it never clips the other lane
func slash_direction(note: AimNote) -> Vector2: return Vector2.DOWN if mode.segment.notes.find(note) % 2 == 0 else Vector2.UP

func _on_judged(result: HitResult) -> void:
	var ms := Time.get_ticks_msec()
	if result.is_miss(): _hurt_ms = ms
	else: _deflected.append([lane(result.note as AimNote), ms])

func _draw() -> void:
	var now := _now()
	var ms := Time.get_ticks_msec()
	BossArena.draw(self, now)
	draw_texture_rect(button, BossArena.button_rect(button, CENTER, BUTTON_SIZE), false)
	for i in LANE_X.size():
		var x := HEART.x + LANE_X[i]
		draw_line(Vector2(x, CENTER.y + BUTTON_SIZE / 2), Vector2(x, GUARD_Y), Color(LANE_COLORS[i], 0.12), 2)
		draw_arc(Vector2(x, GUARD_Y), HIT_RADIUS * 0.5, 0, TAU, 40, Color(LANE_COLORS[i], 0.3), 2, true)
	var hurt := clampf(1.0 - (ms - _hurt_ms) / (HURT_S * 1000), 0.0, 1.0)
	_draw_heart(Color(0.9, 0.1, 0.15).lerp(Color.WHITE, hurt))
	_deflected.assign(_deflected.filter(func(d: Array): return ms - d[1] < DEFLECT_S * 1000))
	for deflected in _deflected: _draw_deflected(deflected[0], (ms - deflected[1]) / (DEFLECT_S * 1000))
	for note: AimNote in mode.pending(): _draw_falling(note, now)
	_draw_missed()
	_draw_shield()

# drops from the button to the guard line on the beat
func _draw_falling(note: AimNote, now: float) -> void:
	var until := note.time - now
	if until > ARROW_LEAD_S: return
	var start := CENTER.y + BUTTON_SIZE / 2
	var tip := Vector2(note.position.x, lerpf(start, GUARD_Y, 1.0 - maxf(until, 0.0) / ARROW_LEAD_S))
	_draw_arrow(tip, lane(note), clampf((ARROW_LEAD_S - until) / 0.15, 0.0, 1.0))

# a missed arrow carries on into the heart
func _draw_missed() -> void:
	var t := clampf(1.0 - (Time.get_ticks_msec() - _hurt_ms) / (HURT_S * 1000), 0.0, 1.0)
	if t <= 0.0: return
	draw_circle(HEART, HEART_SIZE * (2.0 - t), Color(MISS, 0.4 * t), true, -1, true)

func _draw_arrow(tip: Vector2, lane_index: int, alpha: float) -> void:
	var color := Color(LANE_COLORS[lane_index], alpha)
	var back := tip - Vector2(0, ARROW_LENGTH)
	draw_line(back, tip - Vector2(0, ARROW_HEAD * 0.6), color, ARROW_WIDTH, true)
	draw_colored_polygon(PackedVector2Array([tip, tip - Vector2(ARROW_HEAD * 0.6, ARROW_HEAD), tip - Vector2(-ARROW_HEAD * 0.6, ARROW_HEAD)]), color)
	draw_line(back + Vector2(-10, -4), back + Vector2(0, 10), color, 3, true) # fletching
	draw_line(back + Vector2(10, -4), back + Vector2(0, 10), color, 3, true)

# knocked back up and out to its side, spinning, fading
func _draw_deflected(lane_index: int, t: float) -> void:
	var side := -1.0 if lane_index == 0 else 1.0
	var at := Vector2(HEART.x + LANE_X[lane_index] + side * 180 * t, GUARD_Y - 160 * t + 120 * t * t)
	draw_set_transform(at, side * t * TAU)
	_draw_arrow(Vector2(0, ARROW_LENGTH / 2), lane_index, 1.0 - t)
	draw_set_transform(Vector2.ZERO)

# the player's shield rides the cursor
func _draw_shield() -> void:
	var cursor := (mode as AimMode).cursor
	if cursor == null: return
	var texture := shields[0]
	var size := texture.get_size() * SHIELD_HEIGHT / texture.get_height()
	draw_texture_rect(texture, Rect2(to_local(cursor.global_position) - size / 2, size), false, Color(1, 1, 1, 0.9))

# an undertale style soul
func _draw_heart(color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		points.append(HEART + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * HEART_SIZE / 16)
	draw_colored_polygon(points, color)
