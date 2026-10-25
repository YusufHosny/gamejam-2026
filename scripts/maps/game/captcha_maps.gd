class_name CaptchaMaps
extends RefCounted

const DOG_VIEW := preload("res://scenes/views/captcha/dog_captcha_view.tscn")
const ALIGN_VIEW := preload("res://scenes/views/captcha/align_captcha_view.tscn")
const FRUIT_VIEW := preload("res://scenes/views/captcha/fruit_captcha_view.tscn")
const SUBWAY_VIEW := preload("res://scenes/views/captcha/subway_captcha_view.tscn")
const ADS_VIEW := preload("res://scenes/views/ads/ads_view.tscn")
const ADS_AREA := Rect2(300, 150, 600, 330) # window centres, clear of the hud and desktop icons
const ADS_SPACING := 180.0
const ADS_DOUBLE_CHANCE := 0.2 # two ads on one beat, one swipe can get both
const SELECTED_S := 0.4
const MAX_START := Vector2i(4, 3) # furthest the puzzle piece starts from its hole, in nudges
const FRUIT_MARGIN := 60.0
const FRUIT_SPACING := 100.0
const SUBWAY_TAIL_BEATS := 0.75
const SUBWAY_MOVES := [ # [beat, direction], checked frame by frame against Yusuf's take, the clip's opening move at -0.75 plays before the music starts
	[0.75, Vector2.RIGHT], # 0.85s
	[4.25, Vector2.DOWN], # 2.60s
	[7.75, Vector2.LEFT], # 4.35s
	[10.0, Vector2.DOWN], # 5.48s
	[13.5, Vector2.RIGHT], # 7.23s
	[15.75, Vector2.LEFT], # 8.35s
	[16.75, Vector2.RIGHT], # 8.85s
	[20.75, Vector2.RIGHT], # 10.85s
	[24.5, Vector2.LEFT], # 12.73s
	[29.25, Vector2.RIGHT], # 15.10s
	[31.25, Vector2.LEFT], # 16.10s
	[32.75, Vector2.UP], # 16.85s
	[39.5, Vector2.RIGHT], # 20.23s
	[41.5, Vector2.UP], # 21.23s
	[43.75, Vector2.LEFT], # 22.35s
	[46.0, Vector2.UP], # 23.48s
	[47.5, Vector2.UP], # 24.23s
	[51.75, Vector2.UP], # 26.35s
	[53.5, Vector2.LEFT], # 27.23s
	[57.25, Vector2.RIGHT], # 29.10s
]

# c1 on vivaldi, from Yusuf's second take: [first beat, tile, taps, beats apart], corners 0 2 8 6, taps on one tile stack
const EASY_DOG_GAP_BEATS := 1.5
const DOG_MAP := [
	# squares of a single then a half beat double, clockwise then back
	[4, 0, 1, 0], [5.5, 2, 2, 0.5], [7, 8, 1, 0], [8.5, 6, 2, 0.5],
	[10, 0, 1, 0], [11.5, 2, 2, 0.5], [13, 8, 1, 0], [14.5, 6, 2, 0.5],
	[20, 0, 1, 0], [21.5, 6, 2, 0.5], [23, 8, 1, 0], [24.5, 2, 2, 0.5],
	[26, 0, 1, 0], [27.5, 6, 2, 0.5], [29, 8, 1, 0], [30.5, 2, 2, 0.5],
	# a triple, then triangles of single, quarter triple, single
	[33.5, 0, 3, 0.25],
	[38, 0, 1, 0], [39.5, 8, 3, 0.25], [41, 2, 1, 0],
	[44, 6, 1, 0], [45.5, 8, 3, 0.25], [47, 0, 1, 0],
	[50, 2, 1, 0], [51.5, 6, 3, 0.25], [53, 0, 1, 0],
	[56, 8, 1, 0], [57.5, 2, 3, 0.25], [59, 6, 1, 0],
	# singles on the metronome, a square then triangles
	[62, 0, 1, 0], [65, 2, 1, 0], [66, 8, 1, 0], [67, 6, 1, 0],
	[68, 0, 1, 0], [69, 2, 1, 0], [70, 8, 1, 0],
	[71, 0, 1, 0], [72, 8, 1, 0], [73, 2, 1, 0], [74, 6, 1, 0],
	[75, 0, 1, 0], [76, 8, 1, 0], [77, 2, 1, 0], [78, 6, 1, 0],
	[79, 0, 1, 0], [80, 8, 1, 0], [81, 2, 1, 0], [82, 0, 1, 0], [83, 6, 1, 0],
]

# each row starts a combo, easy takes one dog per row and spaces them out
static func fill_dogs_mapped(segment: MapSegment, easy := false) -> void:
	var notes: Array[Note] = []
	for row: Array in DOG_MAP:
		for tap in 1 if easy else int(row[2]): notes.append(_dog(row[0] + tap * row[3], row[1], tap == 0))
	if easy: notes = EasyMaps.spaced(notes, EASY_DOG_GAP_BEATS)
	segment.start_beat = minf(segment.start_beat, notes[0].beat)
	assert(notes.back().beat < segment.end_beat, "the dog map runs past its segment")
	segment.notes = notes
	segment.view = DOG_VIEW

static func _dog(beat: float, tile: int, new_combo: bool) -> AimNote:
	var note := AimNote.new(beat, DogCaptchaView.tile_rect(tile).get_center())
	note.new_combo = new_combo
	return note

# notes hop between tiles, never onto one still showing or ticking its last dog
static func fill_dogs(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
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
		notes.append(FillUtils.aim_note(beat, DogCaptchaView.tile_rect(tile).get_center(), notes.size()))
		beat += step
	segment.notes = notes
	segment.view = DOG_VIEW

# c2 on vivaldi, rhythm from Yusuf's take: [first beat, beats apart, lanes] with lanes 0-3 as ← ↓ ↑ →, nets out to start the piece (3, -2) from its hole
const ALIGN_MAP := [
	# a single on the accent, a jack on the other hand 1.5 beats later
	[95, 1, [1]], [96.5, 0.5, [2, 2]], [98, 1, [0]], [99.5, 0.5, [3, 3]],
	[101, 1, [1]], [102.5, 0.5, [2, 2]], [104, 1, [0]], [105.5, 0.5, [3, 3]], [107, 1, [1]],
	# pairs, out then in
	[109, 1, [0, 3]], [112, 1, [1, 2]], [115, 1, [0, 3]],
	# after the rest, stairs and a roll
	[123, 1, [1, 2, 3]], [127, 1, [2, 1]], [130, 1, [0, 1, 2, 3, 2, 1, 0]],
	# every beat to the end, one shape a bar
	[138, 1, [3, 2]], [140, 1, [0, 1, 2]], [143, 1, [3, 2, 1]], [146, 1, [0, 3, 0]], [149, 1, [1, 2, 1]],
	[152, 1, [0, 1, 2]], [155, 1, [3, 2, 1]], [158, 1, [3, 0, 3]], [161, 1, [2, 1, 2]], [164, 1, [0, 3]],
]

static func fill_align_mapped(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for row: Array in ALIGN_MAP:
		for i in row[2].size(): notes.append(LaneNote.new(row[0] + i * row[1], row[2][i]))
	assert(notes[0].beat >= segment.start_beat and notes.back().beat < segment.end_beat, "the align map runs past its segment")
	segment.notes = notes
	segment.view = ALIGN_VIEW

# the moves that undo a random start offset, padded with opposite pairs and shuffled
static func fill_align(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var count := int((segment.end_beat - segment.start_beat) / step)
	var net := Vector2i(rng.randi_range(2, MAX_START.x) * FillUtils.flip(rng), rng.randi_range(1, MAX_START.y) * FillUtils.flip(rng))
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

# c3 on vivaldi, rhythm from Yusuf's take: [beat, spot, apples], spots on a grid from (-1, -1) top left to (1, 1) bottom right, two levels with edge midpoints between.
# a double's second apple lands a quarter beat later to the right of the first, one slash through both
const L := Vector2i(-1, 0)
const R := Vector2i(1, 0)
const T := Vector2i(0, -1)
const B := Vector2i(0, 1)
const TL := Vector2i(-1, -1)
const TR := Vector2i(1, -1)
const BL := Vector2i(-1, 1)
const BR := Vector2i(1, 1)
const FRUIT_MAP := [
	# a single, a double, a single on the way to the next corner, clockwise
	[178, TL, 1], [180, TR, 2], [182, R, 1], [184, BR, 1], [186, BL, 2], [188, L, 1], [190, TL, 1], [192, TR, 2], [194, T, 1],
	# singles round the square one way, then the other
	[196, TL, 1], [198, T, 1], [199, TR, 1], [201, R, 1], [202, BR, 1], [204, B, 1], [205, BL, 1], [208, Vector2i.ZERO, 1],
	[211, TR, 1], [213, T, 1], [214, TL, 1], [216, L, 1], [217, BL, 1], [219, B, 1], [220, BR, 1],
	# doubles on the corners, singles between
	[222, TL, 2], [224, T, 1], [225, TR, 2], [227, R, 1], [228, BR, 2], [230, B, 1], [231, BL, 2], [233, L, 1],
	[234, TL, 2], [236, T, 1], [237, TR, 2], [239, R, 1], [240, BR, 2], [242, B, 1], [243, BL, 2], [245, L, 1], [246, TL, 2],
]
const FRUIT_SPOT := Vector2(90, 85) # px per grid step from the board's centre
const FRUIT_LIFT := 30.0 # the levels sit a little high
const FRUIT_PAIR := 45.0 # each apple of a double this far either side
const FRUIT_PAIR_BEATS := 0.25

static func fill_fruit_mapped(segment: MapSegment) -> void:
	var center := CaptchaFrame.content().get_center() - Vector2(0, FRUIT_LIFT)
	var notes: Array[Note] = []
	for row: Array in FRUIT_MAP:
		var at := center + FRUIT_SPOT * Vector2(row[1])
		var apples: int = row[2]
		for i in apples:
			var note := AimNote.new(row[0] + i * FRUIT_PAIR_BEATS, at + Vector2(FRUIT_PAIR * (2 * i - 1), 0) if apples == 2 else at)
			note.new_combo = i == 0
			notes.append(note)
	assert(notes[0].beat >= segment.start_beat and notes.back().beat < segment.end_beat, "the fruit map runs past its segment")
	segment.notes = notes
	segment.view = FRUIT_VIEW

# apex points spread over the board, never right on top of the last one
static func fill_fruit(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var board := CaptchaFrame.content().grow(-FRUIT_MARGIN)
	var notes: Array[Note] = []
	var last := board.get_center()
	var beat := segment.start_beat
	while beat < segment.end_beat:
		var at := last
		while at.distance_to(last) < FRUIT_SPACING:
			at = board.position + Vector2(rng.randf(), rng.randf()) * board.size
		notes.append(FillUtils.aim_note(beat, at, notes.size()))
		last = at
		beat += step
	segment.notes = notes
	segment.view = FRUIT_VIEW

# one slash per runner move, offset toward the move, the segment stretches to the whole clip
static func fill_subway(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for move in SUBWAY_MOVES: notes.append(FillUtils.aim_note(move[0], SubwayCaptchaView.runner() + move[1] * SubwayCaptchaView.OFFSET, notes.size()))
	segment.start_beat = notes[0].beat
	segment.end_beat = maxf(segment.end_beat, notes.back().beat + SUBWAY_TAIL_BEATS)
	segment.notes = notes
	segment.view = SUBWAY_VIEW

# an ad a beat, sometimes two, never right on top of the last
static func fill_ads(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var notes: Array[Note] = []
	var last := ADS_AREA.get_center()
	var beat := segment.start_beat
	while beat < segment.end_beat:
		for i in 2 if rng.randf() < ADS_DOUBLE_CHANCE else 1:
			var at := last
			while at.distance_to(last) < ADS_SPACING:
				at = ADS_AREA.position + Vector2(rng.randf(), rng.randf()) * ADS_AREA.size
			notes.append(FillUtils.aim_note(beat, at, notes.size()))
			last = at
		beat += step
	segment.notes = notes
	segment.view = ADS_VIEW
