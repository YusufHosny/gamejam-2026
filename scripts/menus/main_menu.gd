class_name MainMenu
extends Control

signal play_pressed
signal leaderboard_pressed
signal settings_pressed

@onready var _title: Label = %Title
@onready var _play: Button = %Play
@onready var _leaderboard: Button = %Leaderboard
@onready var _settings: Button = %Settings

const TITLE := "A Game About\nSubmitting a Game\nat a Game Jam"
const TITLE_SIZE := 70
const TITLE_TILT := -0.03

func _ready() -> void:
	_style()
	_play.pressed.connect(play_pressed.emit)
	_leaderboard.pressed.connect(leaderboard_pressed.emit)
	_settings.pressed.connect(settings_pressed.emit)
	visibility_changed.connect(func(): if visible: _play.grab_focus())

# the title across the top of the flag, the baguettes stacked under it
func _style() -> void:
	theme = MenuStyle.theme()
	MenuStyle.add_background(self)
	_title.reparent(self)
	_title.text = TITLE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuStyle.title(_title, TITLE_SIZE)
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 14
	_title.pivot_offset = Vector2(size.x / 2.0, 120)
	_title.rotation = TITLE_TILT
	var center: Control = $Center
	center.offset_top = 290
	MenuStyle.baguette_button(_play, "Play")
	MenuStyle.baguette_button(_leaderboard, "Leaderboard")
	MenuStyle.baguette_button(_settings, "Settings")
