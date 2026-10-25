class_name DogCaptchaView
extends AimView

# c1: dogs pop onto tiles as their notes approach, bagels fill the rest

const GAP := 6.0 # frame pixels between tiles
const TILE := (772.0 - 2 * GAP) / 3
const APPROACH_GROW := 32.0 # screen px the approach square starts outside its tile
const APPROACH_FILL := 0.35 # the tile tints in as its next note closes
const BADGE_RADIUS := 15.0
const STACK_GAP_S := 0.25 # closer taps on one tile count as a stack
const SELECTED_S := 0.35
const SELECTED_INSET := 10.0
const MISS := Color(0.85, 0.22, 0.22)

@export var target := "dogs"

var _tiles: Dictionary[AimNote, int] = {}
var _images: Dictionary[AimNote, Texture2D] = {}
var _stack_left: Dictionary[AimNote, int] = {} # taps left in its stack, itself included
var _refreshes: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0] # each hit swaps that tile's decoy
var _marked_ms: Array[int] = [-100000, -100000, -100000, -100000, -100000, -100000, -100000, -100000, -100000]
var _marked_miss: Array[bool] = [false, false, false, false, false, false, false, false, false]
var _marked_image: Array[Texture2D] = [null, null, null, null, null, null, null, null, null] # stays up while ticked

static func tile_rect(tile: int) -> Rect2:
	var source := CaptchaFrame.CONTENT.position + Vector2(tile % 3, tile / 3) * (TILE + GAP)
	return CaptchaFrame.to_screen(Rect2(source, Vector2.ONE * TILE))

static func tile_at(point: Vector2) -> int:
	for tile in 9:
		if tile_rect(tile).has_point(point): return tile
	return -1

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	var targets := CaptchaImages.TARGETS
	for i in mode.segment.notes.size():
		var note := mode.segment.notes[i] as AimNote
		_tiles[note] = tile_at(note.position)
		_images[note] = targets[(i * 7) % targets.size()] # 7 is coprime with 13, so every dog shows up
	var notes := mode.segment.notes
	for i in range(notes.size() - 1, -1, -1):
		var note := notes[i] as AimNote
		var next := notes[i + 1] as AimNote if i + 1 < notes.size() else null
		var stacked := next != null and _tiles[next] == _tiles[note] and next.time - note.time <= STACK_GAP_S
		_stack_left[note] = _stack_left[next] + 1 if stacked else 1
	mode.judged.connect(_on_judged)

func is_hit(note: AimNote, _from: Vector2, to: Vector2) -> bool:
	return tile_rect(_tiles[note]).has_point(to_local(to))

func is_following(_slider: SliderNote, _point: Vector2, _progress: float) -> bool: return false # no sliders here

func _on_judged(result: HitResult) -> void:
	var note := result.note as AimNote
	var tile := _tiles[note]
	_marked_image[tile] = _images[note]
	_marked_ms[tile] = Time.get_ticks_msec()
	_marked_miss[tile] = result.is_miss()
	if not result.is_miss(): _refreshes[tile] += 1

func _draw() -> void:
	Desktop.draw(self)
	var now := _now()
	CaptchaFrame.draw(self)
	CaptchaFrame.draw_header(self, "Select all images with", target, "Click verify once there are none left.")
	for tile in 9: _draw_tile(tile, now)

func _draw_tile(tile: int, now: float) -> void:
	var rect := tile_rect(tile)
	var note := _upcoming(tile, now)
	var decoys := CaptchaImages.DECOYS
	var marked := Time.get_ticks_msec() - _marked_ms[tile] < SELECTED_S * 1000
	var image: Texture2D = decoys[(tile + _refreshes[tile]) % decoys.size()]
	if note != null: image = _images[note]
	elif marked: image = _marked_image[tile]
	draw_texture_rect(image, rect.grow(-SELECTED_INSET) if marked else rect, false)
	if marked: _draw_mark(rect, _marked_miss[tile])
	if note != null: _draw_approach(rect, note, now)

# the square closes on the tile's next note, a stack shows how many taps it holds from the start
func _draw_approach(rect: Rect2, note: AimNote, now: float) -> void:
	var closing := clampf((note.time - now) / GameConfig.approach_time_s, 0.0, 1.0)
	draw_rect(rect, Color(CaptchaFrame.ACCENT, APPROACH_FILL * (1.0 - closing)))
	draw_rect(rect.grow(APPROACH_GROW * closing), Color(CaptchaFrame.ACCENT, 1.0 - closing * 0.5), false, 4)
	var taps := _stack_left[note]
	if taps < 2: return
	var center := rect.end - Vector2.ONE * (BADGE_RADIUS + 6)
	draw_circle(center, BADGE_RADIUS, CaptchaFrame.ACCENT, true, -1, true)
	var font := ThemeDB.fallback_font
	var label := "x%d" % taps
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, center + Vector2(-size.x / 2, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_mark(rect: Rect2, missed: bool) -> void:
	var center := rect.position + Vector2(16, 16)
	draw_circle(center, 12, MISS if missed else CaptchaFrame.ACCENT, true, -1, true)
	if missed:
		draw_line(center + Vector2(-5, -5), center + Vector2(5, 5), Color.WHITE, 3, true)
		draw_line(center + Vector2(-5, 5), center + Vector2(5, -5), Color.WHITE, 3, true)
	else:
		draw_polyline(PackedVector2Array([center + Vector2(-6, 0), center + Vector2(-2, 5), center + Vector2(6, -5)]), Color.WHITE, 3, true)

# the dog showing on a tile: its next note once that note starts approaching
func _upcoming(tile: int, now: float) -> AimNote:
	for note: AimNote in mode.pending():
		if note.time - now > GameConfig.approach_time_s: return null
		if _tiles[note] == tile: return note
	return null
