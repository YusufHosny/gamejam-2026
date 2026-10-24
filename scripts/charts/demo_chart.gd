class_name DemoChart
extends RefCounted

# placeholder split until the tutorial storyboard lands
const TUTORIAL_ORDER := [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D]
const GAME_ORDER := [Modality.Kind.TYPING, Modality.Kind.SLASH]
const PLAYFIELD := Rect2(176, 120, 800, 400)
const MAX_JUMP := 260.0
const LETTER_BEATS := 0.5

static func build(with_tutorial := GameConfig.tutorial_enabled, rng_seed := GameConfig.chart_seed) -> Chart:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var chart := Chart.new()
	chart.bpm = GameConfig.bpm
	if with_tutorial: _append_segments(chart, TUTORIAL_ORDER, true, rng)
	_append_segments(chart, GAME_ORDER, false, rng)
	chart.bake()
	return chart

static func _append_segments(chart: Chart, kinds: Array, tutorial: bool, rng: RandomNumberGenerator) -> void:
	var beat := chart.length_beats()
	for kind: Modality.Kind in kinds:
		beat += GameConfig.cooldown_bars * chart.beats_per_bar
		var segment := ChartSegment.new(kind, beat, beat + GameConfig.segment_bars * chart.beats_per_bar)
		segment.tutorial = tutorial
		segment.notes = _notes(segment, rng)
		chart.segments.append(segment)
		beat = segment.end_beat

static func _notes(segment: ChartSegment, rng: RandomNumberGenerator) -> Array[Note]:
	match segment.kind:
		Modality.Kind.FOUR_D: return _lane_notes(segment, rng)
		Modality.Kind.AIM_CLICK, Modality.Kind.SLASH: return _aim_notes(segment, rng)
		Modality.Kind.TYPING: return _letter_notes(segment, rng)
	assert(false, "unhandled modality %s" % segment.kind)
	return []

static func _lane_notes(segment: ChartSegment, rng: RandomNumberGenerator) -> Array[Note]:
	var notes: Array[Note] = []
	var beat := segment.start_beat
	while beat < segment.end_beat:
		notes.append(LaneNote.new(beat, rng.randi_range(0, 3)))
		beat += 0.5 if rng.randf() < 0.3 else 1.0
	return notes

static func _aim_notes(segment: ChartSegment, rng: RandomNumberGenerator) -> Array[Note]:
	var notes: Array[Note] = []
	var position := PLAYFIELD.get_center()
	var beat := segment.start_beat
	while beat < segment.end_beat:
		position = _jump(position, rng)
		notes.append(AimNote.new(beat, position))
		beat += 1.0
	return notes

static func _letter_notes(segment: ChartSegment, rng: RandomNumberGenerator) -> Array[Note]:
	var notes: Array[Note] = []
	var beat := segment.start_beat
	while true:
		var word := WordList.random(rng)
		if beat + word.length() * LETTER_BEATS > segment.end_beat: break
		for i in word.length():
			notes.append(LetterNote.new(beat, word[i], i == 0 and not notes.is_empty()))
			beat += LETTER_BEATS
		beat += LETTER_BEATS # the space between words is a rest
	return notes

static func _jump(from: Vector2, rng: RandomNumberGenerator) -> Vector2:
	var offset := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(MAX_JUMP * 0.4, MAX_JUMP)
	return (from + offset).clamp(PLAYFIELD.position, PLAYFIELD.end)
