class_name RunResult
extends RefCounted

enum Rank { S, A, B, C }

var score: int
var max_combo: int
var accuracy: float
var counts: Dictionary[Judgement.Grade, int] = {}
var rank: Rank
var finished_at: String

static func from_score(keeper: ScoreKeeper) -> RunResult:
	var result := RunResult.new()
	result.score = keeper.score
	result.max_combo = keeper.max_combo
	result.accuracy = keeper.accuracy()
	for grade: Judgement.Grade in Judgement.Grade.values(): result.counts[grade] = keeper.count(grade)
	result.rank = _rank(result.counts)
	result.finished_at = Time.get_datetime_string_from_system(false, true)
	return result

func rank_label() -> String: return Rank.keys()[rank]

func rank_color() -> Color:
	match rank:
		Rank.S: return Color(1.0, 0.85, 0.3)
		Rank.A: return Color(0.45, 0.9, 0.35)
		Rank.B: return Color(0.4, 0.75, 1.0)
		Rank.C: return Color(0.8, 0.5, 1.0)
	assert(false, "unhandled rank %s" % rank)
	return Color.WHITE

# osu ratio rules with SS folded into S and D into C
static func _rank(grade_counts: Dictionary[Judgement.Grade, int]) -> Rank:
	var total: int = grade_counts.values().reduce(func(s: int, c: int): return s + c, 0)
	if total == 0: return Rank.C
	var greats := grade_counts[Judgement.Grade.GREAT] / float(total)
	var mehs := grade_counts[Judgement.Grade.MEH] / float(total)
	var clean := grade_counts[Judgement.Grade.MISS] == 0
	if greats > 0.9 and mehs < 0.01 and clean: return Rank.S
	if greats > 0.9 or (greats > 0.8 and clean): return Rank.A
	if greats > 0.8 or (greats > 0.7 and clean): return Rank.B
	return Rank.C
