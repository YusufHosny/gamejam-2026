class_name PolygonCut
extends RefCounted

# a texture drawn over a rect, split in two along a line, the pieces fly apart and fade

const SPREAD := 160.0 # px/s the pieces fly apart
const FALL := 1500.0
const SPIN := 2.5
const LIFETIME_S := 0.8

class Piece:
	var points: PackedVector2Array # around its own centroid
	var uvs: PackedVector2Array
	var center: Vector2
	var push: Vector2 # away from the cut
	var spin: float

	func _init(_points: PackedVector2Array, _uvs: PackedVector2Array, _center: Vector2, _push: Vector2, _spin: float) -> void:
		points = _points
		uvs = _uvs
		center = _center
		push = _push
		spin = _spin

var texture: Texture2D
var pieces: Array[Piece] = []
var born_ms: int

# rect split by the line through `through` along `along`
static func split(_texture: Texture2D, rect: Rect2, through: Vector2, along: Vector2) -> PolygonCut:
	var cut := PolygonCut.new()
	cut.texture = _texture
	cut.born_ms = Time.get_ticks_msec()
	var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var side := along.orthogonal()
	var far := rect.size.length()
	for flip in [-1.0, 1.0]:
		var half := PackedVector2Array([
			through - along * far, through + along * far,
			through + along * far + side * flip * far, through - along * far + side * flip * far,
		])
		for polygon in Geometry2D.intersect_polygons(corners, half):
			var centroid := Vector2.ZERO
			for point in polygon: centroid += point
			centroid /= polygon.size()
			var points := PackedVector2Array()
			var uvs := PackedVector2Array()
			for point in polygon:
				points.append(point - centroid)
				uvs.append((point - rect.position) / rect.size)
			cut.pieces.append(Piece.new(points, uvs, centroid, side * flip, SPIN * flip))
	return cut

func alive(ms: int) -> bool: return ms - born_ms < LIFETIME_S * 1000

func draw(item: CanvasItem, ms: int) -> void:
	var s := (ms - born_ms) / 1000.0
	var alpha := 1.0 - s / LIFETIME_S
	for piece in pieces:
		item.draw_set_transform(piece.center + piece.push * SPREAD * s + Vector2(0, 0.5 * FALL * s * s), piece.spin * s)
		item.draw_colored_polygon(piece.points, Color(1, 1, 1, alpha), piece.uvs, texture)
	item.draw_set_transform(Vector2.ZERO)
