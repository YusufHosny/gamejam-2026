class_name App
extends Node

# root of the game, swaps between menu screens and owns the running game

const GAME_SCENE := preload("res://scenes/game.tscn")

@onready var _main_menu: MainMenu = $MainMenu
@onready var _settings: SettingsMenu = $SettingsMenu
@onready var _leaderboard: LeaderboardMenu = $LeaderboardMenu
@onready var _score_screen: ScoreScreen = $ScoreScreen

var _results: Array[RunResult] = [] # session only until we persist the leaderboard
var _game: Game = null

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

# --- Game ---
func _play() -> void:
	_show(null)
	_game = GAME_SCENE.instantiate()
	_game.finished.connect(_on_finished)
	_game.exited.connect(_close_game.bind(_main_menu))
	add_child(_game)

func _on_finished(result: RunResult) -> void:
	_results.append(result)
	_score_screen.show_result(result)
	_close_game(_score_screen)

func _close_game(next_screen: Control) -> void:
	get_tree().paused = false
	_game.queue_free()
	_game = null
	_show(next_screen)
