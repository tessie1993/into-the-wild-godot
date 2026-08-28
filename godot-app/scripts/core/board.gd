class_name Board
extends RefCounted
## The island: a hexagon of hex tiles (GDD section 4).
## Ring layout from config.json — outer rings are Tier 1 terrain, the inner
## three rings are Tier 2 (harsher, richer), the center is the Sanctum.

var tiles: Dictionary = {}  ## Vector2i -> IslandTile
var radius: int = 6


func generate(decks: Decks, rng: RandomNumberGenerator) -> void:
	tiles.clear()
	var cfg: Dictionary = decks.config
	var board_cfg: Dictionary = cfg.get("board", {})
	radius = int(board_cfg.get("radius", 6))
	var sanctum_rings := _int_array(board_cfg.get("sanctum_rings", [0]))
	var tier2_rings := _int_array(board_cfg.get("tier2_rings", [1, 2, 3]))

	var land_elements: Array = []
	for e in decks.elements:
		if String(e["id"]) != "spirit":
			land_elements.append(String(e["id"]))

	for axial in Hex.disk(radius):
		var t := IslandTile.new()
		t.axial = axial
		var ring := Hex.ring_of(axial)
		if sanctum_rings.has(ring):
			t.tier = 3
			t.element_id = "spirit"
			t.has_guardian = ring == 0
		elif tier2_rings.has(ring):
			t.tier = 2
			t.element_id = String(land_elements[rng.randi_range(0, land_elements.size() - 1)])
		else:
			t.tier = 1
			t.element_id = String(land_elements[rng.randi_range(0, land_elements.size() - 1)])
		tiles[axial] = t

	# Scatter guardians across Tier 2 (GDD 4.4: guardians wait deeper in).
	var guardian_count := int(board_cfg.get("guardian_count_tier2", 3))
	var t2_tiles: Array = []
	for axial in tiles.keys():
		var tile: IslandTile = tiles[axial]
		if tile.tier == 2:
			t2_tiles.append(axial)
	for i in guardian_count:
		if t2_tiles.is_empty():
			break
		var pick_i := rng.randi_range(0, t2_tiles.size() - 1)
		var picked: Vector2i = t2_tiles[pick_i]
		t2_tiles.remove_at(pick_i)
		(tiles[picked] as IslandTile).has_guardian = true


func get_tile(axial: Vector2i) -> IslandTile:
	return tiles.get(axial, null)


func ring_tiles(ring: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for axial in tiles.keys():
		if Hex.ring_of(axial) == ring:
			out.append(axial)
	return out


## Evenly spaced starting shores on the outer ring — players wash up apart,
## already-explored (they know where they landed).
func start_positions(count: int) -> Array[Vector2i]:
	var outer := ring_tiles(radius)
	outer.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _angle_of(a) < _angle_of(b))
	var out: Array[Vector2i] = []
	for i in count:
		var idx := int(floor(float(outer.size()) * float(i) / float(count)))
		var axial: Vector2i = outer[idx]
		out.append(axial)
		(tiles[axial] as IslandTile).explored = true
	return out


func _angle_of(axial: Vector2i) -> float:
	var p := Hex.to_pixel(axial, 1.0)
	return atan2(p.y, p.x)


static func _int_array(v: Variant) -> Array[int]:
	var out: Array[int] = []
	if v is Array:
		for item in v:
			out.append(int(item))
	return out


func to_dict() -> Dictionary:
	var arr: Array = []
	for axial in tiles.keys():
		arr.append((tiles[axial] as IslandTile).to_dict())
	return {"radius": radius, "tiles": arr}


static func from_dict(d: Dictionary) -> Board:
	var b := Board.new()
	b.radius = int(d.get("radius", 6))
	for td in d.get("tiles", []):
		var t := IslandTile.from_dict(td)
		b.tiles[t.axial] = t
	return b
