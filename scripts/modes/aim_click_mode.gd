class_name AimClickMode
extends AimMode

const CLICKS: Array[StringName] = [&"click_0", &"click_1"]

var _slider: SliderNote = null # from its head's judgement, hit or missed, until its end
var _ticks: Array[float] = [] # progress of its ticks still to come

func sliding() -> SliderNote: return _slider

func tracking() -> bool: return _slider != null and _tracking(_slider.progress_at(conductor.song_time()))

func end() -> void:
	super()
	_slider = null

func _handle_input(event: InputEvent, now: float) -> void:
	if relax: return # clicks do nothing in relax
	if not CLICKS.any(func(action: StringName): return event.is_action_pressed(action)): return
	var note := _next() as AimNote
	if not _in_window(note, now): return
	var point := cursor.global_position
	if _is_hit(note, point, point): _hit(note, now)
	elif not segment.wait_for_input: _resolve(HitResult.miss(note))

# like osu the slider runs to its end whatever happens, each tick and the end judge whether it's held and followed right then,
# so letting go only breaks combo and it can be picked back up
func _process(delta: float) -> void:
	super(delta)
	if relax: _relax_hit()
	if _slider == null: return
	var progress := _slider.progress_at(conductor.song_time())
	while not _ticks.is_empty() and progress >= _ticks[0]:
		judged.emit(HitResult.slider_tick(_slider, _tracking(_ticks.pop_front())))
	if progress >= 1.0: _finish_slider()

# --- Sliders ---
func _resolve(result: HitResult) -> void:
	super(result)
	var slider := result.note as SliderNote
	if slider == null: return
	if _slider != null: _finish_slider() # the next one started before this one ended
	_slider = slider
	_ticks = slider.ticks()

func _finish_slider() -> void:
	judged.emit(HitResult.new(_slider, Judgement.Grade.GREAT if _tracking(1.0) else Judgement.Grade.MISS))
	_slider = null
	_ticks.clear()

func _tracking(progress: float) -> bool: return _holding() and _is_following(_slider, cursor.global_position, progress)

# relax: the next note is hit the moment the cursor is on it while it's due, always a 300
func _relax_hit() -> void:
	var note := _next() as AimNote
	var point := cursor.global_position
	if _in_window(note, conductor.song_time()) and _is_hit(note, point, point):
		_resolve(HitResult.new(note, Judgement.Grade.GREAT, 0.0))

func _holding() -> bool:
	if relax: return true
	return CLICKS.any(func(action: StringName): return Input.is_action_pressed(action))
