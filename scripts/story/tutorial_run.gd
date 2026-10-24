class_name TutorialRun
extends RefCounted

# untimed, the deadline starts with the real game's countdown

static func steps() -> Array[RunStep]:
	return [
		CutsceneStep.new("initial cutscene here", 0.0, false),
		MapStep.new(TutorialMaps.login(), false),
		MapStep.new(TutorialMaps.phone(), false),
		CutsceneStep.new("cutscene: the email app opens", 0.0, false),
		MapStep.new(TutorialMaps.email(), false),
		CutsceneStep.new("cutscene: you sign in", 0.0, false),
	]
