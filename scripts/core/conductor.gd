class_name Conductor
extends AudioStreamPlayer

var _latency_s := 0.0
var _first_beat_s := 0.0
var _beat_s := 0.5
var _loop_s := 0.0 # 0 when the stream plays once
var _loops := 0
var _last_position := 0.0
var _hold_at := INF
var _held_s := 0.0 # audio time spent frozen by holds
var _min_held_s := 0.0 # keeps a moved hold frozen until the next beat
var _time := 0.0

func start(map: Map) -> void:
	_beat_s = map.beat_time(1.0)
	_first_beat_s = 0.0
	_loop_s = 0.0
	if map.music != null:
		stream = map.music
		_first_beat_s = map.first_beat_s
	elif map.waits():
		stream = SfxUtils.metronome(map.bpm, map.beats_per_bar, map.beats_per_bar, true)
		_loop_s = map.beat_time(map.beats_per_bar)
	else:
		stream = SfxUtils.metronome(map.bpm, ceili(map.length_beats()) + map.beats_per_bar, map.beats_per_bar)
	_latency_s = AudioServer.get_output_latency() # expensive, so cached
	seek_to(0.0)

func seek_to(time: float) -> void:
	_hold_at = INF
	_held_s = 0.0
	_min_held_s = 0.0
	var position := maxf(time + _first_beat_s, 0.0)
	_loops = floori(position / _loop_s) if _loop_s > 0 else 0
	_last_position = position - _loops * _loop_s
	play(_last_position)
	_time = time

# the clock won't pass `time` until moved
func hold_at(time: float) -> void:
	if time == _hold_at: return
	_min_held_s = ceilf(_held_s / _beat_s - 0.001) * _beat_s # resume on the metronome
	_hold_at = time

# audio clock not frame time
func song_time() -> float:
	if playing and can_process():
		var audio := _audio_time()
		_time = minf(audio - maxf(_held_s, _min_held_s), _hold_at)
		_held_s = audio - _time
	return _time

func _audio_time() -> float:
	var position := get_playback_position()
	if _loop_s > 0 and position < _last_position: _loops += 1
	_last_position = position
	return (
		_loops * _loop_s
		+ position
		+ AudioServer.get_time_since_last_mix()
		- _latency_s
		- GameConfig.audio_offset_ms / 1000.0
		- _first_beat_s
	)
