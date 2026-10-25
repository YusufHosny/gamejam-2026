class_name BossChaseView
extends CircleAimView

# f1 and f4: osu circles to hit, the submit button darts ahead and sits under the next one on its beat

const BUTTON_RADIUS := 64.0
const DART := 4.0 # ease out power, it lands well before its beat
const BUTTON_ALPHA := 0.85
const FLASH_S := 0.15
const MISS := Color(1.0, 0.25, 0.25)

@export var button: Texture2D
@export var final := false # last chase, ends with the button caught

var _flash_ms := -100000
var _flash_miss := false

func _ready() -> void:
	super()
	mode.judged.connect(func(r: HitResult):
		_flash_ms = Time.get_ticks_msec()
		_flash_miss = r.is_miss())

func _rect(at: Vector2) -> Rect2: return BossArena.button_rect(button, at, BUTTON_RADIUS * 2)

# rides sliders, between notes eased so it settles early
func _button_at(now: float) -> Vector2:
	var notes := mode.segment.notes
	var previous := notes[0] as AimNote
	for note: AimNote in notes:
		if note is SliderNote and note.time <= now and now <= (note as SliderNote).end_time:
			return (note as SliderNote).ball_at((note as SliderNote).progress_at(now))
		if note.time > now:
			if note == previous: return note.position
			var from := _end_of(previous)
			var leave := (previous as SliderNote).end_time if previous is SliderNote else previous.time
			var t := clampf((now - leave) / (note.time - leave), 0.0, 1.0)
			return from.lerp(note.position, 1.0 - pow(1.0 - t, DART))
		previous = note
	return _end_of(previous)

static func _end_of(note: AimNote) -> Vector2: return (note as SliderNote).ball_at(1.0) if note is SliderNote else note.position

# the button under the circles, so the notes read like osu
func _draw() -> void:
	var now := _now()
	BossArena.draw(self, now)
	var flash := clampf(1.0 - (Time.get_ticks_msec() - _flash_ms) / (FLASH_S * 1000), 0.0, 1.0)
	var at := _button_at(now)
	var done := final and mode.pending().is_empty()
	var rect := _rect(at).grow(12) if done else _rect(at).grow(-8.0 * flash)
	draw_texture_rect(button, rect, false, Color(Color.WHITE.lerp(MISS if _flash_miss else Color(2, 2, 2), flash * 0.6), 1.0 if done else BUTTON_ALPHA))
	super()
	if done: _draw_caught(at)

func _draw_caught(at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := "submitted"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	draw_string(font, at + Vector2(-width / 2, BUTTON_RADIUS + 60), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.4, 1.0, 0.5))
