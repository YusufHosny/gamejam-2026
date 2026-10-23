class_name FourDMode
extends ModeHandler

const LANES: Array[StringName] = [&"lane_0", &"lane_1", &"lane_2", &"lane_3"]
const LANE_WIDTH := 90.0
const NOTE_RADIUS := 32.0
const HIT_LINE_MARGIN := 100.0

func _handle_input(event: InputEvent, now: float) -> void:
	for lane in LANES.size():
		if not event.is_action_pressed(LANES[lane]): continue
		var note: Note = IterUtils.first(_pending, func(n: LaneNote): return n.lane == lane)
		if _in_window(note, now): _hit(note, now)

func _draw() -> void:
	var now := conductor.song_time()
	var hit_y := get_viewport_rect().size.y - HIT_LINE_MARGIN
	for lane in LANES.size():
		var receptor := Vector2(_lane_x(lane), hit_y)
		draw_arc(receptor, NOTE_RADIUS, 0, TAU, 48, Color.WHITE, 3)
		if Input.is_action_pressed(LANES[lane]):
			draw_circle(receptor, NOTE_RADIUS * 0.6, Color(1, 1, 1, 0.4))
	for note: LaneNote in _pending:
		var y := hit_y - (note.time - now) * GameConfig.scroll_speed
		if y < -NOTE_RADIUS: break
		draw_circle(Vector2(_lane_x(note.lane), y), NOTE_RADIUS, Color.WHITE)

func _lane_x(lane: int) -> float:
	return get_viewport_rect().size.x / 2 + (lane - 1.5) * LANE_WIDTH
