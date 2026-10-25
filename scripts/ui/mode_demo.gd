class_name ModeDemo
extends Control

# the card shown while the game holds before a mode switch: one note of the coming mode played on a loop, with the player's own keys

const CARD := Vector2(460, 350)
const LOOP_S := 1.6
const HIT_S := 0.9 # when in the loop the demo note is hit
const APPROACH_S := 0.8
const CIRCLE_RADIUS := 34.0
const KEY_SIZE := Vector2(46, 40)
const LIT_S := 0.18
const BACKGROUND := Color(0.05, 0.05, 0.08)
const SHADE := Color(0, 0, 0, 0.55) # over the frozen game behind the card
const ACCENT := Color(1.0, 0.85, 0.2)
const DIM := Color(1, 1, 1, 0.35)
const LANE_COLORS: Array[Color] = [Color(0.55, 0.4, 1.0), Color(0.35, 0.65, 1.0), Color(0.35, 0.9, 0.6), Color(1.0, 0.45, 0.45)]

var hitsound: AudioStream

var _kind := Modality.Kind.AIM_CLICK
var _footer := ""
var _t := 0.0
var _sounds: AudioStreamPlayer

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = PROCESS_MODE_ALWAYS
	_sounds = AudioStreamPlayer.new()
	_sounds.stream = AudioStreamPolyphonic.new()
	add_child(_sounds)
	hide()

func play(kind: Modality.Kind) -> void:
	_kind = kind
	_t = 0.0
	if not _sounds.playing: _sounds.play()
	show()

func set_footer(footer: String) -> void: _footer = footer

func _process(delta: float) -> void:
	if not visible: return
	var before := _t
	_t = fposmod(_t + delta, LOOP_S)
	if hitsound != null and before < HIT_S and (_t >= HIT_S or _t < before): (_sounds.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(hitsound)
	queue_redraw()

func _draw() -> void:
	var center := size / 2
	var card := Rect2(center - CARD / 2, CARD)
	draw_rect(Rect2(Vector2.ZERO, size), SHADE)
	draw_rect(card, BACKGROUND)
	draw_rect(card, Color(ACCENT, 0.6), false, 3)
	var font := ThemeDB.fallback_font
	_text(font, "next up", Vector2(center.x, card.position.y + 34), 18, DIM)
	_text(font, _title(), Vector2(center.x, card.position.y + 66), 28, Color.WHITE)
	var stage := center + Vector2(0, 15)
	var lit := _t >= HIT_S and _t < HIT_S + LIT_S
	match _kind:
		Modality.Kind.AIM_CLICK: _draw_click(stage, lit)
		Modality.Kind.FOUR_D: _draw_lanes(stage, lit)
		Modality.Kind.SLASH: _draw_slash(stage, lit)
	_text(font, _footer, Vector2(center.x, card.end.y - 18), 18, DIM)

func _title() -> String:
	match _kind:
		Modality.Kind.AIM_CLICK: return "aim + click"
		Modality.Kind.FOUR_D: return "keys"
		Modality.Kind.SLASH: return "aim + slash"
	return ""

# a circle closing in, the cursor gliding over and clicking on time, the click keys and the mouse lighting up
func _draw_click(stage: Vector2, lit: bool) -> void:
	var at := stage + Vector2(70, -25)
	_draw_target(at)
	var from := stage + Vector2(-110, 15)
	_draw_cursor(from.lerp(at, _ease(clampf(_t / (HIT_S - 0.1), 0.0, 1.0))))
	var row := stage + Vector2(0, 85)
	_draw_key(row + Vector2(-110, 0), key_label(AimClickMode.CLICKS[0]), lit)
	_draw_key(row + Vector2(-56, 0), key_label(AimClickMode.CLICKS[1]), false)
	_text(ThemeDB.fallback_font, "or", row + Vector2(4, 6), 16, DIM)
	_draw_mouse(row + Vector2(64, 0), lit, false)

# a note falling into its lane, its key lighting up as it lands
func _draw_lanes(stage: Vector2, lit: bool) -> void:
	var lane := 1
	var top := stage.y - 75
	var receptor_y := stage.y + 22
	for i in FourDMode.LANES.size():
		var x := stage.x + (i - 1.5) * 64
		draw_rect(Rect2(x - 26, top, 52, receptor_y + 26 - top), Color(LANE_COLORS[i], 0.12))
		draw_circle(Vector2(x, receptor_y), 22, Color(LANE_COLORS[i], 0.8 if lit and i == lane else 0.25), true, -1, true)
		_draw_key(Vector2(x, stage.y + 85), key_label(FourDMode.LANES[i]), lit and i == lane)
	var falling := clampf(_t / HIT_S, 0.0, 1.0)
	if _t < HIT_S: draw_circle(Vector2(stage.x + (lane - 1.5) * 64, lerpf(top + 20, receptor_y, falling)), 20, LANE_COLORS[lane], true, -1, true)

# a circle closing in and the cursor swiping across it on time
func _draw_slash(stage: Vector2, lit: bool) -> void:
	var at := stage + Vector2(0, -25)
	_draw_target(at)
	var swipe := clampf((_t - (HIT_S - 0.15)) / 0.3, 0.0, 1.0)
	var from := at + Vector2(-140, 30)
	var to := at + Vector2(140, -30)
	if swipe > 0.0 and swipe < 1.0: draw_line(from, from.lerp(to, swipe), Color(ACCENT, 0.7), 4, true)
	_draw_cursor(from.lerp(to, swipe))
	_draw_mouse(stage + Vector2(0, 85), false, true, lit)

func _draw_target(at: Vector2) -> void: draw_target(self, at, HIT_S - _t)

# a circle with its approach ring, `until` its hit (negative after, it fades out)
static func draw_target(item: CanvasItem, at: Vector2, until: float) -> void:
	if until < -LIT_S: return
	var alpha := clampf(1.0 - (until - APPROACH_S) / 0.2, 0.0, 1.0) if until > 0.0 else 1.0 + until / LIT_S
	item.draw_circle(at, CIRCLE_RADIUS, Color(LANE_COLORS[1], 0.8 * alpha), true, -1, true)
	item.draw_arc(at, CIRCLE_RADIUS, 0, TAU, 48, Color(1, 1, 1, alpha), 4, true)
	if until > 0.0 and until < APPROACH_S:
		var ring := CIRCLE_RADIUS * (1.0 + 2.0 * until / APPROACH_S)
		item.draw_arc(at, ring, 0, TAU, 48, Color(0, 0, 0, 0.5 * alpha), 7, true)
		item.draw_arc(at, ring, 0, TAU, 48, Color(1, 1, 1, alpha), 3, true)

func _draw_cursor(at: Vector2) -> void: draw_cursor(self, at)

static func draw_cursor(item: CanvasItem, at: Vector2) -> void:
	item.draw_circle(at, 9, Color(0.4, 0.9, 1.0), true, -1, true)
	item.draw_arc(at, 9, 0, TAU, 24, Color.WHITE, 2, true)

func _draw_key(at: Vector2, label: String, lit: bool) -> void: draw_key(self, at, label, lit)

static func draw_key(item: CanvasItem, at: Vector2, label: String, lit: bool) -> void:
	var rect := Rect2(at - KEY_SIZE / 2, KEY_SIZE)
	item.draw_rect(rect, Color(ACCENT, 0.9) if lit else Color(1, 1, 1, 0.1))
	item.draw_rect(rect, Color.WHITE if lit else DIM, false, 2)
	text(item, label, at + Vector2(0, 7), 20, Color.BLACK if lit else Color.WHITE)

func _draw_mouse(at: Vector2, click: bool, swipe: bool, lit := false) -> void: draw_mouse(self, at, click, swipe, lit)

# a mouse, its left button lit on a click or arrows either side for a swipe
static func draw_mouse(item: CanvasItem, at: Vector2, click: bool, swipe: bool, lit := false) -> void:
	var body := Rect2(at - Vector2(18, 24), Vector2(36, 48))
	item.draw_rect(body, Color(1, 1, 1, 0.1))
	item.draw_rect(body, DIM, false, 2)
	item.draw_line(at - Vector2(0, 24), at - Vector2(0, 6), DIM, 2)
	item.draw_line(at - Vector2(18, 6), at + Vector2(18, -6), DIM, 2)
	if click: item.draw_rect(Rect2(at - Vector2(17, 23), Vector2(17, 17)), Color(ACCENT, 0.9))
	if not swipe: return
	var color := ACCENT if lit else DIM
	for side in [-1, 1]:
		var tip := at + Vector2(side * 46, 0)
		item.draw_line(at + Vector2(side * 26, 0), tip, color, 3, true)
		item.draw_colored_polygon(PackedVector2Array([tip + Vector2(side * 8, 0), tip + Vector2(0, -7), tip + Vector2(0, 7)]), color)

func _text(_font: Font, string: String, at: Vector2, font_size: int, color: Color) -> void: text(self, string, at, font_size, color)

# centred on `at`'s x, `at` is the baseline
static func text(item: CanvasItem, string: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	item.draw_string(font, at - Vector2(width / 2, 0), string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

static func key_label(action: StringName) -> String:
	for event: InputEvent in GameConfig.keybinds[action]:
		if event is InputEventKey: return OS.get_keycode_string(event.physical_keycode)
	return "?"

static func _ease(t: float) -> float: return 1.0 - pow(1.0 - t, 3.0)
