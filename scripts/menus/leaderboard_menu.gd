class_name LeaderboardMenu
extends Control

signal back_pressed

const MAX_ROWS := 10
const HEADERS: Array[String] = ["#", "rank", "score", "accuracy", "combo", "when"]

@onready var _rows: GridContainer = %Rows
@onready var _empty: Label = %Empty
@onready var _back: Button = %Back

func _ready() -> void:
	_rows.columns = HEADERS.size()
	_back.pressed.connect(back_pressed.emit)
	visibility_changed.connect(func(): if visible: _back.grab_focus())

func show_results(results: Array[RunResult]) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_empty.visible = results.is_empty()
	_rows.visible = not results.is_empty()
	var ranked := results.duplicate()
	ranked.sort_custom(func(a: RunResult, b: RunResult): return a.score > b.score)
	for header in HEADERS: _add_cell(header, Color(1, 1, 1, 0.5))
	for i in mini(ranked.size(), MAX_ROWS):
		var result: RunResult = ranked[i]
		_add_cell(str(i + 1))
		_add_cell(result.rank_label(), result.rank_color())
		_add_cell("%08d" % result.score)
		_add_cell("%.2f%%" % (result.accuracy * 100.0))
		_add_cell("%dx" % result.max_combo)
		_add_cell(result.finished_at)

func _add_cell(text: String, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	_rows.add_child(label)
