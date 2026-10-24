class_name CoverSprite
extends Sprite2D

# a full screen picture, scaled to cover the view whatever its aspect and centred on it

func _ready() -> void:
	centered = false
	get_viewport().size_changed.connect(_cover)
	_cover()

func _cover() -> void:
	var view := get_viewport_rect()
	var size := texture.get_size()
	var fit := maxf(view.size.x / size.x, view.size.y / size.y)
	scale = Vector2(fit, fit)
	position = view.position + (view.size - size * fit) / 2
