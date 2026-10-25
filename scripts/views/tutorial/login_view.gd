class_name LoginView
extends CircleAimView

# the jam site's sign in, in a browser window on the desktop the intro cutscene ends on. the first try's password is
# wrong: the fields shake, clear, and it's username, password, sign in again before the two-factor check

const PAGE_AT := Vector2(172, 134) # login page.png's top left on screen, the window clears the hint and the intro's narration
const PAGE_SCALE := 1.15
const PAGE_SIZE := Vector2(702, 344) * PAGE_SCALE
const TITLE_H := 34.0
const URL := "game_jam"
# spots in login page.png's pixels
const USERNAME := PAGE_AT + Vector2(362, 133) * PAGE_SCALE
const PASSWORD := PAGE_AT + Vector2(362, 212) * PAGE_SCALE
const SIGN_IN := PAGE_AT + Vector2(167, 265) * PAGE_SCALE
const FIELD_LEFT := PAGE_AT.x + 140 * PAGE_SCALE
const ERROR_AT := PAGE_AT + Vector2(225, 265) * PAGE_SCALE # right of the sign in button
const CREDENTIALS: Array[String] = ["oh_my_baguette@email.fr", "••••••••••"]
const ERROR := Color(0.85, 0.15, 0.15)
const SHAKE := 8.0
const SHAKE_S := 0.4
const CLEAR_S := 0.6 # the wrong password stays filled this long before the fields clear

@export var page: Texture2D
@export var hint := "Click the circle when the approach circle hits it"
@export var retry_hint := "Wrong password, try again"

var _filled := 0 # username, password, sign in, then all three again
var _failed_ms := -100000 # when the first sign in bounced

func _ready() -> void:
	super()
	mode.judged.connect(func(_r: HitResult):
		_filled += 1
		if _filled == 3: _failed_ms = Time.get_ticks_msec())

# the window the intro cutscene opens and this view keeps, `pop` grows it in around its centre.
# content draws the page inside it, in page.png's rect
static func draw_window(item: CanvasItem, content: Callable, pop := 1.0) -> void:
	var window := Rect2(PAGE_AT - Vector2(0, TITLE_H), PAGE_SIZE + Vector2(0, TITLE_H))
	var center := window.get_center()
	item.draw_set_transform(center * (1.0 - pop), 0.0, Vector2.ONE * pop)
	TutorialUi.box(item, window.grow(3), Color(0.25, 0.26, 0.3), 10)
	TutorialUi.box(item, Rect2(window.position + Vector2(130, 7), Vector2(window.size.x - 260, TITLE_H - 14)), Color(1, 1, 1, 0.9), 10)
	TutorialUi.label(item, window.position + Vector2(window.size.x / 2, TITLE_H / 2), URL, 14, TutorialUi.MUTED)
	for i in 3: item.draw_circle(window.position + Vector2(20 + i * 20, TITLE_H / 2), 6, [Color("ff5f57"), Color("febc2e"), Color("28c840")][i], true, -1, true)
	content.call()
	item.draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	Desktop.draw(self)
	draw_window(self, _draw_page)
	if _filled >= 6: _draw_two_factor()
	else: super()
	TutorialUi.hint(self, retry_hint if _filled >= 3 and _filled < 6 else hint)

func _draw_page() -> void:
	var since_fail := (Time.get_ticks_msec() - _failed_ms) / 1000.0
	if page != null: draw_texture_rect(page, Rect2(PAGE_AT, PAGE_SIZE), false)
	else: TutorialUi.box(self, Rect2(PAGE_AT, PAGE_SIZE), TutorialUi.SCREEN_COLOR, 0)
	var shake := Vector2(sin(since_fail * 70.0) * SHAKE * (1.0 - since_fail / SHAKE_S), 0) if since_fail < SHAKE_S else Vector2.ZERO
	var shown := _filled if _filled < 3 or since_fail < CLEAR_S else _filled - 3 # the second try starts empty
	for i in CREDENTIALS.size():
		if shown <= i: continue
		var center: Vector2 = [USERNAME, PASSWORD][i]
		var color := ERROR if _filled == 3 and since_fail < CLEAR_S else TutorialUi.INK
		draw_left(self, Vector2(FIELD_LEFT, center.y) + shake, CREDENTIALS[i], 20, color)
	if _filled == 3 and since_fail >= CLEAR_S: # until the second try's first click
		draw_left(self, ERROR_AT, "Wrong password. (caps lock was on)", 18, ERROR)

# the page signed in, both fields filled, the sign in cutscene starts on it
static func draw_filled_page(item: CanvasItem, page_texture: Texture2D) -> void:
	if page_texture != null: item.draw_texture_rect(page_texture, Rect2(PAGE_AT, PAGE_SIZE), false)
	for i in CREDENTIALS.size(): draw_left(item, Vector2(FIELD_LEFT, [USERNAME, PASSWORD][i].y), CREDENTIALS[i], 20, TutorialUi.INK)

static func draw_left(item: CanvasItem, at: Vector2, text: String, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var lift := (font.get_ascent(size) - font.get_descent(size)) / 2
	item.draw_string(font, at + Vector2(0, lift), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func two_factor_rect() -> Rect2: return Rect2(Rect2(PAGE_AT, PAGE_SIZE).get_center() - Vector2(220, 80), Vector2(440, 160))

func _draw_two_factor() -> void:
	var modal := two_factor_rect()
	TutorialUi.box(self, modal, Color(0.1, 0.11, 0.14), 12)
	TutorialUi.label(self, modal.get_center() - Vector2(0, 24), "two-factor check", 26, Color.WHITE)
	TutorialUi.label(self, modal.get_center() + Vector2(0, 20), "we sent a code to your email", 18, Color(1, 1, 1, 0.7))
