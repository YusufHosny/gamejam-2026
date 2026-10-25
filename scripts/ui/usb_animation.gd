class_name UsbAnimation
extends Sprite2D

# the usb gif split into phases. each advance() plays the next one, after the last it loops back to frame 0
# succeed() ends it on a push that goes all the way in, from the 3 hand drawn frames after the gif's on the sheet

signal phase_finished(phase: int)
signal success_finished

const FRAME_COUNT := 149
const FRAME_S := 0.06
# last frame of each phase: arrow, push, bump x4, flip + arrow, push, bump x3, flip back
const PHASE_ENDS: Array[int] = [8, 24, 35, 42, 50, 64, 92, 103, 112, 118, 127, FRAME_COUNT]
const SUCCESS_HOLD := 7 # frames it rests plugged in
static var success_frames: Array[int] = _success_frames() # the arrow and push, then all the way in

@export var speed := 1.0

var _requested := -1 # last phase asked for, counts up across loops
var _playing := -1 # phase being played, or the last one finished
var _frame := 0.0 # unwrapped, keeps counting up across loops
var _success := -1.0 # index into success_frames, -1 until succeed()
var _success_queued := false

func _ready() -> void:
	frame = 0

# presses while a phase is still playing queue up, and the queue plays faster to catch up
func advance() -> void:
	_requested += 1
	if not is_playing(): _playing = _requested

func is_playing() -> bool: return _frame < _phase_end(_playing)

# plays once whatever's playing or queued has finished, then stays plugged in
func succeed() -> void: _success_queued = true

# wraps around so 0 is always the first arrow, -1 before the first advance()
func current_phase() -> int: return -1 if _playing < 0 else _playing % PHASE_ENDS.size()

func _process(delta: float) -> void:
	if _success >= 0.0 or (_success_queued and not is_playing()):
		_play_success(delta)
		return
	if not is_playing(): return
	var queued := _requested - _playing
	_frame = minf(_frame + delta / FRAME_S * speed * (1 + queued), _phase_end(_playing))
	frame = posmod(floori(_frame), FRAME_COUNT)
	if is_playing(): return
	phase_finished.emit(current_phase())
	if _playing < _requested: _playing += 1

func _play_success(delta: float) -> void:
	var last := success_frames.size() - 1
	var was_done := _success >= last
	_success = minf(maxf(_success, 0.0) + delta / FRAME_S * speed, last)
	frame = success_frames[floori(_success)]
	if _success >= last and not was_done: success_finished.emit()

static func _success_frames() -> Array[int]:
	var frames: Array[int] = []
	for i in range(1, 24): frames.append(i)
	frames.append_array([FRAME_COUNT, FRAME_COUNT + 1])
	for i in SUCCESS_HOLD + 1: frames.append(FRAME_COUNT + 2)
	return frames

func _phase_end(phase: int) -> float:
	if phase < 0: return 0.0
	@warning_ignore("integer_division")
	var lap := phase / PHASE_ENDS.size()
	return float(lap * FRAME_COUNT + PHASE_ENDS[phase % PHASE_ENDS.size()])
