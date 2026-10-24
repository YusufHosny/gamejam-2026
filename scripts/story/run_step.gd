@abstract
class_name RunStep
extends Resource

@export var timed := true # counts toward the deadline, needs a fixed length

@abstract func length_s() -> float
