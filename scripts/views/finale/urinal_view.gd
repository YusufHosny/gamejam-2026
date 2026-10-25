class_name UrinalView
extends AimView

# the finale's restroom. picking: guys stand at some urinals, rings close on the free ones, click the one furthest from them all.
# slashing: every urinal is taken, slash each guy as his ring closes and he's gone. drawn shapes until art arrives

const URINAL := Vector2(78, 120)
const GUY := Vector2(70, 170) # seen from behind, standing at the urinal
const PICK_RADIUS := 60.0 # around the urinal's middle
const SLASH_RADIUS := 55.0
const SHOW_S := 1.2 # the round's guys walk up this long before its beat
const RING_GROW := 50.0
const POOF_S := 0.35
const MISS := Color(1.0, 0.3, 0.3)
const WALL := Color(0.86, 0.88, 0.9)
const TILE := Color(0.78, 0.8, 0.83)
const FLOOR := Color(0.55, 0.6, 0.62)
const PORCELAIN := Color(0.98, 0.98, 1.0)
const SHIRTS: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.3, 0.5, 0.85), Color(0.3, 0.7, 0.4), Color(0.85, 0.6, 0.2), Color(0.6, 0.35, 0.75), Color(0.25, 0.6, 0.7)]

@export var slashing := false
@export var urinal_art: Texture2D # replaces the drawn urinal
@export var guy_art: Texture2D # replaces the drawn guy

var _poofs: Array[Array] = [] # [urinal, ms, missed]
var _picked := -1 # where the last pick landed, shown until the next round
var _picked_ms := -100000
var _picked_miss := false

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	mode.judged.connect(_on_judged)

func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	var radius := SLASH_RADIUS if slashing else PICK_RADIUS # a guy's middle is about the urinal's
	return Geometry2D.get_closest_point_to_segment(note.position, to_local(from), to_local(to)).distance_to(note.position) <= radius

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

func _on_judged(result: HitResult) -> void:
	var index := _urinal_of(result.note as AimNote)
	if slashing: _poofs.append([index, Time.get_ticks_msec(), result.is_miss()])
	else:
		_picked = index
		_picked_ms = Time.get_ticks_msec()
		_picked_miss = result.is_miss()

func _urinal_of(note: AimNote) -> int: return roundi((note.position.x - UrinalMaps.ROW_LEFT) / UrinalMaps.ROW_STEP)

func _draw() -> void:
	var now := _now()
	var screen := get_viewport_rect().size
	_draw_room(screen)
	var taken := _taken(now)
	for i in UrinalMaps.COUNT:
		_draw_urinal(UrinalMaps.urinal(i))
		if i in taken: _draw_guy(UrinalMaps.urinal(i), i, 1.0)
	if slashing: _draw_slashes(now)
	else: _draw_pick(now, taken)

# whoever stands at the urinals right now
func _taken(now: float) -> Array:
	var notes := mode.segment.notes
	if slashing:
		var standing := []
		for note: AimNote in mode.pending(): standing.append(_urinal_of(note))
		return standing
	var next := mode.pending()
	if not next.is_empty() and (next[0] as AimNote).time - now < SHOW_S: return UrinalMaps.PICKS[notes.find(next[0])][0]
	return []

func _draw_pick(now: float, taken: Array) -> void:
	var next := mode.pending()
	if not next.is_empty():
		var until := (next[0] as AimNote).time - now
		if until < GameConfig.approach_time_s and until > 0:
			var closing := until / GameConfig.approach_time_s
			for i in UrinalMaps.COUNT:
				if i in taken: continue
				_ring(UrinalMaps.urinal(i), closing)
	var shown := clampf(1.0 - (Time.get_ticks_msec() - _picked_ms) / 600.0, 0.0, 1.0)
	if _picked >= 0 and shown > 0.0:
		var at := UrinalMaps.urinal(_picked)
		if _picked_miss: _draw_cross(at, shown)
		else: _draw_guy(at, 6, shown) # you, at the right one

func _draw_slashes(now: float) -> void:
	var next := mode.pending()
	if not next.is_empty():
		var until := (next[0] as AimNote).time - now
		if until < GameConfig.approach_time_s and until > 0: _ring(next[0].position, until / GameConfig.approach_time_s)
	var ms := Time.get_ticks_msec()
	_poofs.assign(_poofs.filter(func(p: Array): return ms - p[1] < POOF_S * 1000))
	for poof in _poofs:
		var t: float = (ms - poof[1]) / (POOF_S * 1000)
		var at := UrinalMaps.urinal(poof[0])
		if poof[2]: _draw_cross(at, 1.0 - t)
		else: draw_circle(at, 40 + 60 * t, Color(1, 1, 1, 0.7 * (1.0 - t)), true, -1, true)

func _ring(at: Vector2, closing: float) -> void:
	var radius := PICK_RADIUS + RING_GROW * closing
	draw_arc(at, radius, 0, TAU, 48, Color(0, 0, 0, 0.5 * (1.0 - closing * 0.5)), 7, true)
	draw_arc(at, radius, 0, TAU, 48, Color(1.0, 0.85, 0.2, 1.0 - closing * 0.5), 4, true)

func _draw_room(screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), WALL)
	for x in range(0, int(screen.x), 48): draw_line(Vector2(x, 0), Vector2(x, UrinalMaps.ROW_Y + URINAL.y * 0.6), TILE, 2)
	for y in range(0, int(UrinalMaps.ROW_Y + URINAL.y * 0.6), 48): draw_line(Vector2(0, y), Vector2(screen.x, y), TILE, 2)
	draw_rect(Rect2(0, UrinalMaps.ROW_Y + URINAL.y * 0.6, screen.x, screen.y), FLOOR)

func _draw_urinal(at: Vector2) -> void:
	if urinal_art != null:
		draw_texture_rect(urinal_art, Rect2(at - URINAL / 2, URINAL), false)
		return
	var body := Rect2(at - URINAL / 2, URINAL)
	draw_rect(body, PORCELAIN)
	draw_rect(body, Color(0.6, 0.62, 0.66), false, 3)
	draw_rect(Rect2(body.position + Vector2(14, URINAL.y * 0.35), Vector2(URINAL.x - 28, URINAL.y * 0.5)), Color(0.88, 0.9, 0.93))
	draw_line(at - Vector2(0, URINAL.y / 2), at - Vector2(0, URINAL.y / 2 + 40), Color(0.7, 0.72, 0.75), 6) # pipe

# from behind: head, shirt, legs
func _draw_guy(at: Vector2, index: int, alpha: float) -> void:
	var feet := at + Vector2(0, URINAL.y / 2 + 30)
	var rect := Rect2(feet - Vector2(GUY.x / 2, GUY.y), GUY)
	if guy_art != null:
		draw_texture_rect(guy_art, rect, false, Color(1, 1, 1, alpha))
		return
	var shirt := SHIRTS[index % SHIRTS.size()] if index < SHIRTS.size() else Color(1.0, 0.85, 0.2)
	draw_rect(Rect2(feet - Vector2(GUY.x * 0.35, GUY.y * 0.45), Vector2(GUY.x * 0.7, GUY.y * 0.45)), Color(0.2, 0.22, 0.3, alpha)) # legs
	draw_rect(Rect2(feet - Vector2(GUY.x / 2, GUY.y * 0.82), Vector2(GUY.x, GUY.y * 0.42)), Color(shirt, alpha))
	draw_circle(feet - Vector2(0, GUY.y * 0.9), GUY.x * 0.28, Color(0.95, 0.78, 0.62, alpha), true, -1, true)
	draw_arc(feet - Vector2(0, GUY.y * 0.93), GUY.x * 0.28, PI * 1.05, TAU * 0.98, 16, Color(0.3, 0.2, 0.12, alpha), 8, true) # hair

func _draw_cross(at: Vector2, alpha: float) -> void:
	var color := Color(MISS, alpha)
	draw_line(at - Vector2(30, 30), at + Vector2(30, 30), color, 8, true)
	draw_line(at - Vector2(30, -30), at + Vector2(30, -30), color, 8, true)
