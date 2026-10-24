class_name VirtualCursor
extends Node2D

# the os cursor can't be scaled, so we capture the mouse and move our own for sensitivity

const RADIUS := 7.0
const GLOW_RADIUS := 15.0
const COLOR := Color(1.0, 0.85, 0.6)
const TRAIL_LIFETIME_MS := 120
const TRAIL_WIDTH := 7.0

class TrailPoint:
	var position: Vector2 # global
	var born_ms: int

	func _init(_position: Vector2, _born_ms: int) -> void:
		position = _position
		born_ms = _born_ms

var enabled := false:
	set(value):
		enabled = value
		visible = value
		_trail.clear()
		_apply_capture()

var _trail: Array[TrailPoint] = []

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

func _process(_delta: float) -> void:
	if not enabled: return
	var now := Time.get_ticks_msec()
	_trail.append(TrailPoint.new(global_position, now))
	_trail.assign(_trail.filter(func(p: TrailPoint): return now - p.born_ms < TRAIL_LIFETIME_MS))
	queue_redraw()

# the os mouse is free whenever we're disabled or paused
func _apply_capture() -> void:
	var captured := enabled and is_inside_tree() and not get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE

func _draw() -> void:
	var now := Time.get_ticks_msec()
	for i in range(1, _trail.size()):
		var fade := 1.0 - float(now - _trail[i].born_ms) / TRAIL_LIFETIME_MS
		var from := to_local(_trail[i - 1].position)
		var to := to_local(_trail[i].position)
		draw_line(from, to, Color(COLOR, 0.5 * fade), TRAIL_WIDTH * fade, true)
	draw_circle(Vector2.ZERO, GLOW_RADIUS, Color(COLOR, 0.2), true, -1, true)
	draw_circle(Vector2.ZERO, RADIUS, COLOR, true, -1, true)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, Color.WHITE, 2, true)
