class_name MapSegment
extends Resource

# the gap before start_beat is the switching cooldown
@export var kind: Modality.Kind
@export var start_beat: float
@export var end_beat: float
@export var notes: Array[Note] = []
@export var view: PackedScene # ModeView scene, null -> default for mode
@export var tutorial := false
@export var wait_for_input := false # clock holds on each note, stray clicks ignored
@export var unscored := false # a struggle section, played and judged but left out of the score

var start_time: float
var end_time: float

func _init(_kind := Modality.Kind.FOUR_D, _start_beat := 0.0, _end_beat := 0.0) -> void:
	kind = _kind
	start_beat = _start_beat
	end_beat = _end_beat
