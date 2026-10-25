class_name BossChaseView
extends CircleAimView

# f1 and f4: osu circles to hit, the submit button darts ahead and sits under the next one on its beat

const BUTTON_RADIUS := 64.0
const DART := 4.0 # ease out power, it lands well before its beat
const LEAD_CIRCLES := 2.5 # on a slider it runs this many circles ahead of the ball along it, the player chasing it
const LEAD_STEP := 0.002 # progress per step when walking the slider for the lead
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
			var slider := note as SliderNote
			return _ahead(slider, slider.progress_at(now))
		if note.time > now:
			var to := _ahead(note as SliderNote, 0.0) if note is SliderNote else note.position
			if note == previous: return to
			var from := _end_of(previous)
			var leave := (previous as SliderNote).end_time if previous is SliderNote else previous.time
			var t := clampf((now - leave) / (note.time - leave), 0.0, 1.0)
			return from.lerp(to, 1.0 - pow(1.0 - t, DART))
		previous = note
	return _end_of(previous)

static func _end_of(note: AimNote) -> Vector2: return (note as SliderNote).ball_at(1.0) if note is SliderNote else note.position

# LEAD_CIRCLES along the slider past `progress`, or its end
func _ahead(slider: SliderNote, progress: float) -> Vector2:
	var at := slider.ball_at(progress)
	var left := LEAD_CIRCLES * radius * 2.0
	while progress < 1.0 and left > 0.0:
		progress = minf(progress + LEAD_STEP, 1.0)
		var next := slider.ball_at(progress)
		left -= at.distance_to(next)
		at = next
	return at

# over the circles while it leads a slider, under them otherwise so it never hides a circle
func _over_circles(now: float) -> bool:
	var sliding := (mode as AimMode).sliding()
	if sliding != null: return true
	var next := mode.pending()
	return not next.is_empty() and next[0] is SliderNote

# the button under the circles, so the notes read like osu
func _draw() -> void:
	var now := _now()
	BossArena.draw(self, now)
	var flash := clampf(1.0 - (Time.get_ticks_msec() - _flash_ms) / (FLASH_S * 1000), 0.0, 1.0)
	var at := _button_at(now)
	var done := final and mode.pending().is_empty()
	var rect := _rect(at).grow(12) if done else _rect(at).grow(-8.0 * flash)
	var tint := Color(Color.WHITE.lerp(MISS if _flash_miss else Color(2, 2, 2), flash * 0.6), 1.0 if done else BUTTON_ALPHA)
	var over := _over_circles(now)
	if not over: draw_texture_rect(button, rect, false, tint)
	super()
	if over: draw_texture_rect(button, rect, false, tint)
	if done: draw_caught(self, at)

# under the caught button, the win cutscene starts on it
static func draw_caught(item: CanvasItem, at: Vector2, alpha := 1.0) -> void:
	var font := ThemeDB.fallback_font
	var text := "submitted"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	item.draw_string(font, at + Vector2(-width / 2, BUTTON_RADIUS + 60), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.4, 1.0, 0.5, alpha))
