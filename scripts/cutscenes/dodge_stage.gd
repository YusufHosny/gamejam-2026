@tool
class_name DodgeStage
extends Node2D

# the dodge cutscene's top layer: the boss arena, the submit button dodging the cursor twice, its lines and the cursor.
# the cursor fades in with the arena, after the loading screen
# the cutscene's animation keyframes arena and time (linear, so it's the cutscene's own clock), the rest is in code.
# a tool script so scrubbing the animation in the editor shows it

const BUTTON_WIDTH := BossChaseView.RADIUS * 2 # f1's size, so the cut into it doesn't jump
const BOSS_FROM := Vector2(800, 300)
const DODGE_TO := Vector2(360, 220)
const BOSS_TO := BossMaps.CHASE_START # f1's first spot
const CURSOR_FROM := Vector2(1000, 600)
const CURSOR_SIZE := 48.0
const FONT_SIZE := 30
const TEXT_LIFT := 40.0 # above the button's top
const TEXT_FADE_S := 0.2
const TOO_SLOW := Color(1.0, 0.35, 0.35)
const DART := 4.0 # ease out power, like the chase
# timeline in the cutscene's seconds
const BOSS_IN_AT := 11.4
const BOSS_IN_S := 0.8
const LINE_AT := 12.4
const TRY_AT: Array[float] = [14.6, 16.6] # the cursor sets off
const TRY_S: Array[float] = [0.8, 0.45] # and gets there, the second try is faster
const DODGE_LEAD_S := 0.08 # the button goes just before the cursor arrives
const DODGE_S := 0.25
const CLICK_S := 0.15
const TOO_SLOW_AT := 15.6
const TOO_SLOW_UNTIL := 17.2
const READY_AT := 17.5
const READY_UNTIL := 19.0 # the cutscene's end, the boss map starts after

@export var button: Texture2D
@export var cursor: Texture2D
@export var cursor_click: Texture2D
@export_range(0.0, 1.0) var arena := 0.0
@export var time := 0.0

func _process(_delta: float) -> void: queue_redraw()

func _draw() -> void:
	if arena > 0.0: BossArena.draw(self, time, arena)
	if button != null and time >= BOSS_IN_AT: _draw_button()
	_draw_text("I heard you have been looking for me...", Color.WHITE, LINE_AT, _dodge_at(0))
	_draw_text("too slow", TOO_SLOW, TOO_SLOW_AT, TOO_SLOW_UNTIL)
	_draw_text("Ready?", Color.WHITE, READY_AT, READY_UNTIL)
	if cursor != null and arena > 0.0: _draw_cursor()

# fades and grows in from nothing
func _draw_button() -> void:
	var shown := clampf((time - BOSS_IN_AT) / BOSS_IN_S, 0.0, 1.0)
	var grown := 0.6 + 0.4 * (1.0 - pow(1.0 - shown, 3.0))
	draw_texture_rect(button, BossArena.button_rect(button, _button_at(), BUTTON_WIDTH * grown), false, Color(1, 1, 1, shown))

func _button_at() -> Vector2:
	var spots: Array[Vector2] = [BOSS_FROM, DODGE_TO, BOSS_TO]
	var at := spots[0]
	for i in TRY_AT.size():
		var t := clampf((time - _dodge_at(i)) / DODGE_S, 0.0, 1.0)
		if t > 0.0: at = spots[i].lerp(spots[i + 1], 1.0 - pow(1.0 - t, DART))
	return at

func _dodge_at(i: int) -> float: return TRY_AT[i] + TRY_S[i] - DODGE_LEAD_S

# centred over the button, follows it
func _draw_text(text: String, color: Color, from: float, until: float) -> void:
	var alpha := minf(clampf((time - from) / TEXT_FADE_S, 0.0, 1.0), clampf((until - time) / TEXT_FADE_S, 0.0, 1.0))
	if alpha <= 0.0: return
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var top := _button_at().y - BUTTON_WIDTH / 2 - TEXT_LIFT
	var at := Vector2(clampf(_button_at().x - width / 2, 16.0, get_viewport_rect().size.x - width - 16.0), top)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 6, Color(0, 0, 0, alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, alpha))

# waits in the corner from when the arena shows, then goes for where the button is each try and clicks just too late
func _draw_cursor() -> void:
	var spots: Array[Vector2] = [CURSOR_FROM, BOSS_FROM, DODGE_TO]
	var tip := CURSOR_FROM
	var clicking := false
	for i in TRY_AT.size():
		var t := clampf((time - TRY_AT[i]) / TRY_S[i], 0.0, 1.0)
		if t > 0.0: tip = spots[i].lerp(spots[i + 1], smoothstep(0.0, 1.0, t))
		var arrived := TRY_AT[i] + TRY_S[i]
		if time >= arrived and time < arrived + CLICK_S: clicking = true
	var texture := cursor_click if clicking and cursor_click != null else cursor
	draw_texture_rect(texture, Rect2(tip, Vector2.ONE * CURSOR_SIZE), false, Color(1, 1, 1, arena))
