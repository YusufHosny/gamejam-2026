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
const SUBWAY_MOVES := [ # [beat, direction], from tools/subway/moves.py
	[-0.75, Vector2.LEFT], # 0.10s
	[0.75, Vector2.RIGHT], # 0.90s
	[4.25, Vector2.DOWN], # 2.65s
	[7.75, Vector2.LEFT], # 4.30s
	[10.75, Vector2.DOWN], # 5.80s
	[13.5, Vector2.RIGHT], # 7.27s
	[15.75, Vector2.LEFT], # 8.37s
	[16.75, Vector2.RIGHT], # 8.87s
	[20.75, Vector2.RIGHT], # 10.90s
	[24.5, Vector2.LEFT], # 12.70s
	[29.25, Vector2.RIGHT], # 15.07s
	[31.25, Vector2.LEFT], # 16.07s
	[37.25, Vector2.UP], # 19.10s
	[39.5, Vector2.RIGHT], # 20.20s
	[40.25, Vector2.UP], # 20.60s
	[43.75, Vector2.LEFT], # 22.40s
	[52.75, Vector2.UP], # 26.90s
	[53.5, Vector2.LEFT], # 27.20s
	[57.25, Vector2.RIGHT], # 29.10s
]

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

# one slash per runner move that lands inside the segment, offset toward the move
static func fill_subway(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for move in SUBWAY_MOVES:
		var beat: float = move[0]
		if beat < segment.start_beat or beat >= segment.end_beat: continue
		notes.append(FillUtils.aim_note(beat, SubwayCaptchaView.runner() + move[1] * SubwayCaptchaView.OFFSET, notes.size()))
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
