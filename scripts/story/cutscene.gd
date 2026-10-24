class_name Cutscene
extends Control

signal finished

const SKIP_TAIL_S := 2.0 # skipping lands this far from the end

var caption := "" # placeholder text / subtitle
var length_s := 0.0 # 0 waits for the player
var time := 0.0
var _finished := false

func waits() -> bool: return length_s <= 0.0

func restart() -> void:
	time = 0.0
	_finished = false

func skip() -> void:
	if waits(): _finish()
	else: time = maxf(time, length_s - SKIP_TAIL_S)

func _process(delta: float) -> void:
	time += delta
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
