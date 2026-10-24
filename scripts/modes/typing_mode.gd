class_name TypingMode
extends ModeHandler

func _handle_input(event: InputEvent, now: float) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.unicode < "a".unicode_at(0) or event.unicode > "z".unicode_at(0): return
	var note := _next() as LetterNote
	if not _in_window(note, now): return
	if String.chr(event.unicode) == note.letter: _hit(note, now)
	else: _resolve(HitResult.miss(note))
