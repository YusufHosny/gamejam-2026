class_name BlueScreenFlood
extends Node2D

# ads keep popping up after the ads stage, shaking and tearing as the computer gives up.
# procedural, so it stays in code. the cutscene's animation keyframes ads_shown and glitch

const SHAKE := 14.0
const TEAR_BARS := 7
const TEAR_COLORS: Array[Color] = [Color(0.0, 0.47, 0.84), Color.MAGENTA, Color.CYAN, Color.BLACK]

@export var ads: Array[Texture2D] = []
@export var icons: Array[Texture2D] = []
@export var ads_shown := 0.0
@export_range(0.0, 1.0) var glitch := 0.0

func _process(_delta: float) -> void: queue_redraw()

func _draw() -> void:
	var strength := glitch * SHAKE
	draw_set_transform(Vector2(randf_range(-strength, strength), randf_range(-strength, strength)))
	Desktop.draw(self, icons)
	_draw_ads()
	draw_set_transform(Vector2.ZERO)
	if glitch > 0.0: _draw_tears()

func _draw_ads() -> void:
	var screen := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	for i in int(ads_shown):
		rng.seed = i * 7919 + 3 # fixed per ad so they don't jump around between frames
		var texture := ads[(i * 7) % ads.size()]
		var at := Vector2(rng.randf_range(0, screen.x), rng.randf_range(0, screen.y))
		draw_texture_rect(texture, Rect2(at - texture.get_size() / 2, texture.get_size()), false)

func _draw_tears() -> void:
	var screen := get_viewport_rect().size
	for i in TEAR_BARS:
		var height := randf_range(4, 40) * glitch
		var bar := Rect2(randf_range(-80, 80), randf_range(0, screen.y), screen.x, height)
		draw_rect(bar, Color(TEAR_COLORS.pick_random(), randf_range(0.4, 0.9)))
