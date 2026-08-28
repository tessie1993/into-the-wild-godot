class_name CreatureEngine
extends RefCounted
## Creature Micro-Challenges & Chemistry Engine (GDD §5.3 & §8.3).
## Decides creature interaction paths based on Karma Band (Radiant, Kind, Neutral, Shadowed, Dark),
## elemental Heart affinities, character perks, and skill bonuses.

enum EncounterType {
	GIFT,       ## Radiant/Kind: free blessing/aid
	CHALLENGE,  ## Neutral: choice of befriend, fight, or exploit
	HOSTILE,    ## Shadowed/Dark: bite attack or robbery
}


## Computes effective encounter band considering Heart affinity and skills.
static func effective_band(p: PlayerState, creature: Dictionary) -> Duality.Band:
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
		Duality.Band.RADIANT, Duality.Band.KIND:
			return EncounterType.GIFT
		Duality.Band.NEUTRAL:
			return EncounterType.CHALLENGE
		_:
			return EncounterType.HOSTILE


## Checks if the player can fulfill the creature's demand.
static func can_fulfill_demand(p: PlayerState, creature: Dictionary) -> bool:
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
static func fulfill_demand(p: PlayerState, creature: Dictionary, rng: RandomNumberGenerator) -> bool:
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
			
	var op := String(effect.get("op", "none"))
	var n := int(effect.get("n", 1))
	var desc := String(effect.get("desc", ""))
	
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
