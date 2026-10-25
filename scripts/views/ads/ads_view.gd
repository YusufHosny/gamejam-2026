class_name AdsView
extends AimView

# a1: popup ads open on their beat, a slash cuts the window in two. missed ones stay open

const POP_S := 0.12
const APPROACH_GROW := 22.0
const ACCENT := Color(1.0, 0.85, 0.2)
# the virus cutscene's popups: one, a pause, another, a pause, then three in a burst. still open when the stage starts
const INTRO_POPUPS: Array[Dictionary] = [
	{"texture": preload("res://assets/ads/windows/free_robux_ad_1.png"), "at": Vector2(270, 230), "pop_at": 0.0},
	{"texture": preload("res://assets/ads/windows/hacker_cat_ad.png"), "at": Vector2(890, 420), "pop_at": 0.8},
	{"texture": preload("res://assets/ads/windows/virus_ad.png"), "at": Vector2(600, 210), "pop_at": 1.8},
	{"texture": preload("res://assets/ads/windows/japanese_cat_ad.png"), "at": Vector2(330, 460), "pop_at": 1.9},
	{"texture": preload("res://assets/ads/windows/satan_ad.png"), "at": Vector2(880, 170), "pop_at": 2.0},
]

@export var windows: Array[Texture2D] = []
@export var icons: Array[Texture2D] = []

static var left_open: Array[Dictionary] = [] # {texture, rect} of the ads still open when the stage ended, the blue screen flood carries on from them

var _window: Dictionary[AimNote, Texture2D] = {}
var _missed: Array[AimNote] = []
var _cuts: Array[PolygonCut] = []
var _slash: Dictionary[AimNote, Vector2] = {} # slash direction of the hit, see is_hit

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	for i in mode.segment.notes.size():
		_window[mode.segment.notes[i] as AimNote] = windows[(i * 7) % windows.size()]
	mode.judged.connect(_on_judged)

func _exit_tree() -> void:
	left_open.assign(INTRO_POPUPS.map(func(popup: Dictionary): return {"texture": popup.texture, "rect": intro_rect(popup)}))
	left_open.append_array(_missed.map(func(note: AimNote): return {"texture": _window[note], "rect": _rect(note)}))

static func intro_rect(popup: Dictionary) -> Rect2:
	var size: Vector2 = popup.texture.get_size()
	return Rect2(popup.at - size / 2, size)

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
	else: _cuts.append(PolygonCut.split(_window[note], _rect(note), note.position, _slash.get(note, Vector2.RIGHT)))

func _draw() -> void:
	var now := _now()
	Desktop.draw(self, icons)
	for popup in INTRO_POPUPS: draw_texture_rect(popup.texture, intro_rect(popup), false)
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
	_cuts.assign(_cuts.filter(func(c: PolygonCut): return c.alive(ms)))
	for cut in _cuts: cut.draw(self, ms)
