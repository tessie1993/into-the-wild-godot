class_name IslandTile
extends RefCounted
## One hex tile of the island. Face-down (unexplored) until a player enters it.
## tier: 1 = outer terrain, 2 = extreme inner terrain, 3 = the Sanctum.

var axial: Vector2i = Vector2i.ZERO
var element_id: String = ""
var tier: int = 1
var explored: bool = false
var has_guardian: bool = false
var buildings: Array = []   ## building ids placed here ("homebase", "workshop")
var exhausted: bool = false ## exploited tiles stop yielding commons


func _init(p_axial: Vector2i = Vector2i.ZERO, p_element_id: String = "", p_tier: int = 1) -> void:
	axial = p_axial
	element_id = p_element_id
	tier = p_tier


func has_building(id: String) -> bool:
	return buildings.has(id)


func to_dict() -> Dictionary:
	return {
		"q": axial.x,
		"r": axial.y,
		"element_id": element_id,
		"tier": tier,
		"explored": explored,
		"has_guardian": has_guardian,
		"buildings": buildings.duplicate(),
		"exhausted": exhausted,
	}


static func from_dict(d: Dictionary) -> IslandTile:
	var t := IslandTile.new()
	t.axial = Vector2i(int(d.get("q", 0)), int(d.get("r", 0)))
	t.element_id = String(d.get("element_id", ""))
	t.tier = int(d.get("tier", 1))
	t.explored = bool(d.get("explored", false))
	t.has_guardian = bool(d.get("has_guardian", false))
	t.buildings = d.get("buildings", [])
	t.exhausted = bool(d.get("exhausted", false))
	return t
