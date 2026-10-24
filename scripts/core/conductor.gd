class_name Conductor
extends AudioStreamPlayer

var _latency_s := 0.0
var _time := 0.0

func start(chart: Chart) -> void:
	var beats := ceili(chart.length_beats()) + chart.beats_per_bar
	stream = SfxUtils.metronome(chart.bpm, beats, chart.beats_per_bar)
	_latency_s = AudioServer.get_output_latency() # expensive, so cached
	play()

# audio clock, not frame time. holds its last value while paused or stopped
func song_time() -> float:
	if playing and can_process():
		_time = (
			get_playback_position()
			+ AudioServer.get_time_since_last_mix()
			- _latency_s
			- GameConfig.audio_offset_ms / 1000.0
		)
	return _time
