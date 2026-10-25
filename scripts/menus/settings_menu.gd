class_name SettingsMenu
extends Control

# edits GameConfig live, number settings are saved to disk

signal back_pressed

class NumberSetting:
	var label: String
	var property: StringName
	var min_value: float
	var max_value: float
	var step: float

	func _init(_label: String, _property: StringName, _min_value: float, _max_value: float, _step: float) -> void:
		label = _label
		property = _property
		min_value = _min_value
		max_value = _max_value
		step = _step

static var NUMBER_SETTINGS: Array[NumberSetting] = [
	NumberSetting.new("audio offset (ms)", &"audio_offset_ms", -300, 300, 1),
	NumberSetting.new("hitsound volume", &"hitsound_volume", 0.0, 1.0, 0.05),
	NumberSetting.new("mouse sensitivity", &"mouse_sensitivity", 0.1, 5.0, 0.05),
	NumberSetting.new("approach time (s)", &"approach_time_s", 0.3, 2.0, 0.05),
	NumberSetting.new("4d scroll speed (px/s)", &"scroll_speed", 200, 2000, 10),
	NumberSetting.new("min slash speed (px/s)", &"slash_min_speed", 200, 4000, 50),
]
# debug binds are left out on purpose
const KEYBIND_LABELS := {
	&"lane_0": "4d lane 1",
	&"lane_1": "4d lane 2",
	&"lane_2": "4d lane 3",
	&"lane_3": "4d lane 4",
	&"click_0": "click 1",
	&"click_1": "click 2",
	&"pause": "pause",
}
const LABEL_WIDTH := 260.0

@onready var _numbers: VBoxContainer = %Numbers
@onready var _keybinds: GridContainer = %Keybinds
@onready var _difficulty: OptionButton = %Difficulty
@onready var _language: OptionButton = %Language
@onready var _tutorial: CheckBox = %Tutorial
@onready var _back: Button = %Back

var _spins: Dictionary[StringName, SpinBox] = {}
var _rebinding: Button = null # waiting for the next key or mouse press
var _rebind_action: StringName
var _rebind_index: int

func _ready() -> void:
	_back.pressed.connect(back_pressed.emit)
	for setting in NUMBER_SETTINGS: _add_number_row(setting)
	_add_calibrate_row()
	_build_keybinds()
	_build_game_page()
	visibility_changed.connect(func(): if visible: _back.grab_focus())

# --- General Page ---
func _add_number_row(setting: NumberSetting) -> void:
	var row := HBoxContainer.new()
	var label := _row_label(setting.label)
	var spin := SpinBox.new()
	spin.min_value = setting.min_value
	spin.max_value = setting.max_value
	spin.step = setting.step
	spin.value = GameConfig.get(setting.property)
	spin.value_changed.connect(func(value: float):
		GameConfig.set(setting.property, value)
		GameConfig.save_settings())
	_spins[setting.property] = spin
	row.add_child(label)
	row.add_child(spin)
	_numbers.add_child(row)

# right under the audio offset row
func _add_calibrate_row() -> void:
	var row := HBoxContainer.new()
	var button := Button.new()
	button.text = "calibrate"
	button.pressed.connect(_calibrate)
	row.add_child(_row_label(""))
	row.add_child(button)
	_numbers.add_child(row)
	_numbers.move_child(row, 1)

func _calibrate() -> void:
	var calibration := OffsetCalibration.new()
	calibration.finished.connect(func(): _spins[&"audio_offset_ms"].set_value_no_signal(GameConfig.audio_offset_ms))
	add_child(calibration)

func _build_keybinds() -> void:
	for child in _keybinds.get_children():
		_keybinds.remove_child(child)
		child.queue_free()
	var slots: int = KEYBIND_LABELS.keys().map(func(a: StringName): return GameConfig.keybinds[a].size()).max()
	_keybinds.columns = slots + 1
	for action: StringName in KEYBIND_LABELS:
		_keybinds.add_child(_row_label(KEYBIND_LABELS[action]))
		var events: Array = GameConfig.keybinds[action]
		for i in slots:
			if i >= events.size():
				_keybinds.add_child(Control.new())
				continue
			var button := Button.new()
			button.text = _event_label(events[i])
			button.pressed.connect(_start_rebind.bind(button, action, i))
			_keybinds.add_child(button)

func _start_rebind(button: Button, action: StringName, index: int) -> void:
	if _rebinding != null: _build_keybinds()
	_rebinding = button
	_rebind_action = action
	_rebind_index = index
	button.text = "press a key..."

func _input(event: InputEvent) -> void:
	if _rebinding == null: return
	var bound: InputEvent = null
	if event is InputEventKey and event.pressed and not event.echo:
		bound = GameConfig.key_event(event.physical_keycode)
	elif event is InputEventMouseButton and event.pressed:
		bound = GameConfig.mouse_event(event.button_index)
	if bound == null: return
	get_viewport().set_input_as_handled()
	var events: Array[InputEvent] = []
	events.assign(GameConfig.keybinds[_rebind_action])
	events[_rebind_index] = bound
	GameConfig.rebind(_rebind_action, events)
	_rebinding = null
	_build_keybinds()

# --- Game Page ---
func _build_game_page() -> void:
	for level: Difficulty.Level in Difficulty.Level.values():
		_difficulty.add_item(Difficulty.label(level), level)
	_difficulty.select(_difficulty.get_item_index(GameConfig.difficulty))
	_difficulty.item_selected.connect(func(index: int): GameConfig.difficulty = _difficulty.get_item_id(index))
	var languages: Array = VoiceLines.LANGUAGES.keys()
	for code: String in languages: _language.add_item(VoiceLines.LANGUAGES[code])
	_language.select(languages.find(GameConfig.language))
	_language.item_selected.connect(func(index: int):
		GameConfig.language = languages[index]
		GameConfig.save_settings())
	_tutorial.button_pressed = GameConfig.tutorial_enabled
	_tutorial.toggled.connect(func(enabled: bool): GameConfig.tutorial_enabled = enabled)

func _row_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = LABEL_WIDTH
	return label

static func _event_label(event: InputEvent) -> String:
	if event is InputEventKey: return OS.get_keycode_string(event.physical_keycode)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "mouse left"
			MOUSE_BUTTON_RIGHT: return "mouse right"
			MOUSE_BUTTON_MIDDLE: return "mouse middle"
			_: return "mouse %d" % event.button_index
	return event.as_text()
