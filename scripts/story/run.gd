class_name Run
extends Resource

@export var steps: Array[RunStep] = []

func _init(_steps: Array[RunStep] = []) -> void:
	steps = _steps

func first_timed() -> int: return steps.find_custom(func(s: RunStep): return s.timed)

# the deadline is the timed steps back to back, minus the stretch where the clock holds still, so it always hits 0 at the end
func deadline_s() -> float: return _timed_length(steps) - frozen_s()

func time_left(index: int, position_s: float) -> float:
	var elapsed := _timed_length(steps.slice(0, index)) + position_s
	return deadline_s() - maxf(elapsed - frozen_s(), 0.0)

# the clock holds still from the countdown until the first map's first notes
func frozen_s() -> float:
	var first := steps.find_custom(func(s: RunStep): return s.timed and s is MapStep)
	if first == -1: return 0.0
	var step: MapStep = steps[first]
	return _timed_length(steps.slice(0, first)) + step.pre_roll_s + step.map.segments[0].start_time

static func _timed_length(of: Array[RunStep]) -> float:
	return of.filter(func(s: RunStep): return s.timed).reduce(func(t: float, s: RunStep): return t + s.length_s(), 0.0)
