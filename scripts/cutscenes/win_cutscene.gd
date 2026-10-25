class_name WinCutscene
extends Cutscene

# picks up on the boss map's last frame, the button caught with "submitted" under it. it holds, then the button shakes,
# swells and flashes white hot faster and faster until it blows apart. the flash fades onto the desktop with the jam site
# saying the submission went through, and the player breathes out

const LENGTH_S := 12.0
const AT := Vector2(580, 320) # BossMaps.final_spot(), where f4 leaves the button
const BUTTON_WIDTH := (BossChaseView.BUTTON_RADIUS + 12) * 2 # grown like the caught button
const BUILD_AT := 1.5
const EXPLODE_AT := 4.0
const CAPTION_OUT_S := 0.4 # "submitted" fades as the build up starts
const SWELL := 0.3
const SHAKE := 12.0
const SCREEN_SHAKE := 5.0
const RED := Color(1.0, 0.2, 0.15) # the closing rings
const HOT := Color(1.0, 0.97, 0.9) # the button's already red, so it pulses white hot
const HOT_ALPHA := 0.8
const RINGS := 3 # closing in on the button, faster and faster
const RING_FROM := 280.0
const SHARD_GRID := 4 # the button breaks into SHARD_GRID x SHARD_GRID pieces
const SHARD_SPEED := Vector2(380, 900)
const SHARD_SPIN := 9.0
const GRAVITY := 900.0
const SHARD_S := 1.1
const SHOCKWAVE_S := 0.7
const FIREBALL_S := 0.35
const FIREBALL_RADIUS := 230.0
const BLAST_SHAKE := 26.0
const BLAST_SHAKE_S := 0.6
const WHITE_IN_S := 0.5 # the flash builds to full white
const REVEAL_AT := EXPLODE_AT + 0.6 # the desktop's under the white from here
const WHITE_OUT_AT := EXPLODE_AT + 0.7
const WHITE_OUT_S := 0.8
const COMPLETE_POP_AT := WHITE_OUT_AT + 0.3
const POP_S := 0.2
const VOICE_AT := 5.6
const SUCCESS := Color(0.2, 0.72, 0.35)

@export var button: Texture2D # submit_round_angry.png, the final chase's

var _shards: Array[Dictionary] = [] # region, offset from the centre, velocity, spin
var _arena_from := 0.0 # the boss map's clock when it ended, so the grid keeps drifting from where it was

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	assert(AT == BossMaps.final_spot(), "the win cutscene starts where f4 leaves the button")
	assert(is_equal_approx(Sfx.CHARGE_S, EXPLODE_AT - BUILD_AT), "the charge sound lasts the build up")
	var song: Song = GameRun.MOONLIGHT
	_arena_from = song.first_beat_s + GameRun.BOSS_SEGMENTS.back()[2] * 60.0 / song.bpm
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var size := BossArena.button_rect(button, AT, BUTTON_WIDTH).size
	var piece := button.get_size() / SHARD_GRID
	for x in SHARD_GRID:
		for y in SHARD_GRID:
			var offset := (Vector2(x, y) + Vector2.ONE * 0.5) / SHARD_GRID * size - size / 2
			var away := (offset.normalized() + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.6, 0.2))).normalized()
			_shards.append({
				"region": Rect2(Vector2(x, y) * piece, piece),
				"offset": offset,
				"velocity": away * rng.randf_range(SHARD_SPEED.x, SHARD_SPEED.y),
				"spin": rng.randf_range(-SHARD_SPIN, SHARD_SPIN),
			})

func voice_cues() -> Array: return [[VOICE_AT, &"win"]]

# the build up rising into the blast, then the site's good news
func sfx_cues() -> Array: return [[BUILD_AT, &"charge"], [EXPLODE_AT, &"explosion"], [EXPLODE_AT, &"boom"], [COMPLETE_POP_AT, &"fanfare"]]

func _process(delta: float) -> void:
	super(delta)
	queue_redraw()

func _draw() -> void:
	if time < REVEAL_AT: draw_rect(get_viewport_rect().grow(BLAST_SHAKE), BossArena.BACKGROUND) # under the shake, so no edge shows
	draw_set_transform(_screen_shake())
	if time < REVEAL_AT: _draw_arena()
	else: _draw_desktop()
	draw_set_transform(Vector2.ZERO)
	var white := _white()
	if white > 0.0: draw_rect(get_viewport_rect().grow(BLAST_SHAKE), Color(1, 1, 1, white))

# --- Build up and blast ---
func _build() -> float: return clampf((time - BUILD_AT) / (EXPLODE_AT - BUILD_AT), 0.0, 1.0)

func _draw_arena() -> void:
	BossArena.draw(self, _arena_from + time)
	if time < EXPLODE_AT:
		_draw_rings()
		_draw_button()
		var caption := 1.0 - clampf((time - BUILD_AT) / CAPTION_OUT_S, 0.0, 1.0)
		if caption > 0.0: BossChaseView.draw_caught(self, AT, caption)
	else:
		_draw_fireball()
		_draw_shockwave()
		_draw_shards()

func _draw_button() -> void:
	var build := _build()
	var shake := Vector2(sin(time * 73.0), cos(time * 91.0)) * SHAKE * build * build
	var rect := BossArena.button_rect(button, AT + shake, BUTTON_WIDTH * (1.0 + SWELL * build * build))
	# the pulse speeds up: its phase is the integral of a frequency rising from 2 to 14 Hz across the build up
	var since := maxf(time - BUILD_AT, 0.0)
	var phase := TAU * (2.0 * since + 6.0 * since * since / (EXPLODE_AT - BUILD_AT))
	var pulse := (0.5 + 0.5 * sin(phase)) * build
	draw_texture_rect(button, rect, false)
	draw_circle(rect.get_center(), rect.size.x * 0.47, Color(HOT, pulse * HOT_ALPHA), true, -1, true) # a glow over it, 2d colours don't go past white

func _draw_rings() -> void:
	var build := _build()
	if build <= 0.0: return
	var rate := 1.2 + 4.0 * build # rings per second
	var since := time - BUILD_AT
	for i in RINGS:
		var t := fposmod(since * rate + float(i) / RINGS, 1.0)
		var radius := lerpf(RING_FROM, BUTTON_WIDTH * 0.5, t)
		draw_arc(AT, radius, 0, TAU, 64, Color(RED, t * build), 4.0, true)

# a hot core swelling out of where the button was, yellow inside orange
func _draw_fireball() -> void:
	var t := (time - EXPLODE_AT) / FIREBALL_S
	if t >= 1.0: return
	var radius := FIREBALL_RADIUS * (1.0 - pow(1.0 - t, 2.0))
	draw_circle(AT, radius, Color(1.0, 0.45, 0.1, 1.0 - t), true, -1, true)
	draw_circle(AT, radius * 0.65, Color(1.0, 0.85, 0.3, 1.0 - t), true, -1, true)
	draw_circle(AT, radius * 0.3, Color(1, 1, 0.9, 1.0 - t), true, -1, true)

func _draw_shockwave() -> void:
	var t := (time - EXPLODE_AT) / SHOCKWAVE_S
	if t >= 1.0: return
	var eased := 1.0 - pow(1.0 - t, 3.0)
	draw_arc(AT, lerpf(BUTTON_WIDTH * 0.5, 1400.0, eased), 0, TAU, 96, Color(1, 0.85, 0.6, 1.0 - t), lerpf(36.0, 2.0, t), true)

# the button's pieces fly out, spinning and falling
func _draw_shards() -> void:
	var t := time - EXPLODE_AT
	if t >= SHARD_S: return
	var alpha := 1.0 - t / SHARD_S
	var piece_size := BossArena.button_rect(button, AT, BUTTON_WIDTH).size / SHARD_GRID
	for shard in _shards:
		var at: Vector2 = AT + shard.offset + shard.velocity * t + Vector2(0, GRAVITY * t * t / 2)
		draw_set_transform(at + _screen_shake(), shard.spin * t)
		draw_texture_rect_region(button, Rect2(-piece_size / 2, piece_size), shard.region, Color(1, 1, 1, alpha))
	draw_set_transform(_screen_shake())

func _screen_shake() -> Vector2:
	var amount := SCREEN_SHAKE * _build() * _build()
	if time >= EXPLODE_AT: amount = BLAST_SHAKE * maxf(1.0 - (time - EXPLODE_AT) / BLAST_SHAKE_S, 0.0)
	return Vector2(sin(time * 67.0), cos(time * 83.0)) * amount

# up to full white over the blast, then it fades onto the desktop
func _white() -> float:
	if time < EXPLODE_AT: return 0.0
	if time < WHITE_OUT_AT: return clampf((time - EXPLODE_AT) / WHITE_IN_S, 0.0, 1.0)
	return 1.0 - clampf((time - WHITE_OUT_AT) / WHITE_OUT_S, 0.0, 1.0)

# --- After ---
func _draw_desktop() -> void:
	Desktop.draw(self)
	LoginView.draw_window(self, _draw_completed)

func _draw_completed() -> void:
	var rect := Rect2(LoginView.PAGE_AT, LoginView.PAGE_SIZE)
	draw_rect(rect, Color.WHITE)
	var center := rect.get_center()
	TutorialUi.label(self, rect.position + Vector2(rect.size.x / 2, 70), "GAME JAM 2026", 32)
	var pop := 0.6 + 0.4 * clampf((time - COMPLETE_POP_AT) / POP_S, 0.0, 1.0)
	TutorialUi.label(self, center, "SUBMISSION COMPLETED!", roundi(52 * pop), SUCCESS)
	TutorialUi.label(self, center + Vector2(0, 60), "game_FINAL_v3_REAL.zip  ·  submitted at 23:59:59", 18, TutorialUi.MUTED)
