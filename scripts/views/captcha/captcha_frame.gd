class_name CaptchaFrame
extends RefCounted

# layout of assets/captcha/frame.png, shared by every captcha view. rects are in its pixels

const TEXTURE := preload("res://assets/captcha/frame.png")
const SIZE := Vector2(788, 1144)
const SCALE := 540.0 / 1144.0
const ORIGIN := Vector2(576 - 788 * SCALE / 2, 30)
const HEADER := Rect2(6, 9, 772, 228)
const CONTENT := Rect2(6, 243, 772, 786) # the white area, inset to line up with the header
const EDGES: Array[Rect2] = [Rect2(0, 0, 788, 243), Rect2(0, 1029, 788, 115), Rect2(0, 243, 6, 786), Rect2(778, 243, 10, 786)] # everything but CONTENT
const ACCENT := Color(0.1, 0.45, 0.9)
const HEADER_LINES: Array[Dictionary] = [ # line, target, note: y in the header on screen, font size, fit to the header's width
	{"y": 30, "size": 15, "fit": false},
	{"y": 66, "size": 30, "fit": false},
	{"y": 92, "size": 13, "fit": true},
]

static func to_screen(source: Rect2) -> Rect2: return Rect2(ORIGIN + source.position * SCALE, source.size * SCALE)

static func content() -> Rect2: return to_screen(CONTENT)

static func draw(item: CanvasItem, alpha := 1.0) -> void: item.draw_texture_rect(TEXTURE, to_screen(Rect2(Vector2.ZERO, SIZE)), false, Color(1, 1, 1, alpha))

# the frame around the content area, over anything that flew past it or plays inside it
static func draw_edges(item: CanvasItem) -> void:
	for edge in EDGES: item.draw_texture_rect_region(TEXTURE, to_screen(edge), edge)

static func draw_header(item: CanvasItem, line: String, target: String, note: String, alpha := 1.0) -> void:
	for i in HEADER_LINES.size(): draw_header_line(item, i, [line, target, note][i], alpha)

# pop 0..1 grows the line in from its left end, like the ads pop in
static func draw_header_line(item: CanvasItem, index: int, text: String, alpha := 1.0, pop := 1.0) -> void:
	var header := to_screen(HEADER)
	var spec: Dictionary = HEADER_LINES[index]
	var start := Vector2(header.position.x + 14, header.position.y + spec.y)
	var width: float = header.size.x - 28 if spec.fit else -1.0
	item.draw_set_transform(start, 0.0, Vector2.ONE * (0.6 + 0.4 * pop))
	item.draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, width, spec.size, Color(Color.WHITE, alpha * pop))
	item.draw_set_transform(Vector2.ZERO)
