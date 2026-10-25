class_name GameRun
extends RefCounted

const COUNTDOWN_S := DeadlineClock.INTRO_S # ends as the clock settles in the corner
const CUTSCENE_S := 8.0
const VIRUS_S := 11.2 # CUTSCENE_S plus the ~3.2 s the countdown and the captchas' frozen lead in freed
const BLUE_SCREEN_S := 10.9
const DODGE_S := 19.0
const WIN_S := 6.0
const FADE_IN_S := 1.0
const CAPTCHA_PRE_ROLL_S := 1.5
const BOSS_PRE_ROLL_S := 2.5 # the first theme starts with the music, the banner shows before it
const BOSS_SEGMENTS := [ # [kind, start beat, end beat]
	[Modality.Kind.AIM_CLICK, 0, 56], # first theme, to the fermata
	[Modality.Kind.SLASH, 60, 124], # transition and second theme, to its climax
	[Modality.Kind.FOUR_D, 128, 230], # rest of the second theme and the closing theme
	[Modality.Kind.AIM_CLICK, 232, 324], # codetta and the development's climb to the chord
]
const SUBWAY_PRE_ROLL_S := 1.0 # the first move comes just after the music starts, its note needs time to approach
const VIVALDI := preload("res://assets/music/vivaldi_summer.tres")
const AD_MUSIC := preload("res://assets/music/ad_music.tres")
const SCREAM_MIX := preload("res://assets/music/scream_mix.tres")
const MOONLIGHT := preload("res://assets/music/moonlight_3rd.tres")
const SUBWAY := preload("res://assets/music/subway_surfers.tres")
const COUNTDOWN_CUTSCENE := preload("res://scenes/cutscenes/countdown_cutscene.tscn")
const VIRUS_CUTSCENE := preload("res://scenes/cutscenes/virus_cutscene.tscn")
const BLUE_SCREEN_CUTSCENE := preload("res://scenes/cutscenes/blue_screen_cutscene.tscn")
const DODGE_CUTSCENE := preload("res://scenes/cutscenes/dodge_cutscene.tscn")

# the maps are the hard set, standard thins them
static func steps(maps := Difficulty.MapSet.STANDARD) -> Array[RunStep]:
	var steps := _steps(maps == Difficulty.MapSet.STANDARD)
	match maps:
		Difficulty.MapSet.STANDARD:
			for step in steps:
				if step is MapStep: EasyMaps.thin((step as MapStep).map)
		Difficulty.MapSet.HARD: pass
		_: assert(false, "unhandled map set %s" % maps)
	return steps

# easy swaps in the slow aim maps
static func _steps(easy: bool) -> Array[RunStep]:
	var steps: Array[RunStep] = [
		CutsceneStep.new("", COUNTDOWN_S, true, COUNTDOWN_CUTSCENE),
		_captchas(easy),
		_subway(),
		CutsceneStep.new("", VIRUS_S, true, VIRUS_CUTSCENE),
		_ads(),
		CutsceneStep.new("", BLUE_SCREEN_S, true, BLUE_SCREEN_CUTSCENE),
		_backup(easy),
		_boss(easy),
	]
	steps.insert(steps.size() - 1, CutsceneStep.new("", DODGE_S, true, DODGE_CUTSCENE))
	steps.append(CutsceneStep.new("cutscene: submitted as the clock hits 0, you win", WIN_S, false))
	return steps

# c1 dogs, c2 align, c3 apples
static func _captchas(easy: bool) -> MapStep:
	var map := DemoMap.section(VIVALDI, [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D, Modality.Kind.SLASH], [28.9, 27.0, 27.0])
	CaptchaMaps.fill_dogs_mapped(map.segments[0], easy)
	CaptchaMaps.fill_align_mapped(map.segments[1])
	CaptchaMaps.fill_fruit_mapped(map.segments[2])
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
	assert(SUBWAY.fits(map), "the subway map runs past its clip")
	var step := MapStep.new(map)
	step.pre_roll_s = SUBWAY_PRE_ROLL_S
	return step

# a1, popups cut down with slashes
static func _ads() -> MapStep:
	var map := DemoMap.section(AD_MUSIC, [Modality.Kind.SLASH], [26.0])
	CaptchaMaps.fill_ads(map.segments[0], map)
	map.bake()
	return MapStep.new(map)

# f1 chase, f2 shields, f3 lasers, f4 final chase with streams
# split along the sonata's exposition, ending on the development's big chord at 108.9s
static func _boss(easy: bool) -> MapStep:
	var map := Map.new()
	MOONLIGHT.apply_to(map)
	for bounds in BOSS_SEGMENTS: map.segments.append(MapSegment.new(bounds[0], bounds[1], bounds[2]))
	BossMaps.fill_chase_mapped(map.segments[0], BossMaps.CHASE_MAP, BossMaps.CHASE_VIEW, easy)
	BossMaps.fill_shields_mapped(map.segments[1])
	BossMaps.fill_lasers_mapped(map.segments[2])
	BossMaps.fill_chase_mapped(map.segments[3], BossMaps.FINAL_MAP, BossMaps.FINAL_VIEW, easy)
	map.bake()
	assert(MOONLIGHT.fits(map), "the boss map runs past its song")
	var step := MapStep.new(map)
	step.pre_roll_s = BOSS_PRE_ROLL_S
	return step

# b1 plug in the usb
static func _backup(easy: bool) -> MapStep:
	var map := DemoMap.section(SCREAM_MIX, [Modality.Kind.AIM_CLICK], [26.0])
	BackupMaps.fill_usb(map.segments[0], easy)
	map.bake()
	var step := MapStep.new(map)
	step.fade_color = Color("aaaaaa") 
	step.fade_in_s = FADE_IN_S # the blue screen cutscene fades out to black
	return step

static func _section(song: Song, kinds: Array, segment_s: Array[float]) -> MapStep:
	return MapStep.new(DemoMap.section(song, kinds, segment_s))
