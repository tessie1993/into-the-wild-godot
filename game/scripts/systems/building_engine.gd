class_name BuildingEngine
extends RefCounted
## Base Building & Refining Stations Engine (GDD §8.7 & objects-catalog.md §5).
## Manages tile structures, field benches, and interactive benefits.

const BUILDINGS: Dictionary = {
	"homebase": {
		"name": "Homebase Camp",
		"tier": "uncommon",
		"desc": "Acts as Crafting Bench: unlocks Uncommon+ crafting here.",
	},
	"workshop": {
		"name": "Workshop",
		"tier": "rare",
		"desc": "Advanced artisan bench: unlocks Legendary crafting here.",
	},
	"wayside_shrine": {
		"name": "Wayside Shrine",
		"tier": "uncommon",
		"desc": "Sacred pillar: offer a common resource for +1 Light (once per turn).",
	},
	"campfire": {
		"name": "Campfire",
		"tier": "common",
		"desc": "Hearth: cook raw food into Cooked Meals here without tools.",
	},
	"fish_weir": {
		"name": "Fish Weir",
		"tier": "uncommon",
		"desc": "Woven reed trap: gathering on this water tile yields +1 extra Fish/Shells.",
	},
	"storage_cache": {
		"name": "Storage Cache",
		"tier": "uncommon",
		"desc": "Sheltered depot: stores up to 3 shared resources on this tile.",
	},
	"forge": {
		"name": "Stone Forge",
		"tier": "rare",
		"desc": "Blazing smelter: refines stone and ore, adding +1 craft quality.",
	},
}


## Returns whether the tile has a specific building.
static func has_building(tile: IslandTile, building_id: String) -> bool:
	return tile != null and tile.buildings.has(building_id)


## Interacts with a building on the current tile.
## Returns {success: bool, message: String}.
static func interact(p: PlayerState, tile: IslandTile, building_id: String, rng: RandomNumberGenerator) -> Dictionary:
	if not has_building(tile, building_id):
		return {"success": false, "message": "Building not present on this tile."}
		
	match building_id:
		"wayside_shrine":
			if p.commons_count() == 0:
				return {"success": false, "message": "You need a common resource to make an offering."}
			p.spend_any_commons(1, rng)
			Game.shift_light(p, "care_gift")
			if p.skills.has("shrine_keeper"):
				p.vp += 1
				Game.add_rage(-1)
				return {"success": true, "message": "Shrine Keeper blessing: +1 Light, +1 VP, −1 Island Rage."}
			return {"success": true, "message": "You leave an offering at the Wayside Shrine. +1 Light."}
			
		"campfire":
			if p.has_common("grain", 1) and p.has_common("fresh_water", 1):
				p.spend_common("grain", 1)
				p.spend_common("fresh_water", 1)
				p.add_item("cooked_meal")
				EventBus.inventory_changed.emit(p.index)
				return {"success": true, "message": "You cook a warm meal over the campfire!"}
			elif p.has_common("fish", 1):
				p.spend_common("fish", 1)
				p.add_item("cooked_meal")
				EventBus.inventory_changed.emit(p.index)
				return {"success": true, "message": "You roast a freshly caught fish into a Cooked Meal!"}
			return {"success": false, "message": "Need raw food (Grain + Water or Fish) to cook."}
			
		"storage_cache":
			return {"success": true, "message": "Storage cache inspected."}
			
	return {"success": true, "message": "Station active on tile."}


## Generates a summary description of all active structures on tile.
static func tile_buildings_summary(tile: IslandTile) -> String:
	if tile == null or tile.buildings.is_empty():
		return ""
	var names: Array = []
	for b in tile.buildings:
		var info: Dictionary = BUILDINGS.get(b, {})
		names.append(String(info.get("name", b)))
	return "Buildings: " + ", ".join(names)
