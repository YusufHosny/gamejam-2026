class_name TypingMode
extends ModeHandler

const LETTER_WIDTH := 34.0
const FONT_SIZE := 40
const RING_RADIUS := 26.0
const APPROACH_SCALE := 2.0

var _letters: Array[LetterNote] = []
var _offsets: Array[float] = [] # x of each letter along the line
var _grades: Dictionary[LetterNote, Judgement.Grade] = {}

func begin(_segment: ChartSegment) -> void:
	super(_segment)
	_letters.assign(segment.notes)
	_offsets.clear()
	_grades.clear()
	var x := 0.0
	for letter in _letters:
		if letter.space_before: x += LETTER_WIDTH
		_offsets.append(x)
		x += LETTER_WIDTH

func _handle_input(event: InputEvent, now: float) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.unicode < "a".unicode_at(0) or event.unicode > "z".unicode_at(0): return
	var note := _next() as LetterNote
	if not _in_window(note, now): return
	if String.chr(event.unicode) == note.letter: _hit(note, now)
	else: _resolve(HitResult.miss(note))

func _resolve(result: HitResult) -> void:
	_grades[result.note as LetterNote] = result.grade
	super(result)

func _draw() -> void:
	if _letters.is_empty(): return
	var now := conductor.song_time()
	var approach := GameConfig.approach_time_s
	var font := ThemeDB.fallback_font
	var caret := _grades.size() # letters resolve strictly in order
	var scroll := _offsets[mini(caret, _offsets.size() - 1)]
	var center := get_viewport_rect().get_center()
	for i in _letters.size():
		var letter := _letters[i]
		var pos := Vector2(center.x + _offsets[i] - scroll, center.y)
		var judged := _grades.has(letter)
		var color := Judgement.color(_grades[letter]) if judged else Color(1, 1, 1, 1.0 if i == caret else 0.4)
		var baseline := pos + Vector2(-LETTER_WIDTH / 2, FONT_SIZE * 0.35)
		draw_string(font, baseline, letter.letter, HORIZONTAL_ALIGNMENT_CENTER, LETTER_WIDTH, FONT_SIZE, color)
		var until := letter.time - now
		if judged or until > approach: continue
		var alpha := 1.0 - clampf(until / approach, 0.0, 1.0)
		var ring := RING_RADIUS * (1.0 + APPROACH_SCALE * maxf(until, 0.0) / approach)
		draw_arc(pos, ring, 0, TAU, 48, Color(1, 1, 1, alpha), 2)
