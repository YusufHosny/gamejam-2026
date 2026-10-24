class_name AimClickMode
extends AimMode

const CLICKS: Array[StringName] = [&"click_0", &"click_1"]

var _slider: SliderNote = null # head hit, tail still to judge

func sliding() -> SliderNote: return _slider

func end() -> void:
	super()
	_slider = null

func _handle_input(event: InputEvent, now: float) -> void:
	if not CLICKS.any(func(action: StringName): return event.is_action_pressed(action)): return
	var note := _next() as AimNote
	if not _in_window(note, now): return
	var point := cursor.global_position
	if _is_hit(note, point, point): _hit(note, now)
	elif not segment.wait_for_input: _resolve(HitResult.miss(note))

# letting go or straying from the ball breaks the slider early
func _process(delta: float) -> void:
	super(delta)
	if _slider == null: return
	var progress := _slider.progress_at(conductor.song_time())
	if progress >= 1.0: _finish_slider(Judgement.Grade.GREAT)
	elif not _holding() or not _is_following(_slider, cursor.global_position, progress):
		_finish_slider(Judgement.Grade.MISS)

# --- Sliders ---
func _resolve(result: HitResult) -> void:
	super(result)
	var slider := result.note as SliderNote
	if slider == null: return
	if result.is_miss(): judged.emit(HitResult.miss(slider)) # a missed head loses its tail too
	else: _slider = slider

func _finish_slider(grade: Judgement.Grade) -> void:
	judged.emit(HitResult.new(_slider, grade))
	_slider = null

func _holding() -> bool:
	return CLICKS.any(func(action: StringName): return Input.is_action_pressed(action))
