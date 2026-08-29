extends Node
## Autoloaded as `Game`. v2 — the canon turn engine.
## Turn = CARE phase (consume / sleep / meditate / trade&gift — bonus, free)
## then ACTION phase (1 of 6 main actions), then pass left. (canon/actions.json)
## Island Rage +1 every round. Hypocrisy penalty bites in Care. Three victory ways.

const SAVE_PATH := "user://save_v2.json"

var rng := RandomNumberGenerator.new()
var decks: Decks
var board: Board
var fate: Fate
var quest_engine: QuestEngine
var wild_deck: WildDeck
var dark_aggression_rounds: int = 0  ## Eclipse: all creatures act Deep Dark
var players: Array[PlayerState] = []
var current: int = 0
var round_num: int = 1
var rage: int = 0                 ## Island Rage — shared, 0..10
var phase: String = "care"        ## "care" | "action"
var common_quests: Array = []
var started: bool = false
var winner_index: int = -1
var winner_way: String = ""
var pending_player_count: int = 2


func _ready() -> void:
	rng.randomize()


func current_player() -> PlayerState:
	return players[current]


func band_of(p: PlayerState) -> Duality.Band:
	return Duality.band_for(p.light)


# ------------------------------------------------------------------ lifecycle

func new_game(player_count: int, character_ids: Array[String] = []) -> void:
	decks = Decks.new(rng)
	fate = Fate.new(rng, decks.canon.get("fate", {}))
	wild_deck = WildDeck.new(rng, decks.wild_deck_data)
	dark_aggression_rounds = 0
	board = Board.new()
	board.generate(decks, rng)
	players.clear()
	winner_index = -1
	winner_way = ""
	rage = 0
	var starts := board.start_positions(player_count)
	for i in player_count:
		var c: Dictionary = {}
		if i < character_ids.size() and decks.characters_by_id.has(character_ids[i]):
			c = decks.characters_by_id[character_ids[i]]
		else:
			c = decks.characters[i % decks.characters.size()]
		var p := PlayerState.new()
		p.index = i
		p.character_id = String(c["id"])
		p.display_name = "P%d · %s" % [i + 1, String(c["name"])]
		p.move = int(c.get("move", 3))
		p.pack_size = int(c.get("pack_size", 5))
		p.hand_limit = int(c.get("hand_limit", 7))
		p.energy = int(c.get("energy_start", 2))
		p.heart = String(c.get("heart", ""))
		p.cross = String(c.get("cross", ""))
		p.action_levels = ActionCards.default_levels_for(p.character_id)
		p.pos = starts[i]
		players.append(p)
	common_quests = decks.draw_common_quests()
	quest_engine = QuestEngine.new(common_quests)
	current = 0
	round_num = 1
	phase = "care"
	started = true
	save_game()


func begin_turn_for_current() -> void:
	phase = "care"
	var p := current_player()
	p.meditated = false
	p.care_gift_used = false
	p.slept = false


func end_care_phase() -> void:
	phase = "action"


func end_turn() -> void:
	var p := current_player()
	p.fought_recently = false  # set again during the turn if they fought
	# Wild wards burn down one turn of their owner's time.
	for ward_id in p.wards.keys().duplicate():
		p.wards[ward_id] = int(p.wards[ward_id]) - 1
		if int(p.wards[ward_id]) <= 0:
			p.wards.erase(ward_id)
	EventBus.turn_ended.emit(current)
	
	# Single player check: resolve immediately
	if players.size() == 1 and get_victory_way(p) != "":
		winner_index = p.index
		winner_way = get_victory_way(p)
		_clear_save()
		EventBus.game_won.emit(winner_index, winner_way)
		return

	current = (current + 1) % players.size()
	if current == 0:
		# Round complete: evaluate simultaneous finish tiebreakers (GDD §10.3 & S11)
		if resolve_round_end_victory():
			return

		round_num += 1
		for pl in players:
			pl.gifted_players_this_round.clear()
		if dark_aggression_rounds > 0:
			dark_aggression_rounds -= 1
			if dark_aggression_rounds == 0:
				EventBus.message.emit("The eclipse passes — the wilds calm again.")
		# Island Rage: temporal faucet, +1 every round (canon/rage.json).
		add_rage(Rage.delta_for("round_start"))
		# Mode turn limit (canon/modes.json; Standard 15 is the designer-approved
		# default): when the last round completes, the island decides.
		if round_num > _turns_limit():
			_endgame_scoring()
			return
	begin_turn_for_current()
	save_game()
	EventBus.turn_started.emit(current)


func _turns_limit() -> int:
	for m in decks.canon.get("modes", {}).get("modes", []):
		if bool(m.get("baseline", false)):
			return int(m.get("turns_per_player", 15))
	return 15


## Nobody reached a Way in time: closest journey wins — most VP, ties broken
## by higher Light, then Guardian VP (canon tiebreaker order). TUNE.
func _endgame_scoring() -> void:
	var best: PlayerState = players[0]
	for p in players:
		if p.vp > best.vp \
			or (p.vp == best.vp and p.light > best.light) \
			or (p.vp == best.vp and p.light == best.light and p.guardian_vp > best.guardian_vp):
			best = p
	winner_index = best.index
	winner_way = "endgame"
	_clear_save()
	EventBus.game_won.emit(winner_index, winner_way)


# ------------------------------------------------------------------ mutations

func shift_light(p: PlayerState, trigger: String) -> int:
	var delta := Duality.shift_delta(trigger)
	add_light(p, delta)
	return delta


func add_light(p: PlayerState, amount: int) -> void:
	if amount == 0:
		return
	p.light = clampi(p.light + amount, Duality.track_min(), Duality.track_max())
	EventBus.light_changed.emit(p.index, p.light)


func add_vp(p: PlayerState, amount: int, from_guardian: bool = false) -> void:
	p.vp = clampi(p.vp + amount, 0, 20)
	if from_guardian and amount > 0:
		p.guardian_vp += amount
	EventBus.vp_changed.emit(p.index, p.vp)


func add_energy(p: PlayerState, amount: int) -> int:
	var cap := int(decks.canon.get("energy", {}).get("meter", {}).get("cap", 5))
	var before := p.energy
	p.energy = clampi(p.energy + amount, 0, cap)
	EventBus.inventory_changed.emit(p.index)
	return p.energy - before


func add_rage(amount: int) -> void:
	rage = clampi(rage + amount, 0, Rage.track_max())
	EventBus.rage_changed.emit(rage)


## Care-phase eating (canon/energy.json): raw common food +1, Cooked Meal +3.
## The hypocrisy penalty reduces CARE-phase energy GAINS (canon/duality.json).
func care_eat(p: PlayerState, cooked: bool) -> int:
	var gain := 3 if cooked else 1
	gain = maxi(0, gain - Duality.hypocrisy_energy_penalty(p.vp, p.light))
	return add_energy(p, gain)


func care_sleep(p: PlayerState) -> int:
	var gain := maxi(0, 2 - Duality.hypocrisy_energy_penalty(p.vp, p.light))
	p.slept = true
	return add_energy(p, gain)


func care_meditate(p: PlayerState) -> bool:
	if p.energy < 1:
		return false
	add_energy(p, -1)
	p.meditated = true
	return true


## Care-phase gift: transfer 1 common. Light: at most +1 per Care phase (S4);
## Outcast weakness: no Light the round after fighting.
func care_gift(from_p: PlayerState, to_p: PlayerState, common_id: String) -> bool:
	if not from_p.spend_common(common_id, 1):
		return false
	to_p.add_common(common_id, 1)
	if not from_p.care_gift_used:
		var blocked := from_p.character_id == "outcast" and from_p.fought_recently
		if not blocked:
			shift_light(from_p, "gift_card")
		from_p.care_gift_used = true
	if quest_engine != null:
		quest_engine.on_gift_given(from_p, to_p, common_id, false, players.size())
	EventBus.inventory_changed.emit(from_p.index)
	EventBus.inventory_changed.emit(to_p.index)
	return true


## Action 6 — Give Back Light: donate 3 commons to the island/others.
## +2 Light, −1 Rage, +1 VP (synthesis S1 answers Q2).
func give_back_light(p: PlayerState) -> bool:
	if p.commons_count() < 3:
		return false
	p.spend_any_commons(3, rng)
	shift_light(p, "give_back_light")
	add_rage(Rage.delta_for("give_back_light"))
	add_vp(p, decks.vp_faucet("give_back_light"))
	if p.skills.has("avatar_of_harmony"):
		add_vp(p, 2)
		add_energy(p, 2)
	EventBus.inventory_changed.emit(p.index)
	return true


## Guardian quest step at a Guardian site (uses an Offering Bundle).
func guardian_offering(p: PlayerState, sanctum: bool) -> bool:
	if not p.remove_item("offering_bundle"):
		return false
	p.offerings_made += 1
	shift_light(p, "guardian_giveback")
	add_rage(Rage.delta_for("guardian_quest_step"))
	var step_vp := decks.vp_faucet("guardian_chain_step", "rare" if sanctum else "uncommon")
	add_vp(p, step_vp, true)
	if quest_engine != null:
		quest_engine.on_guardian_offering(p, p.pos)
	EventBus.inventory_changed.emit(p.index)
	return true


func lose_commons(p: PlayerState, n: int) -> Array:
	var with_rage := n + Rage.setback_discard(rage)
	var lost := p.spend_any_commons(with_rage, rng)
	EventBus.inventory_changed.emit(p.index)
	return lost


# ------------------------------------------------------------------ item catalog (content drop)

## Eat a catalog consumable in the Care phase. Energy gains respect the
## hypocrisy penalty like all Care-phase gains; Light is bounded by the item.
func use_consumable(p: PlayerState, item_id: String) -> Dictionary:
	var it := decks.item_def(item_id)
	if it.is_empty() or not p.remove_item(item_id):
		return {}
	var gain := maxi(0, int(it.get("use_energy", 1)) - Duality.hypocrisy_energy_penalty(p.vp, p.light))
	var gained := add_energy(p, gain)
	var l := int(it.get("use_light", 0))
	if l != 0:
		add_light(p, l)
	EventBus.inventory_changed.emit(p.index)
	return {"energy": gained, "light": l}


## Offer a catalog relic at a Guardian site: consumed for its offer_vp.
func offer_relic(p: PlayerState, item_id: String) -> int:
	var it := decks.item_def(item_id)
	var vp := int(it.get("offer_vp", 0))
	if vp <= 0 or not p.remove_item(item_id):
		return 0
	p.offerings_made += 1
	add_light(p, 1)
	add_rage(Rage.delta_for("guardian_quest_step"))
	add_vp(p, vp, true)
	if quest_engine != null:
		quest_engine.on_guardian_offering(p, p.pos)
	EventBus.inventory_changed.emit(p.index)
	return vp


## Resolve a bottleneck trial (content-drop dual-path quest) at a Guardian site.
## Light path: deposit 5 commons peacefully. Dark path: force it — free, but
## the island remembers (Rage + the scaled Light loss).
func resolve_bottleneck(p: PlayerState, quest: Dictionary, dark: bool) -> bool:
	var path: Dictionary = quest.get("dark" if dark else "light", {})
	if path.is_empty() or p.trials_done.has(String(quest.get("id", ""))):
		return false
	# Balance: the island only tests each wanderer so many times (TUNE).
	if p.trials_done.size() >= int(decks.config.get("wild", {}).get("trials_per_player", 2)):
		return false
	if not dark:
		if p.commons_count() < int(path.get("cost_commons", 5)):
			return false
		p.spend_any_commons(int(path.get("cost_commons", 5)), rng)
	else:
		add_rage(int(path.get("rage", 2)))
	add_light(p, int(path.get("light", 0)))
	add_vp(p, int(path.get("vp", 0)), true)
	var token := String(path.get("item", ""))
	if token != "" and p.items.size() < p.pack_size:
		p.items.append(token)
	p.trials_done.append(String(quest.get("id", "")))
	EventBus.inventory_changed.emit(p.index)
	return true


## Apply the best catalog tool to a gather: returns its bonus commons and
## burns one use, breaking the tool when its durability is spent.
func use_best_tool(p: PlayerState) -> Dictionary:
	var best_id := ""
	var best_bonus := 0
	for id in p.items:
		var it := decks.item_def(String(id))
		if String(it.get("type", "")) == "tool" and int(it.get("bonus_commons", 0)) > best_bonus:
			best_id = String(id)
			best_bonus = int(it.get("bonus_commons", 0))
	if best_id == "":
		return {}
	if not p.tool_uses.has(best_id):
		p.tool_uses[best_id] = int(decks.item_def(best_id).get("uses", 3))
	p.tool_uses[best_id] = int(p.tool_uses[best_id]) - 1
	var broke := int(p.tool_uses[best_id]) <= 0
	if broke:
		p.tool_uses.erase(best_id)
		p.remove_item(best_id)
	return {"id": best_id, "bonus": best_bonus, "broke": broke}


## Chest roll (content drop): pity-protected rarity roll via GameMathEngine,
## then a random catalog item of that rarity. Chests on spirit ground can
## hold relics.
func open_chest(p: PlayerState, include_relics: bool = false) -> Dictionary:
	var rarity := GameMathEngine.roll_loot_with_pity(
		{"uncommon": 70.0, "rare": 25.0, "legendary": 5.0}, p.chest_pity, "legendary", 10)
	if rarity == "null":
		rarity = "uncommon"
	var types: Array = ["tool", "gear", "consumable"]
	if include_relics:
		types.append("relic")
	return decks.random_catalog_item(rarity, types)


## An item found in the wild (T2+ gathers, fight loot): weighted rarity roll,
## added to the pack. Returns the catalog def, or {} when nothing fits.
func find_catalog_item(p: PlayerState, types: Array) -> Dictionary:
	if p.items.size() >= p.pack_size:
		return {}
	var rarity := GameMathEngine.roll_loot_with_replacement(
		{"common": 50.0, "uncommon": 30.0, "rare": 15.0, "legendary": 5.0})
	var it := decks.random_catalog_item(rarity, types)
	if it.is_empty():
		return {}
	p.items.append(String(it["id"]))
	EventBus.inventory_changed.emit(p.index)
	return it


# ------------------------------------------------------------------ fights

## Resolve a fight (canon chassis + synthesis S2): fate draw + modifiers vs F.
## Returns {won, value, wild, f, detail}.
func fight(p: PlayerState, creature: Dictionary, spend_energy: int) -> Dictionary:
	var f := int(creature.get("f", 4))
	var element := String(creature.get("element", ""))
	if p.heart == element:
		f -= 1
	if p.cross == element:
		f += 1
	var band := band_of(p)
	if band == Duality.Band.DARK or band == Duality.Band.MAX_DARK:
		f += 1  # canon dark band: +1 F on all creature fights
	f += Rage.f_bonus(rage)
	var draw := fate.draw(band, decks.canon.get("fate", {}))
	var value := int(draw["value"])
	if spend_energy > 0 and p.energy >= spend_energy:
		add_energy(p, -spend_energy)
		value += spend_energy  # canon energy spends: +1 per Energy (cap 2 enforced by UI)
	if p.character_id == "outcast" and rage >= 6:
		value += 1  # PERK — Rage Capitalizer
	if ActionCards.get_level(p, "creatures") >= 2:
		value += 1  # Action Card: Creatures Lvl 2+ (+1 Fate combat modifier)
	p.fought_recently = true
	var won: bool = value >= f
	if won:
		shift_light(p, "fight_creature")
	return {"won": won, "value": value, "wild": bool(draw["wild"]), "f": f}


# ------------------------------------------------------------------ victory

## Returns victory way ("enlightened", "capable", "dark") if player qualifies, or "" if not.
## Enforces viability gate (S5 / Q7): player must have completed >= 1 Guardian offering or defiled a site.
func get_victory_way(p: PlayerState) -> String:
	var viable := p.offerings_made >= 1 or p.character_id == "outcast" or p.light <= -8
	if not viable:
		return ""
	var t := decks.victory_thresholds()
	var cap: Dictionary = t.get("capable", {})
	var enl: Dictionary = t.get("enlightened", {})
	var drk: Dictionary = t.get("dark", {})
	if p.vp >= int(enl.get("vp", 10)) and p.light >= int(enl.get("min_light", 8)):
		return "enlightened"
	elif p.vp >= int(cap.get("vp", 16)) and p.light >= int(cap.get("min_light", 3)):
		return "capable"
	elif p.vp >= int(drk.get("vp", 18)) and p.light <= int(drk.get("max_light", -8)):
		return "dark"
	return ""


## Evaluates round-end simultaneous finishes and resolves tiebreakers (GDD §10.3 & S11).
## 1. Higher Light wins (being kind beats being successful).
## 2. Most Guardian VP wins.
## 3. Shared victory (cooperation is the point of the game).
func resolve_round_end_victory() -> bool:
	var qualified: Array[PlayerState] = []
	for p in players:
		if get_victory_way(p) != "":
			qualified.append(p)
	if qualified.is_empty():
		return false
	if qualified.size() == 1:
		winner_index = qualified[0].index
		winner_way = get_victory_way(qualified[0])
		_clear_save()
		EventBus.game_won.emit(winner_index, winner_way)
		return true

	# Tiebreaker 1: Light Track Priority
	qualified.sort_custom(func(a: PlayerState, b: PlayerState) -> bool:
		if a.light != b.light:
			return a.light > b.light
		if a.guardian_vp != b.guardian_vp:
			return a.guardian_vp > b.guardian_vp
		return a.vp > b.vp
	)
	var top: PlayerState = qualified[0]
	var second: PlayerState = qualified[1]

	if top.light > second.light:
		winner_index = top.index
		winner_way = get_victory_way(top)
	elif top.guardian_vp > second.guardian_vp:
		winner_index = top.index
		winner_way = get_victory_way(top)
	else:
		# Shared Victory!
		winner_index = -2
		winner_way = "shared"

	_clear_save()
	EventBus.game_won.emit(winner_index, winner_way)
	return true


# ------------------------------------------------------------------ save/load

func save_game() -> void:
	if not started:
		return
	var data := {
		"version": 2,
		"round": round_num,
		"current": current,
		"rage": rage,
		"phase": phase,
		"winner_index": winner_index,
		"winner_way": winner_way,
		"common_quests": common_quests,
		"board": board.to_dict(),
		"players": players.map(func(p: PlayerState) -> Dictionary: return p.to_dict()),
		"wild_deck": wild_deck.to_dict() if wild_deck != null else {},
		"dark_aggression": dark_aggression_rounds,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null or not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != 2:
		return false
	decks = Decks.new(rng)
	fate = Fate.new(rng, decks.canon.get("fate", {}))
	wild_deck = WildDeck.new(rng, decks.wild_deck_data)
	wild_deck.restore(data.get("wild_deck", {}))
	dark_aggression_rounds = int(data.get("dark_aggression", 0))
	board = Board.from_dict(data.get("board", {}))
	players.clear()
	for pd in data.get("players", []):
		players.append(PlayerState.from_dict(pd))
	if players.is_empty():
		return false
	round_num = int(data.get("round", 1))
	current = int(data.get("current", 0))
	rage = int(data.get("rage", 0))
	phase = String(data.get("phase", "care"))
	winner_index = int(data.get("winner_index", -1))
	winner_way = String(data.get("winner_way", ""))
	common_quests = data.get("common_quests", [])
	quest_engine = QuestEngine.new(common_quests)
	started = true
	return true


func redraw_common_quests() -> void:
	common_quests = decks.draw_common_quests()
	if quest_engine != null:
		quest_engine.set_common_quests(common_quests)
	EventBus.quests_redrawn.emit(common_quests)


func start_quest_redraw_vote(caller_index: int) -> Dictionary:
	if quest_engine == null:
		quest_engine = QuestEngine.new(common_quests)
	return quest_engine.start_redraw_vote(caller_index, players.size())


func submit_quest_redraw_vote(voter_index: int, agree: bool) -> Dictionary:
	if quest_engine == null:
		quest_engine = QuestEngine.new(common_quests)
	var status := quest_engine.submit_vote(voter_index, agree, players.size())
	if bool(status.get("resolved", false)) and bool(status.get("passed", false)):
		redraw_common_quests()
	return status


func _clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
