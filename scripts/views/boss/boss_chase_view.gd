class_name BossChaseView
extends AimView

# f1 and f4: the submit button darts between notes and lands on each one on its beat

const RADIUS := 64.0
const HIT_GROW := 10.0 # a little forgiving around the button
const DART := 4.0 # ease out power, it lands well before its beat
const APPROACH_SCALE := 1.6 # ring starts at RADIUS * (1 + APPROACH_SCALE)
const PREVIEWS := 4 # upcoming spots shown faintly
const FLASH_S := 0.15
const ACCENT := Color(1.0, 0.85, 0.2)
const MISS := Color(1.0, 0.25, 0.25)

@export var button: Texture2D
@export var final := false # last chase, ends with the button caught

var _flash_ms := -100000
var _flash_miss := false

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	mode.judged.connect(func(r: HitResult):
		_flash_ms = Time.get_ticks_msec()
		_flash_miss = r.is_miss())

func _rect(at: Vector2) -> Rect2: return BossArena.button_rect(button, at, RADIUS * 2)

func is_hit(note: AimNote, _from: Vector2, to: Vector2) -> bool:
	return to_local(to).distance_to(note.position) <= RADIUS + HIT_GROW

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

# between the last note and the next, eased so it settles early
func _button_at(now: float) -> Vector2:
	var notes := mode.segment.notes
	var previous := notes[0] as AimNote
	for note: AimNote in notes:
		if note.time > now:
			if note == previous: return note.position
			var t := clampf((now - previous.time) / (note.time - previous.time), 0.0, 1.0)
			return previous.position.lerp(note.position, 1.0 - pow(1.0 - t, DART))
		previous = note
	return previous.position

func _draw() -> void:
	var now := _now()
	BossArena.draw(self, now)
	_draw_targets(now)
	var flash := clampf(1.0 - (Time.get_ticks_msec() - _flash_ms) / (FLASH_S * 1000), 0.0, 1.0)
	var at := _button_at(now)
	var done := final and mode.pending().is_empty()
	var rect := _rect(at).grow(-8.0 * flash)
	if done: rect = _rect(at).grow(12)
	draw_texture_rect(button, rect, false, Color.WHITE.lerp(MISS if _flash_miss else Color(2, 2, 2), flash * 0.6))
	if done: _draw_caught(at)

# the next spot closes in like an approach circle, the ones after are faint previews
func _draw_targets(now: float) -> void:
	var approach := GameConfig.approach_time_s
	var pending := mode.pending()
	for i in range(mini(PREVIEWS, pending.size()) - 1, -1, -1):
		var note := pending[i] as AimNote
		var until := note.time - now
		if until > approach * 2: continue
		if i == 0 and until < approach:
			var closing := clampf(until / approach, 0.0, 1.0)
			draw_arc(note.position, RADIUS * (1.0 + APPROACH_SCALE * closing), 0, TAU, 64, Color(ACCENT, 1.0 - closing * 0.5), 4, true)
		else:
			draw_arc(note.position, RADIUS, 0, TAU, 64, Color(ACCENT, 0.18), 2, true)
		if i + 1 < pending.size() and i + 1 < PREVIEWS:
			draw_dashed_line(note.position, (pending[i + 1] as AimNote).position, Color(ACCENT, 0.25), 2, 8)

func _draw_caught(at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := "submitted"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	draw_string(font, at + Vector2(-width / 2, RADIUS + 60), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.4, 1.0, 0.5))
