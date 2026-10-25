class_name EasyMaps
extends RefCounted

# the standard map set: the hard maps thinned so no two notes come closer than MIN_GAP_S, so streams, jacks, doubles and chords drop to one a beat or so.
# the aim sections get their own slow, slider heavy versions first, see the map builders

const MIN_GAP_S := 0.33

static func thin(map: Map) -> void:
	for segment in map.segments:
		if not segment.unscored: segment.notes = spaced(segment.notes, MIN_GAP_S, true) # struggle sections stay as they are

# drops notes that start less than `gap` after the last kept one ends, in seconds or beats. a dropped combo start passes to the next kept note
static func spaced(notes: Array[Note], gap: float, in_seconds := false) -> Array[Note]:
	var kept: Array[Note] = []
	var free_at := -INF
	var combo := false
	for note in notes:
		var aim := note as AimNote
		var at := note.time if in_seconds else note.beat
		if at - free_at < gap:
			if aim != null and aim.new_combo: combo = true
			continue
		if aim != null and combo: aim.new_combo = true
		combo = false
		kept.append(note)
		var slider := note as SliderNote
		free_at = at if slider == null else (slider.end_time if in_seconds else slider.end_beat())
	return kept
