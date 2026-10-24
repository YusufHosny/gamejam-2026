class_name UsbAnimation
extends Sprite2D

# the usb gif split into phases. each advance() plays the next one, after the last it loops back to frame 0

signal phase_finished(phase: int)

const FRAME_COUNT := 149
const FRAME_S := 0.06
# last frame of each phase: arrow, push, bump x4, flip + arrow, push, bump x3, flip back
const PHASE_ENDS: Array[int] = [8, 24, 35, 42, 50, 64, 92, 103, 112, 118, 127, FRAME_COUNT]

@export var speed := 1.0

var _requested := -1 # last phase asked for, counts up across loops
var _playing := -1 # phase being played, or the last one finished
var _frame := 0.0 # unwrapped, keeps counting up across loops

func _ready() -> void:
	frame = 0

# presses while a phase is still playing queue up, and the queue plays faster to catch up
func advance() -> void:
	_requested += 1
	if not is_playing(): _playing = _requested

func is_playing() -> bool: return _frame < _phase_end(_playing)

# wraps around so 0 is always the first arrow, -1 before the first advance()
func current_phase() -> int: return -1 if _playing < 0 else _playing % PHASE_ENDS.size()

func _process(delta: float) -> void:
	if not is_playing(): return
	var queued := _requested - _playing
	_frame = minf(_frame + delta / FRAME_S * speed * (1 + queued), _phase_end(_playing))
	frame = posmod(floori(_frame), FRAME_COUNT)
	if is_playing(): return
	phase_finished.emit(current_phase())
	if _playing < _requested: _playing += 1

func _phase_end(phase: int) -> float:
	if phase < 0: return 0.0
	@warning_ignore("integer_division")
	var lap := phase / PHASE_ENDS.size()
	return float(lap * FRAME_COUNT + PHASE_ENDS[phase % PHASE_ENDS.size()])
