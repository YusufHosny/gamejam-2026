extends Node

# --- Timing ---
var audio_offset_ms := 0.0 # positive judges notes later
var hit_windows_ms := {
	Judgement.Grade.GREAT: 40.0,
	Judgement.Grade.OK: 90.0,
	Judgement.Grade.MEH: 135.0,
}
var approach_time_s := 0.8
var scroll_speed := 700.0 # px/s for 4d lanes

# --- Chart ---
var bpm := 120.0
var segment_bars := 8
var cooldown_bars := 2
var chart_seed := 41

# --- Mouse ---
var mouse_sensitivity := 1.0
var slash_min_speed := 1200.0 # px/s

# --- Keybinds ---
var keybinds: Dictionary[StringName, Array] = {
	&"lane_0": [_key(KEY_Z)],
	&"lane_1": [_key(KEY_X)],
	&"lane_2": [_key(KEY_N)],
	&"lane_3": [_key(KEY_M)],
	&"click_0": [_key(KEY_Z), _mouse(MOUSE_BUTTON_LEFT)],
	&"click_1": [_key(KEY_X), _mouse(MOUSE_BUTTON_RIGHT)],
	&"release_cursor": [_key(KEY_ESCAPE)],
	&"restart": [_key(KEY_F5)],
	&"debug_four_d": [_key(KEY_F1)],
	&"debug_aim_click": [_key(KEY_F2)],
	&"debug_slash": [_key(KEY_F3)],
	&"debug_typing": [_key(KEY_F4)],
}

func _ready() -> void:
	for action in keybinds: _apply_keybind(action)

func miss_window_s() -> float: return hit_windows_ms[Judgement.Grade.MEH] / 1000.0

func rebind(action: StringName, events: Array[InputEvent]) -> void:
	keybinds[action] = events
	_apply_keybind(action)

func _apply_keybind(action: StringName) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for event in keybinds[action]: InputMap.action_add_event(action, event)

# physical keys so lanes stay put across keyboard layouts
static func _key(physical_keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	return event

static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event
