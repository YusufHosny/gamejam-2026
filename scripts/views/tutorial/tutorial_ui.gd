class_name TutorialUi
extends RefCounted

# placeholder drawing shared by the tutorial views until assets land

const PHONE := Rect2(436, 100, 280, 470)
const SCREEN := Rect2(450, 130, 252, 410)
const PHONE_COLOR := Color(0.12, 0.12, 0.14)
const SCREEN_COLOR := Color(0.93, 0.94, 0.96)
const INK := Color(0.15, 0.16, 0.2)
const MUTED := Color(0.45, 0.47, 0.52)
const HINT_Y := 80.0
const HINT_SIZE := 20

static func hint(item: CanvasItem, text: String) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_SIZE).x
	var center := Vector2(item.get_viewport_rect().size.x / 2, HINT_Y)
	box(item, Rect2(center - Vector2(width / 2 + 16, 18), Vector2(width + 32, 36)), Color(0, 0, 0, 0.6), 18)
	label(item, center, text, HINT_SIZE, Color.WHITE)

# texture is an optional phone frame with a see-through screen
static func phone(item: CanvasItem, texture: Texture2D = null, screen := SCREEN_COLOR) -> void:
	if texture == null: box(item, PHONE, PHONE_COLOR, 28)
	box(item, SCREEN, screen, 10)
	if texture != null: item.draw_texture_rect(texture, PHONE, false)

static func box(item: CanvasItem, rect: Rect2, color: Color, radius := 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	item.draw_style_box(style, rect)

static func label(item: CanvasItem, center: Vector2, text: String, size: int, color := INK) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lift := (font.get_ascent(size) - font.get_descent(size)) / 2
	item.draw_string(font, center + Vector2(-width / 2, lift), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
