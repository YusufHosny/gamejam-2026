class_name CircleSkin
extends Resource

# osu-style skin elements, null ones fall back to the drawn look

@export var hit_circle: Texture2D # gray, tinted by combo colour
@export var overlay: Texture2D
@export var approach_circle: Texture2D
@export var digits: Array[Texture2D] = [] # 0-9
@export var digit_overlap := 6.0
@export var slider_ball: Texture2D
@export var follow_circle: Texture2D
@export var reverse_arrow: Texture2D
@export var combo_colors: Array[Color] = [Color.WHITE]
@export var slider_track := Color(0.1, 0.1, 0.12)
@export var slider_border := Color.WHITE
@export var scale := 1.1 # osu textures pad the circle, this lines the art up with the hit radius

func combo_color(group: int) -> Color: return combo_colors[group % combo_colors.size()]

func number_width(number: int, height: float) -> float:
	var width := 0.0
	for digit in str(number): width += _digit_size(int(digit), height).x - digit_overlap
	return width + digit_overlap

func draw_number(item: CanvasItem, center: Vector2, number: int, height: float, modulate: Color) -> void:
	var x := center.x - number_width(number, height) / 2
	for digit in str(number):
		var size := _digit_size(int(digit), height)
		item.draw_texture_rect(digits[int(digit)], Rect2(Vector2(x, center.y - size.y / 2), size), false, modulate)
		x += size.x - digit_overlap

static func draw_centered(item: CanvasItem, texture: Texture2D, center: Vector2, diameter: float, modulate := Color.WHITE, rotation := 0.0) -> void:
	item.draw_set_transform(center, rotation)
	item.draw_texture_rect(texture, Rect2(-Vector2.ONE * diameter / 2, Vector2.ONE * diameter), false, modulate)
	item.draw_set_transform(Vector2.ZERO)

func _digit_size(digit: int, height: float) -> Vector2:
	var texture := digits[digit]
	return Vector2(texture.get_width() * height / texture.get_height(), height)
