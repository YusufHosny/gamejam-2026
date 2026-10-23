@abstract
class_name TargetMode
extends ModeHandler

# shared osu-style approach circle rendering for aim + click and slash

const RADIUS := 48.0
const APPROACH_SCALE := 2.0 # ring starts at RADIUS * (1 + APPROACH_SCALE)

@export var color := Color.WHITE
var cursor: VirtualCursor

func _draw() -> void:
	var now := conductor.song_time()
	var approach := GameConfig.approach_time_s
	for i in range(_pending.size() - 1, -1, -1): # reversed so the next note is on top
		var note := _pending[i] as AimNote
		var until := note.time - now
		if until > approach: continue
		var alpha := 1.0 - clampf(until / approach, 0.0, 1.0)
		draw_circle(note.position, RADIUS, Color(color, 0.25 * alpha))
		draw_arc(note.position, RADIUS, 0, TAU, 48, Color(color, alpha), 3)
		if until > 0:
			var ring := RADIUS * (1.0 + APPROACH_SCALE * until / approach)
			draw_arc(note.position, ring, 0, TAU, 64, Color(color, alpha), 2)
