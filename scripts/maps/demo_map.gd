class_name DemoMap
extends RefCounted

# placeholder split until the tutorial storyboard lands
const TUTORIAL_ORDER := [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D]
const GAME_ORDER := [Modality.Kind.SLASH]
const PLAYFIELD := Rect2(176, 120, 800, 400)
const MAX_JUMP := 260.0
const SLIDER_CHANCE := 0.35
const SLIDER_BEATS: Array[float] = [1.0, 2.0]
const SLIDER_POINTS := 12
const MAX_REPEATS := 2
const COMBO_SIZE := 4
const MAX_BEND := 120.0

static func build(with_tutorial := GameConfig.tutorial_enabled, rng_seed := GameConfig.map_seed) -> Map:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var map := Map.new()
	map.bpm = GameConfig.bpm
	if with_tutorial: _append_segments(map, TUTORIAL_ORDER, true, rng)
	_append_segments(map, GAME_ORDER, false, rng)
	map.bake()
	return map

static func _append_segments(map: Map, kinds: Array, tutorial: bool, rng: RandomNumberGenerator) -> void:
	var beat := map.length_beats()
	for kind: Modality.Kind in kinds:
		beat += GameConfig.cooldown_bars * map.beats_per_bar
		var segment := MapSegment.new(kind, beat, beat + GameConfig.segment_bars * map.beats_per_bar)
		segment.tutorial = tutorial
		segment.notes = _notes(segment, rng)
		map.segments.append(segment)
		beat = segment.end_beat

static func _notes(segment: MapSegment, rng: RandomNumberGenerator) -> Array[Note]:
	match segment.kind:
		Modality.Kind.FOUR_D: return _lane_notes(segment, rng)
		Modality.Kind.AIM_CLICK, Modality.Kind.SLASH: return _aim_notes(segment, rng)
	assert(false, "unhandled modality %s" % segment.kind)
	return []

static func _lane_notes(segment: MapSegment, rng: RandomNumberGenerator) -> Array[Note]:
	var notes: Array[Note] = []
	var beat := segment.start_beat
	while beat < segment.end_beat:
		notes.append(LaneNote.new(beat, rng.randi_range(0, 3)))
		beat += 0.5 if rng.randf() < 0.3 else 1.0
	return notes

static func _aim_notes(segment: MapSegment, rng: RandomNumberGenerator) -> Array[Note]:
	var with_sliders := segment.kind == Modality.Kind.AIM_CLICK
	var notes: Array[Note] = []
	var position := PLAYFIELD.get_center()
	var beat := segment.start_beat
	while beat < segment.end_beat:
		position = _jump(position, rng)
		var note: AimNote = _slider(segment, beat, position, rng) if with_sliders and rng.randf() < SLIDER_CHANCE else null
		if note == null: note = AimNote.new(beat, position)
		note.new_combo = notes.size() % COMBO_SIZE == 0
		notes.append(note)
		if note is SliderNote:
			var slider := note as SliderNote
			position = slider.ball_at(1.0)
			beat = slider.end_beat() + 1.0
		else:
			beat += 1.0
	return notes

# null when it would run past the segment
static func _slider(segment: MapSegment, beat: float, position: Vector2, rng: RandomNumberGenerator) -> SliderNote:
	var length: float = SLIDER_BEATS[rng.randi() % SLIDER_BEATS.size()]
	var repeats := rng.randi_range(0, MAX_REPEATS) if length <= 1.0 else 0
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
