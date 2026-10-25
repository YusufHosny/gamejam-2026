class_name LaptopDesk
extends CoverSprite

# the laptop on a desk the blue screen zooms out to

const SCREEN := Rect2(0.2545, 0.1506, 0.5108, 0.4505) # fraction of the texture inside the bezel, any export size works
const SIDE := Vector2(0.2188, 0.733) # fraction of the texture, the base's left edge beside the keyboard
const OVERSCAN := 1.02 # the zoomed in screen overshoots the view a little so no bezel shows
const SIDE_ZOOM := 5.0 # how close the side zoom gets to the laptop's side, where the usb goes in

# where the screen is, in the parent's coordinates
func screen_rect() -> Rect2:
	var size := texture.get_size() * scale
	return Rect2(position + SCREEN.position * size, SCREEN.size * size)

func side_point() -> Vector2: return position + SIDE * texture.get_size() * scale

# the parent's transform for a zoom. zoom_out 0 the screen covers the view, 1 the whole desk shows. zoom_side 1 then
# goes in on the laptop's side. both exponentially so the zoom speed feels even, and each moves its focus point to or
# from the view's centre
func framing(view: Rect2, zoom_out: float, zoom_side: float) -> Transform2D:
	var screen := screen_rect()
	var zoomed_in := maxf(view.size.x / screen.size.x, view.size.y / screen.size.y) * OVERSCAN
	var zoom := pow(zoomed_in, 1.0 - zoom_out)
	var centre := screen.get_center()
	var origin := view.get_center().lerp(centre, zoom_out) - centre * zoom
	var side := side_point()
	var side_at := view.get_center().lerp(origin + side * zoom, 1.0 - zoom_side) # where the side shows on screen
	zoom *= pow(SIDE_ZOOM, zoom_side)
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, side_at - side * zoom)
