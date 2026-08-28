class_name PlayerState
extends RefCounted
## Per-player live state (v2 — canon model).
## Commons are unlimited terrain staples (a counted pouch);
## Cards are advanced resources (hand-limited); Items are crafted things.

var index: int = 0
var character_id: String = ""
var display_name: String = ""
var pos: Vector2i = Vector2i.ZERO

var light: int = 0                 ## Duality track −10..+10
var vp: int = 0                    ## 0..20 scale (synthesis S1)
var guardian_vp: int = 0           ## tiebreaker 2
var energy: int = 2                ## 0..5 (canon/energy.json)

var commons: Dictionary = {}       ## res_id -> count (tokens)
var cards: Array = []              ## [{id, tier, element}] hand-limited
var items: Array = []              ## crafted item ids, cap = pack_size

var move: int = 3
var pack_size: int = 5             ## item slots (canon setup: 3 equipped + 2 backpack)
var hand_limit: int = 7
var heart: String = ""             ## loved element (−1 F)
var cross: String = ""             ## distrusted element (+1 F)

var slow_penalty: int = 0
var last_action: String = ""
var meditated: bool = false        ## unlocks Learning this turn
var care_gift_used: bool = false   ## synthesis S4: +1 Light per Care phase max
var slept: bool = false            ## sleeping skips the Action phase
var fought_recently: bool = false  ## Outcast weakness hook
var skills: Array = []             ## learned skill ids
var offerings_made: int = 0

# Action Cards (v2 engine)
var action_levels: Dictionary = {"explore": 1, "craft": 1, "creatures": 1, "magic": 1, "guardian": 1}

# Wild Deck & item catalog (content drop integration)
var wild_cards: Array = []         ## held fate/ward card ids, cap = config wild.hand_cap
var wards: Dictionary = {}         ## ward_id -> turns remaining
var tool_uses: Dictionary = {}     ## catalog tool id -> gathers left before it breaks
var chest_pity: Dictionary = {}    ## GameMathEngine pity counters for chest rolls
var craft_locked: bool = false     ## Ancient Trap: next Craft action is locked
var trials_done: Array = []        ## bottleneck quest ids already faced

# Quest tracking (v2 quest engine)
var completed_quests: Array = []
var quest_progress: Dictionary = {}
var guardian_quests: Array = []
var explored_t1_count: int = 0
var gifted_players_this_round: Array = []
var guardian_sites_offered: Array = []
var crafted_items_history: Array = []


func commons_count() -> int:
	var total := 0
	for k in commons.keys():
		total += int(commons[k])
	return total


func add_common(id: String, n: int = 1) -> void:
	if id == "":
		return
	commons[id] = int(commons.get(id, 0)) + n
	if int(commons[id]) <= 0:
		commons.erase(id)


func has_common(id: String, n: int = 1) -> bool:
	return int(commons.get(id, 0)) >= n


func spend_common(id: String, n: int = 1) -> bool:
	if not has_common(id, n):
		return false
	add_common(id, -n)
	return true


## Spend any n commons (random-ish order). Returns ids spent.
func spend_any_commons(n: int, rng: RandomNumberGenerator) -> Array:
	var spent: Array = []
	for i in n:
		var keys := commons.keys()
		if keys.is_empty():
			break
		var k: String = String(keys[rng.randi_range(0, keys.size() - 1)])
		add_common(k, -1)
		spent.append(k)
	return spent


func add_card(card: Dictionary) -> bool:
	if cards.size() >= hand_limit:
		return false
	cards.append(card)
	return true


func remove_card_of_tier(tier: String) -> Dictionary:
	for i in cards.size():
		if String(cards[i].get("tier", "")) == tier:
			var c: Dictionary = cards[i]
			cards.remove_at(i)
			return c
	return {}


func has_item(id: String) -> bool:
	return items.has(id)


func remove_item(id: String) -> bool:
	var i := items.find(id)
	if i < 0:
		return false
	items.remove_at(i)
	return true


func to_dict() -> Dictionary:
	return {
		"index": index, "character_id": character_id, "display_name": display_name,
		"q": pos.x, "r": pos.y,
		"light": light, "vp": vp, "guardian_vp": guardian_vp, "energy": energy,
		"commons": commons.duplicate(), "cards": cards.duplicate(true), "items": items.duplicate(),
		"move": move, "pack_size": pack_size, "hand_limit": hand_limit,
		"heart": heart, "cross": cross,
		"slow_penalty": slow_penalty, "last_action": last_action,
		"skills": skills.duplicate(), "offerings_made": offerings_made,
		"fought_recently": fought_recently,
		"wild_cards": wild_cards.duplicate(), "wards": wards.duplicate(),
		"tool_uses": tool_uses.duplicate(), "chest_pity": chest_pity.duplicate(),
		"craft_locked": craft_locked, "trials_done": trials_done.duplicate(),
		"action_levels": action_levels.duplicate(),
		"completed_quests": completed_quests.duplicate(),
		"quest_progress": quest_progress.duplicate(),
		"guardian_quests": guardian_quests.duplicate(true),
		"explored_t1_count": explored_t1_count,
		"gifted_players_this_round": gifted_players_this_round.duplicate(),
		"guardian_sites_offered": guardian_sites_offered.map(func(v: Vector2i) -> Array: return [v.x, v.y]),
		"crafted_items_history": crafted_items_history.duplicate(),
	}


static func from_dict(d: Dictionary) -> PlayerState:
	var p := PlayerState.new()
	p.index = int(d.get("index", 0))
	p.character_id = String(d.get("character_id", ""))
	p.display_name = String(d.get("display_name", ""))
	p.pos = Vector2i(int(d.get("q", 0)), int(d.get("r", 0)))
	p.light = int(d.get("light", 0))
	p.vp = int(d.get("vp", 0))
	p.guardian_vp = int(d.get("guardian_vp", 0))
	p.energy = int(d.get("energy", 2))
	p.commons = d.get("commons", {})
	p.cards = d.get("cards", [])
	p.items = d.get("items", [])
	p.move = int(d.get("move", 3))
	p.pack_size = int(d.get("pack_size", 5))
	p.hand_limit = int(d.get("hand_limit", 7))
	p.heart = String(d.get("heart", ""))
	p.cross = String(d.get("cross", ""))
	p.slow_penalty = int(d.get("slow_penalty", 0))
	p.last_action = String(d.get("last_action", ""))
	p.skills = d.get("skills", [])
	p.offerings_made = int(d.get("offerings_made", 0))
	p.fought_recently = bool(d.get("fought_recently", false))
	p.wild_cards = d.get("wild_cards", [])
	p.wards = d.get("wards", {})
	p.tool_uses = d.get("tool_uses", {})
	p.chest_pity = d.get("chest_pity", {})
	p.craft_locked = bool(d.get("craft_locked", false))
	p.trials_done = d.get("trials_done", [])
	p.action_levels = d.get("action_levels", {"explore": 1, "craft": 1, "creatures": 1, "magic": 1, "guardian": 1})
	p.completed_quests = d.get("completed_quests", [])
	p.quest_progress = d.get("quest_progress", {})
	p.guardian_quests = d.get("guardian_quests", [])
	p.explored_t1_count = int(d.get("explored_t1_count", 0))
	p.gifted_players_this_round = d.get("gifted_players_this_round", [])
	var raw_sites: Array = d.get("guardian_sites_offered", [])
	p.guardian_sites_offered = []
	for s in raw_sites:
		if s is Array and s.size() >= 2:
			p.guardian_sites_offered.append(Vector2i(int(s[0]), int(s[1])))
	p.crafted_items_history = d.get("crafted_items_history", [])
	return p
