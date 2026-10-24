class_name CaptchaFrame
extends RefCounted

# layout of assets/captcha/frame.png, shared by every captcha view. rects are in its pixels

const TEXTURE := preload("res://assets/captcha/frame.png")
const SIZE := Vector2(788, 1144)
const SCALE := 540.0 / 1144.0
const ORIGIN := Vector2(576 - 788 * SCALE / 2, 30)
const HEADER := Rect2(6, 9, 772, 228)
const CONTENT := Rect2(6, 243, 772, 786) # the white area, inset to line up with the header
const TOP_EDGE := Rect2(0, 0, 788, 241)
const BOTTOM_EDGE := Rect2(0, 1031, 788, 113)
const ACCENT := Color(0.1, 0.45, 0.9)

static func to_screen(source: Rect2) -> Rect2: return Rect2(ORIGIN + source.position * SCALE, source.size * SCALE)

static func content() -> Rect2: return to_screen(CONTENT)

static func draw(item: CanvasItem) -> void: item.draw_texture_rect(TEXTURE, to_screen(Rect2(Vector2.ZERO, SIZE)), false)

# header and footer again, over anything that flew past the content area
static func draw_edges(item: CanvasItem) -> void:
	for edge in [TOP_EDGE, BOTTOM_EDGE]: item.draw_texture_rect_region(TEXTURE, to_screen(edge), edge)

static func draw_header(item: CanvasItem, line: String, target: String, note: String) -> void:
	var header := to_screen(HEADER)
	var font := ThemeDB.fallback_font
	var left := header.position.x + 14
	item.draw_string(font, Vector2(left, header.position.y + 30), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	item.draw_string(font, Vector2(left, header.position.y + 66), target, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
	item.draw_string(font, Vector2(left, header.position.y + 92), note, HORIZONTAL_ALIGNMENT_LEFT, header.size.x - 28, 13, Color.WHITE)
