class_name Hex
## Axial hex-grid math, pointy-top orientation.
## Coordinates are Vector2i(q, r); the board center is (0, 0).
## Reference: Red Blob Games hex grid guide.

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]


static func neighbors(a: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		out.append(a + d)
	return out


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return int((absf(dq) + absf(dq + dr) + absf(dr)) / 2.0)


static func ring_of(a: Vector2i) -> int:
	return distance(a, Vector2i.ZERO)


static func to_pixel(a: Vector2i, size: float) -> Vector2:
	var x := size * sqrt(3.0) * (float(a.x) + float(a.y) / 2.0)
	var y := size * 1.5 * float(a.y)
	return Vector2(x, y)


static func from_pixel(p: Vector2, size: float) -> Vector2i:
	var qf := (sqrt(3.0) / 3.0 * p.x - 1.0 / 3.0 * p.y) / size
	var rf := (2.0 / 3.0 * p.y) / size
	return _cube_round(qf, rf)


static func _cube_round(qf: float, rf: float) -> Vector2i:
	var sf := -qf - rf
	var q := roundf(qf)
	var r := roundf(rf)
	var s := roundf(sf)
	var dq := absf(q - qf)
	var dr := absf(r - rf)
	var ds := absf(s - sf)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(int(q), int(r))


## The 6 corner points of a hex centered at `center`, for Polygon2D.
static func corners(center: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * float(i) - 30.0)
		pts.append(center + Vector2(cos(angle), sin(angle)) * size)
	return pts


## All axial coords within `radius` rings of the center (a filled hexagon).
static func disk(radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1: int = maxi(-radius, -q - radius)
		var r2: int = mini(radius, -q + radius)
		for r in range(r1, r2 + 1):
			out.append(Vector2i(q, r))
	return out
