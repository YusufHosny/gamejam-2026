class_name Cutscene
extends Control

signal finished

const SKIP_TAIL_S := 2.0 # skipping lands this far from the end

const VOICE_LINE_AT := 0.2

var caption := "" # placeholder text / subtitle
var length_s := 0.0 # 0 waits for the player
var voice_line: StringName = &"" # a placeholder's one line, real cutscenes override voice_cues()
var time := 0.0
var _finished := false
var _voice := VoiceTrack.new()

func _init() -> void:
	add_child(_voice, false, INTERNAL_MODE_BACK) # after the scene's own nodes, the captions draw on top

# [at, id] or [at, id, part], see VoiceTrack.cues
func voice_cues() -> Array: return [[VOICE_LINE_AT, voice_line]] if voice_line != &"" else []

func waits() -> bool: return length_s <= 0.0

func restart() -> void:
	time = 0.0
	_finished = false

func skip() -> void:
	if waits(): _finish()
	else: time = maxf(time, length_s - SKIP_TAIL_S)

func _process(delta: float) -> void:
	time += delta
	if _voice.cues.is_empty(): _voice.cues = voice_cues()
	_voice.sync(time)
	if not waits() and time >= length_s: _finish()

func _unhandled_input(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and waits()
	if event.is_action_pressed(&"skip_cutscene") or clicked:
		skip()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	if _finished: return
	_finished = true
	finished.emit()
