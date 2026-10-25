class_name ShieldBreakView
extends AimView

# f2: the angry button armours up with shields along its bottom, each slash breaks one off

const CENTER := Vector2(576, 250)
const BUTTON_SIZE := 220.0
const SLOTS: Array[Vector2] = [Vector2(-122, 44), Vector2(-75, 106), Vector2(0, 130), Vector2(75, 106), Vector2(122, 44)] # along the bottom of the circle
const SHIELD_HEIGHT := 84.0
const HIT_RADIUS := 46.0
const ARMOR_LEAD_S := 2.4 # shields show up this long before their beat
const FADE_IN_S := 0.2
const RING_SCALE := 1.5

@export var button: Texture2D
@export var shields: Array[Texture2D] = []

var _shield: Dictionary[AimNote, Texture2D] = {}
var _missed: Array[AimNote] = []
var _cuts: Array[PolygonCut] = []
var _slash: Dictionary[AimNote, Vector2] = {} # slash direction of the hit, see is_hit

static func slot(index: int) -> Vector2: return CENTER + SLOTS[index % SLOTS.size()]

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS # shields are drawn well under their size
	for i in mode.segment.notes.size():
		_shield[mode.segment.notes[i] as AimNote] = shields[(i * 7) % shields.size()]
	mode.judged.connect(_on_judged)

func _rect(note: AimNote) -> Rect2:
	var texture := _shield[note]
	var size := texture.get_size() * SHIELD_HEIGHT / texture.get_height()
	return Rect2(note.position - size / 2, size)

# remembers the slash direction so the shield splits along it
func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	var a := to_local(from)
	var b := to_local(to)
	var hit := Geometry2D.get_closest_point_to_segment(note.position, a, b).distance_to(note.position) <= HIT_RADIUS
	if hit: _slash[note] = (b - a).normalized() if a != b else Vector2.RIGHT # a relax touch has no direction
	return hit

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

func _on_judged(result: HitResult) -> void:
	var note := result.note as AimNote
	if result.is_miss(): _missed.append(note)
	else: _cuts.append(PolygonCut.split(_shield[note], _rect(note), note.position, _slash.get(note, Vector2.RIGHT)))

func _draw() -> void:
	var now := _now()
	BossArena.draw(self, now)
	draw_texture_rect(button, BossArena.button_rect(button, CENTER, BUTTON_SIZE), false)
	for note in _missed: draw_texture_rect(_shield[note], _rect(note), false)
	var approach := GameConfig.approach_time_s
	var pending := mode.pending()
	for i in range(pending.size() - 1, -1, -1): # the next shield on top
		var note := pending[i] as AimNote
		var until := note.time - now
		if until > ARMOR_LEAD_S: continue
		var alpha := clampf((ARMOR_LEAD_S - until) / FADE_IN_S, 0.0, 1.0)
		draw_texture_rect(_shield[note], _rect(note), false, Color(1, 1, 1, alpha))
		if until > 0 and until < approach:
			draw_arc(note.position, HIT_RADIUS * (1.0 + RING_SCALE * until / approach), 0, TAU, 48, Color(1, 1, 1, 1.0 - until / approach), 3, true)
	var ms := Time.get_ticks_msec()
	_cuts.assign(_cuts.filter(func(c: PolygonCut): return c.alive(ms)))
	for cut in _cuts: cut.draw(self, ms)
