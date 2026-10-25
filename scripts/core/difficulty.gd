class_name Difficulty
extends RefCounted

# autoplay plays itself, judge is osu relax (aim only, misses count as 50s), french swaps in the hard maps and speaks french
enum Level { AUTOPLAY, JUDGE, STANDARD, HARD }
enum MapSet { STANDARD, HARD }

const JUDGE_WINDOW_SCALE := 2.5
const STANDARD_WINDOW_SCALE := 1.5
const STANDARD_SIZE_SCALE := 1.3 # apples and subway circles

static func label(level: Level) -> String:
	match level:
		Level.AUTOPLAY: return "Autoplay"
		Level.JUDGE: return "Judge"
		Level.STANDARD: return "Standard"
		Level.HARD: return "French"
	assert(false, "unhandled difficulty %s" % level)
	return ""

# the voice lines and captions, VoiceLines.LANGUAGES
static func language(level: Level) -> String: return "fr" if level == Level.HARD else "en"

static func map_set(level: Level) -> MapSet: return MapSet.HARD if level == Level.HARD else MapSet.STANDARD

static func autoplays(level: Level) -> bool: return level == Level.AUTOPLAY

# aim and slash are judged on aim alone, misses score 50 so the combo never drops
static func relaxed(level: Level) -> bool: return level == Level.JUDGE

static func window_scale(level: Level) -> float:
	if relaxed(level): return JUDGE_WINDOW_SCALE
	return STANDARD_WINDOW_SCALE if map_set(level) == MapSet.STANDARD else 1.0

# targets that grow on the standard map set
static func size_scale(level: Level) -> float: return STANDARD_SIZE_SCALE if map_set(level) == MapSet.STANDARD else 1.0

static func on_leaderboard(level: Level) -> bool: return not autoplays(level)
