class_name LaughCutscene
extends Cutscene

# after the stream: the angry button bobs in the arena laughing at you, then slides to where the moonlight chase starts

const LAUGH := "AHAHAHAHAHAHAHAHAHA"
const HA_S := 0.14 # one letter every this long, a ha every two
const BUTTON_SIZE := 220.0
const SETTLE_S := 0.7 # the end, sliding to the chase's first spot
const TEXT_SIZE := 64
const TEXT_COLOR := Color(1.0, 0.3, 0.3)

@export var button: Texture2D

var _laugh: AudioStreamPlayer
var _has := 0

func _ready() -> void:
	_laugh = AudioStreamPlayer.new()
	_laugh.stream = SfxUtils.alarm(0.09, 0.22)
	add_child(_laugh)

func _process(delta: float) -> void:
	super(delta)
	var has := mini(floori(time / (HA_S * 2.0)), LAUGH.length() / 2)
	if has > _has and time < length_s - SETTLE_S: # a ha each, pitch wobbling like a cackle
		_laugh.pitch_scale = 1.3 - 0.06 * (has % 5) + randf() * 0.1
		_laugh.play()
	_has = has
	queue_redraw()

func _draw() -> void:
	BossArena.draw(self, time)
	var middle := get_viewport_rect().size / 2 + Vector2(0, 40)
	var settle := clampf((time - (length_s - SETTLE_S)) / SETTLE_S, 0.0, 1.0)
	var bob := Vector2(sin(time * 40.0) * 6.0, -absf(sin(time * PI / HA_S)) * 18.0) * (1.0 - settle)
	var at := middle.lerp(BossMaps.chase_start(), settle * settle * (3.0 - 2.0 * settle)) + bob
	var squash := 1.0 + 0.08 * sin(time * TAU / (HA_S * 2.0)) * (1.0 - settle)
	draw_texture_rect(button, BossArena.button_rect(button, at, BUTTON_SIZE * squash), false)
	var shown := LAUGH.left(mini(floori(time / HA_S), LAUGH.length()))
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_SIZE).x
	var shake := Vector2(randf_range(-3, 3), randf_range(-3, 3)) * (1.0 - settle)
	draw_string(font, middle + Vector2(-width / 2, -BUTTON_SIZE * 0.75) + shake, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_SIZE, Color(TEXT_COLOR, 1.0 - settle))
