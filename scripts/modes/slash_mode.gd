class_name SlashMode
extends AimMode

var _last_cursor_pos: Vector2

func begin(_segment: ChartSegment) -> void:
	super(_segment)
	_last_cursor_pos = cursor.position

# slashing samples the cursor path each frame instead of reacting to events
func _handle_input(_event: InputEvent, _now: float) -> void: pass

func _process(delta: float) -> void:
	super(delta)
	if not is_active(): return
	var now := conductor.song_time()
	var from := _last_cursor_pos
	var to := cursor.position
	_last_cursor_pos = to
	if from.distance_to(to) / delta < GameConfig.slash_min_speed: return
	for note: AimNote in _pending.duplicate():
		if note.time - now > GameConfig.miss_window_s(): break
		var closest := Geometry2D.get_closest_point_to_segment(note.position, from, to)
		if closest.distance_to(note.position) <= RADIUS: _hit(note, now)
