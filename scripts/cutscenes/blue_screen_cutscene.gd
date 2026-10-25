class_name BlueScreenCutscene
extends AnimatedCutscene

# the ads overflow and the computer blue screens, then it zooms out to the laptop the scream stage is played on.
# the timeline lives in the AnimationPlayer, the ad flood is drawn by BlueScreenFlood

@export_range(0.0, 1.0) var zoom_out := 0.0: # keyframed, 0 the screen fills the view, 1 the whole desk shows
	set(value):
		zoom_out = value
		if is_node_ready(): _layout()

@export_range(0.0, 1.0) var zoom_side := 0.0: # keyframed, 1 the laptop's left edge fills the view for the usb stage
	set(value):
		zoom_side = value
		if is_node_ready(): _layout()

@onready var _world: Node2D = $World
@onready var _desk: LaptopDesk = $World/LaptopDesk
@onready var _blue_screen: Control = $World/BlueScreen
@onready var _flood: BlueScreenFlood = $Flood

# panic through the flood, then the blue screen sinks in
func voice_cues() -> Array: return [[0.3, &"ads_1"], [7.3, &"ads_2"]]

# the timeline's moments, see the AnimationPlayer: the glitch stutters in, the screen dies, both zooms
const GLITCH := Vector2(2.2, 3.0)
const CRASH_AT := 3.0
const ZOOM_OUT_AT := 5.0
const ZOOM_SIDE_AT := 9.5
const POP_GAP_S := 0.05 # the flood's pops at most this often, it adds hundreds of ads

var _pops := 0 # ads popped so far, the flood's ads_shown is keyframed
var _popped_at := -INF

func sfx_cues() -> Array:
	var cues := []
	var at := GLITCH.x
	while at < GLITCH.y:
		cues.append([at, &"glitch", randf_range(0.7, 1.4)])
		at += 0.07
	cues.append_array([[CRASH_AT, &"crash"], [ZOOM_OUT_AT, &"whoosh_low"], [ZOOM_SIDE_AT, &"whoosh"]])
	return cues

func _process(delta: float) -> void:
	super(delta)
	var shown := floori(_flood.ads_shown)
	if shown < _pops: _pops = shown # restarted
	if shown > _pops and time - _popped_at >= POP_GAP_S and time < GLITCH.y:
		play_sfx(&"pop", randf_range(0.8, 1.5), -6.0)
		_popped_at = time
		_pops = shown

func _ready() -> void:
	super()
	get_viewport().size_changed.connect(_layout) # after the desk's own, it refits first
	_layout()

# the blue screen sits on the desk's screen, the world zooms from that screen covering the view out to the desk,
# then in on the laptop's side
func _layout() -> void:
	var screen := _desk.screen_rect()
	_blue_screen.position = screen.position
	_blue_screen.scale = Vector2.ONE * screen.size.y / _blue_screen.size.y
	_world.transform = _desk.framing(get_viewport_rect(), zoom_out, zoom_side)
