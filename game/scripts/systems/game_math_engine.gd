# game_math_engine.gd
# ==============================================================================
# "Creature Explore" / "Into the Wild" — Mathematical Balancing Engine
# Core Autoload Singleton for Godot 4.x / Antigravity IDE
# ==============================================================================
# Implements systems-engineering math formulas sourced from:
# - Written Realms RPG Stat System (asymptotic mitigation, level-constant scaling, EHP)
# - Lostgarden (Daniel Cook) Loot Systems (replacement rolls, progressive pity, part-scoring)
# - Pre-renewal Ragnarok Online (ROConstants & attribute pricing tables)
# ==============================================================================

class_name GameMathEngine
extends RefCounted

# ==========================================
# SECTION 1: LEVEL-CONSTANT & STAT BUDGETS
# ==========================================

## Sourced from Written Realms: C = 1.1^Level * 5.5
## Establishes a mathematically clean 10% progression ramp per level for stats and enemies.
static func get_level_constant(level: int) -> float:
	return pow(1.1, float(level)) * 5.5


## Calculates the baseline stat allocation budget for a creature or item.
## Scales proportional to the level constant relative to level 1.
static func get_stat_budget(level: int, difficulty_modifier: float = 1.0) -> float:
	var base_points: float = 50.0
	var level_factor: float = get_level_constant(level) / get_level_constant(1)
	return base_points * level_factor * difficulty_modifier


# ==========================================
# SECTION 2: COMBAT DAMAGE & MITIGATION MATH
# ==========================================

## Asymptotic scaling formula: Percent = X / (X + L * K)
## Sourced from Diablo 3 / Written Realms.
## Guarantees that mitigation approaches 100% asymptotically, preventing invincibility exploits.
static func calculate_asymptotic_mitigation(stat_val: float, attacker_level: int, k_factor: float = 60.0) -> float:
	if stat_val <= 0.0:
		return 0.0
	var denominator: float = stat_val + (float(attacker_level) * k_factor)
	return stat_val / denominator


## Adjusted asymptotic dodge formula with base chance C:
## Percent = (X + L * K * C) / (X + L * K)
static func calculate_dodge_chance(dodge_rating: float, attacker_level: int, k_factor: float = 60.0, base_dodge: float = 0.02) -> float:
	if dodge_rating < 0.0:
		dodge_rating = 0.0
	var numerator: float = dodge_rating + (float(attacker_level) * k_factor * base_dodge)
	var denominator: float = dodge_rating + (float(attacker_level) * k_factor)
	return numerator / denominator


## Written Realms linear critical scaling:
## Percent = X / (L * K) + C (Since critting 100% doesn't break basic system math).
static func calculate_crit_chance(crit_rating: float, attacker_level: int, k_factor: float = 120.0, base_crit: float = 0.04) -> float:
	if crit_rating <= 0.0:
		return base_crit
	var chance: float = (crit_rating / (float(attacker_level) * k_factor)) + base_crit
	return clampf(chance, 0.0, 1.0)


## Calculates Effective Health Pool (EHP):
## EHP represents the total raw damage a character can absorb before dying.
## Each point of armor or resilience adds a linear increase to overall survivability.
static func calculate_effective_health(base_hp: float, armor_rating: float, attacker_level: int, armor_k: float = 60.0, res_rating: float = 0.0, res_k: float = 120.0) -> float:
	var armor_mitigation: float = calculate_asymptotic_mitigation(armor_rating, attacker_level, armor_k)
	var res_mitigation: float = calculate_asymptotic_mitigation(res_rating, attacker_level, res_k)
	
	# Combined multiplicative mitigation
	var total_mitigation: float = 1.0 - ((1.0 - armor_mitigation) * (1.0 - res_mitigation))
	if total_mitigation >= 1.0:
		return INF
	return base_hp / (1.0 - total_mitigation)


## Core Combat damage calculation:
## FinalDamage = (WeaponDamage + AP / 16) * SkillMod * ElementalMod * (1 - Mitigation)
static func calculate_combat_damage(weapon_dmg: float, attack_power: float, target_armor: float, attacker_level: int, armor_k: float = 60.0, skill_mod: float = 1.0, elemental_mod: float = 1.0) -> float:
	var base_atk: float = weapon_dmg + (attack_power / 16.0)
	var mitigation: float = calculate_asymptotic_mitigation(target_armor, attacker_level, armor_k)
	return base_atk * skill_mod * elemental_mod * (1.0 - mitigation)


# ==========================================
# SECTION 3: LOOT TABLES & REPEATABLE RANDOMNESS
# ==========================================

## Standard loot roller (sampling with replacement) using weights.
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
			return item
	return "null"


## Tetris-style bag roller (sampling without replacement).
## Modifies and tracks the active player's session state inside history_log.
## Resets all weights once the bag is exhausted.
static func roll_loot_without_replacement(loot_table: Dictionary, history_log: Dictionary) -> String:
	var active_table: Dictionary = {}
	for item in loot_table.keys():
		var current_weight: float = history_log.get(item, float(loot_table[item]))
		if current_weight > 0.0:
			active_table[item] = current_weight
			
	# If all items are drawn, reset the active session bag
	if active_table.is_empty() or sum_weights(active_table) <= 0.0:
		for item in loot_table.keys():
			history_log[item] = float(loot_table[item])
			active_table[item] = float(loot_table[item])
			
	var rolled_item: String = roll_loot_with_replacement(active_table)
	
	# Reduce the item's weight pool in the session log
	if rolled_item != "null" and history_log.has(rolled_item):
		history_log[rolled_item] = maxf(0.0, history_log[rolled_item] - 1.0)
		
	return rolled_item


## Blizzard-style pity-protected loot roller.
## Every failed draw for target_item reduces the weight of other items by X%
## (where X = 100 / max_rolls). Assures target_item drops by roll N.
static func roll_loot_with_pity(loot_table: Dictionary, history_counter: Dictionary, target_item: String, max_rolls_before_pity: int = 10) -> String:
	var rolls: int = history_counter.get(target_item, 0)
	var pity_factor: float = 1.0 - (float(rolls) / float(max_rolls_before_pity))
	pity_factor = clampf(pity_factor, 0.0, 1.0)
	
	var modified_table: Dictionary = {}
	for item in loot_table.keys():
		if item == target_item:
			modified_table[item] = float(loot_table[item])
		else:
			modified_table[item] = float(loot_table[item]) * pity_factor
			
	var rolled_item: String = roll_loot_with_replacement(modified_table)
	
	if rolled_item == target_item:
		history_counter[target_item] = 0 # Reset pity tracker
	else:
		history_counter[target_item] = rolls + 1 # Advance pity counter
		
	return rolled_item


# ==========================================
# SECTION 4: PROCEDURAL ENEMY GENERATOR
# ==========================================

## Procedural enemy design and budget compiler (Daniel Cook's thought experiment).
## Rolls random component parts, scores their raw power values, and then scales and
## normalizes their stats to match the level-appropriate difficulty target.
static func generate_balanced_enemy(level: int, target_difficulty_mod: float = 1.0) -> Dictionary:
	var base_power: float = get_level_constant(level) * 10.0 * target_difficulty_mod
	
	var move_parts: Dictionary = {"sluggish": 5.0, "normal_move": 10.0, "swift": 20.0}
	var attack_parts: Dictionary = {"scratch": 5.0, "bite": 10.0, "elemental_blast": 25.0}
	var defense_parts: Dictionary = {"unarmored": 5.0, "harden_shell": 15.0, "spirit_shield": 30.0}
	
	var move: String = roll_loot_with_replacement(move_parts)
	var atk: String = roll_loot_with_replacement(attack_parts)
	var defense: String = roll_loot_with_replacement(defense_parts)
	
	var raw_score: float = move_parts[move] + attack_parts[atk] + defense_parts[defense]
	var multiplier: float = base_power / raw_score
	
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
			"attack_power": attack_parts[atk] * multiplier * 2.0,
			"armor_rating": defense_parts[defense] * multiplier * 1.5,
			"speed": move_parts[move] * multiplier
		},
		"power_scale_factor": multiplier
	}


# ==========================================
# HELPER FUNCTIONS
# ==========================================

static func sum_weights(dict: Dictionary) -> float:
	var total: float = 0.0
	for v in dict.values():
		total += float(v)
	return total
