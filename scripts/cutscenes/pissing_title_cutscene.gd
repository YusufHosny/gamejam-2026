class_name PissingTitleCutscene
extends Cutscene

# the finale's title and thanks cards, big yellow letters bouncing in one at a time with a drip under each

const LETTER_S := 0.08
const POP_S := 0.35
const YELLOW := Color(1.0, 0.88, 0.15)
const OUTLINE := Color(0.35, 0.25, 0.0)
const BACKGROUND := Color(0.08, 0.08, 0.1)

@export var title := "PISSING GAME"
@export var text_size := 110

# a tap per letter as it bounces in, climbing
func sfx_cues() -> Array:
	var cues := []
	for i in title.length():
		if title[i] != " ": cues.append([i * LETTER_S, &"tap", 1.0 + 0.04 * i])
	return cues

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), BACKGROUND)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var x := (screen.x - width) / 2.0
	var baseline := screen.y / 2.0 + text_size * 0.35
	for i in title.length():
		var letter := title[i]
		var advance := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
		var t := clampf((time - i * LETTER_S) / POP_S, 0.0, 1.0)
		if t > 0.0 and letter != " ":
			var bounce := 1.0 + sin(t * PI) * 0.35 # overshoots, then settles
			var wobble := sin(time * 6.0 + i) * 4.0
			var at := Vector2(x + advance / 2.0, baseline + wobble)
			draw_set_transform(at, sin(time * 3.0 + i) * 0.06, Vector2.ONE * bounce * t)
			var offset := Vector2(-advance / 2.0, 0)
			for o: Vector2 in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4), Vector2(5, 6)]: draw_string(font, offset + o, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, OUTLINE)
			draw_string(font, offset, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, YELLOW)
			var drip := clampf((time - i * LETTER_S - POP_S) / 1.2, 0.0, 1.0) * (18 + (i * 7) % 23)
			draw_line(Vector2(0, 8), Vector2(0, 8 + drip), YELLOW, 6, true)
			draw_circle(Vector2(0, 10 + drip), 5, YELLOW, true, -1, true)
			draw_set_transform(Vector2.ZERO)
		x += advance
