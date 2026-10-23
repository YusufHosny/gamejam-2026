class_name VirtualCursor
extends Node2D

# the os cursor can't be scaled, so we capture the mouse and move our own for sensitivity

const RADIUS := 8.0

var enabled := false:
	set(value):
		enabled = value
		visible = value
		_capture(value)

func _ready() -> void:
	position = get_viewport_rect().get_center()
	enabled = false

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event.is_action_pressed(&"release_cursor"): _capture(false)
	elif event is InputEventMouseButton and event.pressed: _capture(true)
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var moved: Vector2 = position + event.relative * GameConfig.mouse_sensitivity
		position = moved.clamp(Vector2.ZERO, get_viewport_rect().size)

func _capture(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 0.5, Color.WHITE)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, Color.WHITE, 2)
