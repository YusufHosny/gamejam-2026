extends Node2D

# F6 to map by feel: play a stretch of a song, click / hold / press along, save the take as json for map building.
# R record, P play back the last take, enter save, tab cycles aim / lanes / slash, T metronome, G cycle guides, S cycle speed
# slash records a swipe each time the mouse crosses the middle of the screen
# K calibrate (tap 16 beats), [ ] nudge the offset, H hitsounds

enum Mode { AIM, LANES, SLASH }
enum Guide { NONE, CAPTCHA, PLAYFIELD, BOSS, ADS, SUBWAY, USB }

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
const SPEEDS: Array[float] = [1.0, 0.75, 0.5]
const SUBWAY_CLIP := preload("res://assets/captcha/subway/subway.ogv")
const RESYNC_S := 0.12
const USB_SHEET := preload("res://assets/usb_sheet.png")
const SLOW_BUS := &"Recorder"
const OFFSETS_FILE := "user://mapping_recorder.cfg"
const CALIBRATION_TAPS := 16
const NUDGE_MS := 5.0

@export var song: Song = preload("res://assets/music/vivaldi_summer.tres")
@export var start_s := 0.0
@export var end_s := 30.0
@export var mode := Mode.AIM
@export var guide := Guide.CAPTCHA
@export var speed := 1.0 # takes are saved in song time whatever the speed

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
var _last_mouse := Vector2.INF # slash mode, last frame's mouse and its time
var _last_mouse_s := 0.0
var _played: Dictionary = {} # playback: events already sounded
var _status := "R to record"
var _pitch_fix: AudioEffectPitchShift
var _offsets_ms: Dictionary = {} # speed -> audio offset, the slowed bus adds its own delay
var _calibrating := false
var _calibration: Array[float] = [] # tap minus nearest beat, song s
var _hitsounds := true
var _clip: VideoStreamPlayer # the subway guide, follows the audio clock like the game's view
var _usb: UsbAnimation = null # the usb guide, each press plays its next phase like a hit would

func _ready() -> void:
	song.apply_to(_map)
	_conductor = Conductor.new()
	add_child(_conductor)
	_conductor.bus = _slow_bus()
	_sounds = AudioStreamPlayer.new()
	_sounds.stream = AudioStreamPolyphonic.new()
	add_child(_sounds)
	_sounds.play()
	_add_clip()
	var config := ConfigFile.new()
	if config.load(OFFSETS_FILE) == OK:
		for key in config.get_section_keys("offsets_ms"): _offsets_ms[float(key)] = config.get_value("offsets_ms", key)

func _now() -> float: return _conductor.song_time()

# behind the recorder's own drawing, so takes draw over the clip
func _add_clip() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.size = get_viewport_rect().size
	background.show_behind_parent = true
	add_child(background)
	_clip = VideoStreamPlayer.new()
	_clip.stream = SUBWAY_CLIP
	_clip.expand = true
	_clip.position = CaptchaFrame.content().position
	_clip.size = CaptchaFrame.content().size
	_clip.show_behind_parent = true
	add_child(_clip)

# --- Controls ---
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	match key.physical_keycode:
		KEY_R: _start(true)
		KEY_P: _start(false)
		KEY_ENTER, KEY_KP_ENTER: _save()
		KEY_TAB: mode = (mode + 1) % Mode.size() as Mode
		KEY_T: _metronome = not _metronome
		KEY_G: guide = (guide + 1) % Guide.size() as Guide
		KEY_S: speed = SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()]
		KEY_K: _start_calibration()
		KEY_BRACKETLEFT: _set_offset(_offset_ms() - NUDGE_MS)
		KEY_BRACKETRIGHT: _set_offset(_offset_ms() + NUDGE_MS)
		KEY_H: _hitsounds = not _hitsounds

func _start(record: bool) -> void:
	_recording = record
	_playing_back = not record
	_calibrating = false
	_last_mouse = Vector2.INF
	if record: _take.clear()
	_open.clear()
	_played.clear()
	GameConfig.audio_offset_ms = _offset_ms()
	_conductor.pitch_scale = speed
	_pitch_fix.pitch_scale = 1.0 / speed
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(SLOW_BUS), 0, speed != 1.0)
	_conductor.start(_map)
	_conductor.seek_to(start_s - _map.beat_time(LEAD_BARS * _map.beats_per_bar))
	_clip.speed_scale = speed
	_clip.play()
	_reset_usb()
	_status = "recording" if record else "playing back"

# slowed music keeps its pitch, the hitsounds and metronome skip this bus
func _reset_usb() -> void:
	if _usb != null: _usb.queue_free()
	_usb = UsbAnimation.new()
	_usb.texture = USB_SHEET
	_usb.hframes = 10
	_usb.vframes = 16
	_usb.speed = 1.6
	_usb.texture_filter = TEXTURE_FILTER_LINEAR
	_usb.position = UsbView.CENTER
	_usb.scale = Vector2.ONE * UsbView.SCALE
	_usb.show_behind_parent = true
	add_child(_usb)

func _advance_usb() -> void:
	if _usb == null: return
	_usb.advance()

func _slow_bus() -> StringName:
	var index := AudioServer.get_bus_index(SLOW_BUS)
	if index == -1:
		index = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, SLOW_BUS)
		var pitch_fix := AudioEffectPitchShift.new()
		pitch_fix.fft_size = AudioEffectPitchShift.FFT_SIZE_1024 # less delay
		AudioServer.add_bus_effect(index, pitch_fix)
	_pitch_fix = AudioServer.get_bus_effect(index, 0)
	return SLOW_BUS

func _stop() -> void:
	_recording = false
	_playing_back = false
	_conductor.stop()
	_clip.stop()
	if _calibrating: _finish_calibration()
	else: _status = "%d inputs, enter to save, R to retake, P to play back" % _take.size()

# --- Calibration ---
# tap along to the music's beat, metronome off, the median lateness becomes the offset for this speed
func _start_calibration() -> void:
	_start(false)
	_playing_back = false
	_calibrating = true
	_calibration.clear()
	_status = "calibrating: tap every beat of the music (%d taps)" % CALIBRATION_TAPS

func _calibration_tap(now: float) -> void:
	_play(HITSOUND)
	if now < start_s: return # lead in
	_calibration.append(now - _map.beat_time(roundf(_map.time_beat(now))))
	if _calibration.size() >= CALIBRATION_TAPS: _stop()

func _finish_calibration() -> void:
	_calibrating = false
	if _calibration.size() < CALIBRATION_TAPS / 2:
		_status = "calibration needs more taps, K to retry"
		return
	_calibration.sort()
	_set_offset(_offset_ms() + _calibration[_calibration.size() / 2] / speed * 1000.0)
	_status = "calibrated, offset %d ms at %sx" % [roundi(_offset_ms()), speed]

func _offset_ms() -> float: return _offsets_ms.get(speed, GameConfig.audio_offset_ms) # the game's calibration until this speed has its own

func _set_offset(ms: float) -> void:
	_offsets_ms[speed] = ms
	GameConfig.audio_offset_ms = ms
	var config := ConfigFile.new()
	for key: float in _offsets_ms: config.set_value("offsets_ms", str(key), _offsets_ms[key])
	config.save(OFFSETS_FILE)

# --- Recording ---
func _input(event: InputEvent) -> void:
	if _calibrating:
		for action in AimClickMode.CLICKS + FourDMode.LANES:
			if event.is_action_pressed(action): _calibration_tap(_now())
		return
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
	_advance_usb()
	if _hitsounds: _play(HITSOUND)

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
		"start_s": start_s, "end_s": end_s, "mode": Mode.keys()[mode].to_lower(), "speed": speed,
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
	if event.has("dir"): out.dir = "right" if event.dir > 0 else "left"
	if held:
		out.up_s = snappedf(up, 0.001)
		out.length_beats = snappedf(_map.time_beat(up) - _map.time_beat(down), 0.001)
		if event.lane < 0: out.path = event.path.map(func(p: Vector2): return [roundi(p.x), roundi(p.y)])
	return out

# --- Playback and feedback ---
func _process(_delta: float) -> void:
	queue_redraw()
	_clip.visible = guide == Guide.SUBWAY
	if _usb != null: _usb.visible = guide == Guide.USB
	if _clip.is_playing() and absf(_clip.stream_position - _conductor.heard_position()) > RESYNC_S: _clip.stream_position = maxf(_conductor.heard_position(), 0.0)
	if not (_recording or _playing_back or _calibrating): return
	var now := _now()
	if now > end_s:
		_stop()
		return
	var heard_at := now + (AudioServer.get_output_latency() + _offset_ms() / 1000.0) * speed # a tick played now is heard then
	var beat := floorf(_map.time_beat(heard_at))
	if _metronome and not _calibrating and beat != _last_beat: _play(_tick)
	_last_beat = beat
	if _recording and mode == Mode.SLASH: _track_slash(now)
	if _playing_back:
		for event in _take:
			if event.down_s <= heard_at and not _played.has(event):
				_played[event] = true
				_advance_usb()
				_play(HITSOUND)

# a swipe is the moment the mouse crosses the middle, timed between the two frames either side
func _track_slash(now: float) -> void:
	var at := get_global_mouse_position()
	var middle := get_viewport_rect().size.x / 2
	if _last_mouse != Vector2.INF and signf(at.x - middle) != signf(_last_mouse.x - middle) and at.x != _last_mouse.x:
		var t := (middle - _last_mouse.x) / (at.x - _last_mouse.x)
		var crossed := _last_mouse.lerp(at, t)
		var event := {"down_s": lerpf(_last_mouse_s, now, t), "up_s": lerpf(_last_mouse_s, now, t), "lane": -1, "at": crossed, "path": [crossed], "dir": signf(at.x - _last_mouse.x)}
		_take.append(event)
		if _hitsounds: _play(HITSOUND)
	_last_mouse = at
	_last_mouse_s = now

func _play(stream: AudioStream) -> void:
	(_sounds.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(stream)

func _draw() -> void:
	var screen := get_viewport_rect().size
	_draw_guide()
	if mode == Mode.SLASH: draw_line(Vector2(screen.x / 2, 0), Vector2(screen.x / 2, screen.y), Color(ACCENT, 0.3), 2) # swipes count as they cross it
	var now := _now()
	var live := _recording or _playing_back or _calibrating
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
		"%s  %.0f-%.0f s  [%s]  %sx  offset %d ms  %s" % [song.resource_path.get_file().get_basename(), start_s, end_s, Mode.keys()[mode].to_lower(), speed, roundi(_offset_ms()), _status],
		"t %.2f  bar %d beat %.2f" % [now, floori(beat / _map.beats_per_bar) + 1, fposmod(beat, _map.beats_per_bar) + 1] if live else "",
		"R record  P play back  enter save  tab aim/lanes  T metronome %s  G guide %s  S speed  K calibrate  [ ] offset  H hitsounds %s" % ["on" if _metronome else "off", Guide.keys()[guide].to_lower(), "on" if _hitsounds else "off"],
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
		Guide.SUBWAY:
			area = CaptchaFrame.content()
			var runner := SubwayCaptchaView.runner() # click the side the runner moves to
			draw_line(runner - Vector2(12, 0), runner + Vector2(12, 0), ACCENT, 2)
			draw_line(runner - Vector2(0, 12), runner + Vector2(0, 12), ACCENT, 2)
	draw_rect(area, Color(1, 1, 1, 0.25), false, 2)
	draw_string(ThemeDB.fallback_font, area.position + Vector2(6, -6), Guide.keys()[guide].to_lower(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.4))
