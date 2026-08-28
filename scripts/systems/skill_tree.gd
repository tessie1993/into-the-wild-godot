class_name SkillTree
extends RefCounted
## Skill Tree Engine (GDD §6.3 & canon/actions.json §4.4).
## Manages 4 rarity tiers of skills: Common (3 CE), Uncommon (6 CE), Rare (18 CE), Legendary (54 CE).
## Evaluates learning requirements, energy costs, and magic action card discounts.

const TIER_CE_BUDGET: Dictionary = {
	"common": 3,
	"uncommon": 6,
	"rare": 18,
	"legendary": 54,
}


## Returns whether player p satisfies prerequisites to learn skill.
static func can_learn(p: PlayerState, skill: Dictionary) -> bool:
	var sid := String(skill.get("id", ""))
	if p.skills.has(sid):
		return false
	var reqs: Array = skill.get("requires", [])
	for r in reqs:
		if not p.skills.has(String(r)):
			return false
	var costs := get_cost(p, skill)
	var ce_needed: int = costs.get("ce", 0)
	var energy_needed: int = costs.get("energy", 0)
	
	if p.energy < energy_needed:
		return false
	if p.commons_count() < ce_needed:
		return false
	return true


## Calculates effective CE and Energy costs for learning a skill (applying Magic card discounts).
static func get_cost(p: PlayerState, skill: Dictionary) -> Dictionary:
	var tier := String(skill.get("tier", "common"))
	var base_ce := int(skill.get("ce_cost", TIER_CE_BUDGET.get(tier, 3)))
	var base_energy := int(skill.get("energy_cost", 0))
	
	# Magic card Lvl 2+ discount (-1 CE)
	var magic_lvl := ActionCards.get_level(p, "magic")
	if magic_lvl >= 2:
		base_ce = maxi(1, base_ce - 1)
	
	return {
		"ce": base_ce,
		"energy": base_energy,
	}


## Learns the skill, consuming CE commons and energy. Applies immediate passive bonuses.
static func learn_skill(p: PlayerState, skill: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not can_learn(p, skill):
		return false
	var costs := get_cost(p, skill)
	var ce_cost: int = costs["ce"]
	var energy_cost: int = costs["energy"]
	
	if energy_cost > 0:
		Game.add_energy(p, -energy_cost)
	p.spend_any_commons(ce_cost, rng)
	var sid := String(skill["id"])
	p.skills.append(sid)
	
	# Apply immediate passive stat changes
	if sid == "swift_stride":
		p.move += 1
	elif sid == "sturdy_pack":
		p.hand_limit += 2
		p.pack_size += 1
		
	EventBus.inventory_changed.emit(p.index)
	return true


## Filters and returns skills currently available for player p to learn.
static func get_learnable_skills(p: PlayerState, all_skills: Array) -> Array:
	var learnable: Array = []
	for s in all_skills:
		if s is Dictionary and not p.skills.has(String(s.get("id", ""))):
			var reqs: Array = s.get("requires", [])
			var reqs_met := true
			for r in reqs:
				if not p.skills.has(String(r)):
					reqs_met = false
					break
			if reqs_met:
				learnable.append(s)
	return learnable
