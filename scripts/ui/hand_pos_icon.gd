class_name HandPosIcon
extends Control

var hand_pos := Modality.HandPos.A:
	set(value):
		hand_pos = value
		queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var color := _color()
	draw_rect(Rect2(Vector2.ZERO, size), color, false, 3.0)
	draw_string(font, Vector2(0, size.y * 0.62), _letter(), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(size.y * 0.55), color)
	draw_string(font, Vector2(0, size.y * 0.88), _hint(), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(size.y * 0.15), color)

func _letter() -> String:
	match hand_pos:
		Modality.HandPos.A: return "A"
		Modality.HandPos.B: return "B"
	assert(false, "unhandled hand pos %s" % hand_pos)
	return ""

func _hint() -> String:
	match hand_pos:
		Modality.HandPos.A: return "MOUSE"
		Modality.HandPos.B: return "KEYS"
	assert(false, "unhandled hand pos %s" % hand_pos)
	return ""

func _color() -> Color:
	match hand_pos:
		Modality.HandPos.A: return Color(1.0, 0.6, 0.2)
		Modality.HandPos.B: return Color(0.3, 0.85, 1.0)
	assert(false, "unhandled hand pos %s" % hand_pos)
	return Color.WHITE
