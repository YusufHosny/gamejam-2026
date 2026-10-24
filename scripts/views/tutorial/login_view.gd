class_name LoginView
extends CircleAimView

const USERNAME := Vector2(576, 270)
const PASSWORD := Vector2(576, 350)
const SIGN_IN := Vector2(576, 440)
const PANEL := Rect2(336, 140, 480, 380)
const FIELD_SIZE := Vector2(360, 48)
const CREDENTIALS: Array[String] = ["player@jamjar.io", "••••••••••"]

@export var page: Texture2D
@export var hint := "Click the circle when the approach circle hits it"

var _filled := 0 # username, password, then sign in

func _ready() -> void:
	super()
	mode.judged.connect(func(_r: HitResult): _filled += 1)

func _draw() -> void:
	_draw_page()
	if _filled >= 3: _draw_two_factor()
	else: super()
	TutorialUi.hint(self, hint)

func _draw_page() -> void:
	if page != null: draw_texture_rect(page, PANEL, false)
	else: TutorialUi.box(self, PANEL, TutorialUi.SCREEN_COLOR, 12)
	TutorialUi.label(self, PANEL.position + Vector2(PANEL.size.x / 2, 48), "forgot your password?", 28)
	TutorialUi.label(self, PANEL.position + Vector2(PANEL.size.x / 2, 82), "we filled it in for you, just click", 16, TutorialUi.MUTED)
	for i in CREDENTIALS.size():
		var center: Vector2 = [USERNAME, PASSWORD][i]
		TutorialUi.box(self, Rect2(center - FIELD_SIZE / 2, FIELD_SIZE), Color.WHITE, 6)
		var text: String = CREDENTIALS[i] if _filled > i else ["email", "password"][i]
		TutorialUi.label(self, center, text, 20, TutorialUi.INK if _filled > i else TutorialUi.MUTED)
	TutorialUi.box(self, Rect2(SIGN_IN - FIELD_SIZE / 2, FIELD_SIZE), Color(0.18, 0.44, 0.87), 6)
	TutorialUi.label(self, SIGN_IN, "sign in", 22, Color.WHITE)

func _draw_two_factor() -> void:
	var modal := Rect2(PANEL.position + Vector2(40, 110), Vector2(PANEL.size.x - 80, 160))
	TutorialUi.box(self, modal, Color(0.1, 0.11, 0.14), 12)
	TutorialUi.label(self, modal.get_center() - Vector2(0, 24), "two-factor check", 26, Color.WHITE)
	TutorialUi.label(self, modal.get_center() + Vector2(0, 20), "we sent a code to your email", 18, Color(1, 1, 1, 0.7))
