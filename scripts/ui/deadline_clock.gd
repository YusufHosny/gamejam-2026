class_name DeadlineClock
extends Control

const SHOWN_S := 300.0 # always reads 5:00 down to 0:00, stretched over however long the run really is
const COLOR := Color(1.0, 0.25, 0.25)
const OVERLAY_ALPHA := 0.25
const BEATS := 4
const BEAT_S := 0.55
const PUNCH_S := 0.55 # the last beat's snap up before it shoots into the corner
const PUNCH := 0.4 # extra size after the first beat
const PUNCH_GROWTH := 0.4 # each beat grows it this much more, and it stays grown
const SHRINK_S := 0.7
const INTRO_S := BEATS * BEAT_S + SHRINK_S # the countdown cutscene lasts this long
const INTRO_FONT_SIZE := 70
const CORNER_FONT_SIZE := 32
const CORNER_MARGIN := Vector2(16, 12)
const CAPTION := "UNTIL DEADLINE"
const CAPTION_FONT_SIZE := 32 # stays put while the clock grows, so it steadies the bounce instead of adding to it
const CAPTION_GAP := 8.0
const CAPTION_FADE_S := 0.4
const CAPTION_RISE := 12.0 # drifts up this far as it fades in

@onready var _alarm: AudioStreamPlayer = $Alarm

var _time_left_s := 0.0
var _minimized := 1.0 # 0 is big in the center, 1 is tucked in the top right corner
var _pulse := 0.0 # extra size on top of the intro size, 0.2 is 20% bigger
var _caption := 0.0 # 0 hidden below its spot, 1 faded in, only shows during the intro

func _ready() -> void:
	_alarm.stream = SfxUtils.alarm()

func set_time_left(seconds: float) -> void: _time_left_s = seconds

# grows a step with a wobble on each alarm beat, then winds up with the biggest punch and shoots into the corner
func play_intro() -> void:
	_minimized = 0.0
	_pulse = 0.0
	_caption = 0.0
	create_tween().tween_property(self, "_caption", 1.0, CAPTION_FADE_S).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var tween := create_tween()
	for i in BEATS:
		tween.tween_callback(_alarm.play)
		# elastic out jumps most of the way at once, then wobbles to rest at the new size for the rest of the beat
		tween.tween_property(self, "_pulse", PUNCH + PUNCH_GROWTH * i, BEAT_S).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_alarm.play)
	# the wind up is the biggest punch yet, then it shoots into the corner from there, shrinking the punch
	# away along the same curve so it's one movement
	tween.tween_property(self, "_pulse", PUNCH + PUNCH_GROWTH * BEATS, PUNCH_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_minimized", 1.0, SHRINK_S - PUNCH_S).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "_pulse", 0.0, SHRINK_S - PUNCH_S).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished

func _process(_delta: float) -> void: queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(COLOR, OVERLAY_ALPHA * clampf(1.0 - _minimized, 0.0, 1.0)))
	var font := get_theme_default_font()
	var text := _format(_time_left_s)
	var font_size := maxi(roundi(lerpf(INTRO_FONT_SIZE, CORNER_FONT_SIZE, _minimized) * (1.0 + _pulse)), 1)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	# lerp the text's center so it travels in a straight line while shrinking
	var corner_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, CORNER_FONT_SIZE)
	var corner_center := Vector2(size.x - CORNER_MARGIN.x - corner_size.x / 2, CORNER_MARGIN.y + corner_size.y / 2)
	var center := (size / 2).lerp(corner_center, _minimized)
	var baseline := center + Vector2(-text_size.x / 2, -text_size.y / 2 + font.get_ascent(font_size))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR)
	_draw_caption(font, center, baseline.y + font.get_descent(font_size))

# under the clock, gone by the time it reaches the corner
func _draw_caption(font: Font, center: Vector2, clock_bottom: float) -> void:
	var alpha := _caption * clampf(1.0 - _minimized, 0.0, 1.0)
	if alpha <= 0.0: return
	var caption_size := font.get_string_size(CAPTION, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE)
	var rise := (1.0 - _caption) * CAPTION_RISE
	var baseline := Vector2(center.x - caption_size.x / 2, clock_bottom + CAPTION_GAP + font.get_ascent(CAPTION_FONT_SIZE) + rise)
	draw_string(font, baseline, CAPTION, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE, Color(COLOR, alpha))

static func _format(seconds: float) -> String:
	var ms := maxi(floori(seconds * 1000.0), 0)
	return "%d:%02d:%03d" % [ms / 60000, ms / 1000 % 60, ms % 1000]
