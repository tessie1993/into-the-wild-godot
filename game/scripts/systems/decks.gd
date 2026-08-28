class_name Decks
extends RefCounted
## v2 data hub — loads the machine-readable CANON (data/canon/*.json, verbatim
## from the Orca lanes) plus the digital adaptations (resources, creatures,
## characters, recipes, quests, events) and expanded balanced datasets
## (items, expanded creatures, expanded trials, deck cards) wired directly
## with GameMathEngine (Action Value Model & balancing formulas).

var canon: Dictionary = {}         ## name -> parsed canon json
var synthesis: Dictionary = {}
var config: Dictionary = {}        ## data/config.json — board layout + app settings
var elements: Array = []           ## resources_digital.json elements
var elements_by_id: Dictionary = {}
var characters: Array = []
var characters_by_id: Dictionary = {}
var creatures: Array = []
var events: Array = []
var recipes: Array = []
var quests: Dictionary = {}
var skills: Array = []
var items_catalog: Dictionary = {}      ## item_id -> catalog def (content drop)
var wild_deck_data: Dictionary = {}     ## data/wild_deck.json (content drop)
var bottleneck_quests: Array = []       ## dual-path guardian trials (content drop)

# Expanded Datasets (balanced via GameMathEngine Action Value Model)
var items: Array = []
var items_by_id: Dictionary = {}
var items_by_type: Dictionary = {}
var items_by_rarity: Dictionary = {}

var expanded_creatures: Array = []
var expanded_creatures_by_id: Dictionary = {}
var creatures_by_biome: Dictionary = {}

var expanded_quests: Array = []
var expanded_quests_by_id: Dictionary = {}
var expanded_deck_cards: Array = []

var _item_pity_trackers: Dictionary = {}  ## player_index -> {item_id: roll_count}
var _rng: RandomNumberGenerator

const CANON_FILES: Array[String] = [
	"actions", "crafting", "decks", "duality", "elements", "energy",
	"fate", "modes", "rage", "tiers", "victory", "synthesis",
]
const TIER_ORDER: Array[String] = ["common", "uncommon", "rare", "legendary"]


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	for name in CANON_FILES:
		canon[name] = _load_json("res://data/canon/%s.json" % name)
	synthesis = canon.get("synthesis", {})
	config = _load_json("res://data/config.json")
	Duality.setup(canon.get("duality", {}))
	Rage.setup(canon.get("rage", {}))

	var res: Dictionary = _load_json("res://data/resources_digital.json")
	elements = res.get("elements", [])
	for e in elements:
		elements_by_id[String(e["id"])] = e
	var cr: Dictionary = _load_json("res://data/creatures_canon.json")
	creatures = cr.get("creatures", [])
	var ch: Dictionary = _load_json("res://data/characters.json")
	characters = ch.get("characters", [])
	for c in characters:
		characters_by_id[String(c["id"])] = c
	var ev: Dictionary = _load_json("res://data/events.json")
	events = ev.get("events", [])
	var rc: Dictionary = _load_json("res://data/recipes.json")
	recipes = rc.get("recipes", [])
	quests = _load_json("res://data/quests.json")
	var sk: Dictionary = _load_json("res://data/skills.json")
	skills = sk.get("skills", [])
	# --- content-drop integrations (converted by tools/drop-converter)
	var wild: Dictionary = _load_json("res://data/creatures_wild.json")
	creatures.append_array(wild.get("creatures", []))
	var cat: Dictionary = _load_json("res://data/items_catalog.json")
	for it in cat.get("items", []):
		items_catalog[String(it["id"])] = it
	wild_deck_data = _load_json("res://data/wild_deck.json")
	bottleneck_quests = _load_json("res://data/quests_bottleneck.json").get("quests", [])

	# Load Expanded Datasets
	_load_expanded_datasets()


func _load_expanded_datasets() -> void:
	# 1. Items dataset (tools, gear, consumables, weapons, dark kit)
	var raw_items: Variant = _load_json_data("res://data/items.json")
	if raw_items is Array:
		items = raw_items
		for it in items:
			if it is Dictionary:
				var iid: String = String(it.get("item_id", ""))
				if iid != "":
					items_by_id[iid] = it
				var itype: String = String(it.get("type", "General")).to_lower()
				if not items_by_type.has(itype):
					items_by_type[itype] = []
				items_by_type[itype].append(it)
				var irarity: String = String(it.get("rarity", "Common")).to_lower()
				if not items_by_rarity.has(irarity):
					items_by_rarity[irarity] = []
				items_by_rarity[irarity].append(it)

	# 2. Expanded creatures dataset (5 karma bands, field moves, biomes)
	var raw_creatures: Variant = _load_json_data("res://data/creatures_expanded.json")
	if raw_creatures is Array:
		expanded_creatures = raw_creatures
		for c in expanded_creatures:
			if c is Dictionary:
				var cid: String = String(c.get("id", ""))
				if cid != "":
					expanded_creatures_by_id[cid] = c
				var biomes: Array = c.get("biomes", [])
				for b in biomes:
					var bstr := String(b)
					if not creatures_by_biome.has(bstr):
						creatures_by_biome[bstr] = []
					creatures_by_biome[bstr].append(c)

	# 3. Expanded trials & bottleneck quests
	var raw_quests: Variant = _load_json_data("res://data/quests_expanded.json")
	if raw_quests is Array:
		expanded_quests = raw_quests
		for q in expanded_quests:
			if q is Dictionary:
				var qid: String = String(q.get("quest_id", ""))
				if qid != "":
					expanded_quests_by_id[qid] = q

	# 4. Expanded deck cards
	var raw_deck: Variant = _load_json_data("res://data/deck.json")
	if raw_deck is Array:
		expanded_deck_cards = raw_deck


static func _load_json(path: String) -> Dictionary:
	var data: Variant = _load_json_data(path)
	if data is Dictionary:
		return data
	return {}


static func _load_json_data(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: " + path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if parsed == null:
		push_error("Invalid JSON in: " + path)
	return parsed


func _pick(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]


# ------------------------------------------------------------------ economy & valuation

func ce_of(tier: String) -> int:
	return GameMathEngine.ce_of_tier(tier)


func ring_element_ids() -> Array:
	var out: Array = []
	for e in elements:
		if not bool(e.get("earned_not_gathered", false)):
			out.append(String(e["id"]))
	return out


func commons_of(element_id: String) -> Array:
	return elements_by_id.get(element_id, {}).get("commons", [])


func random_common(element_id: String) -> String:
	var pool := commons_of(element_id)
	var picked: Variant = _pick(pool)
	return String(picked) if picked != null else ""


## Draw one advanced-resource CARD from the ring deck (tile tier 1 or 2),
## weighted by canon print counts, in the tile's element.
func draw_card(element_id: String, tile_tier: int) -> Dictionary:
	var deck_id := "T2" if tile_tier >= 2 else "T1"
	var counts: Dictionary = {}
	for d in canon.get("decks", {}).get("decks", []):
		if String(d.get("id", "")) == deck_id:
			counts = d.get("print_counts", {})
	var total := 0
	for k in counts.keys():
		total += int(counts[k])
	var tier := "uncommon"
	if total > 0:
		var roll := _rng.randi_range(1, total)
		var acc := 0
		for k in ["uncommon", "rare", "legendary"]:
			acc += int(counts.get(k, 0))
			if roll <= acc:
				tier = k
				break
	var e: Dictionary = elements_by_id.get(element_id, {})
	var pool: Array = e.get("cards", {}).get(tier, [])
	var i := TIER_ORDER.find(tier)
	while pool.is_empty() and i > 0:
		i -= 1
		pool = e.get("cards", {}).get(TIER_ORDER[i], [])
		tier = TIER_ORDER[i]
	var picked: Variant = _pick(pool)
	if picked == null:
		return {}
	return {"id": String(picked), "tier": tier, "element": element_id}


## T2 gather rule: draw 2 keep the higher-CE card (canon draw2keep1).
func draw_card_keep_best(element_id: String, tile_tier: int, n_draws: int) -> Dictionary:
	var best: Dictionary = {}
	for i in n_draws:
		var c := draw_card(element_id, tile_tier)
		if c.is_empty():
			continue
		if best.is_empty() or ce_of(String(c["tier"])) > ce_of(String(best["tier"])):
			best = c
	return best


# ------------------------------------------------------------------ items & loot rolling (GameMathEngine)

func get_item(item_id: String) -> Dictionary:
	return items_by_id.get(item_id, {})


func get_items_by_type(type: String) -> Array:
	return items_by_type.get(type.to_lower(), [])


func get_items_by_rarity(rarity: String) -> Array:
	return items_by_rarity.get(rarity.to_lower(), [])


## Rolls an item using GameMathEngine weights and progressive pity tracking.
func roll_item_loot(rarity_filter: String = "", player_index: int = -1, target_item: String = "") -> Dictionary:
	var candidates: Array = items if rarity_filter == "" else get_items_by_rarity(rarity_filter)
	if candidates.is_empty():
		return {}
	
	var weights: Dictionary = {}
	for it in candidates:
		var iid: String = String(it.get("item_id", ""))
		var w: float = float(it.get("weight", 1.0))
		weights[iid] = w
		
	var rolled_id := ""
	if target_item != "" and player_index >= 0:
		if not _item_pity_trackers.has(player_index):
			_item_pity_trackers[player_index] = {}
		rolled_id = GameMathEngine.roll_loot_with_pity(weights, _item_pity_trackers[player_index], target_item, 8)
	else:
		rolled_id = GameMathEngine.roll_loot_with_replacement(weights)
		
	return get_item(rolled_id)


# ------------------------------------------------------------------ encounters & creatures

func creature_for(element_id: String, tile_tier: int) -> Dictionary:
	# First check if there is an expanded creature matching element/biome or tier
	var allowed: Array = ["common"] if tile_tier < 2 else ["common", "uncommon", "rare"]
	var same: Array = []
	var any: Array = []
	
	# Prefer expanded creatures if loaded, falling back to canon creatures
	var pool_source: Array = expanded_creatures if not expanded_creatures.is_empty() else creatures
	for c in pool_source:
		var c_tier_str: String = "common"
		if c.has("tier"):
			if c["tier"] is int:
				c_tier_str = TIER_ORDER[clampi(int(c["tier"]) - 1, 0, 3)]
			else:
				c_tier_str = String(c["tier"]).to_lower()
				
		if not allowed.has(c_tier_str):
			continue
		any.append(c)
		
		# Check element or biomes
		if String(c.get("element", "")) == element_id:
			same.append(c)
		else:
			var biomes: Array = c.get("biomes", [])
			for b in biomes:
				if String(b).contains(element_id) or element_id.contains(String(b)):
					same.append(c)
					break
					
	var pool := same if not same.is_empty() else any
	var picked: Variant = _pick(pool)
	return picked if picked is Dictionary else {}


func get_expanded_creature(id: String) -> Dictionary:
	return expanded_creatures_by_id.get(id, {})


func creature_for_biome(biome: String, tier: int = 1) -> Dictionary:
	var list: Array = creatures_by_biome.get(biome, [])
	var filtered: Array = []
	for c in list:
		if int(c.get("tier", 1)) == tier:
			filtered.append(c)
	var pool := filtered if not filtered.is_empty() else list
	var picked: Variant = _pick(pool)
	return picked if picked is Dictionary else {}


func random_event() -> Dictionary:
	var picked: Variant = _pick(events)
	return picked if picked is Dictionary else {}


# ------------------------------------------------------------------ quests & trials

func draw_common_quests() -> Array:
	var out: Array = []
	var common: Dictionary = quests.get("common", {})
	for diff in ["easy", "medium", "hard"]:
		var q: Variant = _pick(common.get(diff, []))
		if q is Dictionary:
			var qd: Dictionary = (q as Dictionary).duplicate()
			qd["difficulty"] = diff
			out.append(qd)
	return out


func get_expanded_quest(quest_id: String) -> Dictionary:
	return expanded_quests_by_id.get(quest_id, {})


func draw_expanded_quest() -> Dictionary:
	var picked: Variant = _pick(expanded_quests)
	return picked if picked is Dictionary else {}


# ------------------------------------------------------------------ misc

func display_name_of(id: String) -> String:
	for r in recipes:
		if String(r.get("id", "")) == id:
			return String(r.get("name", id))
	if items_catalog.has(id):
		return String(items_catalog[id].get("name", id))
	if items_by_id.has(id):
		return String(items_by_id[id].get("name", id))
	return id.capitalize()


# ------------------------------------------------------------------ item catalog (content drop)

func item_def(id: String) -> Dictionary:
	return items_catalog.get(id, {})


## Random catalog item of a rarity (optionally filtered by type), rng-stable.
func random_catalog_item(rarity: String, types: Array = []) -> Dictionary:
	var pool: Array = []
	for it in items_catalog.values():
		if String(it.get("rarity", "")) != rarity:
			continue
		if not types.is_empty() and not types.has(String(it.get("type", ""))):
			continue
		pool.append(it)
	var picked: Variant = _pick(pool)
	return picked if picked is Dictionary else {}


## The strongest tool/gear stat a player carries (0 if none).
func best_item_stat(p: PlayerState, type: String, stat: String) -> int:
	var best := 0
	for id in p.items:
		var it := item_def(String(id))
		if String(it.get("type", "")) == type:
			best = maxi(best, int(it.get(stat, 0)))
	return best


## The bottleneck trial for a guardian site: matched by element (fallback any),
## picked deterministically by the site's coordinates so a site always poses
## the same trial.
func bottleneck_for(element_id: String, site: Vector2i) -> Dictionary:
	var same: Array = []
	for q in bottleneck_quests:
		if String(q.get("element", "")) == element_id:
			same.append(q)
	var pool := same if not same.is_empty() else bottleneck_quests
	if pool.is_empty():
		return {}
	var salt := absi(site.x * 92821 + site.y * 486187739)
	return pool[salt % pool.size()]


func vp_faucet(key: String, sub: String = "") -> int:
	var faucets: Dictionary = synthesis.get("S1_vp_scale", {}).get("vp_faucets", {})
	var v: Variant = faucets.get(key, 0)
	if v is Dictionary:
		return int((v as Dictionary).get(sub, 0))
	return int(v)


func victory_thresholds() -> Dictionary:
	return synthesis.get("S1_vp_scale", {}).get("victory_thresholds", {})
