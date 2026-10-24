class_name ScoreScreen
extends Control

signal retry_pressed
signal back_pressed

@onready var _rank: Label = %Rank
@onready var _score: Label = %Score
@onready var _details: Label = %Details
@onready var _retry: Button = %Retry
@onready var _back: Button = %Back

func _ready() -> void:
	_retry.pressed.connect(retry_pressed.emit)
	_back.pressed.connect(back_pressed.emit)
	visibility_changed.connect(func(): if visible: _retry.grab_focus())

func show_result(result: RunResult) -> void:
	_rank.text = result.rank_label()
	_rank.modulate = result.rank_color()
	_score.text = "%08d" % result.score
	var hits := " ".join(Judgement.Grade.values().map(
		func(g: Judgement.Grade): return "%s x%d" % [Judgement.label(g), result.counts[g]]
	))
	_details.text = "accuracy %.2f%%\nmax combo %dx\n%s" % [result.accuracy * 100.0, result.max_combo, hits]
