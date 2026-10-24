class_name GameRun
extends RefCounted

const DEADLINE_S := 300.0
const COUNTDOWN_S := 4.0
const CUTSCENE_S := 8.0
const WIN_S := 6.0
const VIVALDI := preload("res://assets/music/vivaldi_summer.tres")
const AD_MUSIC := preload("res://assets/music/ad_music.tres")
const SCREAM_MIX := preload("res://assets/music/scream_mix.tres")
const MOONLIGHT := preload("res://assets/music/moonlight_3rd.tres")
const SUBWAY := preload("res://assets/music/subway_surfers.tres")
const VIRUS_CUTSCENE := preload("res://scenes/cutscenes/virus_cutscene.tscn")
const BLUE_SCREEN_CUTSCENE := preload("res://scenes/cutscenes/blue_screen_cutscene.tscn")

# TODO: placeholder circle views until each situation has its own
static func steps() -> Array[RunStep]:
	var steps: Array[RunStep] = [
		CutsceneStep.new("5 minutes left to submit", COUNTDOWN_S),
		_captchas(),
		_subway(),
		CutsceneStep.new("", CUTSCENE_S, true, VIRUS_CUTSCENE),
		_ads(),
		CutsceneStep.new("", CUTSCENE_S, true, BLUE_SCREEN_CUTSCENE),
		# b1 usb, b2 password
		_section(SCREAM_MIX, [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D], [26.0, 26.0]),
		# f1 chase, f2 armor, f3 lasers, f1 crescendo
		_section(MOONLIGHT, [Modality.Kind.AIM_CLICK, Modality.Kind.SLASH, Modality.Kind.FOUR_D, Modality.Kind.AIM_CLICK], [14.0, 14.0, 14.0, 14.0]),
	]
	# the dodge cutscene takes up the slack so the deadline is exactly DEADLINE_S
	var dodge_s := DEADLINE_S - Run.new(steps).deadline_s()
	assert(dodge_s > 4.0, "sections run %.1f s over the deadline" % -dodge_s)
	steps.insert(steps.size() - 1, CutsceneStep.new("cutscene: the submit button dodges", dodge_s))
	steps.append(CutsceneStep.new("cutscene: submitted as the clock hits 0, you win", WIN_S, false))
	return steps

# c1 dogs, c2 align, c3 apples
static func _captchas() -> MapStep:
	var map := DemoMap.section(VIVALDI, [Modality.Kind.AIM_CLICK, Modality.Kind.FOUR_D, Modality.Kind.SLASH], [26.0, 26.0, 26.0])
	CaptchaMaps.fill_dogs(map.segments[0], map)
	CaptchaMaps.fill_align(map.segments[1], map)
	CaptchaMaps.fill_fruit(map.segments[2], map)
	map.bake()
	return MapStep.new(map)

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

static func _section(song: Song, kinds: Array, segment_s: Array[float]) -> MapStep:
	return MapStep.new(DemoMap.section(song, kinds, segment_s))
