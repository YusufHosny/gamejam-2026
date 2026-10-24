class_name Hud
extends CanvasLayer

const JUDGEMENT_FADE_S := 0.5
const BANNER_DIM_ALPHA := 0.15

@onready var _score: Label = $Score
@onready var _accuracy: Label = $Accuracy
@onready var _combo: Label = $Combo
@onready var _judgement: Label = $Judgement
@onready var _practice: Label = $Practice
@onready var _timing_bar: TimingBar = $TimingBar
@onready var _hand_pos: HandPosIcon = $HandPos
@onready var _banner: Control = $Banner
@onready var _banner_icon: HandPosIcon = $Banner/Icon
@onready var _deadline_clock: DeadlineClock = $DeadlineClock

func _ready() -> void:
	reset()
	hide_banner()
	set_practice(false)

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

func set_time_left(seconds: float) -> void: _deadline_clock.set_time_left(seconds)

func play_intro() -> void: await _deadline_clock.play_intro()

func set_hand_pos(hand_pos: Modality.HandPos) -> void: _hand_pos.hand_pos = hand_pos

func set_practice(practice: bool) -> void: _practice.visible = practice

# blinks on the beat during a cooldown to warn about the next hand position
func show_banner(hand_pos: Modality.HandPos, lit: bool) -> void:
	_banner.show()
	_banner_icon.hand_pos = hand_pos
	_banner.modulate.a = 1.0 if lit else BANNER_DIM_ALPHA

func hide_banner() -> void: _banner.hide()
