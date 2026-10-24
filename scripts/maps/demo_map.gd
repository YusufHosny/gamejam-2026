class_name DemoMap
extends RefCounted

const ORDER := [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D, Modality.Kind.SLASH]
const PLAYFIELD := Rect2(176, 120, 800, 400)
const MAX_JUMP := 260.0
const SLIDER_CHANCE := 0.35
const SLIDER_BEATS: Array[float] = [1.0, 2.0]
const SLIDER_POINTS := 12
const MAX_REPEATS := 2
const COMBO_SIZE := 4
const MAX_BEND := 120.0
const FAST_BPM := 140.0 # above this notes land every other beat

static func build(rng_seed := GameConfig.map_seed) -> Map:
	var map := Map.new()
	map.bpm = GameConfig.bpm
	var bars: Array[int] = []
	bars.assign(ORDER.map(func(_k): return GameConfig.segment_bars))
	return _filled(map, ORDER, bars, rng_seed)

# one placeholder segment per kind, each about segment_s long, on the song's grid
# song null -> metronome at GameConfig.bpm
static func section(song: Song, kinds: Array, segment_s: Array[float], rng_seed := GameConfig.map_seed) -> Map:
	var map := Map.new()
	map.bpm = GameConfig.bpm
	if song != null: song.apply_to(map)
	var bar_s := map.beat_time(map.beats_per_bar)
	var bars: Array[int] = []
	bars.assign(segment_s.map(func(s: float): return maxi(roundi(s / bar_s), 1)))
	map = _filled(map, kinds, bars, rng_seed)
	if song != null: assert(song.fits(map), "%s is shorter than its map" % song.resource_path)
	return map

static func _filled(map: Map, kinds: Array, bars: Array[int], rng_seed: int) -> Map:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var step := 2.0 if map.bpm > FAST_BPM else 1.0
	var beat := 0.0
	for i in kinds.size():
		beat += GameConfig.cooldown_bars * map.beats_per_bar
		var segment := MapSegment.new(kinds[i], beat, beat + bars[i] * map.beats_per_bar)
		segment.notes = _notes(segment, step, rng)
		map.segments.append(segment)
		beat = segment.end_beat
	map.bake()
	return map

static func _notes(segment: MapSegment, step: float, rng: RandomNumberGenerator) -> Array[Note]:
	match segment.kind:
		Modality.Kind.FOUR_D: return _lane_notes(segment, step, rng)
		Modality.Kind.AIM_CLICK, Modality.Kind.SLASH: return _aim_notes(segment, step, rng)
	assert(false, "unhandled modality %s" % segment.kind)
	return []

static func _lane_notes(segment: MapSegment, step: float, rng: RandomNumberGenerator) -> Array[Note]:
	var notes: Array[Note] = []
	var beat := segment.start_beat
	while beat < segment.end_beat:
		notes.append(LaneNote.new(beat, rng.randi_range(0, 3)))
		beat += step * (0.5 if rng.randf() < 0.3 else 1.0)
	return notes

static func _aim_notes(segment: MapSegment, step: float, rng: RandomNumberGenerator) -> Array[Note]:
	var with_sliders := segment.kind == Modality.Kind.AIM_CLICK
	var notes: Array[Note] = []
	var position := PLAYFIELD.get_center()
	var beat := segment.start_beat
	while beat < segment.end_beat:
		position = _jump(position, rng)
		var note: AimNote = _slider(segment, beat, position, step, rng) if with_sliders and rng.randf() < SLIDER_CHANCE else null
		if note == null: note = AimNote.new(beat, position)
		note.new_combo = notes.size() % COMBO_SIZE == 0
		notes.append(note)
		if note is SliderNote:
			var slider := note as SliderNote
			position = slider.ball_at(1.0)
			beat = slider.end_beat() + step
		else:
			beat += step
	return notes

# null when it would run past the segment
static func _slider(segment: MapSegment, beat: float, position: Vector2, step: float, rng: RandomNumberGenerator) -> SliderNote:
	var length: float = SLIDER_BEATS[rng.randi() % SLIDER_BEATS.size()] * step
	var repeats := rng.randi_range(0, MAX_REPEATS) if length <= step else 0
	var slider := SliderNote.new(beat, position, _curve(position, rng), length, repeats)
	return slider if slider.end_beat() < segment.end_beat else null

# quadratic bezier from a point to a random jump away, bent sideways
static func _curve(from: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var to := _jump(from, rng)
	var bend := (to - from).orthogonal().normalized() * rng.randf_range(-MAX_BEND, MAX_BEND)
	var control := from.lerp(to, 0.5) + bend
	var path := PackedVector2Array()
	for i in range(1, SLIDER_POINTS + 1):
		var t := float(i) / SLIDER_POINTS
		path.append(from.lerp(control, t).lerp(control.lerp(to, t), t).clamp(PLAYFIELD.position, PLAYFIELD.end))
	return path

static func _jump(from: Vector2, rng: RandomNumberGenerator) -> Vector2:
	var offset := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(MAX_JUMP * 0.4, MAX_JUMP)
	return (from + offset).clamp(PLAYFIELD.position, PLAYFIELD.end)
