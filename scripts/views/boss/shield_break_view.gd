class_name ShieldBreakView
extends AimView

# f2: the cursor is a shield, the angry button drops a row of bombs down the middle at the heart, slash the shield through each one as it reaches the guard line

const CENTER := Vector2(576, 110)
const BUTTON_SIZE := 150.0
const HEART := Vector2(576, 500)
const HEART_SIZE := 26.0
const DROP_Y := 190.0 # bombs drop from under the button
const GUARD_Y := 400.0 # and reach this line on their beat
const HIT_RADIUS := 55.0 # a slash has to pass this close to the bomb where it is
const BOMB_LEAD_S := 0.7 # bombs drop this long before their beat
const SLASH_GAP_MS := 120 # after a cut the row holds this long, so one slash takes one bomb
const BOMB_RADIUS := 28.0
const BOMB := Color(0.13, 0.13, 0.16)
const FUSE := Color(0.75, 0.6, 0.4)
const SPARK := Color(1.0, 0.8, 0.3)
const LANE := Color(1.0, 0.6, 0.2)
const SHIELD_HEIGHT := 110.0
const BURST_S := 0.4
const BLAST_S := 0.5
const HURT_S := 0.4
const MISS := Color(1.0, 0.25, 0.25)

@export var button: Texture2D
@export var shields: Array[Texture2D] = [] # the first one is the player's shield

var _bursts: Array[int] = [] # ms of slashed bombs popping
var _blasts: Array[int] = [] # ms of missed bombs going off
var _hurt_ms := -100000
var _cut_ms := -100000

# a note sits on the guard line a pixel toward its swipe's side, so the map carries the swipe for autoplay
static func note_at(swipe: int) -> Vector2: return Vector2(HEART.x + swipe, GUARD_Y)

static func swipe(note: AimNote) -> Vector2: return Vector2(signf(note.position.x - HEART.x), 0)

func _bomb_at(note: AimNote, now: float) -> Vector2:
	return Vector2(HEART.x, lerpf(DROP_Y, GUARD_Y, 1.0 - maxf(note.time - now, 0.0) / BOMB_LEAD_S))

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS # the shield is drawn well under its size
	mode.judged.connect(_on_judged)

# only the lowest bomb can be cut, and only one per slash
func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	if note != mode.pending().front() or Time.get_ticks_msec() - _cut_ms < SLASH_GAP_MS: return false
	var at := _bomb_at(note, _now())
	var hit := Geometry2D.get_closest_point_to_segment(at, to_local(from), to_local(to)).distance_to(at) <= HIT_RADIUS
	if hit: _cut_ms = Time.get_ticks_msec()
	return hit

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

# autoplay swipes across the way the map's swipe went
func slash_direction(note: AimNote) -> Vector2: return swipe(note)

func _on_judged(result: HitResult) -> void:
	var ms := Time.get_ticks_msec()
	if result.is_miss():
		_hurt_ms = ms
		_blasts.append(ms)
	else: _bursts.append(ms)

func _draw() -> void:
	var now := _now()
	var ms := Time.get_ticks_msec()
	BossArena.draw(self, now)
	draw_texture_rect(button, BossArena.button_rect(button, CENTER, BUTTON_SIZE), false)
	draw_line(Vector2(HEART.x, DROP_Y), Vector2(HEART.x, GUARD_Y), Color(LANE, 0.12), 2)
	draw_line(Vector2(HEART.x - 120, GUARD_Y), Vector2(HEART.x + 120, GUARD_Y), Color(LANE, 0.35), 3) # slash across here
	var hurt := clampf(1.0 - (ms - _hurt_ms) / (HURT_S * 1000), 0.0, 1.0)
	_draw_heart(Color(0.9, 0.1, 0.15).lerp(Color.WHITE, hurt))
	_bursts.assign(_bursts.filter(func(b: int): return ms - b < BURST_S * 1000))
	for burst in _bursts: _draw_burst((ms - burst) / (BURST_S * 1000))
	_blasts.assign(_blasts.filter(func(b: int): return ms - b < BLAST_S * 1000))
	for blast in _blasts: _draw_blast((ms - blast) / (BLAST_S * 1000))
	for note: AimNote in mode.pending(): _draw_falling(note, now, ms)
	_draw_shield()

# drops down the middle to the guard line on the beat
func _draw_falling(note: AimNote, now: float, ms: int) -> void:
	var until := note.time - now
	if until > BOMB_LEAD_S: return
	_draw_bomb(_bomb_at(note, now), clampf((BOMB_LEAD_S - until) / 0.1, 0.0, 1.0), ms)

# a round black bomb with a lit fuse
func _draw_bomb(at: Vector2, alpha: float, ms: int) -> void:
	draw_circle(at, BOMB_RADIUS, Color(BOMB, alpha), true, -1, true)
	draw_arc(at, BOMB_RADIUS, 0, TAU, 40, Color(1, 1, 1, 0.35 * alpha), 2, true)
	draw_circle(at + Vector2(-9, -9), 7, Color(1, 1, 1, 0.18 * alpha), true, -1, true) # shine
	var cap := at + Vector2(10, -BOMB_RADIUS + 2)
	draw_rect(Rect2(cap - Vector2(6, 5), Vector2(12, 8)), Color(BOMB.lightened(0.2), alpha))
	var tip := cap + Vector2(10, -14)
	draw_polyline(PackedVector2Array([cap, cap + Vector2(8, -6), tip]), Color(FUSE, alpha), 3, true)
	var flicker := 0.7 + 0.3 * sin(ms * 0.05)
	draw_circle(tip, 6 * flicker, Color(SPARK, alpha), true, -1, true)

# a slashed bomb pops in a puff
func _draw_burst(t: float) -> void:
	var at := Vector2(HEART.x, GUARD_Y)
	draw_circle(at, BOMB_RADIUS * (1.0 + 1.5 * t), Color(0.85, 0.85, 0.9, 0.5 * (1.0 - t)), true, -1, true)
	for i in 6:
		var dir := Vector2.from_angle(TAU * i / 6.0 + 0.4)
		draw_circle(at + dir * (BOMB_RADIUS + 70 * t), 5 * (1.0 - t), Color(BOMB, 1.0 - t), true, -1, true)

# a missed bomb goes off on the guard line
func _draw_blast(t: float) -> void:
	var at := Vector2(HEART.x, GUARD_Y)
	draw_circle(at, BOMB_RADIUS * (1.0 + 3.0 * t), Color(1.0, 0.55, 0.15, 0.8 * (1.0 - t)), true, -1, true)
	draw_circle(at, BOMB_RADIUS * (0.6 + 2.0 * t), Color(SPARK, 0.9 * (1.0 - t)), true, -1, true)

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
