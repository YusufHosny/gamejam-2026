class_name AimClickMode
extends TargetMode

const CLICKS: Array[StringName] = [&"click_0", &"click_1"]

func _handle_input(event: InputEvent, now: float) -> void:
	if not CLICKS.any(func(action: StringName): return event.is_action_pressed(action)): return
	var note := _next() as AimNote
	if not _in_window(note, now): return
	if cursor.position.distance_to(note.position) <= RADIUS: _hit(note, now)
	else: _resolve(HitResult.miss(note))
