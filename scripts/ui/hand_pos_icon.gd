class_name HandPosIcon
extends Control

# the keys the current mode plays on: the click keys and the mouse, or the four lane keys

const KEY := Vector2(36, 32)
const GAP := 6.0

var hand_pos := Modality.HandPos.A:
	set(value):
		hand_pos = value
		queue_redraw()

func _draw() -> void:
	var color := _color()
	var actions: Array[StringName] = []
	match hand_pos:
		Modality.HandPos.A: actions.assign(AimClickMode.CLICKS)
		Modality.HandPos.B: actions.assign(FourDMode.LANES)
		_: assert(false, "unhandled hand pos %s" % hand_pos)
	var mouse := hand_pos == Modality.HandPos.A
	var width := actions.size() * (KEY.x + GAP) + (KEY.x if mouse else -GAP)
	var x := size.x - width # right aligned, under the deadline
	var y := (size.y - KEY.y) / 2
	for action in actions:
		_draw_key(Rect2(x, y, KEY.x, KEY.y), ModeDemo.key_label(action), color)
		x += KEY.x + GAP
	if mouse: _draw_mouse(Rect2(x, y - 6, KEY.x - 6, KEY.y + 12), color)

func _draw_key(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, Color(color, 0.15))
	draw_rect(rect, color, false, 2)
	var font := get_theme_default_font()
	draw_string(font, Vector2(rect.position.x, rect.position.y + rect.size.y * 0.72), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, color)

func _draw_mouse(rect: Rect2, color: Color) -> void:
	draw_rect(rect, Color(color, 0.15))
	draw_rect(rect, color, false, 2)
	var middle := rect.position.x + rect.size.x / 2
	var split := rect.position.y + rect.size.y * 0.4
	draw_line(Vector2(middle, rect.position.y), Vector2(middle, split), color, 2)
	draw_line(Vector2(rect.position.x, split), Vector2(rect.end.x, split), color, 2)

func _color() -> Color:
	match hand_pos:
		Modality.HandPos.A: return Color(1.0, 0.6, 0.2)
		Modality.HandPos.B: return Color(0.3, 0.85, 1.0)
	assert(false, "unhandled hand pos %s" % hand_pos)
	return Color.WHITE
