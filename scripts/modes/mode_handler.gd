@abstract
class_name ModeHandler
extends Node2D

signal judged(result: HitResult)

var conductor: Conductor
var segment: ChartSegment
var _pending: Array[Note] = [] # unjudged, sorted by time

func _ready() -> void: end()

func begin(_segment: ChartSegment) -> void:
	segment = _segment
	_pending.assign(segment.notes)
	show()

func end() -> void:
	segment = null
	_pending.clear()
	hide()

func is_active() -> bool: return segment != null

func _process(_delta: float) -> void:
	if not is_active(): return
	var now := conductor.song_time()
	while not _pending.is_empty() and now - _pending[0].time > GameConfig.miss_window_s():
		_resolve(HitResult.miss(_pending[0]))
	queue_redraw()

func _input(event: InputEvent) -> void:
	if is_active(): _handle_input(event, conductor.song_time())

@abstract func _handle_input(event: InputEvent, now: float) -> void

# --- Judging ---
func _resolve(result: HitResult) -> void:
	_pending.erase(result.note)
	judged.emit(result)

func _hit(note: Note, now: float) -> void: _resolve(HitResult.hit(note, now - note.time))

func _next() -> Note: return null if _pending.is_empty() else _pending[0]

func _in_window(note: Note, now: float) -> bool:
	return note != null and absf(now - note.time) <= GameConfig.miss_window_s()
