class_name PasswordView
extends ModeView

# b2: the backup password's letters fall down the lanes, each hit types one into the uefi prompt

const PASSWORD := "ihatecaptchas"
const SCREEN_CENTER := Vector2(730, 330)
const SCREEN_HEIGHT := 420.0
const FIELD := Rect2(64, 174, 229, 16) # in uefi_password.png pixels
const OK_BUTTON := Rect2(337, 264, 55, 19)
const FIELD_CHARS := 22 # the field scrolls past this many
const TILE := 42.0
const BACKGROUND := Color(0.04, 0.05, 0.09)
const MISS := Color(0.9, 0.2, 0.2)

@export var screen: Texture2D

var _typed: Array[bool] = [] # per judged note, hit or miss
var _pressed_ms: Array[int] = [-100000, -100000, -100000, -100000]

static func letter(index: int) -> String: return PASSWORD[index % PASSWORD.length()]

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	mode.judged.connect(_on_judged)

func _on_judged(result: HitResult) -> void:
	_typed.append(not result.is_miss())
	if not result.is_miss(): _pressed_ms[(result.note as LaneNote).lane] = Time.get_ticks_msec()

func _draw() -> void:
	var now := _now()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BACKGROUND)
	var screen_rect := _screen_rect()
	draw_texture_rect(screen, screen_rect, false)
	_draw_field(screen_rect)
	if mode.pending().is_empty(): draw_rect(_on_screen(OK_BUTTON, screen_rect).grow(3), Color(1, 1, 1, 0.9), false, 3)
	_draw_lanes(now)

func _screen_rect() -> Rect2:
	var size := screen.get_size() * SCREEN_HEIGHT / screen.get_height()
	return Rect2(SCREEN_CENTER - size / 2, size)

func _on_screen(source: Rect2, screen_rect: Rect2) -> Rect2:
	var scale := screen_rect.size.y / screen.get_height()
	return Rect2(screen_rect.position + source.position * scale, source.size * scale)

# a dot per typed letter, a red cross per miss
func _draw_field(screen_rect: Rect2) -> void:
	var field := _on_screen(FIELD, screen_rect)
	var font := ThemeDB.fallback_font
	var size := int(field.size.y * 1.1)
	var x := field.position.x + 4
	for hit in _typed.slice(-FIELD_CHARS):
		draw_string(font, Vector2(x, field.end.y - 2), "•" if hit else "×", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.1, 0.1, 0.12) if hit else MISS)
		x += size * 0.6

func _draw_lanes(now: float) -> void:
	LaneColumn.draw_panel(self)
	TutorialUi.label(self, Vector2(LaneColumn.CENTER_X, LaneColumn.TOP + 22), "type your backup password", 14, LaneColumn.KEY)
	for lane in FourDMode.LANES.size():
		var at := LaneColumn.receptor(lane)
		var lit := LaneColumn.lit(lane, _pressed_ms[lane])
		TutorialUi.box(self, Rect2(at - Vector2.ONE * TILE / 2, Vector2.ONE * TILE), Color(LaneColumn.COLORS[lane], 0.15 + 0.6 * lit), 8)
		LaneColumn.draw_key(self, lane)
	var notes := mode.segment.notes
	for note: LaneNote in mode.pending():
		var y := LaneColumn.y(note, now)
		if y < LaneColumn.TOP + 48: break
		var at := Vector2(LaneColumn.x(note.lane), y)
		TutorialUi.box(self, Rect2(at - Vector2.ONE * TILE / 2, Vector2.ONE * TILE), LaneColumn.COLORS[note.lane], 8)
		TutorialUi.label(self, at, letter(notes.find(note)), 24, Color.WHITE)
