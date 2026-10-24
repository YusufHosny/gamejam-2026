class_name Game
extends Node2D

const DEBUG_SEEKS: Dictionary[StringName, Modality.Kind] = {
	&"debug_four_d": Modality.Kind.FOUR_D,
	&"debug_aim_click": Modality.Kind.AIM_CLICK,
	&"debug_slash": Modality.Kind.SLASH,
	&"debug_typing": Modality.Kind.TYPING,
}
const DEFAULT_VIEWS := {
	Modality.Kind.FOUR_D: preload("res://scenes/views/circle_four_d_view.tscn"),
	Modality.Kind.AIM_CLICK: preload("res://scenes/views/circle_aim_click_view.tscn"),
	Modality.Kind.SLASH: preload("res://scenes/views/circle_slash_view.tscn"),
	Modality.Kind.TYPING: preload("res://scenes/views/text_typing_view.tscn"),
}

@onready var conductor: Conductor = $Conductor
@onready var hud: Hud = $Hud
@onready var cursor: VirtualCursor = $Cursor
@onready var _views: Node2D = $Views
@onready var _hitsounds: AudioStreamPlayer = $Hitsounds
@onready var _four_d: FourDMode = $Modes/FourD
@onready var _aim_click: AimClickMode = $Modes/AimClick
@onready var _slash: SlashMode = $Modes/Slash
@onready var _typing: TypingMode = $Modes/Typing

var chart: Chart
var score := ScoreKeeper.new()
var _segment: ChartSegment = null
var _view: ModeView = null
var _hitsound := SfxUtils.hitsound()

func _ready() -> void:
	chart = DemoChart.build()
	_aim_click.cursor = cursor
	_slash.cursor = cursor
	for handler: ModeHandler in [_four_d, _aim_click, _slash, _typing]:
		handler.conductor = conductor
		handler.judged.connect(_on_judged)
	_hitsounds.stream = AudioStreamPolyphonic.new()
	_hitsounds.play()
	conductor.start(chart)

func _process(_delta: float) -> void:
	var now := conductor.song_time()
	var segment := chart.segment_at(now)
	if segment != _segment: _switch_to(segment)
	if segment != null and now < segment.start_time:
		hud.show_banner(Modality.hand_pos(segment.kind), fmod(chart.time_beat(now), 1.0) < 0.5)
	else:
		hud.hide_banner()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"): _restart()
	for action in DEBUG_SEEKS:
		if event.is_action_pressed(action): _seek_to_kind(DEBUG_SEEKS[action])

# --- Segments ---
func _switch_to(segment: ChartSegment) -> void:
	if _segment != null:
		_handler(_segment.kind).end()
		_view.queue_free()
		_view = null
	_segment = segment
	if segment == null:
		cursor.enabled = false
		return
	var view_scene: PackedScene = segment.view if segment.view != null else DEFAULT_VIEWS[segment.kind]
	_view = view_scene.instantiate()
	_handler(segment.kind).begin(segment, _view)
	_views.add_child(_view)
	var hand_pos := Modality.hand_pos(segment.kind)
	cursor.enabled = hand_pos == Modality.HandPos.A
	hud.set_hand_pos(hand_pos)

func _handler(kind: Modality.Kind) -> ModeHandler:
	match kind:
		Modality.Kind.FOUR_D: return _four_d
		Modality.Kind.AIM_CLICK: return _aim_click
		Modality.Kind.SLASH: return _slash
		Modality.Kind.TYPING: return _typing
	assert(false, "unhandled modality %s" % kind)
	return null

# --- Seeking ---
func _seek(time: float) -> void:
	_switch_to(null)
	conductor.play(maxf(time, 0.0))

func _restart() -> void:
	score = ScoreKeeper.new()
	hud.reset()
	_seek(0.0)

func _seek_to_kind(kind: Modality.Kind) -> void:
	var segment: ChartSegment = IterUtils.first(chart.segments, func(s: ChartSegment): return s.kind == kind)
	_seek(chart.beat_time(segment.start_beat - chart.beats_per_bar)) # one bar of lead in

# --- Scoring ---
func _on_judged(result: HitResult) -> void:
	score.add(result)
	hud.show_judgement(result, score)
	if not result.is_miss():
		(_hitsounds.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(_hitsound)
