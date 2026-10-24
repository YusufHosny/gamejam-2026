class_name SlashMode
extends AimMode

var _last_cursor_pos: Vector2

func begin(_segment: ChartSegment, _view: ModeView) -> void:
	super(_segment, _view)
	_last_cursor_pos = cursor.global_position

# slashing samples the cursor path each frame instead of reacting to events
func _handle_input(_event: InputEvent, _now: float) -> void: pass

func _process(delta: float) -> void:
	super(delta)
	if not is_active(): return
	var now := conductor.song_time()
	var from := _last_cursor_pos
	var to := cursor.global_position
	_last_cursor_pos = to
	if from.distance_to(to) / delta < GameConfig.slash_min_speed: return
	for note: AimNote in _pending.duplicate():
		if note.time - now > GameConfig.miss_window_s(): break
		if _is_hit(note, from, to): _hit(note, now)
