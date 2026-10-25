class_name ShieldBreakView
extends AimView

# f2: arrows fly at the big shield under the angry button from both sides, slash through the shield the way each one flies to block it

const CENTER := Vector2(576, 230)
const BUTTON_SIZE := 200.0
const SHIELD_AT := Vector2(576, 420)
const SHIELD_HEIGHT := 190.0
const BLOCK_RADIUS := 110.0 # a slash has to pass this close to the shield's middle
const MIN_DOT := 0.5 # and run within 60° of the arrow
const ARROW_LEAD_S := 1.0 # arrows show up this long before they reach the shield
const ARROW_LENGTH := 90.0
const ARROW_WIDTH := 8.0
const ARROW_HEAD := 26.0
const FROM_LEFT := Color(0.35, 0.85, 1.0)
const FROM_RIGHT := Color(1.0, 0.6, 0.2)
const DEFLECT_S := 0.45
const FLASH_S := 0.2
const STUCK_S := 0.6
const MISS := Color(1.0, 0.25, 0.25)

@export var button: Texture2D
@export var shields: Array[Texture2D] = [] # the first one is the shield

var _flash_ms := -100000
var _flash_miss := false
var _deflected: Array[Array] = [] # [direction, ms] of blocked arrows spinning away
var _stuck: Array[Array] = [] # [direction, ms] of missed arrows stuck in the shield

# a note sits a pixel to the side its arrow flies toward, so the map carries the direction
static func note_at(direction: int) -> Vector2: return SHIELD_AT + Vector2(direction, 0)

static func direction(note: AimNote) -> Vector2: return Vector2(signf(note.position.x - SHIELD_AT.x), 0)

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS # the shield is drawn well under its size
	mode.judged.connect(_on_judged)

func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	var a := to_local(from)
	var b := to_local(to)
	if Geometry2D.get_closest_point_to_segment(SHIELD_AT, a, b).distance_to(SHIELD_AT) > BLOCK_RADIUS: return false
	return a == b or (b - a).normalized().dot(direction(note)) >= MIN_DOT # a relax touch has no direction

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

func slash_direction(note: AimNote) -> Vector2: return direction(note)

func _on_judged(result: HitResult) -> void:
	var ms := Time.get_ticks_msec()
	_flash_ms = ms
	_flash_miss = result.is_miss()
	(_stuck if result.is_miss() else _deflected).append([direction(result.note as AimNote).x, ms])

func _shield_rect() -> Rect2:
	var texture := shields[0]
	var size := texture.get_size() * SHIELD_HEIGHT / texture.get_height()
	return Rect2(SHIELD_AT - size / 2, size)

func _draw() -> void:
	var now := _now()
	var ms := Time.get_ticks_msec()
	BossArena.draw(self, now)
	draw_texture_rect(button, BossArena.button_rect(button, CENTER, BUTTON_SIZE), false)
	var flash := clampf(1.0 - (ms - _flash_ms) / (FLASH_S * 1000), 0.0, 1.0)
	var tint := Color.WHITE.lerp(MISS if _flash_miss else Color(2, 2, 2), flash * 0.6)
	var shake := Vector2(sin(ms * 0.08) * 6.0 * flash, 0) if _flash_miss else Vector2.ZERO
	var shield := _shield_rect()
	draw_texture_rect(shields[0], Rect2(shield.position + shake, shield.size), false, tint)
	_stuck.assign(_stuck.filter(func(s: Array): return ms - s[1] < STUCK_S * 1000))
	for stuck in _stuck: _draw_arrow(SHIELD_AT - Vector2(stuck[0] * BLOCK_RADIUS * 0.6, 0), stuck[0], 1.0 - (ms - stuck[1]) / (STUCK_S * 1000))
	_deflected.assign(_deflected.filter(func(d: Array): return ms - d[1] < DEFLECT_S * 1000))
	for deflected in _deflected: _draw_deflected(deflected[0], (ms - deflected[1]) / (DEFLECT_S * 1000))
	var pending := mode.pending()
	for i in range(pending.size() - 1, -1, -1):
		var note := pending[i] as AimNote
		var until := note.time - now
		if until > ARROW_LEAD_S: continue
		var side := direction(note).x
		var tip := SHIELD_AT.x - side * (shield.size.x / 2 + maxf(until, 0.0) * _arrow_speed())
		_draw_arrow(Vector2(tip, SHIELD_AT.y), side, clampf((ARROW_LEAD_S - until) / 0.15, 0.0, 1.0))

# from just off screen to the shield's edge in ARROW_LEAD_S
func _arrow_speed() -> float: return (SHIELD_AT.x - _shield_rect().size.x / 2 + ARROW_LENGTH) / ARROW_LEAD_S

# pointing the way it flies, `side` 1 flies right from the left
func _draw_arrow(tip: Vector2, side: float, alpha: float) -> void:
	var color := Color(FROM_LEFT if side > 0 else FROM_RIGHT, alpha)
	var back := tip - Vector2(side * ARROW_LENGTH, 0)
	draw_line(back, tip - Vector2(side * ARROW_HEAD * 0.6, 0), color, ARROW_WIDTH, true)
	draw_colored_polygon(PackedVector2Array([tip, tip - Vector2(side * ARROW_HEAD, ARROW_HEAD * 0.6), tip - Vector2(side * ARROW_HEAD, -ARROW_HEAD * 0.6)]), color)
	draw_line(back - Vector2(side * 4, 10), back + Vector2(side * 10, 0), color, 3, true) # fletching
	draw_line(back - Vector2(side * 4, -10), back + Vector2(side * 10, 0), color, 3, true)

# a blocked arrow bounces back up and away, spinning, fading
func _draw_deflected(side: float, t: float) -> void:
	var at := SHIELD_AT + Vector2(-side * (BLOCK_RADIUS * 0.7 + 160 * t), -220 * t + 200 * t * t)
	draw_set_transform(at, side * t * TAU)
	_draw_arrow(Vector2(side * ARROW_LENGTH / 2, 0), side, 1.0 - t)
	draw_set_transform(Vector2.ZERO)
