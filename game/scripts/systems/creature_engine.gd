class_name CreatureEngine
extends RefCounted
## Creature Micro-Challenges & Chemistry Engine (GDD §5.3 & §8.3).
## Decides creature interaction paths based on 5 Karma Bands (Radiant, Kind, Neutral, Shadowed, Dark),
## elemental Heart affinities, character perks, skill bonuses, and GameMathEngine balancing formulas.

enum EncounterType {
	GIFT,       ## Radiant/Kind: free blessing/aid
	CHALLENGE,  ## Neutral: choice of befriend, fight, or exploit
	HOSTILE,    ## Shadowed/Dark: bite attack or robbery
}

const BAND_TO_KARMA_KEY: Dictionary = {
	Duality.Band.MAX_LIGHT: "exalted_light",
	Duality.Band.LIGHT: "harmonious_light",
	Duality.Band.NEUTRAL: "neutral",
	Duality.Band.DARK: "dark_aligned",
	Duality.Band.MAX_DARK: "exalted_dark",
}


## Computes effective encounter band considering Heart affinity and skills.
static func effective_band(p: PlayerState, creature: Dictionary) -> Duality.Band:
	# Eclipse (Wild Deck): every creature acts from Deep Dark aggression.
	if Game.dark_aggression_rounds > 0:
		return Duality.Band.MAX_DARK
	var base_band := Game.band_of(p)
	var shift := 0
	
	# Heart affinity chemistry: matching element shifts +1 toward Radiant
	var el := String(creature.get("element", ""))
	if p.heart == el and el != "":
		shift += 1
	if p.skills.has("beast_whisperer"):
		shift += 1
		
	var shifted_int: int = clampi(int(base_band) + shift, 0, 4)
	return shifted_int as Duality.Band


## Determines the encounter type for the player.
static func get_encounter_type(band: Duality.Band) -> EncounterType:
	match band:
		Duality.Band.MAX_LIGHT, Duality.Band.LIGHT:
			return EncounterType.GIFT
		Duality.Band.NEUTRAL:
			return EncounterType.CHALLENGE
		_:
			return EncounterType.HOSTILE


## Retrieves the specific karma interaction block from expanded creature datasets.
static func get_karma_interaction(creature: Dictionary, band: Duality.Band) -> Dictionary:
	var ki: Dictionary = creature.get("karma_interactions", {})
	if ki.is_empty():
		return {}
	var key: String = String(BAND_TO_KARMA_KEY.get(band, "neutral"))
	return ki.get(key, {})


## Checks if the player can fulfill the creature's demand or challenge cost.
static func can_fulfill_demand(p: PlayerState, creature: Dictionary, band: Duality.Band = Duality.Band.NEUTRAL) -> bool:
	# 1. Check expanded dataset karma_interactions if present
	var k_inter := get_karma_interaction(creature, band)
	if not k_inter.is_empty():
		var cost: Dictionary = k_inter.get("cost", {})
		if not cost.is_empty():
			var item_id := String(cost.get("item_id", ""))
			var qty := int(cost.get("qty", 1))
			if item_id != "":
				return p.has_common(item_id, qty) or p.has_item(item_id)
			return p.commons_count() >= qty
		return true

	# 2. Check canon creature demand format
	var dem: Dictionary = creature.get("demand", {})
	if dem.is_empty():
		return true
	var dtype := String(dem.get("type", "common"))
	var n := int(dem.get("n", 1))
	
	# Action Card Creatures Lvl 3+ discount
	if ActionCards.get_level(p, "creatures") >= 3 and dtype == "common":
		n = maxi(1, n - 1)
		
	match dtype:
		"free":
			return true
		"item":
			return p.items.size() >= n
		"give_common", "common":
			var ids: Array = dem.get("ids", [])
			if ids.is_empty():
				return p.commons_count() >= n
			for id in ids:
				if p.has_common(String(id), n):
					return true
			return false
	return false


## Spends materials to fulfill the creature's demand.
static func fulfill_demand(p: PlayerState, creature: Dictionary, rng: RandomNumberGenerator, band: Duality.Band = Duality.Band.NEUTRAL) -> bool:
	var k_inter := get_karma_interaction(creature, band)
	if not k_inter.is_empty():
		var cost: Dictionary = k_inter.get("cost", {})
		if not cost.is_empty():
			var item_id := String(cost.get("item_id", ""))
			var qty := int(cost.get("qty", 1))
			if p.has_common(item_id, qty):
				p.spend_common(item_id, qty)
				return true
			elif p.has_item(item_id):
				p.remove_item(item_id)
				return true
			elif p.commons_count() >= qty:
				p.spend_any_commons(qty, rng)
				return true

	var dem: Dictionary = creature.get("demand", {})
	var dtype := String(dem.get("type", "common"))
	var n := int(dem.get("n", 1))
	if ActionCards.get_level(p, "creatures") >= 3 and dtype == "common":
		n = maxi(1, n - 1)

	match dtype:
		"item":
			if p.items.is_empty():
				return false
			p.items.remove_at(0)
			return true
		"give_common", "common":
			var ids: Array = dem.get("ids", [])
			if ids.is_empty():
				p.spend_any_commons(n, rng)
				return true
			for id in ids:
				var cid := String(id)
				if p.has_common(cid, n):
					p.spend_common(cid, n)
					return true
	return true


## Resolves an expanded karma interaction returning structured result.
static func resolve_karma_interaction(p: PlayerState, creature: Dictionary, band: Duality.Band, rng: RandomNumberGenerator) -> Dictionary:
	var inter := get_karma_interaction(creature, band)
	if inter.is_empty():
		return {"action": "none", "message": "The creature regards you silently."}
		
	var action := String(inter.get("action", "gift"))
	var flavor := String(inter.get("flavor", ""))
	var light_chg := int(inter.get("light_change", 0))
	var item_rew := String(inter.get("item_reward", ""))
	
	if light_chg > 0:
		for i in light_chg:
			Game.shift_light(p, "care_gift")
	elif light_chg < 0:
		for i in absi(light_chg):
			Game.shift_light(p, "exploit_tile")
			
	match action:
		"gift", "reward":
			if item_rew != "":
				if Game.decks.items_by_id.has(item_rew):
					p.add_item(item_rew)
				else:
					p.add_common(item_rew, 1)
			EventBus.inventory_changed.emit(p.index)
			return {"action": action, "message": flavor, "reward": item_rew}
			
		"take":
			var steal_id := String(inter.get("steal_item", ""))
			if steal_id != "" and p.has_common(steal_id):
				p.spend_common(steal_id, 1)
			else:
				p.spend_any_commons(1, rng)
			EventBus.inventory_changed.emit(p.index)
			return {"action": "take", "message": flavor}
			
		"attack":
			var dmg := float(inter.get("damage", 1.0))
			# Apply GameMathEngine asymptotic armor mitigation & skill protections
			if p.skills.has("iron_skin"):
				return {"action": "attack", "message": "Iron Skin protects you! The blow glances off harmlessly."}
			var net_dmg := GameMathEngine.calculate_combat_damage(dmg, 0.0, 10.0, 1)
			p.slow_penalty += maxi(1, int(round(net_dmg)))
			EventBus.inventory_changed.emit(p.index)
			return {"action": "attack", "message": "%s (Slowed for %d turns)." % [flavor, p.slow_penalty]}
			
	return {"action": action, "message": flavor}


## Executes a creature's special field ability (Irrigate, Weave, Forage, Kindle, Purify).
static func execute_field_move(p: PlayerState, creature: Dictionary, tile: IslandTile, rng: RandomNumberGenerator) -> String:
	var move := String(creature.get("field_move", "")).to_lower()
	if move == "":
		return "This creature has no field ability."
		
	match move:
		"irrigate":
			tile.exhausted = false
			p.add_common("fresh_water", 1)
			EventBus.inventory_changed.emit(p.index)
			return "Irrigate: The land springs with moisture! Refreshes tile and yields +1 Fresh Water."
		"weave":
			p.add_common("plant_fiber", 2)
			EventBus.inventory_changed.emit(p.index)
			return "Weave: Spun fibers woven from the grass! Yields +2 Plant Fibers."
		"forage":
			var common_id := Game.decks.random_common(tile.element_id)
			if common_id != "":
				p.add_common(common_id, 2)
				EventBus.inventory_changed.emit(p.index)
				return "Forage: The creature uncovers hidden caches, yielding 2× %s!" % Game.decks.display_name_of(common_id)
		"kindle":
			Game.add_energy(p, 1)
			return "Kindle: A spark of ancient warmth warms your spirit (+1 ⚡ Energy)!"
		"purify":
			Game.shift_light(p, "care_gift")
			return "Purify: Cleansing energy clears corruption (+1 Light)!"
			
	return "Field ability '%s' activated." % move.capitalize()


## Applies an effect dictionary (gift or bite) to player p. Returns a human-readable description.
static func apply_effect(p: PlayerState, effect: Dictionary, rng: RandomNumberGenerator, is_bite: bool = false) -> String:
	if effect.is_empty():
		return "Nothing happens."
	
	# Iron skin / Leaf cloak protection against bites
	if is_bite:
		if p.skills.has("iron_skin"):
			return "Iron Skin protects you: the bite glance off safely!"
		if p.has_item("healing_salve"):
			p.remove_item("healing_salve")
			return "Healing Salve soothingly neutralizes the bite effect!"
		# Aura Shield ward (Wild Deck): absorbs one full attack, then fades.
		if p.wards.has("aura_shield"):
			p.wards.erase("aura_shield")
			return "The Aura Shield flares and absorbs the attack completely!"

	var op := String(effect.get("op", "none"))
	var n := int(effect.get("n", 1))
	var desc := String(effect.get("desc", ""))

	# Catalog gear (content drop): armor softens what a bite can take.
	if is_bite and (op == "lose_common" or op == "energy" or op == "lose_card"):
		var armor := Game.decks.best_item_stat(p, "gear", "armor")
		if armor > 0:
			if op == "energy":
				n = mini(0, n + armor)
			else:
				n = maxi(0, n - armor)
			if n == 0:
				return "Your gear takes the hit — the bite does nothing."
	
	match op:
		"gain_common":
			var el := String(effect.get("element", ""))
			var id := String(effect.get("id", ""))
			if id != "":
				p.add_common(id, n)
			elif el != "":
				for i in n:
					var cid := Game.decks.random_common(el)
					if cid != "":
						p.add_common(cid, 1)
			else:
				p.add_common("grain", n)
		"lose_common":
			p.spend_any_commons(n, rng)
		"energy":
			Game.add_energy(p, n)
		"move":
			if n < 0:
				p.slow_penalty += absi(n)
			else:
				p.move += n
		"light":
			if n > 0:
				for i in n:
					Game.shift_light(p, "care_gift")
			elif n < 0:
				for i in absi(n):
					Game.shift_light(p, "exploit_tile")
		"gain_card":
			var cid2 := String(effect.get("id", ""))
			if cid2 != "":
				p.add_card({"id": cid2, "tier": String(effect.get("tier", "uncommon")),
					"element": String(effect.get("element", p.heart if p.heart != "" else "wood"))})
		"gain_item":
			# Catalog item gift (t3 wild creatures entrust relics). Full pack -> a common instead.
			var iid := String(effect.get("id", ""))
			if iid != "" and p.items.size() < p.pack_size:
				p.items.append(iid)
			else:
				p.add_common("spirit_mote", n)
		"draw_card":
			for i in n:
				var c := Game.decks.draw_card(p.heart if p.heart != "" else "wood", 1)
				if not c.is_empty():
					p.add_card(c)
		"lose_card":
			if not p.cards.is_empty():
				p.cards.remove_at(rng.randi_range(0, p.cards.size() - 1))
				
	EventBus.inventory_changed.emit(p.index)
	return desc if desc != "" else "Effect resolved (%s)." % op


## A befriended wild creature works its field move on the land (content drop:
## every creature's field ability "can shape the surrounding environment").
## Returns a description of what happened, or "" for creatures without one.
static func apply_field_move(p: PlayerState, creature: Dictionary, tile: IslandTile) -> String:
	var move_name := String(creature.get("field_move", ""))
	if move_name == "":
		return ""
	if tile.exhausted:
		tile.exhausted = false
		return "%s! The stripped land drinks deep and lives again." % move_name
	var cid := Game.decks.random_common(tile.element_id)
	if cid != "":
		p.add_common(cid, 1)
		return "%s! The land yields +1 %s." % [move_name, Game.decks.display_name_of(cid)]
	return "%s! The land stirs in answer." % move_name
