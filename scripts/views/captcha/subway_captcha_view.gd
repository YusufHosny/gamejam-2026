class_name SubwayCaptchaView
extends CircleAimView

# c4: the clip plays in the captcha, slash the way the runner moves

const RUNNER := Vector2(0.5, 0.79) # where the runner is in the clip
const OFFSET := 56.0 # notes sit this far toward their move
const MIN_DOT := 0.64 # slash must be within ~50° of the move
const ARROW := 18.0
const RESYNC_S := 0.12

@export var target := "the guard"

@onready var _video: VideoStreamPlayer = $Video

static func runner() -> Vector2:
	var content := CaptchaFrame.content()
	return content.position + content.size * RUNNER

static func direction(note: AimNote) -> Vector2: return (note.position - runner()).normalized()

func _ready() -> void:
	super()
	var content := CaptchaFrame.content()
	_video.position = content.position
	_video.size = content.size
	_video.play()
	_sync_video()

# the clip's audio is the map's music, so the video follows the audio clock
func _process(delta: float) -> void:
	super(delta)
	_sync_video()

func _sync_video() -> void:
	var audio := mode.conductor.get_playback_position()
	if absf(_video.stream_position - audio) > RESYNC_S: _video.stream_position = audio

func is_hit(note: AimNote, from: Vector2, to: Vector2) -> bool:
	return super(note, from, to) and (to - from).normalized().dot(direction(note)) >= MIN_DOT

func _draw() -> void:
	CaptchaFrame.draw_edges(self) # the clip shows through the content area
	CaptchaFrame.draw_header(self, "Get away from", target, "Slash the way the runner moves.")
	super()

# the move's arrow instead of a combo number
func _draw_label(note: AimNote, alpha: float) -> void:
	var dir := direction(note)
	var side := dir.orthogonal() * ARROW * 0.7
	var tip := note.position + dir * ARROW
	var back := note.position - dir * ARROW * 0.4
	draw_polyline(PackedVector2Array([back + side, tip, back - side]), Color(Color.WHITE, alpha), 6, true)
