class_name Map
extends Resource

@export var bpm := 120.0
@export var beats_per_bar := 4
@export var segments: Array[MapSegment] = [] # sorted, non-overlapping
@export var music: AudioStream # null -> generated metronome
@export var first_beat_s := 0.0 # where beat 0 falls in the music

func beat_time(beat: float) -> float: return beat * 60.0 / bpm
func time_beat(time: float) -> float: return time * bpm / 60.0

func length_beats() -> float:
	if segments.is_empty(): return 0.0
	return segments.back().end_beat

func duration_s() -> float: return beat_time(length_beats())

func waits() -> bool: return segments.any(func(s: MapSegment): return s.wait_for_input)

func bake() -> void:
	for segment in segments:
		segment.start_time = beat_time(segment.start_beat)
		segment.end_time = beat_time(segment.end_beat)
		for note in segment.notes: note.bake(self)

# the segment being played, or prepared for during its cooldown. null once the map is over
func segment_at(time: float) -> MapSegment:
	return IterUtils.first(
		segments,
		func(s: MapSegment): return time <= s.end_time + GameConfig.miss_window_s()
	)
