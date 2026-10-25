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

# filtered noise swelling in and out, its brightness following the swell. low is longer and darker
static func whoosh(duration := 0.45, low := false, volume := 0.5) -> AudioStreamWAV:
	var samples := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var bright := Vector2(150.0, 900.0) if low else Vector2(400.0, 3000.0) # cutoff at the ends and at the peak, Hz
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var filtered := 0.0
	for i in samples:
		var t := float(i) / samples
		var swell := pow(sin(PI * pow(t, 0.7)), 2) # peaks a little before the middle
		var cutoff := lerpf(bright.x, bright.y, swell)
		filtered += (rng.randf_range(-1.0, 1.0) - filtered) * (1.0 - exp(-TAU * cutoff / MIX_RATE)) # one pole low pass
		data.encode_s16(i * 2, int(clampf(filtered * swell * volume * 2.5, -1.0, 1.0) * 32767))
	return _wav(data)

# a tone climbing in pitch with a tremble that speeds up and noise creeping in, louder to the end, for a build up
static func charge(duration := 2.5, volume := 0.3) -> AudioStreamWAV:
	var samples := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var phase := 0.0
	var wobble := 0.0
	for i in samples:
		var t := float(i) / samples
		phase = fmod(phase + 180.0 * pow(8.0, t) / MIX_RATE, 1.0) # 180 Hz to 1440 Hz, exponential so it sounds even
		wobble = fmod(wobble + lerpf(6.0, 32.0, t) / MIX_RATE, 1.0)
		var tone := sin(TAU * phase) * (0.75 + 0.25 * sin(TAU * wobble))
		var sample := (tone + rng.randf_range(-1.0, 1.0) * 0.35 * t) * lerpf(0.15, 1.0, t * t) * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767))
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
