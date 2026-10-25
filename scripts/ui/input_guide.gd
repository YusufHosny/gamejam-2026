class_name InputGuide
extends Control

# a small card at the side of a tutorial map looping the input it wants, with the player's own keys. drawn like the
# mode switch card (ModeDemo), top level so a sliding view doesn't take it along

enum Move { CLICK, SLIDER, LANE, SWIPE_DOWN }

const SIZE := Vector2(160, 240) # fits right of the login map's browser window
const MARGIN := 8.0 # from the screen's right edge
const TOP := 150.0 # under the hand position icon
const SCALE := 0.54 # the demo's pieces are drawn for the bigger card
const BACKGROUND := Color(0.05, 0.05, 0.08, 0.88)
const LOOPS := {Move.CLICK: 1.6, Move.SLIDER: 2.6, Move.LANE: 1.6, Move.SWIPE_DOWN: 1.6}
const HIT_S := 0.9 # the click, the landing and the swipe all happen here in their loop
const SLIDER_GRAB_S := 0.7
const SLIDER_S := 1.3
const SLIDER_PATH := [Vector2(-70, -80), Vector2(70, -80), Vector2(-70, 20), Vector2(70, 20)] # a little Z, like the pattern
const LANE := 1 # the demo notification's
const LANE_GAP := 52.0
const CARD := Vector2(40, 30)
const SWIPE_S := 0.3
const LABELS := {
	"en": {Move.CLICK: "click on time", Move.SLIDER: "hold + follow", Move.LANE: "press the key", Move.SWIPE_DOWN: "swipe down"},
	"fr": {Move.CLICK: "clique au bon moment", Move.SLIDER: "maintiens + suis", Move.LANE: "appuie sur la touche", Move.SWIPE_DOWN: "glisse vers le bas"},
}

var move := Move.CLICK
var _t := 0.0

func _init() -> void:
	top_level = true
	mouse_filter = MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t = fposmod(_t + delta, LOOPS[move])
	queue_redraw()

func _draw() -> void:
	var screen := get_viewport_rect().size
	var card := Rect2(Vector2(screen.x - SIZE.x - MARGIN, TOP), SIZE)
	TutorialUi.box(self, card, BACKGROUND, 12)
	ModeDemo.text(self, LABELS[GameConfig.language][move], card.position + Vector2(card.size.x / 2, 28), 17, ModeDemo.ACCENT)
	draw_set_transform(card.get_center() + Vector2(0, 16), 0.0, Vector2.ONE * SCALE)
	match move:
		Move.CLICK: _draw_click()
		Move.SLIDER: _draw_slider()
		Move.LANE: _draw_lane()
		Move.SWIPE_DOWN: _draw_swipe_down()
	draw_set_transform(Vector2.ZERO)

func _lit() -> bool: return _t >= HIT_S and _t < HIT_S + ModeDemo.LIT_S

# the circle closes, the cursor glides over and clicks on time
func _draw_click() -> void:
	var at := Vector2(0, -50)
	ModeDemo.draw_target(self, at, HIT_S - _t)
	ModeDemo.draw_cursor(self, Vector2(-100, 40).lerp(at, ModeDemo._ease(clampf(_t / (HIT_S - 0.1), 0.0, 1.0))))
	_draw_click_options(_lit())

# the click key or the left mouse button, either works
func _draw_click_options(pressed: bool) -> void:
	ModeDemo.draw_key(self, Vector2(-70, 110), ModeDemo.key_label(AimClickMode.CLICKS[0]), pressed)
	ModeDemo.text(self, "or", Vector2(0, 116), 16, ModeDemo.DIM)
	ModeDemo.draw_mouse(self, Vector2(70, 110), pressed, false)

# grab the start as it closes, then follow the ball along the path with the click key or the mouse button held
func _draw_slider() -> void:
	var path := PackedVector2Array(SLIDER_PATH)
	var progress := clampf((_t - SLIDER_GRAB_S) / SLIDER_S, 0.0, 1.0)
	var holding := _t >= SLIDER_GRAB_S and _t < SLIDER_GRAB_S + SLIDER_S
	draw_polyline(path, Color(1, 1, 1, 0.15), 14, true)
	var ball := _along(path, progress)
	if progress > 0.0: draw_polyline(_traced(path, progress, ball), Color(ModeDemo.LANE_COLORS[1], 0.9), 10, true)
	if _t < SLIDER_GRAB_S + 0.1: ModeDemo.draw_target(self, path[0], SLIDER_GRAB_S - _t)
	if holding: draw_arc(ball, ModeDemo.CIRCLE_RADIUS * 1.4, 0, TAU, 40, Color(1, 1, 1, 0.6), 3, true)
	var cursor := Vector2(-110, 60).lerp(path[0], ModeDemo._ease(clampf(_t / SLIDER_GRAB_S, 0.0, 1.0))) if _t < SLIDER_GRAB_S else ball
	ModeDemo.draw_cursor(self, cursor)
	_draw_click_options(holding)

# a notification falls down its lane and its key lights up as it hits the line
func _draw_lane() -> void:
	var line_y := 40.0
	var top := -120.0
	for i in FourDMode.LANES.size():
		var x := (i - 1.5) * LANE_GAP
		draw_rect(Rect2(x - LANE_GAP / 2 + 3, top, LANE_GAP - 6, line_y - top + 20), Color(ModeDemo.LANE_COLORS[i], 0.1))
		ModeDemo.draw_key(self, Vector2(x, 110), ModeDemo.key_label(FourDMode.LANES[i]), _lit() and i == LANE)
	draw_line(Vector2(-2 * LANE_GAP, line_y), Vector2(2 * LANE_GAP, line_y), Color.WHITE, 3, true)
	var x := (LANE - 1.5) * LANE_GAP
	if _t < HIT_S: _draw_card(Vector2(x, lerpf(top + CARD.y, line_y, _t / HIT_S)), 1.0)
	elif _t < HIT_S + 0.4: # flung away like the real ones
		var fling := (_t - HIT_S) / 0.4
		_draw_card(Vector2(x + 140 * fling * fling, line_y), 1.0 - fling)

func _draw_card(center: Vector2, alpha: float) -> void:
	TutorialUi.box(self, Rect2(center - CARD / 2, CARD), Color(1, 1, 1, alpha), 6)
	draw_circle(center + Vector2(-9, -4), 5, Color(ModeDemo.LANE_COLORS[LANE], alpha), true, -1, true)
	draw_line(center + Vector2(0, -4), center + Vector2(13, -4), Color(TutorialUi.MUTED, alpha), 3)

# the circle closes and the cursor swipes down through it on time
func _draw_swipe_down() -> void:
	var at := Vector2(0, -20)
	ModeDemo.draw_target(self, at, HIT_S - _t)
	_draw_chevron(at, Color.WHITE)
	var swipe := clampf((_t - (HIT_S - SWIPE_S / 2)) / SWIPE_S, 0.0, 1.0)
	var from := at - Vector2(0, 110)
	var to := at + Vector2(0, 110)
	if swipe > 0.0 and swipe < 1.0: draw_line(from, from.lerp(to, swipe), Color(ModeDemo.ACCENT, 0.7), 5, true)
	ModeDemo.draw_cursor(self, from.lerp(to, swipe))
	for i in 2: _draw_chevron(Vector2(110, -40 + i * 30), Color(ModeDemo.ACCENT if _lit() else ModeDemo.DIM))

func _draw_chevron(center: Vector2, color: Color) -> void:
	draw_polyline(PackedVector2Array([center + Vector2(-14, -7), center + Vector2(0, 7), center + Vector2(14, -7)]), color, 5, true)

static func _along(path: PackedVector2Array, progress: float) -> Vector2:
	var total := 0.0
	for i in path.size() - 1: total += path[i].distance_to(path[i + 1])
	var left := progress * total
	for i in path.size() - 1:
		var step := path[i].distance_to(path[i + 1])
		if left <= step: return path[i].lerp(path[i + 1], left / step)
		left -= step
	return path[path.size() - 1]

static func _traced(path: PackedVector2Array, progress: float, ball: Vector2) -> PackedVector2Array:
	var traced := PackedVector2Array([path[0]])
	var total := 0.0
	for i in path.size() - 1: total += path[i].distance_to(path[i + 1])
	var walked := 0.0
	for i in path.size() - 1:
		walked += path[i].distance_to(path[i + 1])
		if walked > progress * total: break
		traced.append(path[i + 1])
	traced.append(ball)
	return traced
