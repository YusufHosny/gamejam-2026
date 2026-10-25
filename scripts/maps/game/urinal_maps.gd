class_name UrinalMaps
extends RefCounted

# the finale after the credits: pick the urinal furthest from everyone on the beat, then they're all taken and you slash the guys away

const PICK_VIEW := preload("res://scenes/views/finale/urinal_pick_view.tscn")
const SLASH_VIEW := preload("res://scenes/views/finale/urinal_slash_view.tscn")
const COUNT := 6
const ROW_Y := 380.0
const ROW_LEFT := 236.0
const ROW_STEP := 136.0
# [taken urinals, the one furthest from all of them], every answer unique
const PICKS := [
	[[0], 5], [[5], 0], [[2], 5], [[3], 0], [[0, 4], 2], [[1, 5], 3],
	[[0, 3], 5], [[2, 5], 0], [[1, 3], 5], [[0, 1, 5], 3], [[0, 4, 5], 2], [[2, 3, 4], 0],
]
const PICK_EVERY := 4.0 # beats between picks
const SLASH_ORDER: Array[int] = [0, 5, 1, 4, 2, 3] # outside in
const SLASH_EVERY := 2.0

static func urinal(index: int) -> Vector2: return Vector2(ROW_LEFT + index * ROW_STEP, ROW_Y)

static func fill_picks(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for i in PICKS.size(): notes.append(FillUtils.aim_note(segment.start_beat + i * PICK_EVERY, urinal(PICKS[i][1]), i))
	segment.notes = notes
	segment.view = PICK_VIEW

static func fill_slashes(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for i in SLASH_ORDER.size(): notes.append(FillUtils.aim_note(segment.start_beat + i * SLASH_EVERY, urinal(SLASH_ORDER[i]), i))
	segment.notes = notes
	segment.view = SLASH_VIEW
