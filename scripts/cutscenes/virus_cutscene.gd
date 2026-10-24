class_name VirusCutscene
extends Cutscene

# the shady submit button is a sticker: clicked, it peels off the virus button, then the ads start

const CENTER := Vector2(576, 300)
const BUTTON_WIDTH := 300.0
const CURSOR_SIZE := 48.0
const CURSOR_FROM := Vector2(1000, 600)
const PEEL_FROM := Vector2(1, 1) # the bottom right corner lifts first
# timeline in seconds
const CLICK_AT := 1.2
const PEEL_AT := 1.6
const PEEL_S := 1.8
const FLY_S := 0.8
const ADS_AT := 5.4
const ADS_PER_S := 4.0

@export var sticker: Texture2D
@export var sticker_back: Texture2D # same outline, paper coloured
@export var virus: Texture2D
@export var cursor: Texture2D
@export var cursor_click: Texture2D
@export var ads: Array[Texture2D] = []
@export var icons: Array[Texture2D] = []

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	Desktop.draw(self, icons)
	var rect := _button_rect(virus)
	draw_texture_rect(virus, rect, false)
	if time < PEEL_AT + PEEL_S + FLY_S: _draw_sticker()
	if time >= ADS_AT: _draw_ads()
	if time < PEEL_AT: _draw_cursor()

func _button_rect(texture: Texture2D) -> Rect2:
	var size := texture.get_size() * BUTTON_WIDTH / texture.get_width()
	return Rect2(CENTER - size / 2, size)

# --- Sticker ---
# folds along a line sweeping from the lifted corner, the folded flap shows the paper back
func _draw_sticker() -> void:
	var rect := _button_rect(sticker)
	var pressed := time >= CLICK_AT and time < PEEL_AT
	if pressed: rect = rect.grow(-6)
	var peel := smoothstep(0.0, 1.0, clampf((time - PEEL_AT) / PEEL_S, 0.0, 1.0))
	var fly := clampf((time - PEEL_AT - PEEL_S) / FLY_S, 0.0, 1.0)
	var toward := -PEEL_FROM.normalized() # the way the fold travels
	var reach := absf(rect.size.dot(toward)) # corner to corner along the fold direction
	var start := rect.get_center() + rect.size / 2 * PEEL_FROM
	var fold := start + toward * reach * peel * 1.02
	var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	if fly == 0.0:
		for polygon in Geometry2D.intersect_polygons(corners, _half(fold, toward, rect)):
			draw_colored_polygon(polygon, Color.WHITE, _uvs(polygon, rect), sticker)
	var lift := toward * 260.0 * fly * fly + Vector2(0, -120) * fly
	for polygon in Geometry2D.intersect_polygons(corners, _half(fold, -toward, rect)):
		var flap := PackedVector2Array()
		for point in polygon: flap.append(_mirror(point, fold, toward) + lift)
		draw_colored_polygon(flap, Color(1, 1, 1, 1.0 - fly), _uvs(polygon, rect), sticker_back)

func _half(through: Vector2, facing: Vector2, rect: Rect2) -> PackedVector2Array:
	var far := rect.size.length() * 2
	var side := facing.orthogonal() * far
	return PackedVector2Array([through - side, through + side, through + side + facing * far, through - side + facing * far])

static func _mirror(point: Vector2, through: Vector2, normal: Vector2) -> Vector2:
	return point - 2 * (point - through).dot(normal) * normal

static func _uvs(polygon: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for point in polygon: uvs.append((point - rect.position) / rect.size)
	return uvs

# --- Reveal ---
# the first few popups, a preview of the ad minigame
func _draw_ads() -> void:
	var count := mini(int((time - ADS_AT) * ADS_PER_S) + 1, ads.size() * 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var screen := get_viewport_rect().size
	for i in count:
		var texture := ads[(i * 7) % ads.size()]
		var at := Vector2(rng.randf_range(160, screen.x - 160), rng.randf_range(120, screen.y - 140))
		draw_texture_rect(texture, Rect2(at - texture.get_size() / 2, texture.get_size()), false)

func _draw_cursor() -> void:
	var move := smoothstep(0.0, 1.0, clampf(time / (CLICK_AT * 0.85), 0.0, 1.0))
	var tip := CURSOR_FROM.lerp(CENTER, move)
	var texture := cursor_click if time >= CLICK_AT and cursor_click != null else cursor
	draw_texture_rect(texture, Rect2(tip, Vector2.ONE * CURSOR_SIZE), false)
