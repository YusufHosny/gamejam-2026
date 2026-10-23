class_name ScoreKeeper
extends RefCounted

var score := 0
var combo := 0
var max_combo := 0
var _counts: Dictionary[Judgement.Grade, int] = {}

# osu v1 scoring, hitval x combo
func add(result: HitResult) -> void:
	_counts[result.grade] = _counts.get(result.grade, 0) + 1
	if result.is_miss():
		combo = 0
		return
	score += roundi(Judgement.value(result.grade) * (1.0 + combo / 25.0))
	combo += 1
	max_combo = maxi(max_combo, combo)

func accuracy() -> float:
	var total := 0
	var scored := 0
	for grade in _counts:
		total += _counts[grade]
		scored += _counts[grade] * Judgement.value(grade)
	if total == 0: return 1.0
	return scored / float(total * Judgement.value(Judgement.Grade.GREAT))
