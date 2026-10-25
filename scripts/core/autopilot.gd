class_name Autopilot
extends Node

# autoplay: plays the map by itself through the same cursor and input actions a player uses

const GLIDE := 14.0 # how fast the cursor eases toward the next note
const SWIPE := 140.0 # px either side of a slashed note

var player: MapPlayer
var _held: Array[StringName] = [] # pressed last frame, released this one
var _swipe_to := Vector2.INF # second half of a slash, next frame

func _process(delta: float) -> void:
	for action in _held: _send(action, false)
	_held.clear()
	var handler := player.active_handler()
	if handler == null: return
	var now := player.time()
	var due := now + delta / 2 # act on the frame closest to the beat
	if handler is FourDMode: _play_lanes(handler, due)
	elif handler is AimClickMode: _play_clicks(handler as AimClickMode, now, due, delta)
	elif handler is SlashMode: _play_slashes(handler as SlashMode, due)

func _play_lanes(handler: ModeHandler, due: float) -> void:
	for note: LaneNote in handler.pending():
		if note.time > due: return
		_press(FourDMode.LANES[note.lane])

# glides to each note, clicks on the beat and rides sliders with the button held
func _play_clicks(handler: AimClickMode, now: float, due: float, delta: float) -> void:
	var cursor := player.cursor
	var slider := handler.sliding()
	if slider != null:
		cursor.position = slider.ball_at(slider.progress_at(now))
		Input.action_press(AimClickMode.CLICKS[0])
		return
	Input.action_release(AimClickMode.CLICKS[0])
	var note := _next(handler)
	if note == null: return
	cursor.position = cursor.position.lerp(note.position, 1.0 - exp(-GLIDE * delta))
	if note.time > due: return
	cursor.position = note.position
	Input.action_press(AimClickMode.CLICKS[0])
	_press(AimClickMode.CLICKS[0])

# a fast stroke through the note on its beat, along the way the view wants it cut
func _play_slashes(handler: SlashMode, due: float) -> void:
	var cursor := player.cursor
	if _swipe_to != Vector2.INF:
		cursor.position = _swipe_to
		_swipe_to = Vector2.INF
		return
	var note := _next(handler)
	if note == null or note.time > due: return
	var along := (handler.view as AimView).slash_direction(note)
	cursor.position = note.position - along * SWIPE
	_swipe_to = note.position + along * SWIPE

func _next(handler: ModeHandler) -> AimNote:
	var pending := handler.pending()
	return null if pending.is_empty() else pending[0] as AimNote

func _press(action: StringName) -> void:
	_send(action, true)
	_held.append(action)

static func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
