class_name VoiceTrack
extends Control

# plays voice lines and draws their captions in a box above the taskbar. cutscenes give it cues and sync it to their
# own clock every frame, so skipping, restarting and pausing keep the audio and captions exact. maps just say() a line.
# top level so it draws over everything and doesn't move with a sliding view

const RESYNC_S := 0.15 # only seek after a jump, seeking every frame stutters
const CAPTION_SIZE := 24
const CAPTION_LIFT := 40.0 # box centre above the taskbar

static var _tracks: Array[VoiceTrack] = [] # in the tree, for speaking()

var cues: Array = [] # [at, id] or [at, id, part]: that part of the line starts at `at`

var _player := AudioStreamPlayer.new()
var _cue := -1 # the cue playing
var _caption := ""
var _said: StringName = &"" # say()'s line
var _said_t := 0.0
var _said_captioned := true

func _init() -> void:
	top_level = true
	mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_player)

func _enter_tree() -> void: _tracks.append(self)

func _exit_tree() -> void: _tracks.erase(self)

# a line's being said somewhere, the metronome ducks under it
static func speaking() -> bool: return _tracks.any(func(t: VoiceTrack): return t._player.playing)

func _process(delta: float) -> void:
	if _said != &"":
		_said_t += delta
		_caption = VoiceLines.caption(_said, _said_t) if _said_captioned else ""
	queue_redraw()

# a line now, the caption follows it. tutorial hints already show their text, so they can go uncaptioned
func say(id: StringName, captioned := true) -> void:
	_said = id
	_said_t = 0.0
	_said_captioned = captioned
	_player.stream = VoiceLines.stream(id)
	_player.play()

# the cue under `time` plays from where it should be, captions come from whichever line is still showing
func sync(time: float) -> void:
	var active := -1
	_caption = ""
	for i in cues.size():
		var at := _start(i)
		var id: StringName = cues[i][1]
		if time >= at and time < at + VoiceLines.stream(id).get_length(): active = i
		if time >= at and time < at + VoiceLines.caption_end(id): _caption = VoiceLines.caption(id, time - at)
	if active == -1:
		if _cue != -1: _player.stop()
		_cue = -1
		return
	var offset := time - _start(active)
	if active != _cue:
		_cue = active
		_player.stream = VoiceLines.stream(cues[active][1])
		_player.play(offset)
	elif _player.playing and absf(_player.get_playback_position() - offset) > RESYNC_S:
		_player.play(offset)
	elif not _player.playing and offset < _player.stream.get_length() - RESYNC_S: # stopped early, a restart or a seek back
		_player.play(offset)

func _start(i: int) -> float:
	var cue: Array = cues[i]
	return cue[0] - (VoiceLines.part_start(cue[1], cue[2]) if cue.size() > 2 else 0.0)

func _draw() -> void:
	if _caption == "": return
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x
	var screen := get_viewport_rect().size
	var center := Vector2(screen.x / 2, screen.y - Desktop.TASKBAR_H - CAPTION_LIFT)
	TutorialUi.box(self, Rect2(center - Vector2(width / 2 + 24, 26), Vector2(width + 48, 52)), Color(0, 0, 0, 0.7), 14)
	TutorialUi.label(self, center, _caption, CAPTION_SIZE, Color.WHITE)
