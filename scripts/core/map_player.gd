class_name MapPlayer
extends Node2D

signal finished

const DEBUG_SEEKS: Dictionary[StringName, Modality.Kind] = {
	&"debug_four_d": Modality.Kind.FOUR_D,
	&"debug_aim_click": Modality.Kind.AIM_CLICK,
	&"debug_slash": Modality.Kind.SLASH,
}
const DEFAULT_VIEWS := {
	Modality.Kind.FOUR_D: preload("res://scenes/views/circle_four_d_view.tscn"),
	Modality.Kind.AIM_CLICK: preload("res://scenes/views/circle_aim_click_view.tscn"),
	Modality.Kind.SLASH: preload("res://scenes/views/circle_slash_view.tscn"),
}

const COMBO_BREAK_MIN := 10

@export var hitsound: AudioStream # null -> synthesized blip
@export var combo_break: AudioStream

@onready var conductor: Conductor = $Conductor
@onready var hud: Hud = $Hud
@onready var cursor: VirtualCursor = $Cursor
@onready var _views: Node2D = $Views
@onready var _hitsounds: AudioStreamPlayer = $Hitsounds
@onready var _four_d: FourDMode = $Modes/FourD
@onready var _aim_click: AimClickMode = $Modes/AimClick
@onready var _slash: SlashMode = $Modes/Slash

var map: Map # set before entering the tree
var score := ScoreKeeper.new() # the run's score, handed back on finish
var pre_roll_s := 0.0 # set before entering the tree, silence before the music starts
var _pre_roll_left := 0.0
var _segment: MapSegment = null
var _view: ModeView = null
var _checkpoint := ScoreKeeper.new() # checkpointed score
var _finished := false
var _relaxed := false # judge mode, see Difficulty

func _ready() -> void:
	_aim_click.cursor = cursor
	_slash.cursor = cursor
	_relaxed = Difficulty.relaxed(GameConfig.difficulty)
	for handler: ModeHandler in [_four_d, _aim_click, _slash]:
		handler.conductor = conductor
		handler.relax = _relaxed and handler != _four_d # 4d only gets wider windows
		handler.judged.connect(_on_judged)
	if Difficulty.autoplays(GameConfig.difficulty): _add_autopilot()
	if hitsound == null: hitsound = SfxUtils.hitsound()
	_hitsounds.stream = AudioStreamPolyphonic.new()
	_hitsounds.play()
	hud.show_score(score)
	_pre_roll_left = pre_roll_s
	if _pre_roll_left <= 0.0: conductor.start(map)

func _process(delta: float) -> void:
	_count_down_pre_roll(delta)
	_hold_for_next_note()
	var now := time()
	var segment := map.segment_at(now)
	if segment != _segment: _switch_to(segment)
	if segment == null:
		_finish()
		return
	if now < segment.start_time:
		hud.show_banner(Modality.hand_pos(segment.kind), fposmod(map.time_beat(now), 1.0) < 0.5) # fposmod, now is negative in the pre roll
	else:
		hud.hide_banner()

func _unhandled_input(event: InputEvent) -> void:
	for action in DEBUG_SEEKS:
		if event.is_action_pressed(action): _seek_to_segment(_first_segment(DEBUG_SEEKS[action]))

# negative during the pre roll, counting up to the music starting at 0
func time() -> float: return conductor.song_time() - _pre_roll_left

func active_handler() -> ModeHandler: return null if _segment == null else _handler(_segment.kind)

func _add_autopilot() -> void:
	var autopilot := Autopilot.new()
	autopilot.player = self
	add_child(autopilot)

func load_checkpoint() -> void:
	var segment := _segment
	_set_score(_checkpoint.copy())
	_seek_to_segment(segment)

# --- Segments ---
func _switch_to(segment: MapSegment) -> void:
	if _segment != null:
		_handler(_segment.kind).end()
		_views.remove_child(_view) # out of the tree now so it can't draw an ended segment
		_view.queue_free()
		_view = null
	_segment = segment
	if segment == null:
		cursor.enabled = false
		return
	_checkpoint = score.copy()
	var view_scene: PackedScene = segment.view if segment.view != null else DEFAULT_VIEWS[segment.kind]
	_view = view_scene.instantiate()
	_handler(segment.kind).begin(segment, _view)
	_views.add_child(_view)
	var hand_pos := Modality.hand_pos(segment.kind)
	cursor.enabled = hand_pos == Modality.HandPos.A
	hud.set_hand_pos(hand_pos)
	hud.set_tutorial(segment.tutorial)

func _count_down_pre_roll(delta: float) -> void:
	if _pre_roll_left <= 0.0: return
	_pre_roll_left = maxf(_pre_roll_left - delta, 0.0)
	if _pre_roll_left == 0.0: conductor.start(map)

# wait segments freeze the clock on each note until it's hit
func _hold_for_next_note() -> void:
	var pending: Array[Note] = []
	if _segment != null and _segment.wait_for_input: pending = _handler(_segment.kind).pending()
	conductor.hold_at(INF if pending.is_empty() else pending[0].time)

func _handler(kind: Modality.Kind) -> ModeHandler:
	match kind:
		Modality.Kind.FOUR_D: return _four_d
		Modality.Kind.AIM_CLICK: return _aim_click
		Modality.Kind.SLASH: return _slash
	assert(false, "unhandled modality %s" % kind)
	return null

func _first_segment(kind: Modality.Kind) -> MapSegment:
	return IterUtils.first(map.segments, func(s: MapSegment): return s.kind == kind)

func _finish() -> void:
	if _finished: return
	_finished = true
	finished.emit()

# --- Seeking ---
func _seek(time: float) -> void:
	_pre_roll_left = 0.0 # seeking skips what's left of the silence
	_switch_to(null)
	conductor.seek_to(time)

func _seek_to_segment(segment: MapSegment) -> void:
	_seek(map.beat_time(segment.start_beat - map.beats_per_bar)) # one bar of lead in

# --- Scoring ---
func _set_score(keeper: ScoreKeeper) -> void:
	score = keeper
	hud.show_score(score)

func _on_judged(result: HitResult) -> void:
	if _relaxed and result.is_miss(): result = HitResult.new(result.note, Judgement.Grade.MEH) # judge mode never drops combo
	hud.show_judgement(result)
	var volume := 1.0 if Difficulty.autoplays(GameConfig.difficulty) else GameConfig.hitsound_volume # autoplay is for hearing the map
	if not result.is_miss() and volume > 0.0: _play(hitsound, volume)
	if _segment.tutorial: return
	if result.is_miss() and score.combo >= COMBO_BREAK_MIN: _play(combo_break)
	score.add(result)
	hud.show_score(score)

func _play(sound: AudioStream, volume := 1.0) -> void:
	if sound != null: (_hitsounds.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(sound, 0, linear_to_db(volume))
