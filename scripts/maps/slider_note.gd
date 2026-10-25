class_name SliderNote
extends AimNote

@export var path: PackedVector2Array
@export var length_beats := 1.0 # one pass along the path
@export var repeats := 0
@export var tick_beats := 1.0 # a tick every this many beats along it, osu's tick rate
var end_time: float

func _init(_beat := 0.0, _position := Vector2.ZERO, _path := PackedVector2Array(), _length_beats := 1.0, _repeats := 0) -> void:
	super(_beat, _position)
	path = _path
	length_beats = _length_beats
	repeats = _repeats

func bake(map: Map) -> void:
	super(map)
	end_time = map.beat_time(end_beat())

func spans() -> int: return repeats + 1

# progress of each tick, none right on the end
func ticks() -> Array[float]:
	var out: Array[float] = []
	var total := length_beats * spans()
	var beat := tick_beats
	while beat < total - tick_beats * 0.25:
		out.append(beat / total)
		beat += tick_beats
	return out
func end_beat() -> float: return beat + length_beats * spans()

func points() -> PackedVector2Array:
	var all := PackedVector2Array([position])
	all.append_array(path)
	return all

func progress_at(at: float) -> float:
	return clampf((at - time) / (end_time - time), 0.0, 1.0)

func ball_at(progress: float) -> Vector2: return point_at(path_t(progress))

func path_t(progress: float) -> float:
	var t := progress * spans()
	var span := mini(floori(t), repeats)
	var along := t - span
	return along if span % 2 == 0 else 1.0 - along

func turns_left(progress: float) -> int: return repeats - mini(floori(progress * spans()), repeats)

func heading_out(progress: float) -> bool: return mini(floori(progress * spans()), repeats) % 2 == 0

func point_at(t: float) -> Vector2:
	var all := points()
	var lengths: Array[float] = []
	for i in all.size() - 1: lengths.append(all[i].distance_to(all[i + 1]))
	var remaining: float = t * lengths.reduce(func(s: float, l: float): return s + l, 0.0)
	for i in lengths.size():
		if remaining <= lengths[i] and lengths[i] > 0: return all[i].lerp(all[i + 1], remaining / lengths[i])
		remaining -= lengths[i]
	return all[-1]
