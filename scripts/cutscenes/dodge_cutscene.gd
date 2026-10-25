class_name DodgeCutscene
extends AnimatedCutscene

# the usb is in. the blue screen's zoom runs backwards on the laptop, now with the backup drive, it boots and loads,
# then DodgeStage takes over: the submit button shows up and dodges the cursor onto f1's first spot.
# the laptop part lives in the AnimationPlayer, the arena part is drawn by DodgeStage

@export_range(0.0, 1.0) var zoom_out := 1.0: # keyframed, 0 the screen fills the view, 1 the whole desk shows
	set(value):
		zoom_out = value
		if is_node_ready(): _layout()

@export_range(0.0, 1.0) var zoom_side := 1.0: # keyframed, 1 the laptop's left edge fills the view, where the usb went in
	set(value):
		zoom_side = value
		if is_node_ready(): _layout()

@onready var _world: Node2D = $World
@onready var _desk: LaptopDesk = $World/LaptopDesk
@onready var _boot_screen: Control = $World/BootScreen
@onready var _usb: Sprite2D = $Usb/Frame

func _ready() -> void:
	super()
	_usb.position = UsbView.CENTER # the last frame of b1's usb, where it was
	_usb.scale = Vector2.ONE * UsbView.SCALE
	get_viewport().size_changed.connect(_layout) # after the desk's own, it refits first
	_layout()

# the boot screen sits on the desk's screen
func _layout() -> void:
	var screen := _desk.screen_rect()
	_boot_screen.position = screen.position
	_boot_screen.scale = Vector2.ONE * screen.size.y / _boot_screen.size.y
	_world.transform = _desk.framing(get_viewport_rect(), zoom_out, zoom_side)
