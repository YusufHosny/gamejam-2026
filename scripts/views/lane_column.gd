class_name LaneColumn
extends RefCounted

# four falling lanes left of a centred minigame, shared by the boxed 4d views

const CENTER_X := 205.0
const WIDTH := 62.0
const TOP := 100.0 # below the score
const HIT_Y := 480.0
const PANEL := Color(0.11, 0.13, 0.19, 0.92)
const KEY := Color(0.55, 0.58, 0.66)
const COLORS: Array[Color] = [Color(0.69, 0.29, 0.88), Color(0.18, 0.56, 0.88), Color(0.18, 0.72, 0.42), Color(0.88, 0.28, 0.28)]
const FLASH_MS := 150.0

static func x(lane: int) -> float: return CENTER_X + (lane - 1.5) * WIDTH

static func y(note: LaneNote, now: float) -> float: return HIT_Y - (note.time - now) * GameConfig.scroll_speed

static func receptor(lane: int) -> Vector2: return Vector2(x(lane), HIT_Y)

# how lit a receptor is: a flash after a hit, dimmer while its key is held
static func lit(lane: int, hit_ms: int) -> float:
	var flash := clampf(1.0 - (Time.get_ticks_msec() - hit_ms) / FLASH_MS, 0.0, 1.0)
	return maxf(flash, 0.35) if Input.is_action_pressed(FourDMode.LANES[lane]) else flash

static func draw_panel(item: CanvasItem) -> void:
	TutorialUi.box(item, Rect2(x(0) - WIDTH / 2 - 8, TOP, WIDTH * 4 + 16, HIT_Y + 64 - TOP), PANEL, 10)

static func draw_key(item: CanvasItem, lane: int) -> void:
	var event: InputEvent = GameConfig.keybinds[FourDMode.LANES[lane]][0]
	TutorialUi.label(item, receptor(lane) + Vector2(0, 38), OS.get_keycode_string(event.physical_keycode) if event is InputEventKey else "?", 14, KEY)
