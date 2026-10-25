class_name TimingBar
extends Control

const TICK_LIFETIME_MS := 4000
const MEAN_SMOOTHING := 0.15
const BANDS: Array[Judgement.Grade] = [Judgement.Grade.MEH, Judgement.Grade.OK, Judgement.Grade.GREAT]

class Tick:
	var error_s: float
	var born_ms: int

	func _init(_error_s: float, _born_ms: int) -> void:
		error_s = _error_s
		born_ms = _born_ms

var _ticks: Array[Tick] = []
var _mean_error_s := 0.0

func add(error_s: float) -> void:
	_ticks.append(Tick.new(error_s, Time.get_ticks_msec()))
	_mean_error_s = lerpf(_mean_error_s, error_s, MEAN_SMOOTHING)

func clear() -> void:
	_ticks.clear()
	_mean_error_s = 0.0

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	_ticks.assign(_ticks.filter(func(t: Tick): return now - t.born_ms < TICK_LIFETIME_MS))
	queue_redraw()

func _draw() -> void:
	for grade in BANDS: # widest first so narrower bands paint over
		var half := _x(GameConfig.hit_window_ms(grade) / 1000.0) - size.x / 2
		draw_rect(Rect2(size.x / 2 - half, size.y * 0.35, half * 2, size.y * 0.3), Color(Judgement.color(grade), 0.5))
	var now := Time.get_ticks_msec()
	for tick in _ticks:
		var alpha := 1.0 - float(now - tick.born_ms) / TICK_LIFETIME_MS
		var x := _x(tick.error_s)
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(Judgement.color(Judgement.grade(tick.error_s)), alpha), 2)
	var mean := _x(_mean_error_s)
	draw_colored_polygon(PackedVector2Array([
		Vector2(mean, size.y), Vector2(mean - 6, size.y + 9), Vector2(mean + 6, size.y + 9)
	]), Color.WHITE)

# early on the left, late on the right
func _x(error_s: float) -> float:
	return size.x / 2 * (1.0 + error_s / GameConfig.miss_window_s())
