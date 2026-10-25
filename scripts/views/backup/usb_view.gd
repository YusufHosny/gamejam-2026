class_name UsbView
extends CircleAimView

# b1: short sliders and singles round the port, each note plays the usb's next phase

enum Move { PUSH, BUMP, FLIP, FLIP_BACK }

const CENTER := Vector2(576, 340)
const SCALE := 1.5
const FRAME_SIZE := Vector2(500, 300) # usb_sheet.png frames, spots below are in their pixels
const PLUG := Vector2(127, 200)
const PORT := Vector2(400, 108)

@onready var _usb: UsbAnimation = $Usb

var _started: Dictionary[AimNote, bool] = {} # a slider's tail doesn't play anything

static func plug() -> Vector2: return _on_screen(PLUG)
static func port() -> Vector2: return _on_screen(PORT)

static func _on_screen(point: Vector2) -> Vector2: return CENTER + (point - FRAME_SIZE / 2) * SCALE

# half a circle over `center`, flipping back runs the other way
static func flip_arc(center: Vector2, radius: float, back: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		points.append(center + Vector2.from_angle(lerpf(TAU, PI, t) if back else lerpf(PI, TAU, t)) * radius)
	return points

func _ready() -> void:
	super()
	_usb.position = CENTER
	_usb.scale = Vector2.ONE * SCALE
	mode.judged.connect(_on_judged)

# every note head plays the next phase, misses too, so the plug keeps pace with the map
func _on_judged(result: HitResult) -> void:
	var note := result.note as AimNote
	if _started.has(note): return
	_started[note] = true
	_usb.advance()
