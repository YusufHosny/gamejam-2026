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

# "huh?" lands on the first dodge whatever the language, the complaint follows "too slow"
func voice_cues() -> Array: return [[DodgeStage.TRY_AT[0] + DodgeStage.TRY_S[0] - DodgeStage.DODGE_LEAD_S, &"dodge_1", 1], [DodgeStage.TOO_SLOW_AT + 0.4, &"dodge_2"]]

# the laptop part's moments are the AnimationPlayer's keys: the grey fade, the zoom out, booting up, the zoom in, the bar full
const GREY_AT := 2.0
const ZOOM_OUT_AT := 2.9
const BOOT_AT := 4.0
const ZOOM_IN_AT := 5.8
const LOADED_AT := 10.8

# then the arena: it lands, the cursor clicks where the button was, the button darts off, its taunts
func sfx_cues() -> Array:
	var cues := [[GREY_AT, &"whoosh_low"], [ZOOM_OUT_AT, &"whoosh"], [BOOT_AT, &"startup"], [ZOOM_IN_AT, &"whoosh"], [LOADED_AT, &"success"], [LOADED_AT + 0.15, &"boom"]]
	for i in DodgeStage.TRY_AT.size():
		cues.append([DodgeStage.TRY_AT[i] + DodgeStage.TRY_S[i] - DodgeStage.DODGE_LEAD_S, &"whoosh", 1.3])
		cues.append([DodgeStage.TRY_AT[i] + DodgeStage.TRY_S[i], &"click"])
	cues.append_array([[DodgeStage.TOO_SLOW_AT, &"sting", 0.8], [DodgeStage.READY_AT, &"sting"]])
	return cues

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
