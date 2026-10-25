class_name EmailRefreshView
extends CircleAimView

# the mail app the email cutscene opens: each downward slash pulls the inbox to refresh, the last one brings in the code

const REFRESH := Vector2(576, 360) # over the inbox
const CODE := "482 913"
const SPIN_S := 0.7
const SPINNER_FROM := Vector2(192, 70) # in the mail images' pixels, it's pulled down from under the header
const SPINNER_TO := Vector2(192, 150) # to where the compose button was
const SPINNER_SIZE := 44.0
const SPINNER_FRAME := Vector2(32, 32) # loading.png is 2x2 of these
const SPINNER_FPS := 12.0
const ARROW := 16.0 # the down chevron in each circle
const GUIDE_ARROWS := 3 # chevrons under the next circle, rippling down
const GUIDE_GAP := 26.0
const GUIDE_FROM := 70.0 # below the circle's centre
const GUIDE_CYCLE_S := 0.9

@export var phone: Texture2D
@export var inbox_empty: Texture2D
@export var inbox_one: Texture2D
@export var spinner: Texture2D
const HINT := &"tutorial_4" # the voice line, its text is the hint

var _refreshes := 0
var _refreshed_ms := -100000

func _ready() -> void:
	super()
	mode.judged.connect(_on_judged)
	var voice := VoiceTrack.new()
	add_child(voice)
	voice.say(HINT, false)
	var guide := InputGuide.new()
	guide.move = InputGuide.Move.SWIPE_DOWN
	add_child(guide)

func _on_judged(_result: HitResult) -> void:
	_refreshes += 1
	_refreshed_ms = Time.get_ticks_msec()

func _draw() -> void:
	TutorialUi.phone(self, phone)
	var since := (Time.get_ticks_msec() - _refreshed_ms) / 1000.0
	var arrived := _refreshes >= mode.segment.notes.size() and since >= SPIN_S
	TutorialUi.mail(self, inbox_one if arrived else inbox_empty)
	if since < SPIN_S and spinner != null: _draw_spinner(since)
	if arrived: draw_code(self)
	super()
	TutorialUi.hint(self, VoiceLines.text(HINT))

func slash_direction(_note: AimNote) -> Vector2: return Vector2.DOWN

# pulled down from under the header as it spins, fading out at the end
func _draw_spinner(since: float) -> void:
	var t := since / SPIN_S
	var frame := floori(since * SPINNER_FPS) % 4
	var region := Rect2(Vector2(frame % 2, frame / 2) * SPINNER_FRAME, SPINNER_FRAME)
	var at := TutorialUi.mail_point(SPINNER_FROM.lerp(SPINNER_TO, 1.0 - pow(1.0 - minf(t * 1.6, 1.0), 3.0)))
	var alpha := clampf((1.0 - t) * 4.0, 0.0, 1.0)
	draw_texture_rect_region(spinner, Rect2(at - Vector2.ONE * SPINNER_SIZE / 2, Vector2.ONE * SPINNER_SIZE), region, Color(1, 1, 1, alpha))

# a down chevron instead of a combo number
func _draw_label(note: AimNote, alpha: float) -> void:
	_draw_chevron(note.position, ARROW, Color(Color.WHITE, alpha), 6)
	if note == mode.pending()[0]: _draw_guide(note.position, alpha)

# chevrons under the next circle lighting up one after another, downwards
func _draw_guide(from: Vector2, alpha: float) -> void:
	var phase := fmod(Time.get_ticks_msec() / 1000.0, GUIDE_CYCLE_S) / GUIDE_CYCLE_S
	for i in GUIDE_ARROWS:
		var lit := 1.0 - clampf(absf(phase * GUIDE_ARROWS - i - 0.5), 0.0, 1.0)
		_draw_chevron(from + Vector2(0, GUIDE_FROM + i * GUIDE_GAP), 12.0, Color(color, alpha * (0.35 + 0.65 * lit)), 5)

func _draw_chevron(center: Vector2, size: float, tint: Color, width: float) -> void:
	var side := Vector2(size * 0.8, 0)
	var tip := center + Vector2(0, size * 0.5)
	var back := center - Vector2(0, size * 0.5)
	draw_polyline(PackedVector2Array([back - side, tip, back + side]), tint, width, true)

# the new message's card, from security with the code. the sign in cutscene fades out from it
static func draw_code(item: CanvasItem) -> void:
	var row := TutorialUi.MAIL_ROW
	var left := TutorialUi.mail_point(row.position + Vector2(62, 0)).x # clear of the avatar
	var top := TutorialUi.mail_point(row.position).y
	var bottom := TutorialUi.mail_point(row.end).y
	var font := ThemeDB.fallback_font
	item.draw_string(font, Vector2(left, top + (bottom - top) * 0.38), "game_jam security", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TutorialUi.MUTED)
	item.draw_string(font, Vector2(left, top + (bottom - top) * 0.78), "code: %s" % CODE, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, TutorialUi.INK)
