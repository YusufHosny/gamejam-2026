class_name VirusCutscene
extends Cutscene

# picks up on the subway captcha: verified, here's the submit button. its red top is a sticker: clicked, it peels
# off the virus button, the ads pop up and the captcha fades away, leaving the desktop the ads stage starts on

const CENTER := CaptchaFrame.ORIGIN + (CaptchaFrame.CONTENT.position + CaptchaFrame.CONTENT.size / 2) * CaptchaFrame.SCALE # inside the captcha
const BUTTON_WIDTH := 300.0
const CURSOR_SIZE := 48.0
const CURSOR_FROM := Vector2(1000, 600)
const PEEL_FROM := Vector2(1, 1) # the bottom right edge lifts first
# the red tops of both button images as ellipses in their own pixels, the sticker is only its red top
const STICKER_CAP_CENTER := Vector2(211, 148)
const STICKER_CAP_RADII := Vector2(198, 146) # a touch inside the red so none of the silver base shows
const VIRUS_CAP_CENTER := Vector2(96.5, 69)
const VIRUS_CAP_RADII := Vector2(92, 69)
const CAP_POINTS := 48
# timeline in seconds
const VERIFIED_S := 3.2 # the captcha says you're human before the cursor goes for the button
const HEADER_AT: Array[float] = [0.1, 0.5, 1.0] # when each header line shows
const HEADER_POPS: Array[bool] = [false, true, false] # the first two just appear, the last one pops in
const LINE_POP_S := 0.15
const BUTTON_IN_AT := 1.8 # after the last line
const BUTTON_POP_S := 0.15
const CLICK_AT := VERIFIED_S + 1.2
const PEEL_AT := VERIFIED_S + 1.6
const PEEL_S := 1.8
const FLY_S := 0.8
const ADS_AT := VERIFIED_S + 5.4 # AdsView.INTRO_POPUPS pop in from here
const FADE_AT := ADS_AT + 1.8 # the captcha fades out during the burst of three
const FADE_S := 0.6

@export var sticker: Texture2D
@export var sticker_back: Texture2D # same outline, paper coloured
@export var virus: Texture2D
@export var cursor: Texture2D
@export var cursor_click: Texture2D
@export var icons: Array[Texture2D] = []

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	Desktop.draw(self, icons)
	var alpha := 1.0 - clampf((time - FADE_AT) / FADE_S, 0.0, 1.0)
	if alpha > 0.0: _draw_captcha(alpha)
	_draw_ads()
	if time < PEEL_AT: _draw_cursor()

func _draw_captcha(alpha: float) -> void:
	CaptchaFrame.draw(self, alpha)
	var lines := ["Verification complete", "You're human!", "Here is your submit button."]
	for i in lines.size():
		if time < HEADER_AT[i]: continue
		var pop := clampf((time - HEADER_AT[i]) / LINE_POP_S, 0.0, 1.0) if HEADER_POPS[i] else 1.0
		CaptchaFrame.draw_header_line(self, i, lines[i], alpha, pop)
	if time < BUTTON_IN_AT: return
	draw_texture_rect(virus, _popped(_button_rect(virus)), false, Color(1, 1, 1, alpha))
	if time < PEEL_AT + PEEL_S + FLY_S: _draw_sticker()

func _button_rect(texture: Texture2D) -> Rect2:
	var size := texture.get_size() * BUTTON_WIDTH / texture.get_width()
	return Rect2(CENTER - size / 2, size)

# the virus button's red top on screen, the bounds of its ellipse
func _virus_cap() -> Rect2:
	var button := _button_rect(virus)
	var to_screen := button.size / virus.get_size()
	return Rect2(button.position + (VIRUS_CAP_CENTER - VIRUS_CAP_RADII) * to_screen, VIRUS_CAP_RADII * 2 * to_screen)

# grows in around the button's centre like the ads do, so the sticker and the button stay lined up
func _popped(rect: Rect2) -> Rect2:
	var grown := 0.6 + 0.4 * clampf((time - BUTTON_IN_AT) / BUTTON_POP_S, 0.0, 1.0)
	return Rect2(CENTER + (rect.position - CENTER) * grown, rect.size * grown)

static func _ellipse(bounds: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in CAP_POINTS: points.append(bounds.get_center() + Vector2.from_angle(TAU * i / CAP_POINTS) * bounds.size / 2)
	return points

# --- Sticker ---
# the red top of the submit image, stuck exactly over the virus button's. folds along a line sweeping from
# the lifted edge, the folded flap shows the paper back
func _draw_sticker() -> void:
	var cap := _popped(_virus_cap())
	var pressed := time >= CLICK_AT and time < PEEL_AT
	if pressed: cap = cap.grow(-6)
	var to_screen := cap.size / (STICKER_CAP_RADII * 2)
	var rect := Rect2(cap.get_center() - STICKER_CAP_CENTER * to_screen, sticker.get_size() * to_screen) # the whole image, so its red top lands on cap
	var peel := smoothstep(0.0, 1.0, clampf((time - PEEL_AT) / PEEL_S, 0.0, 1.0))
	var fly := clampf((time - PEEL_AT - PEEL_S) / FLY_S, 0.0, 1.0)
	var toward := -PEEL_FROM.normalized() # the way the fold travels
	var radii := cap.size / 2
	var edge := Vector2(radii.x * toward.x, radii.y * toward.y).length() # centre to the ellipse's edge along the fold direction
	var start := cap.get_center() - toward * edge
	var fold := start + toward * 2 * edge * peel * 1.02
	var outline := _ellipse(cap)
	if fly == 0.0:
		for polygon in Geometry2D.intersect_polygons(outline, _half(fold, toward, cap)):
			draw_colored_polygon(polygon, Color.WHITE, _uvs(polygon, rect), sticker)
	var lift := toward * 260.0 * fly * fly + Vector2(0, -120) * fly
	for polygon in Geometry2D.intersect_polygons(outline, _half(fold, -toward, cap)):
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
# the first popups, a preview of the ad minigame. they stay open when it starts
func _draw_ads() -> void:
	for popup in AdsView.INTRO_POPUPS:
		var shown: float = time - ADS_AT - popup.pop_at # typed, popup is a Dictionary
		if shown < 0.0: continue
		var rect := AdsView.intro_rect(popup)
		var pop := 0.6 + 0.4 * clampf(shown / AdsView.POP_S, 0.0, 1.0)
		draw_texture_rect(popup.texture, Rect2(rect.get_center() - rect.size * pop / 2, rect.size * pop), false)

func _draw_cursor() -> void:
	var move := smoothstep(0.0, 1.0, clampf((time - VERIFIED_S) / ((CLICK_AT - VERIFIED_S) * 0.85), 0.0, 1.0))
	var tip := CURSOR_FROM.lerp(CENTER, move)
	var texture := cursor_click if time >= CLICK_AT and cursor_click != null else cursor
	draw_texture_rect(texture, Rect2(tip, Vector2.ONE * CURSOR_SIZE), false)
