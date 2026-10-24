class_name TutorialMaps
extends RefCounted

const LOGIN_VIEW := preload("res://scenes/views/tutorial/login_view.tscn")
const PATTERN_VIEW := preload("res://scenes/views/tutorial/pattern_lock_view.tscn")
const NOTIFICATIONS_VIEW := preload("res://scenes/views/tutorial/notifications_view.tscn")
const EMAIL_VIEW := preload("res://scenes/views/tutorial/email_refresh_view.tscn")
const START_BEAT := 4.0
const COOLDOWN_BEATS := 4.0
const NOTIFICATION_LANES: Array[int] = [0, 1, 2, 3, 3, 2, 1, 0]
const REFRESHES := 4

static func login() -> Map:
	var notes: Array[Note] = [
		AimNote.new(START_BEAT, LoginView.USERNAME),
		AimNote.new(START_BEAT + 2, LoginView.PASSWORD),
		AimNote.new(START_BEAT + 4, LoginView.SIGN_IN),
	]
	return _map([_segment(Modality.Kind.AIM_CLICK, notes, LOGIN_VIEW, 6.0)])

# pattern unlock, then swipe the notifications away
static func phone() -> Map:
	var dots := PatternLockView.pattern_points()
	var unlock: Array[Note] = [SliderNote.new(START_BEAT, dots[0], dots.slice(1), 4.0)]
	var pattern := _segment(Modality.Kind.AIM_CLICK, unlock, PATTERN_VIEW, 2.0)
	var swipes: Array[Note] = []
	for i in NOTIFICATION_LANES.size():
		swipes.append(LaneNote.new(pattern.end_beat + COOLDOWN_BEATS + i, NOTIFICATION_LANES[i]))
	return _map([pattern, _segment(Modality.Kind.FOUR_D, swipes, NOTIFICATIONS_VIEW, 2.0)])

static func email() -> Map:
	var notes: Array[Note] = []
	for i in REFRESHES: notes.append(AimNote.new(START_BEAT + i * 2, EmailRefreshView.REFRESH))
	return _map([_segment(Modality.Kind.SLASH, notes, EMAIL_VIEW, 6.0)])

static func _segment(kind: Modality.Kind, notes: Array[Note], view: PackedScene, tail_beats: float) -> MapSegment:
	var last := notes.back() as Note
	var end := (last as SliderNote).end_beat() if last is SliderNote else last.beat
	var segment := MapSegment.new(kind, notes[0].beat, end + tail_beats)
	segment.notes = notes
	segment.view = view
	segment.tutorial = true
	segment.wait_for_input = true
	return segment

static func _map(segments: Array[MapSegment]) -> Map:
	var map := Map.new()
	map.bpm = GameConfig.bpm
	map.segments = segments
	map.bake()
	return map
