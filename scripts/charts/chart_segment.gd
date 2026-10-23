class_name ChartSegment
extends Resource

# the gap before start_beat is the switching cooldown
@export var kind: Modality.Kind
@export var start_beat: float
@export var end_beat: float
@export var notes: Array[Note] = []

var start_time: float
var end_time: float

func _init(_kind := Modality.Kind.FOUR_D, _start_beat := 0.0, _end_beat := 0.0) -> void:
	kind = _kind
	start_beat = _start_beat
	end_beat = _end_beat
