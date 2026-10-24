class_name FourDMode
extends ModeHandler

const LANES: Array[StringName] = [&"lane_0", &"lane_1", &"lane_2", &"lane_3"]

func _handle_input(event: InputEvent, now: float) -> void:
	for lane in LANES.size():
		if not event.is_action_pressed(LANES[lane]): continue
		var note: Note = IterUtils.first(_pending, func(n: LaneNote): return n.lane == lane)
		if _in_window(note, now): _hit(note, now)
