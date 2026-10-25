class_name LaptopDesk
extends CoverSprite

# the laptop on a desk the blue screen zooms out to

const SCREEN := Rect2(0.2545, 0.1506, 0.5108, 0.4505) # fraction of the texture inside the bezel, any export size works
const SIDE := Vector2(0.2188, 0.733) # fraction of the texture, the base's left edge beside the keyboard

# where the screen is, in the parent's coordinates
func screen_rect() -> Rect2:
	var size := texture.get_size() * scale
	return Rect2(position + SCREEN.position * size, SCREEN.size * size)

func side_point() -> Vector2: return position + SIDE * texture.get_size() * scale
