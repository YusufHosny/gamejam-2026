class_name Difficulty
extends RefCounted

# judge is osu autoplay, hard swaps in harder maps
enum Level { JUDGE, STANDARD, HARD }

static func label(level: Level) -> String:
	match level:
		Level.JUDGE: return "judge"
		Level.STANDARD: return "standard"
		Level.HARD: return "hard"
	assert(false, "unhandled difficulty %s" % level)
	return ""

# only standard is implemented so far
static func is_available(level: Level) -> bool: return level == Level.STANDARD
