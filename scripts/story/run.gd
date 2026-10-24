class_name Run
extends Resource

@export var steps: Array[RunStep] = []

func _init(_steps: Array[RunStep] = []) -> void:
	steps = _steps

func first_timed() -> int: return steps.find_custom(func(s: RunStep): return s.timed)

# the deadline is the timed steps back to back, so it always hits 0 at the end
func deadline_s() -> float: return _timed_length(steps)

func time_left(index: int, position_s: float) -> float:
	return deadline_s() - _timed_length(steps.slice(0, index)) - position_s

static func _timed_length(of: Array[RunStep]) -> float:
	return of.filter(func(s: RunStep): return s.timed).reduce(func(t: float, s: RunStep): return t + s.length_s(), 0.0)
