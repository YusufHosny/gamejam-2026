class_name Judgement
extends RefCounted

enum Grade { GREAT, OK, MEH, MISS }

static func grade(error_s: float) -> Grade:
	var error_ms := absf(error_s) * 1000.0
	for g: Grade in [Grade.GREAT, Grade.OK, Grade.MEH]:
		if error_ms <= GameConfig.hit_window_ms(g): return g
	return Grade.MISS

static func value(g: Grade) -> int:
	match g:
		Grade.GREAT: return 300
		Grade.OK: return 100
		Grade.MEH: return 50
		Grade.MISS: return 0
	assert(false, "unhandled grade %s" % g)
	return 0

static func label(g: Grade) -> String:
	match g:
		Grade.MISS: return "miss"
		_: return str(value(g))

static func color(g: Grade) -> Color:
	match g:
		Grade.GREAT: return Color(0.4, 0.75, 1.0)
		Grade.OK: return Color(0.45, 0.9, 0.35)
		Grade.MEH: return Color(1.0, 0.85, 0.3)
		Grade.MISS: return Color(1.0, 0.3, 0.3)
	assert(false, "unhandled grade %s" % g)
	return Color.WHITE
