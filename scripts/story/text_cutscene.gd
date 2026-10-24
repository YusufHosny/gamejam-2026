class_name TextCutscene
extends Cutscene

# placeholder until real cutscenes exist

@onready var _caption: Label = %Caption
@onready var _hint: Label = %Hint

func _ready() -> void:
	_caption.text = caption
	_hint.text = "space / enter to continue" if waits() else "space / enter to skip"
