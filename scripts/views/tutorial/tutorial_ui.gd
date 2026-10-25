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

# --- Mail app ---
const MAIL_SIZE := Vector2(384, 688) # the mail interface images
const MAIL_BG := Color8(238, 242, 245) # their background, fills the screen either side
const MAIL_ROW := Rect2(31, 191, 324, 98) # the first message's card, in the images' pixels
const MAIL_COMPOSE_ROWS := Vector2(92, 180) # the blue compose button and its shadow, left out of the image

# a mail interface image fitted to the screen's height, `grow` scales it in around `from` (the app opening)
static func mail(item: CanvasItem, texture: Texture2D, grow := 1.0, from := SCREEN.get_center()) -> void:
	item.draw_set_transform(from * (1.0 - grow), 0.0, Vector2.ONE * grow)
	box(item, SCREEN, MAIL_BG, 10)
	if texture != null: # above and below the compose button, the background box shows where it was
		for rows: Vector2 in [Vector2(0, MAIL_COMPOSE_ROWS.x), Vector2(MAIL_COMPOSE_ROWS.y, MAIL_SIZE.y)]:
			var source := Rect2(0, rows.x, MAIL_SIZE.x, rows.y - rows.x)
			item.draw_texture_rect_region(texture, Rect2(mail_point(source.position), mail_point(source.end) - mail_point(source.position)), source)
	item.draw_set_transform(Vector2.ZERO)

static func mail_rect() -> Rect2:
	var size := MAIL_SIZE * SCREEN.size.y / MAIL_SIZE.y
	return Rect2(SCREEN.get_center() - size / 2, size)

# a spot in the mail images' pixels, on screen
static func mail_point(pixel: Vector2) -> Vector2:
	var rect := mail_rect()
	return rect.position + pixel * rect.size / MAIL_SIZE
