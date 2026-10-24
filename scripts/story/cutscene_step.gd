class_name CutsceneStep
extends RunStep

const TEXT_CUTSCENE := preload("res://scenes/cutscenes/text_cutscene.tscn")

@export var scene: PackedScene = TEXT_CUTSCENE # a Cutscene scene
@export var caption := ""
@export var duration_s := 0.0 # 0 waits for the player, untimed steps only

func _init(_caption := "", _duration_s := 0.0, _timed := true, _scene: PackedScene = TEXT_CUTSCENE) -> void:
	caption = _caption
	duration_s = _duration_s
	timed = _timed
	scene = _scene

func length_s() -> float: return duration_s
