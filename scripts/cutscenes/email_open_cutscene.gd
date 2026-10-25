class_name EmailOpenCutscene
extends Cutscene

# picks up on the emptied notification screen: it's swiped closed, the mail app is tapped and opens onto the inbox
# the refresh map starts on

const LENGTH_S := 3.0
const CLOSE_AT := 0.4
const CLOSE_S := 0.45 # the notification screen rolls up
const TAP_AT := 1.5 # the cursor becomes a tapping hand
const OPEN_AT := 1.9
const OPEN_S := 0.45 # the inbox grows out of the icon
const HOME_WIDTH := 180.0 # the Go to email images across the screen, narrow enough to stay inside it
const ICON_LIFT := 40.0 # the envelope sits this far above the screen's centre
const HOME_SIZE := Vector2(1187, 1253) # Go to email.png
const ENVELOPE := Vector2(375, 366) # its centre, in the image's pixels

@export var home: Texture2D # Go to email.png
@export var home_tap: Texture2D # Go to email 2.png
@export var inbox: Texture2D # mail interface empty.png, the refresh map's first screen

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	var screen := TutorialUi.SCREEN
	TutorialUi.phone(self)
	TutorialUi.box(self, screen, Color.WHITE, 10)
	var picture := home_tap if time >= TAP_AT else home
	if picture != null: draw_texture_rect(picture, _home_rect(), false)
	var close := smoothstep(0.0, 1.0, clampf((time - CLOSE_AT) / CLOSE_S, 0.0, 1.0))
	if close < 1.0: _draw_notifications(close)
	if time >= OPEN_AT:
		var open := clampf((time - OPEN_AT) / OPEN_S, 0.0, 1.0)
		var grow := lerpf(0.12, 1.0, 1.0 - pow(1.0 - open, 3.0))
		TutorialUi.mail(self, inbox, grow, _envelope())

# rolls up from the bottom, its contents fade first
func _draw_notifications(close: float) -> void:
	var screen := TutorialUi.SCREEN
	TutorialUi.box(self, Rect2(screen.position, Vector2(screen.size.x, screen.size.y * (1.0 - close))), TutorialUi.SCREEN_COLOR, 10)
	var alpha := 1.0 - clampf(close * 4.0, 0.0, 1.0)
	if alpha > 0.0: NotificationsView.draw_screen(self, alpha)

# placed by the envelope, which is off in the image's top left
func _home_rect() -> Rect2:
	var size := HOME_SIZE * HOME_WIDTH / HOME_SIZE.x
	var envelope := TutorialUi.SCREEN.get_center() - Vector2(0, ICON_LIFT)
	return Rect2(envelope - ENVELOPE * size / HOME_SIZE, size)

func _envelope() -> Vector2:
	var rect := _home_rect()
	return rect.position + ENVELOPE * rect.size / HOME_SIZE
