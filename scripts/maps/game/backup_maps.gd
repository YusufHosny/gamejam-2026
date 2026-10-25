class_name BackupMaps
extends RefCounted

const USB_VIEW := preload("res://scenes/views/backup/usb_view.tscn")
const PASSWORD_VIEW := preload("res://scenes/views/backup/password_view.tscn")
const MAX_SAME_LANE := 2

const SLIDER_BEATS := 1.0
const STACK := Vector2(-10, -10) # the second note of a double sits up-left, like an osu stack
const PUSH_POINTS := 8

# UsbView.CYCLE on repeat until the segment runs out
static func fill_usb(segment: MapSegment) -> void:
	var notes: Array[Note] = []
	var cycle_start := segment.start_beat
	while cycle_start + UsbView.CYCLE_BEATS <= segment.end_beat:
		var last_bump := -INF
		for step in UsbView.CYCLE:
			var beat: float = cycle_start + step[0]
			var note := _usb_note(step[1], beat, beat - last_bump <= 0.5)
			if step[1] == UsbView.Move.BUMP: last_bump = beat
			notes.append(note)
		cycle_start += UsbView.CYCLE_BEATS
	segment.notes = notes
	segment.view = USB_VIEW

static func _usb_note(move: UsbView.Move, beat: float, stacked: bool) -> AimNote:
	match move:
		UsbView.Move.PUSH: return _slider(beat, _line(UsbView.plug(), UsbView.port()))
		UsbView.Move.BUMP: return AimNote.new(beat, UsbView.port() + (STACK if stacked else Vector2.ZERO))
		UsbView.Move.FLIP: return _slider(beat, UsbView.flip_arc(false))
		UsbView.Move.FLIP_BACK: return _slider(beat, UsbView.flip_arc(true))
	assert(false, "unhandled usb move %s" % move)
	return null

# pushes and flips start a new combo
static func _slider(beat: float, points: PackedVector2Array) -> SliderNote:
	var slider := SliderNote.new(beat, points[0], points.slice(1), SLIDER_BEATS)
	slider.new_combo = true
	return slider

static func _line(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in PUSH_POINTS + 1: points.append(from.lerp(to, float(i) / PUSH_POINTS))
	return points

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
