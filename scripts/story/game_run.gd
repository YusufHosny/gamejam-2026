class_name GameRun
extends RefCounted

const COUNTDOWN_S := DeadlineClock.INTRO_S # ends as the clock settles in the corner
const CUTSCENE_S := 8.0
const VIRUS_S := 15.7 # CUTSCENE_S plus the ~3.2 s the countdown and the captchas' frozen lead in freed, plus the voice line before the cursor moves, and a second on the ads before the stage
const BLUE_SCREEN_S := 10.9
const DODGE_S := 21.6
const LAUGH_S := 3.8
const CREDITS_S := 24.0 # 20 s of rolling and the hold at the end
const PISSING_TITLE_S := 3.0
const THANKS_S := 4.0
const URINAL_SEGMENTS := [ # [kind, start beat, end beat] on the ad music
	[Modality.Kind.AIM_CLICK, 8, 56], # pick the urinal furthest away, a round every PICK_EVERY beats
	[Modality.Kind.SLASH, 60, 74], # all taken, slash them away
]
const PUPPETS_PRE_ROLL_S := 1.5 # the first chord comes half a second in, its note needs time to approach
const PUPPETS_END_BEAT := 69.0
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
const WIN_CUTSCENE := preload("res://scenes/cutscenes/win_cutscene.tscn")
const LAUGH_CUTSCENE := preload("res://scenes/cutscenes/laugh_cutscene.tscn")
const CREDITS_CUTSCENE := preload("res://scenes/cutscenes/credits_cutscene.tscn")
const PISSING_TITLE_CUTSCENE := preload("res://scenes/cutscenes/pissing_title_cutscene.tscn")
const THANKS_CUTSCENE := preload("res://scenes/cutscenes/thanks_cutscene.tscn")
const PUPPETS := preload("res://assets/music/master_of_puppets.tres")

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
		CutsceneStep.new("", DODGE_S, true, DODGE_CUTSCENE),
		_puppets(easy),
		CutsceneStep.new("", LAUGH_S, true, LAUGH_CUTSCENE),
		_boss(easy),
	]
	steps.append(CutsceneStep.new("", WinCutscene.LENGTH_S, false, WIN_CUTSCENE))
	steps.append(CutsceneStep.new("", CREDITS_S, false, CREDITS_CUTSCENE))
	steps.append(CutsceneStep.new("", PISSING_TITLE_S, false, PISSING_TITLE_CUTSCENE))
	steps.append(_urinals())
	steps.append(CutsceneStep.new("", THANKS_S, false, THANKS_CUTSCENE)) # then the score screen
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
	if easy: BossMaps.fill_chase_easy(map.segments[0], 0, 54, BossMaps.CHASE_VIEW) # the fermata chord ends it
	else: BossMaps.fill_chase_mapped(map.segments[0])
	BossMaps.fill_shields_mapped(map.segments[1])
	BossMaps.fill_lasers_mapped(map.segments[2])
	if easy: BossMaps.fill_chase_easy(map.segments[3], 234, 320, BossMaps.FINAL_VIEW) # the development's chord ends it
	else: BossMaps.fill_chase_mapped(map.segments[3], BossMaps.FINAL_MAP, BossMaps.FINAL_VIEW)
	map.bake()
	assert(MOONLIGHT.fits(map), "the boss map runs past its song")
	var step := MapStep.new(map)
	step.pre_roll_s = BOSS_PRE_ROLL_S
	return step

# the button shows off with master of puppets' intro, the same map on every set. on standard it's a struggle section left out of the score
static func _puppets(easy: bool) -> MapStep:
	var map := Map.new()
	PUPPETS.apply_to(map)
	var segment := MapSegment.new(Modality.Kind.AIM_CLICK, 0, PUPPETS_END_BEAT)
	segment.unscored = easy
	map.segments.append(segment)
	BossMaps.fill_puppets(segment)
	map.bake()
	assert(PUPPETS.fits(map), "the puppets map runs past its song")
	var step := MapStep.new(map)
	step.pre_roll_s = PUPPETS_PRE_ROLL_S
	return step

# the finale after the credits, untimed, the clock's long gone
static func _urinals() -> MapStep:
	var map := Map.new()
	AD_MUSIC.apply_to(map)
	for bounds in URINAL_SEGMENTS: map.segments.append(MapSegment.new(bounds[0], bounds[1], bounds[2]))
	UrinalMaps.fill_picks(map.segments[0])
	UrinalMaps.fill_slashes(map.segments[1])
	map.bake()
	return MapStep.new(map, false)

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
