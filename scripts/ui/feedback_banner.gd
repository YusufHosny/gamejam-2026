class_name FeedbackBanner
extends Control

# slides down at the top with a reaction image and Louis' line, then back up

const CARD := Vector2(420, 150)
const IMAGE := 120.0
const SLIDE_S := 0.25
const HOLD_S := 2.2
const BACKGROUND := Color(0.08, 0.08, 0.12, 0.95)
const BORDER := Color(1.0, 0.85, 0.2)
const TEXT_SIZE := 30

var _image: Texture2D
var _caption := ""
var _shown := 0.0 # 0 up out of view, 1 down
var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = PROCESS_MODE_ALWAYS

func show_feedback(image: Texture2D, caption: String) -> void:
	_image = image
	_caption = caption
	if _tween != null: _tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_shown, _shown, 1.0, SLIDE_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(HOLD_S)
	_tween.tween_method(_set_shown, 1.0, 0.0, SLIDE_S).set_ease(Tween.EASE_IN)

func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()

func _draw() -> void:
	if _shown <= 0.0 or _image == null: return
	var card := Rect2(Vector2((size.x - CARD.x) / 2.0, lerpf(-CARD.y - 10, 16, _shown)), CARD)
	draw_rect(card, BACKGROUND)
	draw_rect(card, BORDER, false, 3)
	var frame := Rect2(card.position + Vector2(15, 15), Vector2.ONE * IMAGE)
	var fit := _image.get_size() * minf(IMAGE / _image.get_width(), IMAGE / _image.get_height())
	draw_texture_rect(_image, Rect2(frame.get_center() - fit / 2.0, fit), false)
	var font := ThemeDB.fallback_font
	var text_x := frame.end.x + 16
	draw_multiline_string(font, Vector2(text_x, card.position.y + CARD.y / 2.0 + 10), _caption, HORIZONTAL_ALIGNMENT_LEFT, card.end.x - text_x - 12, TEXT_SIZE, 2, Color.WHITE)
