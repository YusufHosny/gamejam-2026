class_name HitResult
extends RefCounted

var note: Note
var grade: Judgement.Grade
var error_s: float # negative is early, NAN on a miss

func _init(_note: Note, _grade: Judgement.Grade, _error_s := NAN) -> void:
	note = _note
	grade = _grade
	error_s = _error_s

static func hit(_note: Note, _error_s: float) -> HitResult:
	return HitResult.new(_note, Judgement.grade(_error_s), _error_s)

static func miss(_note: Note) -> HitResult:
	return HitResult.new(_note, Judgement.Grade.MISS)

func is_miss() -> bool: return grade == Judgement.Grade.MISS
