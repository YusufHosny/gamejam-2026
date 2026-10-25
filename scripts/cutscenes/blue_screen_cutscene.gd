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

# panic through the flood, then the blue screen sinks in
func voice_cues() -> Array: return [[0.3, &"ads_1"], [7.3, &"ads_2"]]

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
