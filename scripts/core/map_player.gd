class_name MapPlayer
extends Node2D

signal finished
signal segment_done(accuracy: float) # each played segment as it ends, for Louis to comment on

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
const TICK_VOLUME := 0.35 # slider ticks are a quieter hitsound
const SWITCH_HOLD_S := 3.0 # without the tutorial the hold before a mode switch lasts this long
const SWITCH_LEAD_S := 1.2 # the hold starts this long before the segment, ahead of its first notes showing

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
@onready var _demo: ModeDemo = $Demo/ModeDemo

var map: Map # set before entering the tree
var score := ScoreKeeper.new() # the run's score, handed back on finish
var pre_roll_s := 0.0 # set before entering the tree, silence before the music starts
var _pre_roll_left := 0.0
var _segment: MapSegment = null
var _view: ModeView = null
var _checkpoint := ScoreKeeper.new() # checkpointed score
var _finished := false
var _relaxed := false # judge mode, see Difficulty
var previous_kind := -1 # set before entering the tree, the mode the run was last in, -1 for none
var _switches: Array[MapSegment] = [] # segments that change mode, each held for before it starts
var _segment_score := ScoreKeeper.new() # just the segment being played
var _holding: MapSegment = null
var _hold_left := 0.0

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
	_demo.hitsound = hitsound
	var kind := previous_kind
	for segment in map.segments:
		if segment.kind != kind: _switches.append(segment)
		kind = segment.kind
	_pre_roll_left = pre_roll_s
	if _pre_roll_left <= 0.0: conductor.start(map)

func _process(delta: float) -> void:
	if _hold_for_switch(delta): return
	_count_down_pre_roll(delta)
	_hold_for_next_note()
	var now := time()
	var segment := map.segment_at(now)
	if segment != _segment:
		_report_segment()
		_switch_to(segment)
	if segment == null: _finish()

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
	_segment_score = ScoreKeeper.new()
	var view_scene: PackedScene = segment.view if segment.view != null else DEFAULT_VIEWS[segment.kind]
	_view = view_scene.instantiate()
	_handler(segment.kind).begin(segment, _view)
	_views.add_child(_view)
	var hand_pos := Modality.hand_pos(segment.kind)
	cursor.enabled = hand_pos == Modality.HandPos.A
	hud.set_hand_pos(hand_pos)
	hud.set_tutorial(segment.tutorial)

# --- Mode Switches ---
# the game stops before a new mode and the demo card shows it, the tutorial waits for space, otherwise it moves on after SWITCH_HOLD_S
func _hold_for_switch(delta: float) -> bool:
	if _holding == null:
		if _switches.is_empty(): return false
		var next := _switches[0]
		var first := next == map.segments[0]
		if not first and time() < next.start_time - SWITCH_LEAD_S: return false
		_switches.pop_front()
		_holding = next
		_hold_left = SWITCH_HOLD_S
		conductor.stream_paused = true
		_demo.play(next.kind)
	var waits := GameConfig.tutorial_enabled and not Difficulty.autoplays(GameConfig.difficulty)
	_hold_left -= delta
	_demo.set_footer("press space to continue" if waits else "starting in %d" % ceili(maxf(_hold_left, 0.0)))
	if waits and not Input.is_action_just_pressed(&"skip_cutscene"): return true
	if not waits and _hold_left > 0.0: return true
	_release_switch()
	return false

func _release_switch() -> void:
	if _holding == null: return
	_holding = null
	conductor.stream_paused = false
	_demo.hide()

func last_kind() -> int: return map.segments.back().kind if not map.segments.is_empty() else previous_kind

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

# tutorial segments and ones nothing was judged in pass without a word
func _report_segment() -> void:
	if _segment == null or _segment.tutorial or _segment_score.count_judged() == 0: return
	segment_done.emit(_segment_score.accuracy())

func _finish() -> void:
	if _finished: return
	_finished = true
	finished.emit()

# --- Seeking ---
func _seek(time: float) -> void:
	_release_switch()
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
	if _relaxed and result.is_miss(): # judge mode never drops combo
		if result.tick: result = HitResult.slider_tick(result.note, true)
		else: result = HitResult.new(result.note, Judgement.Grade.MEH)
	if not result.tick: hud.show_judgement(result)
	_segment_score.add(result)
	var volume := 1.0 if Difficulty.autoplays(GameConfig.difficulty) else GameConfig.hitsound_volume # autoplay is for hearing the map
	if result.tick: volume *= TICK_VOLUME
	if not result.is_miss() and volume > 0.0: _play(hitsound, volume)
	if _segment.tutorial or _segment.unscored: return
	if result.is_miss() and score.combo >= COMBO_BREAK_MIN: _play(combo_break)
	score.add(result)
	hud.show_score(score)

func _play(sound: AudioStream, volume := 1.0) -> void:
	if sound != null: (_hitsounds.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(sound, 0, linear_to_db(volume))
