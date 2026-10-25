class_name TakeMaps
extends RefCounted

# turns a mapping recorder take (mapping/takes/*.json) into notes for a segment

const SNAP := 0.25 # beats
const MIN_SLIDER_BEATS := 0.5

static func load_take(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

# inputs inside the segment become notes on the beat grid: taps, holds as sliders, lanes as lane notes
static func fill(segment: MapSegment, take: Dictionary, snap := SNAP) -> void:
	var notes: Array[Note] = []
	for input: Dictionary in take.inputs:
		var beat := snappedf(input.beat, snap)
		if beat < segment.start_beat or beat >= segment.end_beat: continue
		notes.append(_note(input, beat, snap))
	for i in notes.size():
		if notes[i] is AimNote: (notes[i] as AimNote).new_combo = i % FillUtils.COMBO_SIZE == 0
	segment.notes = notes

static func _note(input: Dictionary, beat: float, snap: float) -> Note:
	if input.has("lane"): return LaneNote.new(beat, int(input.lane))
	var at := Vector2(input.at[0], input.at[1])
	var length := snappedf(input.get("length_beats", 0.0), snap)
	if input.kind == "hold" and input.has("path") and length >= MIN_SLIDER_BEATS:
		var path := PackedVector2Array()
		for point in input.path.slice(1): path.append(Vector2(point[0], point[1]))
		if not path.is_empty(): return SliderNote.new(beat, at, path, length)
	return AimNote.new(beat, at)
