class_name LetterNote
extends Note

@export var letter: String
@export var space_before: bool # word boundary, spaces are rests not notes

func _init(_beat := 0.0, _letter := "", _space_before := false) -> void:
	super(_beat)
	letter = _letter
	space_before = _space_before
