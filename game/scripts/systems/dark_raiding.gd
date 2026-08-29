class_name DarkRaiding
extends RefCounted
## Dark Path Raiding & PvP Stealing System (GDD §5.4 & §10.2 & open design Q3).
## Allows Shadowed/Dark wanderers to raid other players on the same/adjacent tile,
## with explicit defender counterplay (energy shields, iron skin skill, holy ground).

## Returns whether player attacker can raid defender.
static func can_raid(attacker: PlayerState, defender: PlayerState) -> bool:
	if attacker.index == defender.index:
		return false
	var band := Game.band_of(attacker)
	var is_dark := band == Duality.Band.DARK or band == Duality.Band.MAX_DARK or attacker.character_id == "outcast"
	if not is_dark:
		return false
	var dist := Hex.distance(attacker.pos, defender.pos)
	if dist > 1:
		return false
	if defender.commons_count() == 0 and defender.cards.is_empty():
		return false
	return true


## Executes the raid attempt from attacker on defender.
## Returns {success: bool, blocked: bool, stolen_desc: String, message: String}.
static func execute_raid(attacker: PlayerState, defender: PlayerState, rng: RandomNumberGenerator) -> Dictionary:
	if not can_raid(attacker, defender):
		return {"success": false, "blocked": false, "stolen_desc": "", "message": "Raid invalid or target out of reach."}
	
	var def_tile: IslandTile = Game.board.get_tile(defender.pos)
	if BuildingEngine.has_building(def_tile, "wayside_shrine"):
		Game.shift_light(attacker, "cast_dark_spell")
		Game.add_rage(1)
		return {
			"success": false,
			"blocked": true,
			"stolen_desc": "",
			"message": "Sacred Grounds: The Wayside Shrine repels the shadows! Raid failed (−2 Light, +1 Rage).",
		}
		
	# Defender counterplay: Iron Skin skill
	if defender.skills.has("iron_skin"):
		return {
			"success": false,
			"blocked": true,
			"stolen_desc": "",
			"message": "%s's Iron Skin completely deflects the raid!" % defender.display_name,
		}
		
	# Defender counterplay: Spend 1 Energy to defend if available
	if defender.energy >= 1:
		Game.add_energy(defender, -1)
		return {
			"success": false,
			"blocked": true,
			"stolen_desc": "",
			"message": "%s spent 1⚡ to block your strike and defend their supplies!" % defender.display_name,
		}
		
	# Unblocked raid: steal up to 2 commons or 1 card
	var stolen_parts: Array = []
	if defender.commons_count() > 0:
		var stolen := defender.spend_any_commons(2, rng)
		for s in stolen:
			attacker.add_common(String(s), 1)
			stolen_parts.append(Game.decks.display_name_of(String(s)))
	elif not defender.cards.is_empty():
		var cindex := rng.randi_range(0, defender.cards.size() - 1)
		var card: Dictionary = defender.cards[cindex]
		defender.cards.remove_at(cindex)
		attacker.add_card(card)
		stolen_parts.append("[%s] %s" % [String(card.get("tier", "?")), Game.decks.display_name_of(String(card.get("id", "")))])
		
	Game.shift_light(attacker, "cast_dark_spell")
	Game.add_rage(1)
	EventBus.inventory_changed.emit(attacker.index)
	EventBus.inventory_changed.emit(defender.index)
	
	var stolen_str := ", ".join(stolen_parts)
	return {
		"success": true,
		"blocked": false,
		"stolen_desc": stolen_str,
		"message": "Raid successful! Snatched %s from %s (−2 Light, +1 Rage)." % [stolen_str, defender.display_name],
	}
