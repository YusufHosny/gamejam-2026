class_name CreditsCutscene
extends Cutscene

# the end credits roll up over la marseillaise: every role is Louis, then the supporting team side by side. photos come from
# assets/french guy, one per role in order, missing ones show a placeholder frame

const ROLES: Array[String] = [
	"Team Leader", "Lead Voice Actor", "Voice Director", "French Culture Specialist", "French Translation",
	"English Translation", "Asset Manager", "Head of Quality Assurance", "Executive Producer", "Catering",
]
const STAR := "Louis Anseaume"
const SUPPORT: Array[String] = ["Yusuf Hussien", "Vivian Tsang"]
const PHOTOS := "res://assets/french guy/"
const STAR_PHOTO := "french guy %d.png" # 1 to ROLES.size(), in ROLES' order
const SUPPORT_PHOTOS: Array[String] = ["yusuf.jpeg", "vivian.jpeg"]
const PHOTO := 230.0 # square frame
const SUPPORT_PHOTO := 190.0
const SUPPORT_GAP := 70.0 # between the two supporting photos
const ROLE_SIZE := 22
const NAME_SIZE := 44
const HEADING_SIZE := 60
const ENTRY_GAP := 90.0
const HOLD_S := 4.0 # the supporting team stays up this long at the end
const FADE_S := 1.5 # the anthem fades out over the end
const BACKGROUND := Color(0.04, 0.04, 0.07)
const GOLD := Color(1.0, 0.85, 0.45)
const FLAG: Array[Color] = [Color(0.0, 0.33, 0.64), Color.WHITE, Color(0.94, 0.25, 0.21)]

@export var music: AudioStream

var _photos: Array[Texture2D] = []
var _support_photos: Array[Texture2D] = []
var _player: AudioStreamPlayer

func _ready() -> void:
	for i in ROLES.size(): _photos.append(_photo(STAR_PHOTO % (i + 1)))
	for name in SUPPORT_PHOTOS: _support_photos.append(_photo(name))
	_player = AudioStreamPlayer.new()
	_player.stream = music
	add_child(_player)
	_player.play()

static func _photo(file: String) -> Texture2D:
	var path := PHOTOS + file
	return load(path) if ResourceLoader.exists(path) else null

func restart() -> void:
	super()
	_player.play()

func _process(delta: float) -> void:
	super(delta)
	_player.volume_db = linear_to_db(clampf((length_s - time) / FADE_S, 0.001, 1.0))
	queue_redraw()

func _draw() -> void:
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), BACKGROUND)
	for i in FLAG.size(): draw_rect(Rect2(i * screen.x / 3.0, screen.y - 6, screen.x / 3.0, 6), FLAG[i])
	# the column scrolls up until the supporting team sits in the middle, then holds
	var stop := _height() - screen.y / 2.0 - SUPPORT_PHOTO / 2.0
	var scroll := screen.y + stop
	var y := screen.y - scroll * clampf(time / maxf(length_s - HOLD_S, 0.001), 0.0, 1.0)
	var x := screen.x / 2.0
	_text("CREDITS", Vector2(x, y + HEADING_SIZE), HEADING_SIZE, GOLD)
	y += HEADING_SIZE + ENTRY_GAP
	for i in ROLES.size():
		_text(ROLES[i].to_upper(), Vector2(x, y + ROLE_SIZE), ROLE_SIZE, GOLD)
		_text(STAR, Vector2(x, y + ROLE_SIZE + 12 + NAME_SIZE), NAME_SIZE, Color.WHITE)
		_draw_photo(_photos[i], Rect2(x - PHOTO / 2.0, y + ROLE_SIZE + NAME_SIZE + 36, PHOTO, PHOTO))
		y += _entry_height()
	_text("SUPPORTING TEAM MEMBERS", Vector2(x, y + ROLE_SIZE), ROLE_SIZE, GOLD)
	y += ROLE_SIZE + 24
	for i in SUPPORT.size():
		var middle := x + (i - 0.5) * (SUPPORT_PHOTO + SUPPORT_GAP) # either side of the middle
		var frame := Rect2(middle - SUPPORT_PHOTO / 2.0, y, SUPPORT_PHOTO, SUPPORT_PHOTO)
		_draw_photo(_support_photos[i], frame)
		_text(SUPPORT[i], Vector2(frame.get_center().x, frame.end.y + 40), 30, Color.WHITE)

func _entry_height() -> float: return ROLE_SIZE + NAME_SIZE + 36 + PHOTO + ENTRY_GAP

# top of the column to the middle of the supporting photos
func _height() -> float: return HEADING_SIZE + ENTRY_GAP + ROLES.size() * _entry_height() + ROLE_SIZE + 24 + SUPPORT_PHOTO

# fitted inside the square, or a placeholder frame until the photo arrives
func _draw_photo(photo: Texture2D, frame: Rect2) -> void:
	if photo == null:
		draw_rect(frame, Color(1, 1, 1, 0.06))
		draw_rect(frame, Color(1, 1, 1, 0.35), false, 2)
		_text("photo", frame.get_center() + Vector2(0, 8), 20, Color(1, 1, 1, 0.35))
		return
	var size := photo.get_size() * minf(frame.size.x / photo.get_width(), frame.size.y / photo.get_height())
	draw_texture_rect(photo, Rect2(frame.get_center() - size / 2.0, size), false)
	draw_rect(Rect2(frame.get_center() - size / 2.0, size), GOLD, false, 2)

func _text(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, at - Vector2(width / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
