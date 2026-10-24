extends Node2D

# sandbox for the usb animation: any key or click plays the next phase

const PHASE_NAMES: Array[String] = [
	"arrow", "push", "bump", "bump", "bump", "bump", "flip", "push", "bump", "bump", "bump", "flip back",
]

@onready var _usb: UsbAnimation = $Usb
@onready var _label: Label = $Label

func _ready() -> void:
	_usb.position = get_viewport_rect().get_center()
	_usb.phase_finished.connect(func(_phase: int): _update_label())
	_update_label()

func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_usb.advance()
		_update_label()

func _update_label() -> void:
	var phase := _usb.current_phase()
	var status := "ready" if phase < 0 else "phase %d: %s" % [phase, PHASE_NAMES[phase]]
	_label.text = "%s   (any key / click to advance)" % status
