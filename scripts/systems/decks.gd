class_name Decks
extends RefCounted
## v2 data hub — loads the machine-readable CANON (data/canon/*.json, verbatim
## from the Orca lanes) plus the digital adaptations (resources, creatures,
## characters, recipes, quests, events) and answers draws.
## Commons come from terrain staples; Uncommon/Rare/Legendary come from the
## ring decks with canon print-count weights (T1: 30U/10R; T2: 16U/18R/6L).

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


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("Invalid JSON in: " + path)
	return {}


func _pick(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]


# ------------------------------------------------------------------ economy

func ce_of(tier: String) -> int:
	for t in canon.get("tiers", {}).get("tiers", []):
		if String(t.get("id", "")) == tier:
			return int(t.get("ce", 1))
	return 1


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


# ------------------------------------------------------------------ encounters

func creature_for(element_id: String, tile_tier: int) -> Dictionary:
	var allowed: Array = ["common"] if tile_tier < 2 else ["common", "uncommon", "rare"]
	var same: Array = []
	var any: Array = []
	for c in creatures:
		if not allowed.has(String(c.get("tier", "common"))):
			continue
		any.append(c)
		if String(c.get("element", "")) == element_id:
			same.append(c)
	var pool := same if not same.is_empty() else any
	var picked: Variant = _pick(pool)
	return picked if picked is Dictionary else {}


func random_event() -> Dictionary:
	var picked: Variant = _pick(events)
	return picked if picked is Dictionary else {}


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


# ------------------------------------------------------------------ misc

func display_name_of(id: String) -> String:
	for r in recipes:
		if String(r.get("id", "")) == id:
			return String(r.get("name", id))
	return id.capitalize()


func vp_faucet(key: String, sub: String = "") -> int:
	var faucets: Dictionary = synthesis.get("S1_vp_scale", {}).get("vp_faucets", {})
	var v: Variant = faucets.get(key, 0)
	if v is Dictionary:
		return int((v as Dictionary).get(sub, 0))
	return int(v)


func victory_thresholds() -> Dictionary:
	return synthesis.get("S1_vp_scale", {}).get("victory_thresholds", {})
