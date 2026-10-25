class_name BossMaps
extends RefCounted

const CHASE_VIEW := preload("res://scenes/views/boss/boss_chase_view.tscn")
const FINAL_VIEW := preload("res://scenes/views/boss/boss_final_view.tscn")
const SHIELD_VIEW := preload("res://scenes/views/boss/shield_break_view.tscn")
const LASER_VIEW := preload("res://scenes/views/boss/laser_defend_view.tscn")
const CHASE_AREA := Rect2(280, 170, 600, 300) # button centres, clear of the hud
const JUMP := 170.0
const STREAM_SPACING := 46.0
const STREAM_CHANCE := 0.5
const STREAM_BEND := 0.35 # radians per note, streams curve
const STREAM_NOTES := Vector2i(5, 8)
const MAX_SAME_LANE := 2

enum Chase { TAPS, SLIDER }
const CHASE_SLIDER_BEATS := 0.75
# f1 on the first theme, from Yusuf's take. [TAPS, first beat, notes, beats apart, spots]: one spot stacks, as many spots as notes jump, otherwise
# the notes are spread evenly along the spots. [SLIDER, beat, path, beats (CHASE_SLIDER_BEATS when left out)]
const CHASE_MAP := [
	# the arpeggios: a sixteenth stream, a breath, a half beat triple from the first chord to the second, the next stream starting clear of it
	[Chase.TAPS, 0, 19, 0.25, [Vector2(296, 170), Vector2(285, 199), Vector2(285, 278), Vector2(294, 308), Vector2(301, 334), Vector2(310, 353), Vector2(322, 368), Vector2(335, 390), Vector2(349, 416), Vector2(380, 438), Vector2(401, 444), Vector2(446, 417), Vector2(454, 394), Vector2(467, 353), Vector2(476, 334), Vector2(488, 306), Vector2(502, 286), Vector2(514, 275), Vector2(584, 296)]],
	[Chase.TAPS, 6, 3, 0.5, [Vector2(584, 446), Vector2(714, 446), Vector2(844, 446)]],
	[Chase.TAPS, 8, 19, 0.25, [Vector2(449, 328), Vector2(452, 285), Vector2(454, 253), Vector2(459, 237), Vector2(467, 222), Vector2(501, 218), Vector2(533, 233), Vector2(576, 320), Vector2(600, 374), Vector2(614, 388), Vector2(669, 397)]],
	[Chase.TAPS, 14, 3, 0.5, [Vector2(814, 358), Vector2(722, 266), Vector2(630, 174)]],
	[Chase.TAPS, 16, 19, 0.25, [Vector2(510, 283), Vector2(485, 291), Vector2(490, 361), Vector2(492, 379), Vector2(484, 395), Vector2(450, 392), Vector2(415, 340), Vector2(399, 249), Vector2(406, 175), Vector2(418, 170), Vector2(489, 214), Vector2(541, 325), Vector2(523, 384), Vector2(503, 392), Vector2(489, 392), Vector2(442, 387), Vector2(439, 387)]],
	[Chase.TAPS, 22, 3, 0.5, [Vector2(400, 242), Vector2(526, 208), Vector2(651, 175)]],
	# two short streams, a slider between them, a triple onto the chords
	[Chase.TAPS, 24, 5, 0.25, [Vector2(600, 215), Vector2(660, 195), Vector2(685, 213)]],
	[Chase.SLIDER, 26, [Vector2(733, 324), Vector2(511, 304)]],
	[Chase.TAPS, 27, 7, 0.25, [Vector2(515, 415), Vector2(445, 400), Vector2(416, 350)]],
	[Chase.TAPS, 30, 3, 0.5, [Vector2(560, 311), Vector2(686, 277), Vector2(812, 243)]],
	# a star on and off the beat, three slow singles crossing over, and again
	[Chase.TAPS, 32, 5, 0.5, [Vector2(430, 175), Vector2(515, 437), Vector2(292, 275), Vector2(568, 275), Vector2(345, 437)]],
	[Chase.TAPS, 35, 3, 1, [Vector2(520, 250), Vector2(600, 390), Vector2(680, 250)]],
	[Chase.TAPS, 38, 5, 0.5, [Vector2(775, 182), Vector2(775, 458), Vector2(613, 235), Vector2(875, 320), Vector2(613, 405)]],
	[Chase.TAPS, 41, 3, 1, [Vector2(640, 390), Vector2(560, 250), Vector2(480, 390)]],
	[Chase.TAPS, 44, 5, 0.5, [Vector2(515, 203), Vector2(430, 465), Vector2(345, 203), Vector2(568, 365), Vector2(292, 365)]],
	# square jumps round the corners twice on the half beat, gold dust style, then the middle and out to the fermata
	[Chase.TAPS, 47, 8, 0.5, [Vector2(440, 180), Vector2(720, 180), Vector2(720, 460), Vector2(440, 460), Vector2(440, 180), Vector2(720, 180), Vector2(720, 460), Vector2(440, 460)]],
	[Chase.TAPS, 52, 1, 0, [Vector2(580, 320)]],
	[Chase.TAPS, 54, 1, 0, [Vector2(710, 320)]],
]

# f4 on the codetta and the development's climb, from Yusuf's take, rows like CHASE_MAP
const FINAL_MAP := [
	# the codetta: a slider into singles on the beat
	[Chase.SLIDER, 234, [Vector2(502, 202), Vector2(657, 327)]],
	[Chase.TAPS, 235, 5, 1, [Vector2(654, 347), Vector2(538, 413), Vector2(608, 216), Vector2(624, 404), Vector2(532, 247)]],
	[Chase.SLIDER, 242, [Vector2(429, 376), Vector2(680, 338)]],
	[Chase.TAPS, 243, 6, 1, [Vector2(684, 342), Vector2(590, 425), Vector2(492, 231), Vector2(659, 202), Vector2(527, 401), Vector2(700, 300)]],
	# jumps, half beat pairs then a zigzag
	[Chase.TAPS, 250, 2, 0.5, [Vector2(490, 233), Vector2(464, 390)]],
	[Chase.TAPS, 252, 2, 0.5, [Vector2(635, 223), Vector2(606, 344)]],
	[Chase.TAPS, 254, 2, 0.5, [Vector2(755, 210), Vector2(741, 365)]],
	[Chase.TAPS, 256, 2, 0.5, [Vector2(504, 209), Vector2(496, 371)]],
	[Chase.TAPS, 259, 2, 1, [Vector2(588, 206), Vector2(607, 395)]],
	[Chase.TAPS, 261, 9, 0.5, [Vector2(430, 230), Vector2(475, 400), Vector2(520, 230), Vector2(565, 400), Vector2(610, 230), Vector2(655, 400), Vector2(700, 230), Vector2(745, 400), Vector2(790, 230)]],
	# a sixteenth stream, a beat's breath, three half beat jumps in a line, three times
	[Chase.TAPS, 266, 20, 0.25, [Vector2(485, 219), Vector2(476, 226), Vector2(458, 234), Vector2(411, 240), Vector2(395, 244), Vector2(380, 256), Vector2(373, 266), Vector2(355, 283), Vector2(351, 301), Vector2(348, 341), Vector2(374, 373), Vector2(395, 395), Vector2(411, 400), Vector2(450, 400), Vector2(466, 396), Vector2(495, 375), Vector2(523, 365), Vector2(534, 362), Vector2(546, 362)]],
	[Chase.TAPS, 271.75, 3, 0.5, [Vector2(640, 245), Vector2(721, 170), Vector2(803, 170)]],
	[Chase.TAPS, 274, 20, 0.25, [Vector2(556, 229), Vector2(532, 234), Vector2(517, 249), Vector2(493, 281), Vector2(461, 319), Vector2(400, 350), Vector2(353, 303), Vector2(343, 245), Vector2(344, 230), Vector2(361, 228), Vector2(391, 239), Vector2(438, 297), Vector2(439, 356), Vector2(441, 401), Vector2(453, 425), Vector2(500, 433), Vector2(532, 432), Vector2(618, 423), Vector2(675, 406)]],
	[Chase.TAPS, 279.75, 3, 0.5, [Vector2(564, 306), Vector2(467, 219), Vector2(371, 170)]],
	[Chase.TAPS, 282, 20, 0.25, [Vector2(354, 254), Vector2(352, 268), Vector2(357, 322), Vector2(417, 372), Vector2(475, 384), Vector2(519, 389), Vector2(599, 380), Vector2(695, 322), Vector2(716, 293), Vector2(764, 286), Vector2(782, 349), Vector2(730, 390), Vector2(695, 397), Vector2(671, 389), Vector2(593, 344), Vector2(573, 305), Vector2(551, 276), Vector2(513, 258), Vector2(450, 250), Vector2(409, 264), Vector2(385, 297)]],
	[Chase.TAPS, 287.75, 3, 0.5, [Vector2(534, 315), Vector2(664, 330), Vector2(793, 345)]],
	# the climb: half beat runs, zigzags across and triangles on alternating sides
	[Chase.TAPS, 290, 5, 0.5, [Vector2(380, 230), Vector2(505, 410), Vector2(630, 230), Vector2(755, 410), Vector2(880, 230)]],
	[Chase.TAPS, 293, 9, 0.5, [Vector2(430, 180), Vector2(551, 390), Vector2(309, 390), Vector2(430, 180), Vector2(551, 390), Vector2(309, 390), Vector2(430, 180), Vector2(551, 390), Vector2(309, 390)]],
	[Chase.TAPS, 298, 5, 0.5, [Vector2(880, 230), Vector2(755, 410), Vector2(630, 230), Vector2(505, 410), Vector2(380, 230)]],
	[Chase.TAPS, 301, 7, 0.5, [Vector2(730, 460), Vector2(609, 250), Vector2(851, 250), Vector2(730, 460), Vector2(609, 250), Vector2(851, 250), Vector2(730, 460)]],
	[Chase.TAPS, 305, 3, 0.5, [Vector2(380, 230), Vector2(630, 410), Vector2(880, 230)]],
	[Chase.TAPS, 307, 3, 0.5, [Vector2(430, 180), Vector2(551, 390), Vector2(309, 390)]],
	[Chase.TAPS, 309, 3, 0.5, [Vector2(880, 230), Vector2(630, 410), Vector2(380, 230)]],
	[Chase.TAPS, 311, 3, 0.5, [Vector2(730, 460), Vector2(609, 250), Vector2(851, 250)]],
	[Chase.TAPS, 313, 3, 0.5, [Vector2(380, 230), Vector2(630, 410), Vector2(880, 230)]],
	[Chase.TAPS, 315, 4, 0.5, [Vector2(430, 180), Vector2(551, 390), Vector2(309, 390), Vector2(430, 180)]],
	# one long slider round the arena, then the chord in the middle
	[Chase.SLIDER, 317, [Vector2(380, 300), Vector2(430, 200), Vector2(580, 175), Vector2(730, 200), Vector2(800, 320), Vector2(730, 440), Vector2(580, 460)], 2.5],
	[Chase.TAPS, 320, 1, 0, [Vector2(580, 320)]],
]

# f1's first spot, the dodge cutscene leaves the button there
static func chase_start() -> Vector2: return CHASE_MAP[0][4][0]

static func fill_chase_mapped(segment: MapSegment, rows := CHASE_MAP, view := CHASE_VIEW) -> void:
	var notes: Array[Note] = []
	for row: Array in rows:
		match row[0]:
			Chase.TAPS:
				var spots := _spread(row[4], row[2])
				for i in spots.size():
					var note := AimNote.new(row[1] + i * row[3], spots[i])
					note.new_combo = i == 0
					notes.append(note)
			Chase.SLIDER:
				var path := PackedVector2Array(row[2])
				var slider := SliderNote.new(row[1], path[0], path.slice(1), row[3] if row.size() > 3 else CHASE_SLIDER_BEATS)
				slider.new_combo = true
				notes.append(slider)
			_: assert(false, "unhandled chase row %s" % row)
	assert(notes[0].beat >= segment.start_beat and notes.back().beat < segment.end_beat, "the chase map runs past its segment")
	segment.notes = notes
	segment.view = view

static func _spread(spots: Array, count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if spots.size() == count or spots.size() == 1:
		for i in count: out.append(spots[i % spots.size()])
		return out
	var curve := Curve2D.new()
	for spot: Vector2 in spots: curve.add_point(spot)
	for i in count: out.append(curve.sample_baked(curve.get_baked_length() * i / (count - 1)))
	return out

# jumps across the arena, the final chase mixes in streams at twice the note rate
static func fill_chase(segment: MapSegment, map: Map, streams := false, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var notes: Array[Note] = []
	var at := CHASE_AREA.get_center()
	var beat := segment.start_beat
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

const RIGHT := 1
const LEFT := -1
# f2 on the second theme, from Yusuf's left right swipes: [beat, swipe], an arrow flies at the shield the way the swipe goes
const SHIELD_MAP := [
	[60, RIGHT], [61, LEFT], [62, RIGHT], [63, LEFT], [64, RIGHT], [65, LEFT], [66, RIGHT], [66.5, LEFT], [67, RIGHT], [68, LEFT],
	[69, RIGHT], [70, LEFT], [71, RIGHT], [72, LEFT], [73, RIGHT], [74, LEFT], [74.5, RIGHT], [75, LEFT], [76, RIGHT], [77, LEFT],
	[78, RIGHT], [79, LEFT], [80, RIGHT], [81, LEFT], [82, RIGHT], [83, LEFT], [84, RIGHT], [86.5, LEFT], [87.5, RIGHT], [88, LEFT],
	[89, RIGHT], [91.5, LEFT], [92, RIGHT], [92.5, LEFT], [93, RIGHT], [94, LEFT], [95.5, RIGHT], [96, LEFT], [96.5, RIGHT], [97, LEFT],
	[98, RIGHT], [99.5, LEFT], [100, RIGHT], [100.5, LEFT], [101, RIGHT], [101.5, LEFT], [102.5, RIGHT], [103.5, LEFT], [104, RIGHT], [104.5, LEFT],
	[105.5, RIGHT], [106, LEFT], [107, RIGHT], [108, LEFT], [108.5, RIGHT], [109, LEFT], [109.5, RIGHT], [110, LEFT], [111, RIGHT], [112, LEFT],
	[112.5, RIGHT], [113, LEFT], [114, RIGHT], [114.5, LEFT], [115.5, RIGHT], [116.5, LEFT], [117, RIGHT], [117.5, LEFT], [119, RIGHT], [120, LEFT],
	[121, RIGHT], [122, LEFT], [122.5, RIGHT], [123, LEFT],
]

static func fill_shields_mapped(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for row: Array in SHIELD_MAP: notes.append(FillUtils.aim_note(row[0], ShieldBreakView.note_at(row[1]), notes.size()))
	assert(notes.back().beat < segment.end_beat, "the shield map runs past its segment")
	segment.notes = notes
	segment.view = SHIELD_VIEW

# arrows a step apart, swipes back and forth with the odd repeat
static func fill_shields(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
	var rng := FillUtils.rng(rng_seed)
	var step := FillUtils.step(map)
	var notes: Array[Note] = []
	var swipe := RIGHT
	var beat := segment.start_beat
	while beat < segment.end_beat:
		notes.append(FillUtils.aim_note(beat, ShieldBreakView.note_at(swipe), notes.size()))
		if rng.randf() < 0.8: swipe = -swipe
		beat += step
	segment.notes = notes
	segment.view = SHIELD_VIEW

# f3 on the second theme and closing theme, from Yusuf's take: [first beat, beats apart, lanes], a lane pair is a chord, lanes 0-3 on Z X N M
const LASER_MAP := [
	# chords every two beats, outer then inner
	[128, 2, [[0, 3], [1, 2], [0, 3], [1, 2], [0, 3], [1, 2], [0, 3], [1, 2], [0, 3]]],
	# one a beat into a Z M trill
	[146, 1, [1, 2, 1, 3, 0, 3, 0, 3, 0, 3, 0]],
	# half beat rolls of three, each side
	[157, 0.5, [1, 0, 1]], [159, 0.5, [2, 3, 2]], [161, 0.5, [1, 0, 1]], [163, 0.5, [2, 3, 2]],
	[165, 1, [1, 0, 1, 2, 2, 1, 3, 3, 0, 1]],
	# half beat jacks a bar each, the button hammering one slot
	[175, 0.5, [1, 1, 1, 1, 1, 1, 1, 1]], [179, 0.5, [2, 2, 2, 2, 2, 2, 2, 2]],
	[183, 0.5, [1, 1, 1, 1, 1, 1, 1, 1]], [187, 0.5, [2, 2, 2, 2, 2, 2, 2, 2]], [191, 0.5, [0, 0, 0, 0]],
	[193.5, 0.5, [3, 3, 3]], [195.5, 0.5, [1, 1, 1]], [197.5, 0.5, [2, 2, 2]],
	[200, 1, [0]], [201, 0.5, [0, 0, 0, 0]], [203.5, 0.5, [3, 3, 3, 3, 3, 3, 3]],
	[207, 0.5, [1, 1, 1, 1, 1, 1, 1, 1]], [211, 0.5, [2, 2, 2, 2, 2, 2, 2, 2]], [215, 0.5, [0, 0, 0, 0]],
	# triples down to the end
	[217.5, 0.5, [1, 1, 1]], [219.5, 0.5, [2, 2, 2]], [221.5, 0.5, [3, 3, 3]], [223.5, 0.5, [2, 2, 2]], [225.5, 0.5, [1, 1, 1]], [227.5, 0.5, [0, 0, 0]],
]

static func fill_lasers_mapped(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for row: Array in LASER_MAP:
		for i in row[2].size():
			var lanes: Array = row[2][i] if row[2][i] is Array else [row[2][i]]
			for lane: int in lanes: notes.append(LaneNote.new(row[0] + i * row[1], lane))
	assert(notes[0].beat >= segment.start_beat and notes.back().beat < segment.end_beat, "the laser map runs past its segment")
	segment.notes = notes
	segment.view = LASER_VIEW

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
