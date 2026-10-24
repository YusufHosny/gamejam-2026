class_name VirtualCursor
extends Node2D

# the os cursor can't be scaled, so we capture the mouse and move our own for sensitivity

const RADIUS := 8.0

var enabled := false:
	set(value):
		enabled = value
		visible = value
		_apply_capture()

func _ready() -> void:
	position = get_viewport_rect().get_center()
	enabled = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED: _apply_capture()

func _exit_tree() -> void: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventMouseButton and event.pressed: _apply_capture() # regain after alt tab
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var moved: Vector2 = position + event.relative * GameConfig.mouse_sensitivity
		position = moved.clamp(Vector2.ZERO, get_viewport_rect().size)

# the os mouse is free whenever we're disabled or paused
func _apply_capture() -> void:
	var captured := enabled and is_inside_tree() and not get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 0.5, Color.WHITE)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, Color.WHITE, 2)
