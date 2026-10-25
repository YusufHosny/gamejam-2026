class_name NotificationsView
extends ModeView

const LANE_WIDTH := 63.0
const CARD_SIZE := Vector2(54, 44)
const HIT_LINE_MARGIN := 70.0 # above the bottom of the screen
const FLING_S := 0.35
const FLING_DISTANCE := 360.0
const APP_COLORS: Array[Color] = [Color(0.9, 0.3, 0.3), Color(0.3, 0.6, 0.95), Color(0.35, 0.8, 0.45), Color(0.95, 0.7, 0.25)]

@export var phone: Texture2D
const HINT := &"tutorial_3" # the voice line, its text is the hint

class Fling:
	var lane: int
	var born_ms: int

	func _init(_lane: int, _born_ms: int) -> void:
		lane = _lane
		born_ms = _born_ms

var _flings: Array[Fling] = []

func _ready() -> void:
	mode.judged.connect(_on_judged)
	var voice := VoiceTrack.new()
	add_child(voice)
	voice.say(HINT, false)
	var guide := InputGuide.new()
	guide.move = InputGuide.Move.LANE
	add_child(guide)

func _on_judged(result: HitResult) -> void:
	if not result.is_miss(): _flings.append(Fling.new((result.note as LaneNote).lane, Time.get_ticks_msec()))

func _draw() -> void:
	var now := _now()
	var screen := TutorialUi.SCREEN
	var hit_y := screen.end.y - HIT_LINE_MARGIN
	TutorialUi.phone(self, phone)
	draw_screen(self)
	for lane in FourDMode.LANES.size():
		var x := _lane_x(lane)
		if Input.is_action_pressed(FourDMode.LANES[lane]):
			TutorialUi.box(self, Rect2(x - LANE_WIDTH / 2 + 2, screen.position.y + 44, LANE_WIDTH - 4, hit_y - screen.position.y - 44), Color(0, 0, 0, 0.06), 6)
	for note: LaneNote in mode.pending():
		var y := hit_y - (note.time - now) * GameConfig.scroll_speed
		if y < screen.position.y + 44 + CARD_SIZE.y / 2: break
		_draw_card(Vector2(_lane_x(note.lane), y), note.lane, 1.0)
	var ms := Time.get_ticks_msec()
	_flings.assign(_flings.filter(func(f: Fling): return ms - f.born_ms < FLING_S * 1000))
	for fling in _flings:
		var t := (ms - fling.born_ms) / (FLING_S * 1000)
		_draw_card(Vector2(_lane_x(fling.lane) + FLING_DISTANCE * t * t, hit_y), fling.lane, 1.0 - t)
	TutorialUi.hint(self, VoiceLines.text(HINT))

# the screen without its notifications, the email cutscene starts on it
static func draw_screen(item: CanvasItem, alpha := 1.0) -> void:
	var screen := TutorialUi.SCREEN
	var hit_y := screen.end.y - HIT_LINE_MARGIN
	TutorialUi.label(item, screen.position + Vector2(screen.size.x / 2, 28), "notifications", 18, Color(TutorialUi.MUTED, alpha))
	item.draw_line(Vector2(screen.position.x + 8, hit_y), Vector2(screen.end.x - 8, hit_y), Color(TutorialUi.INK, alpha), 3, true)
	for lane in FourDMode.LANES.size():
		TutorialUi.label(item, Vector2(_lane_x(lane), hit_y + 30), _key_label(FourDMode.LANES[lane]), 18, Color(TutorialUi.MUTED, alpha))

func _draw_card(center: Vector2, lane: int, alpha: float) -> void:
	TutorialUi.box(self, Rect2(center - CARD_SIZE / 2, CARD_SIZE), Color(1, 1, 1, alpha), 8)
	draw_circle(center + Vector2(-12, -8), 7, Color(APP_COLORS[lane], alpha), true, -1, true)
	draw_line(center + Vector2(0, -8), center + Vector2(18, -8), Color(TutorialUi.MUTED, alpha), 3)
	draw_line(center + Vector2(-18, 8), center + Vector2(18, 8), Color(TutorialUi.MUTED, 0.5 * alpha), 3)

static func _lane_x(lane: int) -> float:
	return TutorialUi.SCREEN.get_center().x + (lane - 1.5) * LANE_WIDTH

static func _key_label(action: StringName) -> String:
	var event: InputEvent = GameConfig.keybinds[action][0]
	return OS.get_keycode_string(event.physical_keycode) if event is InputEventKey else "?"
