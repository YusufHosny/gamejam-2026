class_name RunPlayer
extends Node

signal finished(result: RunResult)
signal exited

const MAP_PLAYER_SCENE := preload("res://scenes/map_player.tscn")

@onready var _stage: Node = $Stage
@onready var _deadline: DeadlineClock = $Deadline/DeadlineClock
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _fade: ColorRect = $Fade/Black

var run: Run # set before entering the tree
var start_step := 0 # set before entering the tree, the stage sandbox starts mid run
var score := ScoreKeeper.new()
var _index := -1
var _cutscene: Cutscene = null
var _map_player: MapPlayer = null
var _intro_played := false

func _ready() -> void:
	_pause_menu.resumed.connect(_set_paused.bind(false))
	_pause_menu.restarted.connect(_unpause_then.bind(_restart))
	_pause_menu.checkpointed.connect(_unpause_then.bind(_load_checkpoint))
	_pause_menu.exited.connect(_unpause_then.bind(exited.emit))
	_deadline.hide()
	_intro_played = start_step > run.first_timed() # starting past it goes straight to the corner clock
	_play_step(start_step)

func _process(_delta: float) -> void:
	_fade.modulate.a = _fade_alpha()
	if _index >= run.steps.size(): return
	var timed := run.steps[_index].timed
	_deadline.visible = timed
	if timed: _deadline.set_time_left(maxf(run.time_left(_index, _step_position()), 0.0))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_set_paused(true)
		get_viewport().set_input_as_handled()

# --- Steps ---
func _play_step(index: int) -> void:
	_clear_stage()
	_index = index
	if index >= run.steps.size():
		finished.emit(RunResult.from_score(score, GameConfig.difficulty))
		return
	var step := run.steps[index]
	assert(not step.timed or step.length_s() > 0.0, "timed steps need a fixed length")
	if step.timed and not _intro_played:
		_intro_played = true
		_deadline.play_intro()
	if step is CutsceneStep: _start_cutscene(step)
	elif step is MapStep: _start_map(step)
	else: assert(false, "unhandled run step %s" % step)

func _start_cutscene(step: CutsceneStep) -> void:
	_cutscene = step.scene.instantiate()
	_cutscene.caption = step.caption
	_cutscene.length_s = step.duration_s
	_cutscene.finished.connect(_advance)
	_stage.add_child(_cutscene)

func _start_map(step: MapStep) -> void:
	_map_player = MAP_PLAYER_SCENE.instantiate()
	_map_player.map = step.map
	_map_player.score = score
	_map_player.pre_roll_s = step.pre_roll_s
	_map_player.finished.connect(_advance)
	_fade.color = step.fade_color
	_stage.add_child(_map_player)

func _advance() -> void:
	if _map_player != null: score = _map_player.score
	_play_step.call_deferred(_index + 1) # steps finish from their own _process

func _clear_stage() -> void:
	for child in _stage.get_children():
		_stage.remove_child(child)
		child.queue_free()
	_cutscene = null
	_map_player = null

func _step_position() -> float:
	if _cutscene != null: return minf(_cutscene.time, _cutscene.length_s)
	if _map_player != null:
		var step: MapStep = run.steps[_index]
		return clampf(_map_player.time() + step.pre_roll_s, 0.0, step.length_s()) # map time is negative during the pre roll
	return 0.0

# follows the map's clock so pausing and restarts stay exact
func _fade_alpha() -> float:
	if _map_player == null: return 0.0
	var fade_in_s := (run.steps[_index] as MapStep).fade_in_s
	if fade_in_s <= 0.0: return 0.0
	return 1.0 - clampf(_step_position() / fade_in_s, 0.0, 1.0)

# --- Pause Menu ---
func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused

func _unpause_then(action: Callable) -> void:
	_set_paused(false)
	action.call()

# back to the countdown once the tutorial is done
func _restart() -> void:
	score = ScoreKeeper.new()
	var first_timed := run.first_timed()
	_intro_played = false
	_play_step(first_timed if first_timed != -1 and _index >= first_timed else 0)

func _load_checkpoint() -> void:
	if _map_player != null: _map_player.load_checkpoint()
	elif _cutscene != null: _cutscene.restart()
