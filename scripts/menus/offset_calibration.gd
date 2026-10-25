class_name OffsetCalibration
extends Control

# tap along to a metronome, the median lateness becomes the audio offset. sound only, a visual beat would hide the delay

signal finished

const BPM := 80.0 # slow, so even bluetooth delays stay under half a tick
const TAPS := 16
const LEAD_TAPS := 4 # warm up taps that are not counted
const TAP_ACTIONS: Array[StringName] = [&"click_0", &"click_1", &"lane_0", &"lane_1", &"lane_2", &"lane_3"]

var _player: AudioStreamPlayer
var _lateness: Array[float] = [] # s after the nearest tick
var _taps := 0
var _label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 28)
	add_child(_label)
	_player = AudioStreamPlayer.new()
	_player.stream = SfxUtils.metronome(BPM, 4, 4, true)
	add_child(_player)
	_player.play()
	_show()

func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if event.is_action_pressed(&"pause"):
		_close()
		return
	for action in TAP_ACTIONS:
		if event.is_action_pressed(action): _tap()

func _tap() -> void:
	var beat_s := 60.0 / BPM
	var heard := _player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	_taps += 1
	if _taps > LEAD_TAPS: _lateness.append(heard - roundf(heard / beat_s) * beat_s)
	if _lateness.size() < TAPS:
		_show()
		return
	_lateness.sort()
	GameConfig.audio_offset_ms = roundf(_lateness[TAPS / 2] * 1000.0)
	GameConfig.save_settings()
	_close()

func _show() -> void:
	var counted := maxi(_taps - LEAD_TAPS, 0)
	_label.text = "tap Z, X or click on every tick\n%s\n\nesc to cancel" % ("get the feel..." if _taps < LEAD_TAPS else "%d / %d" % [counted, TAPS])

func _close() -> void:
	finished.emit()
	queue_free()
