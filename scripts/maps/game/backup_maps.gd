class_name BackupMaps
extends RefCounted

const USB_VIEW := preload("res://scenes/views/backup/usb_view.tscn")
const PASSWORD_VIEW := preload("res://scenes/views/backup/password_view.tscn")
const MAX_SAME_LANE := 2

const STACK := Vector2(-10, -10) # every other note of a bump run sits up-left, like an osu stack
const PUSH_POINTS := 8
const SLIDER_BEATS := 0.375
const KICK := Vector2(220, 90) # a push slides along the cable from this far out to this close to the port
const FLIP_AT: Array[Vector2] = [Vector2(0, 170), Vector2(-170, -40)] # from the port, flips arc round below it and back ones up left of it
const FLIP_RADIUS := 50.0
const USB_CYCLE_BEATS := 16.0
# [beat in four bars, move], from Yusuf's take: three bars of short sliders into singles on the port, then a bar of singles
const USB_CYCLE := [
	[0, UsbView.Move.PUSH], [0.5, UsbView.Move.BUMP], [1, UsbView.Move.FLIP], [1.5, UsbView.Move.BUMP], [2, UsbView.Move.PUSH], [2.5, UsbView.Move.BUMP], [3, UsbView.Move.BUMP],
	[4, UsbView.Move.PUSH], [4.5, UsbView.Move.BUMP], [5, UsbView.Move.FLIP_BACK], [5.5, UsbView.Move.BUMP], [6, UsbView.Move.PUSH], [6.5, UsbView.Move.BUMP], [7, UsbView.Move.FLIP],
	[8, UsbView.Move.PUSH], [8.5, UsbView.Move.BUMP], [9, UsbView.Move.FLIP_BACK], [9.5, UsbView.Move.BUMP], [10, UsbView.Move.PUSH], [10.5, UsbView.Move.BUMP], [11, UsbView.Move.BUMP],
	[12, UsbView.Move.PUSH], [12.5, UsbView.Move.BUMP], [13, UsbView.Move.BUMP], [13.5, UsbView.Move.BUMP], [14, UsbView.Move.BUMP], [14.5, UsbView.Move.BUMP], [15, UsbView.Move.BUMP],
]

# easy: a beat long slider into two singles a bar
const EASY_SLIDER_BEATS := 1.0
const EASY_USB_CYCLE := [
	[0, UsbView.Move.PUSH], [2, UsbView.Move.BUMP], [3, UsbView.Move.BUMP],
	[4, UsbView.Move.FLIP], [6, UsbView.Move.BUMP], [7, UsbView.Move.BUMP],
	[8, UsbView.Move.PUSH], [10, UsbView.Move.BUMP], [11, UsbView.Move.BUMP],
	[12, UsbView.Move.FLIP_BACK], [14, UsbView.Move.BUMP], [15, UsbView.Move.BUMP],
]

# USB_CYCLE on repeat until the segment runs out
static func fill_usb(segment: MapSegment, easy := false) -> void:
	var cycle: Array = EASY_USB_CYCLE if easy else USB_CYCLE
	var notes: Array[Note] = []
	var cycle_start := segment.start_beat
	var last_bump := -INF
	var stacked := false
	while cycle_start < segment.end_beat:
		for step in cycle:
			var beat: float = cycle_start + step[0]
			if beat >= segment.end_beat: break
			var bump: bool = step[1] == UsbView.Move.BUMP
			stacked = bump and beat - last_bump <= 0.5 and not stacked
			if bump: last_bump = beat
			notes.append(_usb_note(step[1], beat, stacked, EASY_SLIDER_BEATS if easy else SLIDER_BEATS))
		cycle_start += USB_CYCLE_BEATS
	segment.notes = notes
	segment.view = USB_VIEW

static func _usb_note(move: UsbView.Move, beat: float, stacked: bool, slider_beats: float) -> AimNote:
	var port := UsbView.port()
	var cable := (UsbView.plug() - port).normalized()
	match move:
		UsbView.Move.PUSH: return _slider(beat, _line(port + cable * KICK.x, port + cable * KICK.y), slider_beats)
		UsbView.Move.BUMP: return AimNote.new(beat, port + (STACK if stacked else Vector2.ZERO))
		UsbView.Move.FLIP: return _slider(beat, UsbView.flip_arc(port + FLIP_AT[0], FLIP_RADIUS, false), slider_beats)
		UsbView.Move.FLIP_BACK: return _slider(beat, UsbView.flip_arc(port + FLIP_AT[1], FLIP_RADIUS, true), slider_beats)
	assert(false, "unhandled usb move %s" % move)
	return null

# sliders start a new combo
static func _slider(beat: float, points: PackedVector2Array, beats: float) -> SliderNote:
	var slider := SliderNote.new(beat, points[0], points.slice(1), beats)
	slider.new_combo = true
	return slider

static func _line(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in PUSH_POINTS + 1: points.append(from.lerp(to, float(i) / PUSH_POINTS))
	return points

# b2 on the scream mix, in the vibe of the captcha maps: [first beat, beats apart, lanes] with lanes 0-3 on Z X N M
const PASSWORD_MAP := [
	# a single, a half beat jack on the other hand, a single
	[60, 1, [1]], [61.5, 0.5, [2, 2]], [63, 1, [0]],
	[64, 1, [3]], [65.5, 0.5, [1, 1]], [67, 1, [2]],
	[68, 1, [0]], [69.5, 0.5, [3, 3]], [71, 1, [1]],
	# pairs out then in, then half beat stairs
	[72, 1, [0, 3, 1, 2]],
	[76, 0.5, [0, 1, 2, 3]], [78, 1, [3, 0]],
	# the jacks again
	[80, 1, [2]], [81.5, 0.5, [0, 0]], [83, 1, [3]],
	[84, 1, [1]], [85.5, 0.5, [3, 3]], [87, 1, [0]],
	# a half beat roll, then one a beat into the end
	[88, 0.5, [0, 1, 2, 3, 2, 1]], [91, 1, [0]],
	[92, 1, [3, 2, 1, 0]], [96, 1, [0, 3, 0, 3]],
	[100, 0.5, [1, 2, 1, 2]], [102, 1, [0, 3]],
]

static func fill_password_mapped(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	for row: Array in PASSWORD_MAP:
		for i in row[2].size(): notes.append(LaneNote.new(row[0] + i * row[1], row[2][i]))
	assert(notes[0].beat >= segment.start_beat and notes.back().beat < segment.end_beat, "the password map runs past its segment")
	segment.notes = notes
	segment.view = PASSWORD_VIEW

# a letter a step on a random lane, never three in a row on the same one
static func fill_password(segment: MapSegment, map: Map, rng_seed := GameConfig.map_seed) -> void:
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
	segment.view = PASSWORD_VIEW
