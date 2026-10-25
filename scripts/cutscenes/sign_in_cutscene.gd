class_name SignInCutscene
extends Cutscene

# back on the desktop with the code from the email: it's typed in, signed in, but there's a captcha first, the
# dog one from c1. then the player notices the time, the tutorial's done, and it fades to the countdown's background.
# it opens on the email map's last frame, the Phone layer, and fades that out onto the desktop

const CROSSFADE_S := 2.0
const WAIT_S := 1.0 # a beat on the desktop before the code goes in
const TYPE_AT := CROSSFADE_S + WAIT_S
const SUBMIT_AT := TYPE_AT + 1.8 # the code's in, a second later the cursor goes for verify. the rest counts from here
const LENGTH_S := SUBMIT_AT + 17.0
const CODE := EmailRefreshView.CODE
const TYPE_STEP_S := 0.15 # per character
const CURSOR_REST := Vector2(820, 560)
const CURSOR_SIZE := 48.0
const TO_VERIFY_AT := SUBMIT_AT
const TO_VERIFY_S := 0.6
const VERIFY_CLICK := SUBMIT_AT + 0.7
const CLICK_S := 0.1
const AWAY_AT := SUBMIT_AT + 1.1 # then out of the way of the text and the captcha
const AWAY_S := 0.6
const CURSOR_AWAY := Vector2(900, 430)
const SIGNED_IN_AT := SUBMIT_AT + 0.9
const ONE_MORE_AT := SUBMIT_AT + 2.1
const CAPTCHA_AT := SUBMIT_AT + 5.4 # once "let's see..." is said
const POP_S := 0.15
const CLOCK_AT := SUBMIT_AT + 7.9 # the taskbar clock catches their eye
const CLOCK := "23:55"
const DARK_AT := SUBMIT_AT + 13.2 # into the countdown's background
const DARK_S := 0.6
const COMPLETE_AT := SUBMIT_AT + 13.8
const STARTS_AT := SUBMIT_AT + 14.4
const TEXT_OUT_AT := SUBMIT_AT + 16.5
const DARK := Color(0.08, 0.08, 0.1) # CountdownCutscene's background
const SUCCESS := Color(0.3, 0.85, 0.45)
# the player's voice lines, VoiceLines ids
const VOICE := [[SIGNED_IN_AT, &"sign_in_1"], [CAPTCHA_AT + 0.2, &"seriously"], [CLOCK_AT + 0.2, &"sign_in_2"]]

@export var page: Texture2D # login page.png
@export var inbox: Texture2D # mail interface one.png, how the email map leaves the phone

@onready var _phone: Node2D = $Phone
@export var cursor: Texture2D
@export var cursor_click: Texture2D

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	_phone.draw.connect(_draw_phone)

func voice_cues() -> Array: return VOICE

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()
	_phone.modulate.a = 1.0 - clampf(time / CROSSFADE_S, 0.0, 1.0)
	_phone.visible = _phone.modulate.a > 0.0

func _draw_phone() -> void:
	TutorialUi.phone(_phone)
	TutorialUi.mail(_phone, inbox)
	EmailRefreshView.draw_code(_phone)

func _draw() -> void:
	Desktop.draw(self)
	if time >= CLOCK_AT: _draw_clock()
	LoginView.draw_window(self, func(): LoginView.draw_filled_page(self, page))
	_draw_modal()
	if time >= CAPTCHA_AT: _draw_captcha()
	if time < DARK_AT and cursor != null: _draw_cursor()
	var dark := clampf((time - DARK_AT) / DARK_S, 0.0, 1.0)
	if dark > 0.0: draw_rect(get_viewport_rect(), Color(DARK, dark))
	if time >= COMPLETE_AT: _draw_complete()

# the two-factor check, now with the code going in, then signed in
func _draw_modal() -> void:
	var modal := LoginView.two_factor_rect()
	TutorialUi.box(self, modal, Color(0.1, 0.11, 0.14), 12)
	var center := modal.get_center()
	if time >= SIGNED_IN_AT:
		var pop := 0.6 + 0.4 * clampf((time - SIGNED_IN_AT) / POP_S, 0.0, 1.0)
		TutorialUi.label(self, center - Vector2(0, 34), "✓ Signed in successfully!", roundi(26 * pop), SUCCESS)
		if time >= ONE_MORE_AT:
			TutorialUi.label(self, center + Vector2(0, 10), "One more step:", 18, Color.WHITE)
			TutorialUi.label(self, center + Vector2(0, 36), "complete the captcha to prove you're human", 16, Color(1, 1, 1, 0.75))
		return
	TutorialUi.label(self, center - Vector2(0, 52), "two-factor check", 22, Color.WHITE)
	var field := Rect2(center + Vector2(-150, -26), Vector2(190, 44))
	TutorialUi.box(self, field, Color.WHITE, 6)
	var typed := CODE.left(clampi(floori((time - TYPE_AT) / TYPE_STEP_S) + 1, 0, CODE.length())) if time >= TYPE_AT else ""
	TutorialUi.label(self, field.get_center(), typed if typed != "" else "code", 22, TutorialUi.INK if typed != "" else TutorialUi.MUTED)
	var pressed := time >= VERIFY_CLICK and time < VERIFY_CLICK + CLICK_S
	TutorialUi.box(self, _verify_rect().grow(-3 if pressed else 0), Color(0.18, 0.44, 0.87), 6)
	TutorialUi.label(self, _verify_rect().get_center(), "verify", 20, Color.WHITE)

func _verify_rect() -> Rect2: return Rect2(LoginView.two_factor_rect().get_center() + Vector2(52, -26), Vector2(100, 44))

# the c1 captcha as it opens, popped in over the window
func _draw_captcha() -> void:
	var pop := 0.6 + 0.4 * clampf((time - CAPTCHA_AT) / POP_S, 0.0, 1.0)
	var center := CaptchaFrame.to_screen(Rect2(Vector2.ZERO, CaptchaFrame.SIZE)).get_center()
	draw_set_transform(center * (1.0 - pop), 0.0, Vector2.ONE * pop)
	CaptchaFrame.draw(self)
	CaptchaFrame.draw_header(self, "Select all images with", "dogs", "Click verify once there are none left.")
	var decoys := CaptchaImages.DECOYS
	for tile in 9: draw_texture_rect(decoys[tile % decoys.size()], DogCaptchaView.tile_rect(tile), false)
	draw_set_transform(Vector2.ZERO)

# the time in the taskbar's corner, flashing red once they've seen it
func _draw_clock() -> void:
	var screen := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var flash := fmod(time - CLOCK_AT, 0.5) < 0.25
	var width := font.get_string_size(CLOCK, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, Vector2(screen.x - width - 14, screen.y - 9), CLOCK, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.1, 0.1) if flash else Color(0.1, 0.1, 0.12))

func _draw_cursor() -> void:
	var tip := CURSOR_REST.lerp(_verify_rect().get_center(), smoothstep(0.0, 1.0, clampf((time - TO_VERIFY_AT) / TO_VERIFY_S, 0.0, 1.0)))
	tip = tip.lerp(CURSOR_AWAY, smoothstep(0.0, 1.0, clampf((time - AWAY_AT) / AWAY_S, 0.0, 1.0)))
	var clicking := time >= VERIFY_CLICK and time < VERIFY_CLICK + CLICK_S
	draw_texture_rect(cursor_click if clicking and cursor_click != null else cursor, Rect2(tip, Vector2.ONE * CURSOR_SIZE), false)

# on the countdown's background, gone again before it starts
func _draw_complete() -> void:
	var center := get_viewport_rect().get_center()
	var out := 1.0 - clampf((time - TEXT_OUT_AT) / (LENGTH_S - TEXT_OUT_AT), 0.0, 1.0)
	var pop := 0.6 + 0.4 * clampf((time - COMPLETE_AT) / POP_S, 0.0, 1.0)
	TutorialUi.label(self, center - Vector2(0, 30), "TUTORIAL COMPLETE", roundi(56 * pop), Color(SUCCESS, out))
	if time >= STARTS_AT: TutorialUi.label(self, center + Vector2(0, 34), "The real game starts now.", 26, Color(1, 1, 1, out * clampf((time - STARTS_AT) / 0.3, 0.0, 1.0)))
