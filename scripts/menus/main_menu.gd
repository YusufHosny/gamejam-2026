class_name MainMenu
extends Control

signal play_pressed
signal leaderboard_pressed
signal settings_pressed

@onready var _title: Label = %Title
@onready var _play: Button = %Play
@onready var _leaderboard: Button = %Leaderboard
@onready var _settings: Button = %Settings

func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name")
	_play.pressed.connect(play_pressed.emit)
	_leaderboard.pressed.connect(leaderboard_pressed.emit)
	_settings.pressed.connect(settings_pressed.emit)
	visibility_changed.connect(func(): if visible: _play.grab_focus())
