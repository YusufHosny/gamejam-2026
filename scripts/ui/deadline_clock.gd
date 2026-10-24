class_name DeadlineClock
extends Control

const COLOR := Color(1.0, 0.25, 0.25)
const OVERLAY_ALPHA := 0.25
const FLASHES := 4
const FLASH_ON_S := 0.35
const FLASH_OFF_S := 0.2
const SHRINK_S := 0.7
const INTRO_FONT_SIZE := 160
const CORNER_FONT_SIZE := 32
const CORNER_MARGIN := Vector2(16, 12)

@onready var _alarm: AudioStreamPlayer = $Alarm

var _time_left_s := 0.0
var _lit := true
var _minimized := 1.0 # 0 is big in the center, 1 is tucked in the top right corner

func _ready() -> void:
	_alarm.stream = SfxUtils.alarm()

func set_time_left(seconds: float) -> void: _time_left_s = seconds

# flashes with the alarm, then shrinks into the corner
func play_intro() -> void:
	_minimized = 0.0
	var tween := create_tween()
	for i in FLASHES:
		tween.tween_callback(_flash.bind(true))
		tween.tween_interval(FLASH_ON_S)
		tween.tween_callback(_flash.bind(false))
		tween.tween_interval(FLASH_OFF_S)
	tween.tween_callback(_flash.bind(true))
	tween.tween_property(self, "_minimized", 1.0, SHRINK_S).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _flash(on: bool) -> void:
	_lit = on
	if on: _alarm.play()

func _process(_delta: float) -> void: queue_redraw()

func _draw() -> void:
	if not _lit: return
	draw_rect(Rect2(Vector2.ZERO, size), Color(COLOR, OVERLAY_ALPHA * (1.0 - _minimized)))
	var font := get_theme_default_font()
	var text := _format(_time_left_s)
	var font_size := roundi(lerpf(INTRO_FONT_SIZE, CORNER_FONT_SIZE, _minimized))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	# lerp the text's center so it travels in a straight line while shrinking
	var corner_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, CORNER_FONT_SIZE)
	var corner_center := Vector2(size.x - CORNER_MARGIN.x - corner_size.x / 2, CORNER_MARGIN.y + corner_size.y / 2)
	var center := (size / 2).lerp(corner_center, _minimized)
	var baseline := center + Vector2(-text_size.x / 2, -text_size.y / 2 + font.get_ascent(font_size))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR)

static func _format(seconds: float) -> String:
	var ms := maxi(floori(seconds * 1000.0), 0)
	return "%d:%02d:%03d" % [ms / 60000, ms / 1000 % 60, ms % 1000]
