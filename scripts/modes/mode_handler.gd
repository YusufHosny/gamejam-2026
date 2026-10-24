@abstract
class_name ModeHandler
extends Node

# timing and judging only, the bound view does all rendering

signal judged(result: HitResult)

var conductor: Conductor
var segment: ChartSegment
var view: ModeView
var _pending: Array[Note] = [] # unjudged, sorted by time

func _ready() -> void: end()

# binds before the view enters the tree so its _ready can read the mode
func begin(_segment: ChartSegment, _view: ModeView) -> void:
	segment = _segment
	view = _view
	view.mode = self
	_pending.assign(segment.notes)

func end() -> void:
	segment = null
	view = null
	_pending.clear()

func is_active() -> bool: return segment != null

# read only for views
func pending() -> Array[Note]: return _pending

func _process(_delta: float) -> void:
	if not is_active(): return
	var now := conductor.song_time()
	while not _pending.is_empty() and now - _pending[0].time > GameConfig.miss_window_s():
		_resolve(HitResult.miss(_pending[0]))

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
