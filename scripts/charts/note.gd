class_name Note
extends Resource

@export var beat: float
var time: float # seconds, baked from beat by Chart.bake()

func _init(_beat := 0.0) -> void:
	beat = _beat
