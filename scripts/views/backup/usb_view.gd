class_name UsbView
extends CircleAimView

# b1: sliders push the usb into the port, doubles bump it, arcing sliders flip it

enum Move { PUSH, BUMP, FLIP, FLIP_BACK }

const CENTER := Vector2(576, 340)
const SCALE := 1.5
const FRAME_SIZE := Vector2(500, 300) # usb_sheet.png frames, spots below are in their pixels
const PLUG := Vector2(127, 200)
const PORT := Vector2(400, 108)
const FLIP_RADIUS := 70.0
# [beat in the cycle, move, usb phases its head plays], one cycle walks the whole animation once
const CYCLE := [
	[0.0, Move.PUSH, 2], [2.0, Move.BUMP, 1], [2.5, Move.BUMP, 1], [3.5, Move.BUMP, 1], [4.0, Move.BUMP, 1],
	[5.0, Move.FLIP, 1], [7.0, Move.PUSH, 1], [9.0, Move.BUMP, 1], [9.5, Move.BUMP, 1], [10.5, Move.BUMP, 1],
	[11.5, Move.FLIP_BACK, 1],
]
const CYCLE_BEATS := 14.0

@onready var _usb: UsbAnimation = $Usb

var _started: Dictionary[AimNote, bool] = {} # a slider's tail doesn't play anything

static func plug() -> Vector2: return _on_screen(PLUG)
static func port() -> Vector2: return _on_screen(PORT)

static func _on_screen(point: Vector2) -> Vector2: return CENTER + (point - FRAME_SIZE / 2) * SCALE

# over the top of the plug, flipping back runs the other way
static func flip_arc(back: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		points.append(plug() + Vector2.from_angle(lerpf(TAU, PI, t) if back else lerpf(PI, TAU, t)) * FLIP_RADIUS)
	return points

func _ready() -> void:
	super()
	_usb.position = CENTER
	_usb.scale = Vector2.ONE * SCALE
	mode.judged.connect(_on_judged)

# misses play their phase too so the animation always matches the next note
func _on_judged(result: HitResult) -> void:
	var note := result.note as AimNote
	if _started.has(note): return
	_started[note] = true
	var index := mode.segment.notes.find(note)
	for i in CYCLE[index % CYCLE.size()][2]: _usb.advance()
