class_name IntroCutscene
extends Cutscene

# the game's done, sort of. on the desktop the player talks themselves into submitting, opens the jam site and hits
# submit, which wants a sign in first: the login map carries on in the same window

const LENGTH_S := 14.5
const FADE_IN_S := 0.8
# [from, until, line] the player's narration, typed out
const LINES := [
	[0.8, 2.8, "Okay. The game is done."],
	[3.0, 5.2, "Well... it runs. That counts as done."],
	[5.4, 9.8, "The jam closes in a few minutes. Let's submit it before anything goes wrong."],
	[11.9, LENGTH_S, "Sign in first? ...Sure. Easy."],
]
const TYPE_CPS := 40.0
const NARRATION_SIZE := 24
const NARRATION_LIFT := 40.0 # box centre above the taskbar, under the browser window
const CURSOR_SIZE := 48.0
const CURSOR_REST := Vector2(700, 380)
const INTERNET_ICON := Desktop.ICON_START + Vector2(0, 2 * Desktop.ICON_STEP)
const SUBMIT_BUTTON := LoginView.PAGE_AT + LoginView.PAGE_SIZE * Vector2(0.5, 0.7)
const SUBMIT_SIZE := Vector2(320, 60)
# cursor and window timeline
const TO_ICON_AT := 8.6
const TO_ICON_S := 0.7
const ICON_CLICKS: Array[float] = [9.35, 9.55] # a double click
const WINDOW_AT := 9.9
const POP_S := 0.15
const TO_SUBMIT_AT := 10.8
const TO_SUBMIT_S := 0.7
const SUBMIT_CLICK := 11.55
const LOGIN_AT := 11.7 # submit wants a sign in first
const CLICK_S := 0.1
const CURSOR_HIDE_S := 0.3 # gone before the end, the game's own cursor takes over

@export var page: Texture2D # the sign in page, the login map's
@export var cursor: Texture2D
@export var cursor_click: Texture2D

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	Desktop.draw(self)
	if time >= WINDOW_AT:
		var pop := 0.6 + 0.4 * clampf((time - WINDOW_AT) / POP_S, 0.0, 1.0)
		LoginView.draw_window(self, _draw_login if time >= LOGIN_AT else _draw_submit, pop)
	_draw_narration()
	if time < LENGTH_S - CURSOR_HIDE_S and cursor != null: _draw_cursor()
	var fade := 1.0 - clampf(time / FADE_IN_S, 0.0, 1.0)
	if fade > 0.0: draw_rect(get_viewport_rect(), Color(0, 0, 0, fade))

# the jam's page, before it asks for a sign in
func _draw_submit() -> void:
	var rect := Rect2(LoginView.PAGE_AT, LoginView.PAGE_SIZE)
	draw_rect(rect, Color.WHITE)
	TutorialUi.label(self, rect.position + Vector2(rect.size.x / 2, 90), "GAME JAM 2026", 48)
	TutorialUi.label(self, rect.position + Vector2(rect.size.x / 2, 150), "submissions closing soon!", 24, Color(0.85, 0.2, 0.2))
	var pressed := time >= SUBMIT_CLICK and time < SUBMIT_CLICK + CLICK_S
	var button := Rect2(SUBMIT_BUTTON - SUBMIT_SIZE / 2, SUBMIT_SIZE).grow(-3 if pressed else 0)
	TutorialUi.box(self, button, Color(0.18, 0.44, 0.87), 8)
	TutorialUi.label(self, SUBMIT_BUTTON, "submit your game", 24, Color.WHITE)

func _draw_login() -> void:
	if page != null: draw_texture_rect(page, Rect2(LoginView.PAGE_AT, LoginView.PAGE_SIZE), false)

# typed in a box above the taskbar, left aligned to where the whole line will sit so it doesn't shift
func _draw_narration() -> void:
	for line: Array in LINES:
		if time < line[0] or time >= line[1]: continue
		var text: String = line[2]
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NARRATION_SIZE).x
		var screen := get_viewport_rect().size
		var center := Vector2(screen.x / 2, screen.y - Desktop.TASKBAR_H - NARRATION_LIFT)
		TutorialUi.box(self, Rect2(center - Vector2(width / 2 + 24, 26), Vector2(width + 48, 52)), Color(0, 0, 0, 0.7), 14)
		var typed := text.left(floori((time - line[0]) * TYPE_CPS))
		var lift := (font.get_ascent(NARRATION_SIZE) - font.get_descent(NARRATION_SIZE)) / 2
		draw_string(font, center + Vector2(-width / 2, lift), typed, HORIZONTAL_ALIGNMENT_LEFT, -1, NARRATION_SIZE, Color.WHITE)

# rests mid screen, double clicks the internet icon, then clicks submit
func _draw_cursor() -> void:
	var tip := CURSOR_REST.lerp(INTERNET_ICON, smoothstep(0.0, 1.0, clampf((time - TO_ICON_AT) / TO_ICON_S, 0.0, 1.0)))
	tip = tip.lerp(SUBMIT_BUTTON, smoothstep(0.0, 1.0, clampf((time - TO_SUBMIT_AT) / TO_SUBMIT_S, 0.0, 1.0)))
	var clicking := false
	for at in ICON_CLICKS + [SUBMIT_CLICK]:
		if time >= at and time < at + CLICK_S: clicking = true
	var texture := cursor_click if clicking and cursor_click != null else cursor
	draw_texture_rect(texture, Rect2(tip, Vector2.ONE * CURSOR_SIZE), false)
