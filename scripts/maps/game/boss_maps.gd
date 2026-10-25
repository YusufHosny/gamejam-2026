class_name BossMaps
extends RefCounted

const CHASE_VIEW := preload("res://scenes/views/boss/boss_chase_view.tscn")
const FINAL_VIEW := preload("res://scenes/views/boss/boss_final_view.tscn")
const SHIELD_VIEW := preload("res://scenes/views/boss/shield_break_view.tscn")
const LASER_VIEW := preload("res://scenes/views/boss/laser_defend_view.tscn")
const CHASE_AREA := Rect2(280, 170, 600, 300) # button centres, clear of the hud
const CHASE_START := Vector2(580, 320) # CHASE_AREA's centre, the first note's there so the dodge cutscene can end on it
const JUMP := 170.0
const STREAM_SPACING := 46.0
const STREAM_CHANCE := 0.5
const STREAM_BEND := 0.35 # radians per note, streams curve
const STREAM_NOTES := Vector2i(5, 8)
const MAX_SAME_LANE := 2

# jumps across the arena, the final chase mixes in streams at twice the note rate
static func fill_chase(segment: MapSegment, map: Map, streams := false, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var notes: Array[Note] = []
	var at := CHASE_START
	var beat := segment.start_beat
	notes.append(FillUtils.aim_note(beat, at, 0))
	beat += step
	while beat < segment.end_beat:
		if streams and rng.randf() < STREAM_CHANCE:
			var angle := rng.randf() * TAU
			var bend := rng.randf_range(-STREAM_BEND, STREAM_BEND)
			for i in rng.randi_range(STREAM_NOTES.x, STREAM_NOTES.y):
				if beat >= segment.end_beat: break
				var next := at + Vector2.from_angle(angle) * STREAM_SPACING
				if not CHASE_AREA.has_point(next): angle += PI # bounce off the edge
				at = (at + Vector2.from_angle(angle) * STREAM_SPACING).clamp(CHASE_AREA.position, CHASE_AREA.end)
				angle += bend
				notes.append(FillUtils.aim_note(beat, at, notes.size()))
				beat += step / 2
			beat += step / 2 # a breath after the stream
			continue
		var target := at
		while target.distance_to(at) < JUMP:
			target = CHASE_AREA.position + Vector2(rng.randf(), rng.randf()) * CHASE_AREA.size
		at = target
		notes.append(FillUtils.aim_note(beat, at, notes.size()))
		beat += step
	segment.notes = notes
	segment.view = FINAL_VIEW if streams else CHASE_VIEW

# shields cycle the slots around the button, never the same slot twice in a row
static func fill_shields(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var notes: Array[Note] = []
	var last := -1
	var beat := segment.start_beat
	while beat < segment.end_beat:
		var slot := last
		while slot == last: slot = rng.randi_range(0, ShieldBreakView.SLOTS.size() - 1)
		last = slot
		notes.append(FillUtils.aim_note(beat, ShieldBreakView.slot(slot), notes.size()))
		beat += step
	segment.notes = notes
	segment.view = SHIELD_VIEW

# one laser a step from a random side, never three in a row from the same one
static func fill_lasers(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var notes: Array[Note] = []
	var run: Array[int] = []
	var beat := segment.start_beat
	while beat < segment.end_beat:
		var lane := rng.randi_range(0, 3)
		while run.size() >= MAX_SAME_LANE and run.slice(-MAX_SAME_LANE).all(func(l: int): return l == lane):
			lane = rng.randi_range(0, 3)
		run.append(lane)
		notes.append(LaneNote.new(beat, lane))
		beat += step
	segment.notes = notes
	segment.view = LASER_VIEW
