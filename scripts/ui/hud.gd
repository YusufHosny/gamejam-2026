class_name Hud
extends CanvasLayer

const JUDGEMENT_FADE_S := 0.5
const BANNER_DIM_ALPHA := 0.15

@onready var _score: Label = $Score
@onready var _accuracy: Label = $Accuracy
@onready var _combo: Label = $Combo
@onready var _judgement: Label = $Judgement
@onready var _timing_bar: TimingBar = $TimingBar
@onready var _hand_pos: HandPosIcon = $HandPos
@onready var _banner: Control = $Banner
@onready var _banner_icon: HandPosIcon = $Banner/Icon

func _ready() -> void:
	reset()
	hide_banner()

func _process(delta: float) -> void:
	_judgement.modulate.a = maxf(_judgement.modulate.a - delta / JUDGEMENT_FADE_S, 0.0)

func reset() -> void:
	_show_score(ScoreKeeper.new())
	_timing_bar.clear()
	_judgement.modulate.a = 0.0

func show_judgement(result: HitResult, score: ScoreKeeper) -> void:
	_show_score(score)
	_judgement.text = Judgement.label(result.grade)
	_judgement.modulate = Judgement.color(result.grade)
	if not result.is_miss(): _timing_bar.add(result.error_s)

func set_hand_pos(hand_pos: Modality.HandPos) -> void: _hand_pos.hand_pos = hand_pos

# blinks on the beat during a cooldown to warn about the next hand position
func show_banner(hand_pos: Modality.HandPos, lit: bool) -> void:
	_banner.show()
	_banner_icon.hand_pos = hand_pos
	_banner.modulate.a = 1.0 if lit else BANNER_DIM_ALPHA

func hide_banner() -> void: _banner.hide()

func _show_score(score: ScoreKeeper) -> void:
	_score.text = "%08d" % score.score
	_accuracy.text = "%.2f%%" % (score.accuracy() * 100.0)
	_combo.text = "%dx" % score.combo
