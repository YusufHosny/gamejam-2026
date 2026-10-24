class_name BlueScreenCutscene
extends AnimatedCutscene

# the ads overflow and the computer blue screens, then it zooms out to the laptop the scream stage is played on.
# the timeline lives in the AnimationPlayer, the ad flood is drawn by BlueScreenFlood

const OVERSCAN := 1.02 # the zoomed in screen overshoots the view a little so no bezel shows
const SIDE_ZOOM := 5.0 # how close the last zoom gets to the laptop's side, where the usb goes in

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

func _ready() -> void:
	super()
	get_viewport().size_changed.connect(_layout) # after the desk's own, it refits first
	_layout()

# the blue screen sits on the desk's screen. the world zooms from that screen covering the view out to identity,
# then in on the laptop's side. both exponentially so the zoom speed feels even, and each moves its focus
# point to or from the view's centre
func _layout() -> void:
	var screen := _desk.screen_rect()
	_blue_screen.position = screen.position
	_blue_screen.scale = Vector2.ONE * screen.size.y / _blue_screen.size.y
	var view := get_viewport_rect()
	var zoomed_in := maxf(view.size.x / screen.size.x, view.size.y / screen.size.y) * OVERSCAN
	var zoom := pow(zoomed_in, 1.0 - zoom_out)
	var centre := screen.get_center()
	var origin := view.get_center().lerp(centre, zoom_out) - centre * zoom
	var side := _desk.side_point()
	var side_at := view.get_center().lerp(origin + side * zoom, 1.0 - zoom_side) # where the side shows on screen
	zoom *= pow(SIDE_ZOOM, zoom_side)
	_world.scale = Vector2(zoom, zoom)
	_world.position = side_at - side * zoom
