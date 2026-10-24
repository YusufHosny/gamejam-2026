class_name App
extends Node

# root of the game, swaps between menu screens and owns the running game

const RUN_SCENE := preload("res://scenes/run.tscn")

@onready var _main_menu: MainMenu = $MainMenu
@onready var _settings: SettingsMenu = $SettingsMenu
@onready var _leaderboard: LeaderboardMenu = $LeaderboardMenu
@onready var _score_screen: ScoreScreen = $ScoreScreen

var _results: Array[RunResult] = [] # session only until we persist the leaderboard
var _run: RunPlayer = null

func _ready() -> void:
	_main_menu.play_pressed.connect(_play)
	_main_menu.leaderboard_pressed.connect(_open_leaderboard)
	_main_menu.settings_pressed.connect(_show.bind(_settings))
	_settings.back_pressed.connect(_show.bind(_main_menu))
	_leaderboard.back_pressed.connect(_show.bind(_main_menu))
	_score_screen.back_pressed.connect(_show.bind(_main_menu))
	_score_screen.retry_pressed.connect(_play)
	_show(_main_menu)

func _show(screen: Control) -> void:
	for s: Control in [_main_menu, _settings, _leaderboard, _score_screen]: s.visible = s == screen

func _open_leaderboard() -> void:
	_leaderboard.show_results(_results)
	_show(_leaderboard)

# --- Run ---
func _play() -> void:
	_show(null)
	var steps: Array[RunStep] = []
	if GameConfig.tutorial_enabled: steps.append_array(TutorialRun.steps())
	steps.append_array(GameRun.steps())
	_run = RUN_SCENE.instantiate()
	_run.run = Run.new(steps)
	_run.finished.connect(_on_finished)
	_run.exited.connect(_close_run.bind(_main_menu))
	add_child(_run)

func _on_finished(result: RunResult) -> void:
	_results.append(result)
	_score_screen.show_result(result)
	_close_run(_score_screen)

func _close_run(next_screen: Control) -> void:
	get_tree().paused = false
	_run.queue_free()
	_run = null
	_show(next_screen)
