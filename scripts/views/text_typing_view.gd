class_name TextTypingView
extends ModeView

const LETTER_WIDTH := 34.0
const FONT_SIZE := 40
const RING_RADIUS := 26.0
const APPROACH_SCALE := 2.0

var _letters: Array[LetterNote] = []
var _offsets: Array[float] = [] # x of each letter along the line
var _grades: Dictionary[LetterNote, Judgement.Grade] = {}

func _ready() -> void:
	mode.judged.connect(_on_judged)
	_letters.assign(mode.segment.notes)
	var x := 0.0
	for letter in _letters:
		if letter.space_before: x += LETTER_WIDTH
		_offsets.append(x)
		x += LETTER_WIDTH

func _on_judged(result: HitResult) -> void:
	_grades[result.note as LetterNote] = result.grade

func _draw() -> void:
	if _letters.is_empty(): return
	var now := _now()
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
