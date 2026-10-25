extends Node

# --- Timing ---
var audio_offset_ms := 0.0 # positive judges notes later
var hitsound_volume := 0.0 # 0 mutes them, they lag behind on high latency setups
var hit_windows_ms := {
	Judgement.Grade.GREAT: 40.0,
	Judgement.Grade.OK: 90.0,
	Judgement.Grade.MEH: 135.0,
}
var approach_time_s := 0.8
var scroll_speed := 700.0 # px/s for 4d lanes

# --- Run ---
var difficulty := Difficulty.Level.STANDARD
var tutorial_enabled := true

# --- Map ---
var bpm := 120.0
var segment_bars := 8
var cooldown_bars := 2
var map_seed := 41

# --- Mouse ---
var mouse_sensitivity := 1.5
var slash_min_speed := 1200.0 # px/s

# --- Saved ---
const SETTINGS_FILE := "user://settings.cfg"
const SAVED: Array[StringName] = [&"audio_offset_ms", &"hitsound_volume", &"mouse_sensitivity", &"approach_time_s", &"scroll_speed", &"slash_min_speed"]

# --- Keybinds ---
var keybinds: Dictionary[StringName, Array] = {
	&"lane_0": [key_event(KEY_Z)],
	&"lane_1": [key_event(KEY_X)],
	&"lane_2": [key_event(KEY_N)],
	&"lane_3": [key_event(KEY_M)],
	&"click_0": [key_event(KEY_Z), mouse_event(MOUSE_BUTTON_LEFT)],
	&"click_1": [key_event(KEY_X), mouse_event(MOUSE_BUTTON_RIGHT)],
	&"pause": [key_event(KEY_ESCAPE)],
	&"skip_cutscene": [key_event(KEY_SPACE), key_event(KEY_ENTER)],
	&"debug_four_d": [key_event(KEY_F1)],
	&"debug_aim_click": [key_event(KEY_F2)],
	&"debug_slash": [key_event(KEY_F3)],
}

func _ready() -> void:
	for action in keybinds: _apply_keybind(action)
	_load_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	for property in SAVED: config.set_value("settings", property, get(property))
	config.save(SETTINGS_FILE)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK: return
	for property in SAVED: set(property, config.get_value("settings", property, get(property)))

# autoplay ignores it, so its hitsounds share the music's delay and stay in sync
func offset_ms() -> float: return 0.0 if Difficulty.autoplays(difficulty) else audio_offset_ms

# scaled by the difficulty, judge mode widens them
func hit_window_ms(grade: Judgement.Grade) -> float: return hit_windows_ms[grade] * Difficulty.window_scale(difficulty)

func miss_window_s() -> float: return hit_window_ms(Judgement.Grade.MEH) / 1000.0

func rebind(action: StringName, events: Array[InputEvent]) -> void:
	keybinds[action] = events
	_apply_keybind(action)

func _apply_keybind(action: StringName) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for event in keybinds[action]: InputMap.action_add_event(action, event)

# physical keys so lanes stay put across keyboard layouts
static func key_event(physical_keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	return event

static func mouse_event(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event
