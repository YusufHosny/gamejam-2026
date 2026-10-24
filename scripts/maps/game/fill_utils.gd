class_name FillUtils
extends RefCounted

# shared by the hand-shaped map fillers

const COMBO_SIZE := 4

static func rng(rng_seed: int) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = rng_seed
	return generator

# beats between notes, fast songs get every other beat
static func step(map: Map) -> float: return 2.0 if map.bpm > DemoMap.FAST_BPM else 1.0

static func aim_note(beat: float, position: Vector2, index: int) -> AimNote:
	var note := AimNote.new(beat, position)
	note.new_combo = index % COMBO_SIZE == 0
	return note

static func flip(generator: RandomNumberGenerator) -> int: return 1 if generator.randf() < 0.5 else -1
