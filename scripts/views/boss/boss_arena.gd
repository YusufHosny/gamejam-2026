class_name BossArena
extends RefCounted

# dark stage behind the final fight

const BACKGROUND := Color(0.05, 0.05, 0.08)
const GRID := Color(0.5, 0.12, 0.16, 0.18)
const GRID_STEP := 48.0

static func draw(item: CanvasItem, now: float) -> void:
	var screen := item.get_viewport_rect().size
	item.draw_rect(Rect2(Vector2.ZERO, screen), BACKGROUND)
	var drift := fmod(now * 20.0, GRID_STEP)
	var x := -drift
	while x < screen.x:
		item.draw_line(Vector2(x, 0), Vector2(x, screen.y), GRID, 1)
		x += GRID_STEP
	var y := drift
	while y < screen.y:
		item.draw_line(Vector2(0, y), Vector2(screen.x, y), GRID, 1)
		y += GRID_STEP

static func button_rect(texture: Texture2D, center: Vector2, width: float) -> Rect2:
	var size := texture.get_size() * width / texture.get_width()
	return Rect2(center - size / 2, size)
