class_name BuildingEngine
extends RefCounted
## Base Building & Refining Stations Engine (GDD §8.7 & objects-catalog.md §5).
## Manages tile structures, field benches, tool harvest multipliers, and
## GameMathEngine Action Value Model calculations for stations and upgrades.

const BUILDINGS: Dictionary = {
	"homebase": {
		"name": "Homebase Camp",
		"tier": "uncommon",
		"level": 2,
		"desc": "Acts as Crafting Bench: unlocks Uncommon+ crafting here.",
	},
	"workshop": {
		"name": "Workshop",
		"tier": "rare",
		"level": 3,
		"desc": "Advanced artisan bench: unlocks Legendary crafting here.",
	},
	"wayside_shrine": {
		"name": "Wayside Shrine",
		"tier": "uncommon",
		"level": 2,
		"desc": "Sacred pillar: offer a common resource for +1 Light (once per turn).",
	},
	"campfire": {
		"name": "Campfire",
		"tier": "common",
		"level": 1,
		"desc": "Hearth: cook raw food into Cooked Meals here without tools.",
	},
	"fish_weir": {
		"name": "Fish Weir",
		"tier": "uncommon",
		"level": 2,
		"desc": "Woven reed trap: gathering on this water tile yields +1 extra Fish/Shells.",
	},
	"storage_cache": {
		"name": "Storage Cache",
		"tier": "uncommon",
		"level": 2,
		"desc": "Sheltered depot: stores up to 3 shared resources on this tile.",
	},
	"forge": {
		"name": "Stone Forge",
		"tier": "rare",
		"level": 3,
		"desc": "Blazing smelter: refines stone and ore, adding +1 craft quality.",
	},
}


## Returns whether the tile has a specific building.
static func has_building(tile: IslandTile, building_id: String) -> bool:
	return tile != null and tile.buildings.has(building_id)


## Queries player's equipped tools from items.json and returns maximum harvest multiplier.
static func get_player_harvest_multiplier(p: PlayerState) -> float:
	var best_mult := 1.0
	for item_id in p.items:
		var item_data: Dictionary = Game.decks.get_item(item_id)
		var props: Dictionary = item_data.get("properties", {})
		var mult: float = float(props.get("harvest_multiplier", 1.0))
		if mult > best_mult:
			best_mult = mult
	return best_mult


## Calculates the stat and resource budget for constructing or upgrading a structure using GameMathEngine.
static func get_building_stat_budget(building_id: String) -> float:
	var info: Dictionary = BUILDINGS.get(building_id, {})
	var lvl: int = int(info.get("level", 1))
	return GameMathEngine.get_stat_budget(lvl)


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
			# Salvage/Scrap roll using GameMathEngine
			var salvage_table := {"flint": 3.0, "sticks": 4.0, "plant_fiber": 3.0, "iron_ore": 1.0}
			var salvaged := GameMathEngine.roll_loot_with_replacement(salvage_table)
			if salvaged != "null":
				p.add_common(salvaged, 1)
				EventBus.inventory_changed.emit(p.index)
				return {"success": true, "message": "Storage Cache inspected: found 1× %s in the depot!" % Game.decks.display_name_of(salvaged)}
			return {"success": true, "message": "Storage cache inspected."}
			
		"forge":
			if p.has_common("stone", 2):
				p.spend_common("stone", 2)
				p.add_item("sharpened_blade")
				EventBus.inventory_changed.emit(p.index)
				return {"success": true, "message": "Stone Forge: Smelted 2 Stone into a Sharpened Blade!"}
			return {"success": true, "message": "Stone Forge active. Ready to refine stone/ore."}
			
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
