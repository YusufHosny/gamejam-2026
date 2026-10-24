class_name SfxUtils
extends RefCounted

# placeholder synthesized audio until we have real assets
const MIX_RATE := 22050

static func hitsound() -> AudioStreamWAV:
	return _wav(_blip(1320.0, 0.05, 0.35))

static func metronome(bpm: float, beats: int, beats_per_bar := 4, loop := false) -> AudioStreamWAV:
	var accent := _blip(1760.0, 0.04, 0.5)
	var tick := _blip(880.0, 0.04, 0.35)
	var data := PackedByteArray()
	for beat in beats:
		var click := accent if beat % beats_per_bar == 0 else tick
		# place each beat from its absolute time so rounding never drifts
		var beat_end := int((beat + 1) * 60.0 / bpm * MIX_RATE) * 2
		var gap := PackedByteArray()
		gap.resize(maxi(beat_end - data.size() - click.size(), 0))
		gap.fill(0)
		data.append_array(click)
		data.append_array(gap)
	var wav := _wav(data)
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = data.size() / 2
	return wav

# one beep of a two tone square warble
static func alarm(duration := 0.3, volume := 0.25) -> AudioStreamWAV:
	var samples := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in samples:
		var freq := 1400.0 if fmod(float(i) / MIX_RATE, 0.1) < 0.05 else 1050.0
		phase = fmod(phase + freq / MIX_RATE, 1.0) # accumulated so tone switches don't click
		var envelope := minf(1.0, (samples - i) / (0.01 * MIX_RATE)) # short fade out
		var sample := (1.0 if phase < 0.5 else -1.0) * envelope * volume
		data.encode_s16(i * 2, int(sample * 32767))
	return _wav(data)

# decaying sine, 16 bit mono
static func _blip(freq: float, duration: float, volume: float) -> PackedByteArray:
	var samples := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var envelope := pow(1.0 - float(i) / samples, 2)
		var sample := sin(TAU * freq * i / MIX_RATE) * envelope * volume
		data.encode_s16(i * 2, int(sample * 32767))
	return data

static func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
