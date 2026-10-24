class_name EmailRefreshView
extends CircleAimView

const REFRESH := Vector2(576, 250)
const CODE := "482 913"
const SPIN_S := 0.5

@export var phone: Texture2D
@export var hint := "Slash through the circle when the approach circle hits it"

var _refreshes := 0
var _refreshed_ms := -100000

func _ready() -> void:
	super()
	mode.judged.connect(_on_judged)

func _on_judged(_result: HitResult) -> void:
	_refreshes += 1
	_refreshed_ms = Time.get_ticks_msec()

func _draw() -> void:
	var screen := TutorialUi.SCREEN
	TutorialUi.phone(self, phone)
	TutorialUi.label(self, screen.position + Vector2(screen.size.x / 2, 28), "inbox", 22)
	var row := Rect2(screen.position + Vector2(12, 200), Vector2(screen.size.x - 24, 70))
	if _refreshes >= mode.segment.notes.size():
		TutorialUi.box(self, row, Color(0.86, 0.93, 1.0), 8)
		TutorialUi.label(self, row.get_center() - Vector2(0, 14), "jamjar security", 16, TutorialUi.MUTED)
		TutorialUi.label(self, row.get_center() + Vector2(0, 14), "your code: %s" % CODE, 22)
	else:
		var spinning := Time.get_ticks_msec() - _refreshed_ms < SPIN_S * 1000
		TutorialUi.label(self, row.get_center(), "checking..." if spinning else "no new mail", 18, TutorialUi.MUTED)
	super()
	TutorialUi.hint(self, hint)
