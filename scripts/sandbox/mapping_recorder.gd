extends Node2D

# F6 to map by feel: play a stretch of a song, click / hold / press along, save the take as json for map building.
# R record, P play back the last take, enter save, tab aim <-> lanes, T metronome, G cycle guides

enum Mode { AIM, LANES }
enum Guide { NONE, CAPTCHA, PLAYFIELD, BOSS, ADS }

const TAKES_DIR := "res://mapping/takes"
const HOLD_MIN_S := 0.15 # shorter presses are taps, longer ones become sliders
const PATH_STEP := 6.0 # px between recorded slider points
const LEAD_BARS := 1
const MARKER_S := 1.2 # how long a recorded input stays drawn
const RADIUS := 48.0
const LANE_X: Array[float] = [-135.0, -45.0, 45.0, 135.0]
const LANE_Y := 520.0
const HITSOUND := preload("res://assets/skin/mobamba/normal-hitnormal.wav")
const BACKGROUND := Color(0.06, 0.06, 0.09)
const ACCENT := Color(1.0, 0.85, 0.2)

@export var song: Song = preload("res://assets/music/vivaldi_summer.tres")
@export var start_s := 0.0
@export var end_s := 30.0
@export var mode := Mode.AIM
@export var guide := Guide.CAPTCHA

var _map := Map.new()
var _conductor: Conductor
var _sounds: AudioStreamPlayer
var _tick := SfxUtils.metronome(120.0, 1, 4) # one click, played on each beat
var _metronome := true
var _recording := false
var _playing_back := false
var _take: Array[Dictionary] = [] # the last take, see _event
var _open: Dictionary = {} # input name -> event still held
var _last_beat := -INF
var _played: Dictionary = {} # playback: events already sounded
var _status := "R to record"

func _ready() -> void:
	song.apply_to(_map)
	_conductor = Conductor.new()
	add_child(_conductor)
	_sounds = AudioStreamPlayer.new()
	_sounds.stream = AudioStreamPolyphonic.new()
	add_child(_sounds)
	_sounds.play()

func _now() -> float: return _conductor.song_time()

# --- Controls ---
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	match key.physical_keycode:
		KEY_R: _start(true)
		KEY_P: _start(false)
		KEY_ENTER, KEY_KP_ENTER: _save()
		KEY_TAB: mode = Mode.LANES if mode == Mode.AIM else Mode.AIM
		KEY_T: _metronome = not _metronome
		KEY_G: guide = (guide + 1) % Guide.size() as Guide

func _start(record: bool) -> void:
	_recording = record
	_playing_back = not record
	if record: _take.clear()
	_open.clear()
	_played.clear()
	_conductor.start(_map)
	_conductor.seek_to(start_s - _map.beat_time(LEAD_BARS * _map.beats_per_bar))
	_status = "recording" if record else "playing back"

func _stop() -> void:
	_recording = false
	_playing_back = false
	_conductor.stop()
	_status = "%d inputs, enter to save, R to retake, P to play back" % _take.size()

# --- Recording ---
func _input(event: InputEvent) -> void:
	if not _recording: return
	var now := _now()
	for input: StringName in _open.keys():
		if event.is_action_released(input): _release(input, now)
	if mode == Mode.AIM:
		for action in AimClickMode.CLICKS:
			if event.is_action_pressed(action): _press(action, now, -1)
		if event is InputEventMouseMotion: _extend_paths()
	else:
		for lane in FourDMode.LANES.size():
			if event.is_action_pressed(FourDMode.LANES[lane]): _press(FourDMode.LANES[lane], now, lane)

func _press(input: StringName, now: float, lane: int) -> void:
	var at := get_global_mouse_position()
	var event := {"down_s": now, "up_s": now, "lane": lane, "at": at, "path": [at]}
	_open[input] = event
	_take.append(event)
	_play(HITSOUND)

func _release(input: StringName, now: float) -> void:
	if not _open.has(input): return
	_open[input].up_s = now
	_open.erase(input)

func _extend_paths() -> void:
	var at := get_global_mouse_position()
	for event: Dictionary in _open.values():
		var path: Array = event.path
		if at.distance_to(path.back()) >= PATH_STEP: path.append(at)

# --- Saving ---
# times are map times and beats are on the song's grid, the same ones map builders use
func _save() -> void:
	if _take.is_empty():
		_status = "nothing to save"
		return
	DirAccess.make_dir_recursive_absolute(TAKES_DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s_%d-%d_%s_%s.json" % [TAKES_DIR, song.resource_path.get_file().get_basename(), roundi(start_s), roundi(end_s), Mode.keys()[mode].to_lower(), stamp]
	var take := {
		"song": song.resource_path, "bpm": song.bpm, "first_beat_s": song.first_beat_s, "beats_per_bar": song.beats_per_bar,
		"start_s": start_s, "end_s": end_s, "mode": Mode.keys()[mode].to_lower(),
		"inputs": _take.map(_describe),
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(take, "\t"))
	_status = "saved %s" % path
	print(_status)

func _describe(event: Dictionary) -> Dictionary:
	var down: float = event.down_s
	var up: float = event.up_s
	var held := up - down >= HOLD_MIN_S
	var out := {
		"kind": "hold" if held else "tap",
		"down_s": snappedf(down, 0.001), "beat": snappedf(_map.time_beat(down), 0.001),
		"beat_quarter": snappedf(_map.time_beat(down), 0.25), "beat_half": snappedf(_map.time_beat(down), 0.5),
		"at": [roundi(event.at.x), roundi(event.at.y)],
	}
	if event.lane >= 0: out.lane = event.lane
	if held:
		out.up_s = snappedf(up, 0.001)
		out.length_beats = snappedf(_map.time_beat(up) - _map.time_beat(down), 0.001)
		if event.lane < 0: out.path = event.path.map(func(p: Vector2): return [roundi(p.x), roundi(p.y)])
	return out

# --- Playback and feedback ---
func _process(_delta: float) -> void:
	queue_redraw()
	if not (_recording or _playing_back): return
	var now := _now()
	if now > end_s:
		_stop()
		return
	var beat := floorf(_map.time_beat(now))
	if _metronome and beat != _last_beat: _play(_tick)
	_last_beat = beat
	if _playing_back:
		for event in _take:
			if event.down_s <= now and not _played.has(event):
				_played[event] = true
				_play(HITSOUND)

func _play(stream: AudioStream) -> void:
	(_sounds.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(stream)

func _draw() -> void:
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), BACKGROUND)
	_draw_guide()
	var now := _now()
	var live := _recording or _playing_back
	if mode == Mode.LANES: _draw_lanes(now)
	for event in _take:
		var age: float = now - event.down_s
		var approach := GameConfig.approach_time_s
		if mode == Mode.LANES or age > MARKER_S + (event.up_s - event.down_s) or (_playing_back and age < -approach): continue
		if _recording and age < 0: continue
		var alpha := 1.0 - clampf((age - (event.up_s - event.down_s)) / MARKER_S, 0.0, 1.0)
		if event.path.size() > 1: draw_polyline(PackedVector2Array(event.path), Color(ACCENT, 0.5 * alpha), RADIUS, true)
		draw_arc(event.at, RADIUS, 0, TAU, 48, Color(ACCENT, alpha), 3, true)
		if age < 0: draw_arc(event.at, RADIUS * (1.0 - 2.0 * age / approach), 0, TAU, 48, Color(1, 1, 1, 1.0 + age / approach), 2, true)
	var beat := _map.time_beat(now) if live else 0.0
	var flash := 1.0 - fposmod(beat, 1.0) if live else 0.0
	draw_circle(Vector2(screen.x - 40, 40), 14 + 8 * flash, Color(1, 1, 1, 0.2 + 0.6 * flash), true, -1, true)
	var font := ThemeDB.fallback_font
	var lines := [
		"%s  %.0f-%.0f s  [%s]  %s" % [song.resource_path.get_file().get_basename(), start_s, end_s, Mode.keys()[mode].to_lower(), _status],
		"t %.2f  bar %d beat %.2f" % [now, floori(beat / _map.beats_per_bar) + 1, fposmod(beat, _map.beats_per_bar) + 1] if live else "",
		"R record  P play back  enter save  tab aim/lanes  T metronome %s  G guide %s" % ["on" if _metronome else "off", Guide.keys()[guide].to_lower()],
	]
	for i in lines.size(): draw_string(font, Vector2(16, 28 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))

func _draw_lanes(now: float) -> void:
	for lane in LANE_X.size():
		var at := Vector2(get_viewport_rect().size.x / 2 + LANE_X[lane], LANE_Y)
		var lit := 0.0
		for event in _take:
			if event.lane == lane and now >= event.down_s - 0.02 and now <= maxf(event.up_s, event.down_s + 0.12): lit = 1.0
		draw_circle(at, 34, Color(LaneColumn.COLORS[lane], 0.2 + 0.7 * lit), true, -1, true)
		draw_arc(at, 34, 0, TAU, 40, Color.WHITE, 2, true)

# where each kind of section draws its notes, so taken positions land in the right place
func _draw_guide() -> void:
	var area := Rect2()
	match guide:
		Guide.NONE: return
		Guide.CAPTCHA: area = CaptchaFrame.content()
		Guide.PLAYFIELD: area = DemoMap.PLAYFIELD
		Guide.BOSS: area = BossMaps.CHASE_AREA
		Guide.ADS: area = CaptchaMaps.ADS_AREA
	draw_rect(area, Color(1, 1, 1, 0.25), false, 2)
	draw_string(ThemeDB.fallback_font, area.position + Vector2(6, -6), Guide.keys()[guide].to_lower(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.4))
