extends Node

# F6 to start a run at any stage, it then carries on through the rest of the run. `-- --autoplay` on the command line watches it, `-- --osu-circles` draws the boss chases as plain circles, `-- --step=N` skips the picker, `-- --difficulty=judge` (or autoplay, standard, french) picks the difficulty

const RUN_SCENE := preload("res://scenes/run.tscn")

@export var start_step := -1 # skips the picker when set, -1 shows it
@export var include_tutorial := true

@onready var _menu: Control = %Menu
@onready var _picker: ItemList = %Picker

var _steps: Array[RunStep] = []
var _player: RunPlayer = null

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay": GameConfig.difficulty = Difficulty.Level.AUTOPLAY
		for level: Difficulty.Level in Difficulty.Level.values():
			if arg == "--difficulty=" + Difficulty.label(level).to_lower(): GameConfig.difficulty = level
	# same order as App._play()
	if include_tutorial: _steps.append_array(TutorialRun.steps())
	_steps.append_array(GameRun.steps(Difficulty.map_set(GameConfig.difficulty)))
	if "--osu-circles" in OS.get_cmdline_user_args(): _plain_chases()
	for i in _steps.size(): _picker.add_item("%2d   %s" % [i, _label(_steps[i])])
	_picker.item_activated.connect(_start)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--step="): start_step = int(arg.trim_prefix("--step="))
	if start_step >= 0: _start(start_step)
	else: _show_picker()

# the boss chases drawn as plain osu circles, same notes, to compare readability
func _plain_chases() -> void:
	for step in _steps:
		if not step is MapStep: continue
		for segment: MapSegment in (step as MapStep).map.segments:
			if segment.view == BossMaps.CHASE_VIEW: segment.view = null

func _start(index: int) -> void:
	_menu.hide()
	_player = RUN_SCENE.instantiate()
	_player.run = Run.new(_steps)
	_player.start_step = index
	_player.finished.connect(func(_result: RunResult): _back_to_picker())
	_player.exited.connect(_back_to_picker)
	add_child(_player)

func _back_to_picker() -> void:
	get_tree().paused = false
	_player.queue_free()
	_player = null
	_show_picker()

func _show_picker() -> void:
	_menu.show()
	if not _picker.is_anything_selected(): _picker.select(0)
	_picker.grab_focus()

static func _label(step: RunStep) -> String:
	var untimed := "" if step.timed else "   (untimed)"
	if step is CutsceneStep:
		var name: String = step.caption.trim_prefix("cutscene: ")
		if name.is_empty(): name = step.scene.resource_path.get_file().get_basename()
		return "cutscene: %s%s" % [name, untimed]
	if step is MapStep:
		var map: Map = step.map
		var song := "metronome" if map.music == null else map.music.resource_path.get_file().get_basename()
		var kinds := map.segments.map(func(s: MapSegment): return Modality.Kind.keys()[s.kind].to_lower())
		return "map: %s  [%s]%s" % [song, ", ".join(kinds), untimed]
	return str(step)
