class_name CircleFourDView
extends ModeView

const LANE_WIDTH := 90.0
const NOTE_RADIUS := 32.0
const HIT_LINE_MARGIN := 100.0

@export var skin: CircleSkin

func _ready() -> void:
	if skin != null: texture_filter = TEXTURE_FILTER_LINEAR

func _draw() -> void:
	var now := _now()
	var hit_y := get_viewport_rect().size.y - HIT_LINE_MARGIN
	for lane in FourDMode.LANES.size():
		var receptor := Vector2(_lane_x(lane), hit_y)
		var pressed := Input.is_action_pressed(FourDMode.LANES[lane])
		if skin != null:
			CircleSkin.draw_centered(self, skin.overlay, receptor, NOTE_RADIUS * 2 * skin.scale, Color(1, 1, 1, 1.0 if pressed else 0.5))
			continue
		draw_arc(receptor, NOTE_RADIUS, 0, TAU, 48, Color.WHITE, 3)
		if pressed: draw_circle(receptor, NOTE_RADIUS * 0.6, Color(1, 1, 1, 0.4))
	for note: LaneNote in mode.pending():
		var y := hit_y - (note.time - now) * GameConfig.scroll_speed
		if y < -NOTE_RADIUS: break
		_draw_note(Vector2(_lane_x(note.lane), y), note.lane)

func _draw_note(center: Vector2, lane: int) -> void:
	if skin == null:
		draw_circle(center, NOTE_RADIUS, Color.WHITE)
		return
	var diameter := NOTE_RADIUS * 2 * skin.scale
	CircleSkin.draw_centered(self, skin.hit_circle, center, diameter, skin.combo_color(lane))
	CircleSkin.draw_centered(self, skin.overlay, center, diameter)

func _lane_x(lane: int) -> float:
	return get_viewport_rect().size.x / 2 + (lane - 1.5) * LANE_WIDTH
