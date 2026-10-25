class_name Hud
extends CanvasLayer

const JUDGEMENT_FADE_S := 0.5

@onready var _score: Label = $Score
@onready var _accuracy: Label = $Accuracy
@onready var _combo: Label = $Combo
@onready var _judgement: Label = $Judgement
@onready var _tutorial: Label = $Tutorial
@onready var _timing_bar: TimingBar = $TimingBar
@onready var _hand_pos: HandPosIcon = $HandPos

func _ready() -> void:
	reset()
	set_tutorial(false)

func _process(delta: float) -> void:
	_judgement.modulate.a = maxf(_judgement.modulate.a - delta / JUDGEMENT_FADE_S, 0.0)

func reset() -> void:
	show_score(ScoreKeeper.new())
	_timing_bar.clear()
	_judgement.modulate.a = 0.0

func show_score(score: ScoreKeeper) -> void:
	_score.text = "%08d" % score.score
	_accuracy.text = "%.2f%%" % (score.accuracy() * 100.0)
	_combo.text = "%dx" % score.combo

func show_judgement(result: HitResult) -> void:
	_judgement.text = Judgement.label(result.grade)
	_judgement.modulate = Judgement.color(result.grade)
	if result.is_timed(): _timing_bar.add(result.error_s)

func set_hand_pos(hand_pos: Modality.HandPos) -> void: _hand_pos.hand_pos = hand_pos

func set_tutorial(tutorial: bool) -> void: _tutorial.visible = tutorial
