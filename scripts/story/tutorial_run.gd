class_name TutorialRun
extends RefCounted

# untimed, the deadline starts with the real game's countdown

const INTRO_CUTSCENE := preload("res://scenes/cutscenes/intro_cutscene.tscn")
const EMAIL_OPEN_CUTSCENE := preload("res://scenes/cutscenes/email_open_cutscene.tscn")
const SIGN_IN_CUTSCENE := preload("res://scenes/cutscenes/sign_in_cutscene.tscn")

static func steps() -> Array[RunStep]:
	return [
		CutsceneStep.new("", IntroCutscene.LENGTH_S, false, INTRO_CUTSCENE),
		MapStep.new(TutorialMaps.login(), false),
		MapStep.new(TutorialMaps.phone(), false),
		CutsceneStep.new("", EmailOpenCutscene.LENGTH_S, false, EMAIL_OPEN_CUTSCENE),
		MapStep.new(TutorialMaps.email(), false),
		CutsceneStep.new("", SignInCutscene.LENGTH_S, false, SIGN_IN_CUTSCENE),
	]
