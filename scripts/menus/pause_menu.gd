class_name PauseMenu
extends CanvasLayer

# runs while the tree is paused, the game owns what each choice does

signal resumed
signal restarted
signal checkpointed
signal exited

@onready var _resume: Button = %Resume
@onready var _restart: Button = %Restart
@onready var _checkpoint: Button = %Checkpoint
@onready var _exit: Button = %Exit

func _ready() -> void:
	hide()
	var center: Control = $Center
	center.theme = MenuStyle.theme()
	MenuStyle.title($Center/Items/Title, 72)
	$Center/Items/Title.text = "Paused"
	for pair in [[_resume, "Resume"], [_restart, "Restart"], [_checkpoint, "Checkpoint"], [_exit, "Menu"]]: MenuStyle.baguette_button(pair[0], pair[1])
	_resume.pressed.connect(resumed.emit)
	_restart.pressed.connect(restarted.emit)
	_checkpoint.pressed.connect(checkpointed.emit)
	_exit.pressed.connect(exited.emit)
	visibility_changed.connect(func(): if visible: _resume.grab_focus())

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		resumed.emit()
		get_viewport().set_input_as_handled()
