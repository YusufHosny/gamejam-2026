class_name Cutscene
extends Control

signal finished
signal sfx_played(id: StringName) # for checking the cues

const SKIP_TAIL_S := 2.0 # skipping lands this far from the end

const VOICE_LINE_AT := 0.2
const SFX_STALE_S := 0.25 # a sound cue further back than this is skipped, so a skip doesn't fire them all at once

var caption := "" # placeholder text / subtitle
var length_s := 0.0 # 0 waits for the player
var voice_line: StringName = &"" # a placeholder's one line, real cutscenes override voice_cues()
var time := 0.0
var _finished := false
var _voice := VoiceTrack.new()
var _sfx := AudioStreamPlayer.new()
var _sfx_cues: Array = []
var _sfx_from := -1.0 # the clock last frame, cues after it and up to now play
var _sfx_last := -1.0 # this frame's, it's _sfx_from next frame

func _init() -> void:
	add_child(_voice, false, INTERNAL_MODE_BACK) # after the scene's own nodes, the captions draw on top
	_sfx.stream = AudioStreamPolyphonic.new()
	_sfx.max_polyphony = 16
	add_child(_sfx, false, INTERNAL_MODE_BACK)

# [at, id] or [at, id, part], see VoiceTrack.cues
func voice_cues() -> Array: return [[VOICE_LINE_AT, voice_line]] if voice_line != &"" else []

# [at, id] or [at, id, pitch], Sfx ids
func sfx_cues() -> Array: return []

# for sounds the timeline doesn't know ahead, like one per flooded ad
func play_sfx(id: StringName, pitch := 1.0, volume_db := 0.0) -> void:
	if not _sfx.playing: _sfx.play()
	(_sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic).play_stream(Sfx.stream(id), 0.0, Sfx.volume_db(id) + volume_db, pitch)
	sfx_played.emit(id)

# whether `at` was passed this frame, recently enough to still sound right
func passed(at: float) -> bool: return at > _sfx_from and at <= time and time - at < SFX_STALE_S

func waits() -> bool: return length_s <= 0.0

func restart() -> void:
	time = 0.0
	_sfx_last = -1.0
	_finished = false

func skip() -> void:
	if waits(): _finish()
	else: time = maxf(time, length_s - SKIP_TAIL_S)

func _process(delta: float) -> void:
	_sfx_from = _sfx_last # kept for the whole frame, so subclasses can check passed() after super()
	time += delta
	if _voice.cues.is_empty(): _voice.cues = voice_cues()
	_voice.sync(time)
	if _sfx_cues.is_empty(): _sfx_cues = sfx_cues()
	if time < _sfx_from: _sfx_from = time - 0.001 # jumped back
	for cue: Array in _sfx_cues:
		if passed(cue[0]): play_sfx(cue[1], cue[2] if cue.size() > 2 else 1.0)
	_sfx_last = time
	if not waits() and time >= length_s: _finish()

func _unhandled_input(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and waits()
	if event.is_action_pressed(&"skip_cutscene") or clicked:
		skip()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	if _finished: return
	_finished = true
	finished.emit()
