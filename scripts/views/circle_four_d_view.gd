class_name CircleFourDView
extends ModeView

const LANE_WIDTH := 90.0
const NOTE_RADIUS := 32.0
const HIT_LINE_MARGIN := 100.0

func _draw() -> void:
	var now := _now()
	var hit_y := get_viewport_rect().size.y - HIT_LINE_MARGIN
	for lane in FourDMode.LANES.size():
		var receptor := Vector2(_lane_x(lane), hit_y)
		draw_arc(receptor, NOTE_RADIUS, 0, TAU, 48, Color.WHITE, 3)
		if Input.is_action_pressed(FourDMode.LANES[lane]):
			draw_circle(receptor, NOTE_RADIUS * 0.6, Color(1, 1, 1, 0.4))
	for note: LaneNote in mode.pending():
		var y := hit_y - (note.time - now) * GameConfig.scroll_speed
		if y < -NOTE_RADIUS: break
		draw_circle(Vector2(_lane_x(note.lane), y), NOTE_RADIUS, Color.WHITE)

func _lane_x(lane: int) -> float:
	return get_viewport_rect().size.x / 2 + (lane - 1.5) * LANE_WIDTH
