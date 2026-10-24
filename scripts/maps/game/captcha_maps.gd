class_name CaptchaMaps
extends RefCounted

const DOG_VIEW := preload("res://scenes/views/captcha/dog_captcha_view.tscn")
const ALIGN_VIEW := preload("res://scenes/views/captcha/align_captcha_view.tscn")
const FRUIT_VIEW := preload("res://scenes/views/captcha/fruit_captcha_view.tscn")
const SELECTED_S := 0.4
const COMBO_SIZE := 4
const MAX_START := Vector2i(4, 3) # furthest the puzzle piece starts from its hole, in nudges
const FRUIT_MARGIN := 60.0
const FRUIT_SPACING := 100.0

# notes hop between tiles, never onto one still showing or ticking its last dog
static func fill_dogs(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := _rng(rng_seed)
	var step := _step(map)
	var busy_beats := map.time_beat(GameConfig.approach_time_s + SELECTED_S)
	var free_from: Array[float] = []
	free_from.resize(9)
	free_from.fill(-INF)
	var notes: Array[Note] = []
	var beat := segment.start_beat
	while beat < segment.end_beat:
		var free := range(9).filter(func(t: int): return free_from[t] <= beat)
		var tile: int = free[rng.randi() % free.size()]
		free_from[tile] = beat + busy_beats
		notes.append(_aim_note(beat, DogCaptchaView.tile_rect(tile).get_center(), notes.size()))
		beat += step
	segment.notes = notes
	segment.view = DOG_VIEW

# the moves that undo a random start offset, padded with opposite pairs and shuffled
static func fill_align(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := _rng(rng_seed)
	var step := _step(map)
	var count := int((segment.end_beat - segment.start_beat) / step)
	var net := Vector2i(rng.randi_range(2, MAX_START.x) * _sign(rng), rng.randi_range(1, MAX_START.y) * _sign(rng))
	var lanes: Array[int] = []
	for i in absi(net.x): lanes.append(3 if net.x > 0 else 0)
	for i in absi(net.y): lanes.append(1 if net.y > 0 else 2)
	if (count - lanes.size()) % 2 == 1: count -= 1
	while lanes.size() < count: lanes.append_array([0, 3] if rng.randf() < 0.5 else [1, 2])
	for i in range(lanes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := lanes[i]
		lanes[i] = lanes[j]
		lanes[j] = swap
	var notes: Array[Note] = []
	for i in lanes.size(): notes.append(LaneNote.new(segment.start_beat + i * step, lanes[i]))
	segment.notes = notes
	segment.view = ALIGN_VIEW

# apex points spread over the board, never right on top of the last one
static func fill_fruit(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := _rng(rng_seed)
	var step := _step(map)
	var board := CaptchaFrame.content().grow(-FRUIT_MARGIN)
	var notes: Array[Note] = []
	var last := board.get_center()
	var beat := segment.start_beat
	while beat < segment.end_beat:
		var at := last
		while at.distance_to(last) < FRUIT_SPACING:
			at = board.position + Vector2(rng.randf(), rng.randf()) * board.size
		notes.append(_aim_note(beat, at, notes.size()))
		last = at
		beat += step
	segment.notes = notes
	segment.view = FRUIT_VIEW

static func _aim_note(beat: float, position: Vector2, index: int) -> AimNote:
	var note := AimNote.new(beat, position)
	note.new_combo = index % COMBO_SIZE == 0
	return note

static func _rng(rng_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng

static func _step(map: Map) -> float: return 2.0 if map.bpm > DemoMap.FAST_BPM else 1.0

static func _sign(rng: RandomNumberGenerator) -> int: return 1 if rng.randf() < 0.5 else -1
