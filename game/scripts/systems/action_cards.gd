class_name ActionCards
extends RefCounted
## Action-Card Engine (GDD §8.7 v2 design).
## Manages the 5 core leveled action cards per player:
## 1. Explore (movement, gathering, tile reveals)
## 2. Craft (items, buildings, refining)
## 3. Creatures (encounters, combat modifiers, familiar)
## 4. Magic (signature abilities, skill learning discount, sponsor perk)
## 5. Guardian (offerings, worker placement, action level-ups, trade unlock)

const ACTION_IDS: Array[String] = ["explore", "craft", "creatures", "magic", "guardian"]

const ACTION_NAMES: Dictionary = {
	"explore": "Explore / Gather",
	"craft": "Building / Craft",
	"creatures": "Creatures",
	"magic": "Magic / Learning",
	"guardian": "Guardian / Association",
}

const ACTION_DESCRIPTIONS: Dictionary = {
	"explore": "Move across the island, flip unexplored hexes, and gather element resources.",
	"craft": "Craft items, equipment, and shared public buildings.",
	"creatures": "Interact with living island creatures (befriend, fight, or exploit).",
	"magic": "Cast character signature magic and learn persistent skill perks.",
	"guardian": "Visit ancient Guardian sites, make offerings, and empower action cards.",
}


## Returns default starting action levels for a given character class (asymmetry per GDD §8.7).
static func default_levels_for(character_id: String) -> Dictionary:
	var levels := {
		"explore": 1,
		"craft": 1,
		"creatures": 1,
		"magic": 1,
		"guardian": 1,
	}
	match character_id:
		"cartographer":
			levels["explore"] = 2
		"botanist":
			levels["magic"] = 2
		"blacksmith":
			levels["craft"] = 2
		"outcast":
			levels["guardian"] = 2
	return levels


## Gets the level of a specific action card for player p.
static func get_level(p: PlayerState, action_id: String) -> int:
	return int(p.action_levels.get(action_id, 1))


## Levels up an action card for player p (cap 5).
static func level_up(p: PlayerState, action_id: String) -> bool:
	var cur: int = get_level(p, action_id)
	if cur >= 5:
		return false
	p.action_levels[action_id] = cur + 1
	return true


## Returns perk summary string for the current level of an action card.
static func get_perks_text(action_id: String, level: int) -> String:
	match action_id:
		"explore":
			match level:
				1: return "Lvl 1: Standard movement & gathering."
				2: return "Lvl 2: +1 Move speed; +1 common on gathers."
				3: return "Lvl 3: +1 card draw when revealing face-down tiles."
				4: return "Lvl 4: Immune to Tier 2 movement cost penalty."
				_: return "Lvl 5: Master Explorer (double gather without exhaust)."
		"craft":
			match level:
				1: return "Lvl 1: Common crafts without bench."
				2: return "Lvl 2: Crafting discount (1 less common on U recipes)."
				3: return "Lvl 3: Can build field benches anywhere."
				4: return "Lvl 4: Rare crafts gain +1 bonus durability."
				_: return "Lvl 5: Legendary craft anywhere without Workshop."
		"creatures":
			match level:
				1: return "Lvl 1: Standard encounters."
				2: return "Lvl 2: +1 bonus to Fate combat rolls."
				3: return "Lvl 3: Befriend demands cost 1 fewer common."
				4: return "Lvl 4: Tamed familiar (+1 Energy boost)."
				_: return "Lvl 5: Master Beast Whisperer."
		"magic":
			match level:
				1: return "Lvl 1: Character signature ability."
				2: return "Lvl 2: Skill learning costs -1 CE."
				3: return "Lvl 3: Sponsor perk (+1 common upon meditation)."
				4: return "Lvl 4: Signature ability costs 0 Energy once per round."
				_: return "Lvl 5: Ascended Magic."
		"guardian":
			match level:
				1: return "Lvl 1: Standard Guardian offerings."
				2: return "Lvl 2: Offerings grant +1 extra VP."
				3: return "Lvl 3: Unlocks Free Action Trading & empowers action cards."
				4: return "Lvl 4: Guardian Blessing active."
				_: return "Lvl 5: Sanctum Ascension."
	return ""


## Returns whether free action trading is unlocked (Guardian level >= 3).
static func has_free_trading(p: PlayerState) -> bool:
	return get_level(p, "guardian") >= 3
