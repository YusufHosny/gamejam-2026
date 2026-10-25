class_name GameRun
extends RefCounted

const COUNTDOWN_S := DeadlineClock.INTRO_S # ends as the clock settles in the corner
const CUTSCENE_S := 8.0
const VIRUS_S := 11.2 # CUTSCENE_S plus the ~3.2 s the countdown and the captchas' frozen lead in freed
const BLUE_SCREEN_S := 10.9
const DODGE_S := 8.0
const WIN_S := 6.0
const FADE_IN_S := 1.0
const CAPTCHA_PRE_ROLL_S := 1.5
const VIVALDI := preload("res://assets/music/vivaldi_summer.tres")
const AD_MUSIC := preload("res://assets/music/ad_music.tres")
const SCREAM_MIX := preload("res://assets/music/scream_mix.tres")
const MOONLIGHT := preload("res://assets/music/moonlight_3rd.tres")
const SUBWAY := preload("res://assets/music/subway_surfers.tres")
const COUNTDOWN_CUTSCENE := preload("res://scenes/cutscenes/countdown_cutscene.tscn")
const VIRUS_CUTSCENE := preload("res://scenes/cutscenes/virus_cutscene.tscn")
const BLUE_SCREEN_CUTSCENE := preload("res://scenes/cutscenes/blue_screen_cutscene.tscn")

static func steps(maps := Difficulty.MapSet.STANDARD) -> Array[RunStep]:
	match maps:
		Difficulty.MapSet.STANDARD: return _standard()
		Difficulty.MapSet.HARD: return _hard()
	assert(false, "unhandled map set %s" % maps)
	return []

# TODO: the mapping pass gives hard its own maps
static func _hard() -> Array[RunStep]: return _standard()

static func _standard() -> Array[RunStep]:
	var steps: Array[RunStep] = [
		CutsceneStep.new("", COUNTDOWN_S, true, COUNTDOWN_CUTSCENE),
		_captchas(),
		_subway(),
		CutsceneStep.new("", VIRUS_S, true, VIRUS_CUTSCENE),
		_ads(),
		CutsceneStep.new("", BLUE_SCREEN_S, true, BLUE_SCREEN_CUTSCENE),
		_backup(),
		_boss(),
	]
	steps.insert(steps.size() - 1, CutsceneStep.new("cutscene: the submit button dodges", DODGE_S))
	steps.append(CutsceneStep.new("cutscene: submitted as the clock hits 0, you win", WIN_S, false))
	return steps

# c1 dogs, c2 align, c3 apples
static func _captchas() -> MapStep:
	var map := DemoMap.section(VIVALDI, [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D, Modality.Kind.SLASH], [26.0, 26.0, 26.0])
	CaptchaMaps.fill_dogs(map.segments[0], map)
	CaptchaMaps.fill_align(map.segments[1], map)
	CaptchaMaps.fill_fruit(map.segments[2], map)
	map.bake()
	var step := MapStep.new(map)
	step.fade_in_s = FADE_IN_S
	step.fade_color = Color("505050ff")
	step.pre_roll_s = CAPTCHA_PRE_ROLL_S
	return step

# c4, the music switches to the clip's own
static func _subway() -> MapStep:
	var map := DemoMap.section(SUBWAY, [Modality.Kind.SLASH], [24.0])
	CaptchaMaps.fill_subway(map.segments[0])
	map.bake()
	return MapStep.new(map)

# a1, popups cut down with slashes
static func _ads() -> MapStep:
	var map := DemoMap.section(AD_MUSIC, [Modality.Kind.SLASH], [26.0])
	CaptchaMaps.fill_ads(map.segments[0], map)
	map.bake()
	return MapStep.new(map)

# f1 chase, f2 shields, f3 lasers, f4 final chase with streams
static func _boss() -> MapStep:
	var map := DemoMap.section(MOONLIGHT, [Modality.Kind.AIM_CLICK, Modality.Kind.SLASH, Modality.Kind.FOUR_D, Modality.Kind.AIM_CLICK], [14.0, 14.0, 14.0, 14.0])
	BossMaps.fill_chase(map.segments[0], map)
	BossMaps.fill_shields(map.segments[1], map)
	BossMaps.fill_lasers(map.segments[2], map)
	BossMaps.fill_chase(map.segments[3], map, true, GameConfig.map_seed + 1)
	map.bake()
	return MapStep.new(map)

# b1 plug in the usb, b2 type the backup password
static func _backup() -> MapStep:
	var map := DemoMap.section(SCREAM_MIX, [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D], [26.0, 26.0])
	BackupMaps.fill_usb(map.segments[0])
	BackupMaps.fill_password(map.segments[1], map)
	map.bake()
	var step := MapStep.new(map)
	step.fade_color = Color("aaaaaa") 
	step.fade_in_s = FADE_IN_S # the blue screen cutscene fades out to black
	return step

static func _section(song: Song, kinds: Array, segment_s: Array[float]) -> MapStep:
	return MapStep.new(DemoMap.section(song, kinds, segment_s))
