# scripts/systems/game_math_engine.gd
# ==============================================================================
# "Into the Wild" — Action Value Model & Mathematical Balancing Engine
# Core Autoload/Static Systems Engine for Godot 4.x / Antigravity IDE
# ==============================================================================
# Unifies:
# - Action Value Model (AVM): Common Energy (CE), turn opportunity costs, object pricing
# - Combat & Mitigation: Asymptotic mitigation, Effective Health (EHP), dodge/crit scaling
# - Loot & Randomness: Daniel Cook bag rollers, pity tracking, repeatable sampling
# - Procedural Object & Enemy Generation: Balanced stat budgets per level and tier
# ==============================================================================

class_name GameMathEngine
extends RefCounted

# ==============================================================================
# SECTION 1: ACTION VALUE MODEL & CE VALUATION CONSTANTS (GDD & SYNTHESIS S1)
# ==============================================================================

## Standard Common Energy (CE) tier values (canon invariant I1: 1 / 3 / 9 / 27)
const CE_VALUES: Dictionary = {
	"common": 1,
	"uncommon": 3,
	"rare": 9,
	"legendary": 27,
	"1": 1,
	"2": 3,
	"3": 9,
	"4": 27
}

## Macroeconomic conversion rates to CE
const BASELINE_TURN_CE: float = 8.2      ## Average CE income per turn (12-income turn baseline)
const CE_PER_ENERGY: float = 2.5         ## Valuation of 1 Spirit/Energy
const CE_PER_LIGHT: float = 2.0          ## Valuation of +1 Light shift
const CE_PER_VP: float = 3.5             ## Valuation of 1 Victory Point (on 0..20 scale)
const CE_PER_RAGE: float = -1.5          ## Negative valuation of +1 Island Rage


## Returns the Common Energy (CE) value of a tier.
static func ce_of_tier(tier: String) -> int:
	return int(CE_VALUES.get(tier.to_lower(), 1))


## Calculates total CE value of an item or resource bundle based on its properties and rarity.
static func calculate_item_value(item: Dictionary) -> float:
	var rarity: String = String(item.get("rarity", "Common")).to_lower()
	var base_ce: float = float(ce_of_tier(rarity))
	var props: Dictionary = item.get("properties", {})
	
	var harvest_mult: float = float(props.get("harvest_multiplier", 1.0))
	var durability: float = float(props.get("durability", 10.0))
	var armor: float = float(props.get("armor", 0.0))
	var damage: float = float(props.get("damage", 0.0))
	
	# Action Value Formula for items:
	# Value = Base CE + (Durability / 10) * (HarvestMultiplier - 1.0) * 2.0 + (Armor + Damage) * 0.5
	var utility_value: float = (durability / 10.0) * maxf(0.0, harvest_mult - 1.0) * 2.0
	var combat_value: float = (armor + damage) * 0.5
	return base_ce + utility_value + combat_value


## Calculates Return On Investment (ROI) in turns for a tool or building.
static func calculate_tool_roi(tool: Dictionary, avg_harvests_per_turn: float = 1.0) -> float:
	var cost_ce: float = calculate_item_value(tool)
	var props: Dictionary = tool.get("properties", {})
	var harvest_mult: float = float(props.get("harvest_multiplier", 1.0))
	var extra_ce_per_harvest: float = (harvest_mult - 1.0) * 1.0 # extra commons per gather
	var income_per_turn: float = extra_ce_per_harvest * avg_harvests_per_turn
	if income_per_turn <= 0.0:
		return INF
	return cost_ce / income_per_turn


## Evaluates the Action Value (Net CE Return) of a Quest.
static func calculate_quest_balance(deliverable_ce: float, vp_reward: int, light_shift: int, is_dark: bool = false) -> Dictionary:
	var total_cost: float = deliverable_ce + (BASELINE_TURN_CE * 1.0) # materials + 1 turn opportunity cost
	var total_reward: float = (float(vp_reward) * CE_PER_VP) + (float(light_shift) * CE_PER_LIGHT)
	if is_dark:
		total_reward += (1.0 * CE_PER_RAGE) # Rage penalty implicit in Dark path
	var net_roi: float = total_reward - total_cost
	var efficiency: float = total_reward / maxf(1.0, total_cost)
	return {
		"total_cost_ce": total_cost,
		"total_reward_ce": total_reward,
		"net_roi_ce": net_roi,
		"efficiency_ratio": efficiency,
		"balanced": efficiency >= 0.9 and efficiency <= 1.4
	}


# ==============================================================================
# SECTION 2: COMBAT DAMAGE & ASYMPTOTIC MITIGATION (Written Realms / D3)
# ==============================================================================

## Level progression scaling constant: C = 1.1^Level * 5.5
static func get_level_constant(level: int) -> float:
	return pow(1.1, float(level)) * 5.5


## Stat budget scaling per level relative to level 1 baseline.
static func get_stat_budget(level: int, difficulty_modifier: float = 1.0) -> float:
	var base_points: float = 50.0
	var level_factor: float = get_level_constant(level) / get_level_constant(1)
	return base_points * level_factor * difficulty_modifier


## Asymptotic mitigation formula: Mitigation = Stat / (Stat + Level * K)
## Guarantees smooth diminishing returns that never reach 100% invincibility.
static func calculate_asymptotic_mitigation(stat_val: float, attacker_level: int, k_factor: float = 60.0) -> float:
	if stat_val <= 0.0:
		return 0.0
	var denominator: float = stat_val + (float(attacker_level) * k_factor)
	return stat_val / denominator


## Asymptotic dodge formula with baseline chance:
static func calculate_dodge_chance(dodge_rating: float, attacker_level: int, k_factor: float = 60.0, base_dodge: float = 0.02) -> float:
	if dodge_rating < 0.0:
		dodge_rating = 0.0
	var numerator: float = dodge_rating + (float(attacker_level) * k_factor * base_dodge)
	var denominator: float = dodge_rating + (float(attacker_level) * k_factor)
	return numerator / denominator


## Linear critical strike scaling clamped to [0, 1]:
static func calculate_crit_chance(crit_rating: float, attacker_level: int, k_factor: float = 120.0, base_crit: float = 0.04) -> float:
	if crit_rating <= 0.0:
		return base_crit
	var chance: float = (crit_rating / (float(attacker_level) * k_factor)) + base_crit
	return clampf(chance, 0.0, 1.0)


## Effective Health Pool (EHP) calculation:
## EHP = BaseHP / (1 - TotalMitigation)
static func calculate_effective_health(base_hp: float, armor_rating: float, attacker_level: int, armor_k: float = 60.0, res_rating: float = 0.0, res_k: float = 120.0) -> float:
	var armor_mitigation: float = calculate_asymptotic_mitigation(armor_rating, attacker_level, armor_k)
	var res_mitigation: float = calculate_asymptotic_mitigation(res_rating, attacker_level, res_k)
	var total_mitigation: float = 1.0 - ((1.0 - armor_mitigation) * (1.0 - res_mitigation))
	if total_mitigation >= 1.0:
		return INF
	return base_hp / (1.0 - total_mitigation)


## Combat damage resolution formula:
static func calculate_combat_damage(weapon_dmg: float, attack_power: float, target_armor: float, attacker_level: int, armor_k: float = 60.0, skill_mod: float = 1.0, elemental_mod: float = 1.0) -> float:
	var base_atk: float = weapon_dmg + (attack_power / 16.0)
	var mitigation: float = calculate_asymptotic_mitigation(target_armor, attacker_level, armor_k)
	return base_atk * skill_mod * elemental_mod * (1.0 - mitigation)


# ==============================================================================
# SECTION 3: CREATURE ENCOUNTER & FATE PROBABILITY MATHEMATICS (Q9 & GDD §5.3)
# ==============================================================================

## Computes the probability of winning a creature fight given creature F, spent energy, band, and rage.
## Fate deck composition: 10 numbered cards (1..6) + 2 Spirit/Wild cards.
static func calculate_fight_win_probability(creature_f: int, spent_energy: int, band: int, island_rage: int = 0) -> float:
	var effective_f: int = creature_f + (1 if island_rage >= 5 else 0)
	var deck: Array[int] = [1, 2, 2, 3, 3, 4, 4, 5, 5, 6]
	
	# Wild card resolution based on Duality Band (0: MAX_DARK .. 4: MAX_LIGHT)
	var wild_val: int = 1
	match band:
		4: wild_val = 5 # MAX_LIGHT / Radiant
		3: wild_val = 4 # LIGHT / Kind
		2: wild_val = 3 # NEUTRAL
		1: wild_val = 2 # DARK / Shadowed
		0: wild_val = 1 # MAX_DARK / Deep Dark
	
	deck.append(wild_val)
	deck.append(wild_val)
	
	var wins: int = 0
	for card in deck:
		var total_roll: int = card + spent_energy
		if total_roll >= effective_f:
			wins += 1
			
	return float(wins) / float(deck.size())


## Evaluates expected CE return for Befriend vs Fight vs Exploit paths on a creature.
static func evaluate_creature_encounter(creature: Dictionary, band: int, spent_energy: int = 0, island_rage: int = 0) -> Dictionary:
	var f: int = int(creature.get("f", 3))
	var win_prob: float = calculate_fight_win_probability(f, spent_energy, band, island_rage)
	
	# Fight EV: 2 card draws on win (average T1/T2 card value ~ 4.5 CE), lose bite on loss
	var win_reward_ce: float = 2.0 * float(ce_of_tier("uncommon"))
	var bite_cost_ce: float = 1.0 # loss of 1 common
	var fight_ev: float = (win_prob * win_reward_ce) - ((1.0 - win_prob) * bite_cost_ce) - (float(spent_energy) * CE_PER_ENERGY)
	
	# Befriend EV: Gift value + +1 Light shift - Demand cost
	var gift_ce: float = 3.0 # typical gift value
	var demand_ce: float = 1.0 # typical 1 common
	var befriend_ev: float = gift_ce + (1.0 * CE_PER_LIGHT) - demand_ce
	
	# Exploit EV: 2 card draws + -1 Light + +1 Rage + bite suffered
	var exploit_ev: float = (2.0 * float(ce_of_tier("uncommon"))) + (-1.0 * CE_PER_LIGHT) + (1.0 * CE_PER_RAGE) - bite_cost_ce
	
	return {
		"win_probability": win_prob,
		"fight_ev_ce": fight_ev,
		"befriend_ev_ce": befriend_ev,
		"exploit_ev_ce": exploit_ev,
		"recommended_action": "befriend" if befriend_ev >= fight_ev else "fight"
	}


# ==============================================================================
# SECTION 4: LOOT TABLES, RANDOMNESS & PROGRESSIVE PITY
# ==============================================================================

## Standard weighted roll with replacement.
static func roll_loot_with_replacement(loot_table: Dictionary) -> String:
	var total_weight: float = 0.0
	for weight in loot_table.values():
		total_weight += float(weight)
		
	if total_weight <= 0.0:
		return "null"
		
	var roll: float = randf_range(0.0, total_weight)
	var cumulative: float = 0.0
	for item in loot_table.keys():
		cumulative += float(loot_table[item])
		if roll <= cumulative:
			return String(item)
	return "null"


## Tetris-style bag roller without replacement (tracked inside history_log).
static func roll_loot_without_replacement(loot_table: Dictionary, history_log: Dictionary) -> String:
	var active_table: Dictionary = {}
	for item in loot_table.keys():
		var current_weight: float = float(history_log.get(item, float(loot_table[item])))
		if current_weight > 0.0:
			active_table[item] = current_weight
			
	if active_table.is_empty() or sum_weights(active_table) <= 0.0:
		for item in loot_table.keys():
			history_log[item] = float(loot_table[item])
			active_table[item] = float(loot_table[item])
			
	var rolled_item: String = roll_loot_with_replacement(active_table)
	if rolled_item != "null" and history_log.has(rolled_item):
		history_log[rolled_item] = maxf(0.0, float(history_log[rolled_item]) - 1.0)
		
	return rolled_item


## Progressive pity-protected loot roller. Guarantees target_item by roll N.
static func roll_loot_with_pity(loot_table: Dictionary, history_counter: Dictionary, target_item: String, max_rolls_before_pity: int = 10) -> String:
	var rolls: int = int(history_counter.get(target_item, 0))
	var pity_factor: float = 1.0 - (float(rolls) / float(max_rolls_before_pity))
	pity_factor = clampf(pity_factor, 0.0, 1.0)
	
	var modified_table: Dictionary = {}
	for item in loot_table.keys():
		if String(item) == target_item:
			modified_table[item] = float(loot_table[item])
		else:
			modified_table[item] = float(loot_table[item]) * pity_factor
			
	var rolled_item: String = roll_loot_with_replacement(modified_table)
	
	if rolled_item == target_item:
		history_counter[target_item] = 0
	else:
		history_counter[target_item] = rolls + 1
		
	return rolled_item


# ==============================================================================
# SECTION 5: PROCEDURAL ENEMY & OBJECT GENERATOR
# ==============================================================================

## Procedural enemy generator balancing part-scoring with target power budget.
static func generate_balanced_enemy(level: int, target_difficulty_mod: float = 1.0) -> Dictionary:
	var base_power: float = get_level_constant(level) * 10.0 * target_difficulty_mod
	
	var move_parts: Dictionary = {"sluggish": 5.0, "normal_move": 10.0, "swift": 20.0}
	var attack_parts: Dictionary = {"scratch": 5.0, "bite": 10.0, "elemental_blast": 25.0}
	var defense_parts: Dictionary = {"unarmored": 5.0, "harden_shell": 15.0, "spirit_shield": 30.0}
	
	var move: String = roll_loot_with_replacement(move_parts)
	var atk: String = roll_loot_with_replacement(attack_parts)
	var defense: String = roll_loot_with_replacement(defense_parts)
	
	var raw_score: float = float(move_parts[move]) + float(attack_parts[atk]) + float(defense_parts[defense])
	var multiplier: float = base_power / maxf(1.0, raw_score)
	
	return {
		"level": level,
		"target_power": base_power,
		"generated_parts": {
			"movement": move,
			"attack": atk,
			"defense": defense
		},
		"stats": {
			"max_hp": get_level_constant(level) * 15.0 * multiplier,
			"attack_power": float(attack_parts[atk]) * multiplier * 2.0,
			"armor_rating": float(defense_parts[defense]) * multiplier * 1.5,
			"speed": float(move_parts[move]) * multiplier
		},
		"power_scale_factor": multiplier
	}


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

static func sum_weights(dict: Dictionary) -> float:
	var total: float = 0.0
	for v in dict.values():
		total += float(v)
	return total
