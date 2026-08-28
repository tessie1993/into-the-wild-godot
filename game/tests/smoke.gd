extends Node
## Headless smoke test v2 — canon systems, Action Value Model & GameMathEngine.
## Runs as a scene so autoloads (Game, EventBus) are live:
##   godot --headless --path . res://tests/smoke.tscn

var failures := 0


func _ready() -> void:
	print("== Into the Wild smoke test v2 (canon + GameMathEngine) ==")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# --- canon + data load
	var decks := Decks.new(rng)
	for name in Decks.CANON_FILES:
		_check(not (decks.canon.get(name, {}) as Dictionary).is_empty(), "canon/%s.json loads" % name)
	_check(decks.elements.size() == 6, "6 elements")
	_check(decks.ring_element_ids().size() == 5, "5 ring terrains (Spirit is earned)")
	_check(decks.characters.size() == 4, "4 characters")
	_check(decks.creatures.size() >= 62, "creature roster incl. wild drop loads (%d)" % decks.creatures.size())
	_check(decks.items_catalog.size() == 156, "item catalog loads (150 drop + 6 tokens, got %d)" % decks.items_catalog.size())
	_check(decks.wild_deck_data.get("cards", []).size() == 20, "wild deck: 20 unique cards")
	var wd_total := 0
	for wc in decks.wild_deck_data.get("cards", []):
		wd_total += int(wc.get("count", 1))
	_check(wd_total == 200, "wild deck: 200 printed cards (got %d)" % wd_total)
	_check(decks.bottleneck_quests.size() == 50, "bottleneck trials load (50)")
	var trial_a := decks.bottleneck_for("stone", Vector2i(2, -1))
	_check(not trial_a.is_empty() and trial_a == decks.bottleneck_for("stone", Vector2i(2, -1)),
		"a guardian site always poses the same trial")

	# --- GameMathEngine (content drop): loot math
	_check(absf(GameMathEngine.get_level_constant(1) - 6.05) < 0.001, "math engine level constant")
	_check(GameMathEngine.roll_loot_with_replacement({"only": 1.0}) == "only", "weighted loot roll")
	var pity: Dictionary = {"want": 10}
	var pity_roll := GameMathEngine.roll_loot_with_pity({"want": 1.0, "other": 99.0}, pity, "want", 10)
	_check(pity_roll == "want", "pity roll guarantees the target at max rolls")

	# --- Expanded Datasets loading
	_check(decks.items.size() >= 50, "expanded items dataset loaded (%d items)" % decks.items.size())
	_check(decks.expanded_creatures.size() >= 10, "expanded creatures dataset loaded (%d creatures)" % decks.expanded_creatures.size())
	_check(decks.expanded_quests.size() >= 10, "expanded trials dataset loaded (%d trials)" % decks.expanded_quests.size())
	_check(decks.expanded_deck_cards.size() >= 10, "expanded deck cards loaded (%d cards)" % decks.expanded_deck_cards.size())

	# --- GameMathEngine Action Value Model (AVM) Tests
	_check(GameMathEngine.ce_of_tier("common") == 1 and GameMathEngine.ce_of_tier("uncommon") == 3
		and GameMathEngine.ce_of_tier("rare") == 9 and GameMathEngine.ce_of_tier("legendary") == 27, "GameMathEngine CE tier ladder 1/3/9/27")
	var sample_item := {"item_id": "tool_01", "rarity": "Uncommon", "properties": {"harvest_multiplier": 2.0, "durability": 100.0}}
	var item_val := GameMathEngine.calculate_item_value(sample_item)
	_check(item_val > 3.0, "GameMathEngine item valuation calculates utility (%f CE)" % item_val)
	# A mid bottleneck trial by the actual rebalanced numbers: 5-common deposit,
	# +3 VP, +3 Light — the AVM should judge it balanced.
	var quest_bal := GameMathEngine.calculate_quest_balance(5.0, 3, 3, false)
	_check(bool(quest_bal["balanced"]), "GameMathEngine judges a mid trial balanced (ROI)")

	# --- GameMathEngine Combat & Asymptotic Mitigation Tests
	_check(absf(GameMathEngine.calculate_asymptotic_mitigation(60.0, 1, 60.0) - 0.5) < 0.001, "asymptotic mitigation at stat=60, L=1, K=60 is 50%")
	_check(absf(GameMathEngine.calculate_dodge_chance(0.0, 1, 60.0, 0.02) - 0.02) < 0.001, "base dodge chance is 2%")
	_check(absf(GameMathEngine.calculate_crit_chance(0.0, 1, 120.0, 0.04) - 0.04) < 0.001, "base crit chance is 4%")
	_check(absf(GameMathEngine.calculate_effective_health(100.0, 60.0, 1, 60.0) - 200.0) < 0.01, "EHP with 50% armor mitigation doubles raw HP (100 -> 200)")
	_check(absf(GameMathEngine.calculate_combat_damage(10.0, 16.0, 0.0, 1) - 11.0) < 0.001, "combat damage calculation (10 weapon + 16/16 AP = 11)")

	# --- GameMathEngine Loot Systems with Pity
	var test_loot_table := {"common_stick": 10.0, "rare_gem": 1.0}
	var pity_counter := {}
	var rolled := GameMathEngine.roll_loot_with_pity(test_loot_table, pity_counter, "rare_gem", 2)
	_check(rolled != "null", "pity roller outputs valid drop")
	var rolled_item_dict := decks.roll_item_loot()
	_check(not rolled_item_dict.is_empty(), "decks.roll_item_loot rolls valid item from dataset")

	# --- GameMathEngine Procedural Enemy Generator
	var enemy := GameMathEngine.generate_balanced_enemy(1, 1.0)
	_check(int(enemy["level"]) == 1 and enemy.has("stats") and float(enemy["stats"]["max_hp"]) > 0.0, "procedural enemy generator compiles level 1 budget")

	# --- CE tier ladder (canon invariant I1)
	_check(decks.ce_of("common") == 1 and decks.ce_of("uncommon") == 3
		and decks.ce_of("rare") == 9 and decks.ce_of("legendary") == 27, "CE ladder 1/3/9/27")

	# --- Duality bands tile the track (I4) + shifts + hypocrisy
	var ok_tiling := true
	for l in range(-10, 11):
		var b := Duality.band_for(l)
		if l <= -8 and b != Duality.Band.MAX_DARK: ok_tiling = false
		if l >= 8 and b != Duality.Band.MAX_LIGHT: ok_tiling = false
	_check(ok_tiling, "duality bands tile −10..+10")
	_check(Duality.band_for(-5) == Duality.Band.DARK and Duality.band_for(0) == Duality.Band.NEUTRAL
		and Duality.band_for(5) == Duality.Band.LIGHT, "band midpoints correct")
	_check(Duality.shift_delta("give_back_light") == 2, "give_back_light +2")
	_check(Duality.shift_delta("dark_quest") == -3, "dark_quest −3")
	_check(Duality.shift_delta("fight_creature") == -1, "fight win leans Dark")
	_check(Duality.hypocrisy_energy_penalty(20, 0) == 4, "hypocrisy: VP20/L0 → −4 energy gain")
	_check(Duality.hypocrisy_energy_penalty(20, -9) == 0, "Deep Dark exempt from hypocrisy")
	_check(Duality.sanctum_open(Duality.Band.MAX_LIGHT) and not Duality.sanctum_open(Duality.Band.LIGHT),
		"Guardian Gate opens only at Radiant")

	# --- Rage
	_check(Rage.delta_for("round_start") == 1, "island rage +1 per round")
	_check(Rage.f_bonus(7) == 2 and Rage.f_bonus(1) == 0, "rage fight modifier")
	_check(Rage.setback_discard(9) == 2, "rage setback discards")

	# --- Fate deck: 12 cards, exactly 2 wilds per cycle, wilds obey the band
	var fate := Fate.new(rng, decks.canon.get("fate", {}))
	var wilds := 0
	for i in 12:
		var d := fate.draw(Duality.Band.MAX_LIGHT, decks.canon.get("fate", {}))
		if bool(d["wild"]):
			wilds += 1
			_check(int(d["value"]) == 5, "wild at Radiant resolves to 5")
		else:
			_check(int(d["value"]) >= 1 and int(d["value"]) <= 6, "fate value in 1..6")
	_check(wilds == 2, "exactly 2 Spirit/Wild cards per cycle (got %d)" % wilds)

	# --- deck draws
	for i in 20:
		var c := decks.draw_card("stone", 1)
		_check(not c.is_empty() and ["uncommon", "rare", "legendary"].has(String(c["tier"])), "T1 card draw #%d" % i)
	var best := decks.draw_card_keep_best("water", 2, 2)
	_check(not best.is_empty(), "T2 draw2keep1")

	# --- board
	var board := Board.new()
	board.generate(decks, rng)
	_check(board.tiles.size() == 127, "board 127 tiles")
	var center: IslandTile = board.get_tile(Vector2i.ZERO)
	_check(center.tier == 3 and center.has_guardian, "sanctum at center")

	# --- crafting v2
	var p := PlayerState.new()
	p.add_common("vines", 2)
	var rope: Dictionary = {}
	for r in decks.recipes:
		if String(r["id"]) == "rope":
			rope = r
	_check(Crafting.can_craft(rope, p), "can craft rope (2 vines)")
	_check(Crafting.craft(rope, p, rng) == "item", "rope crafts")
	_check(p.has_item("rope") and p.commons_count() == 0, "vines consumed")
	_check(Crafting.bench_ok(rope, false, false), "common crafting needs no bench")

	# --- turn engine (autoload present when run in-project)
	var game: Node = get_tree().root.get_node_or_null("Game")
	if game != null:
		var chosen: Array[String] = ["botanist", "blacksmith"]
		game.new_game(2, chosen)
		_check(game.players.size() == 2, "new_game(2)")
		_check(game.players[0].character_id == "botanist" and game.players[0].heart == "wood", "p0 assigned Botanist")
		_check(game.players[1].character_id == "blacksmith" and game.players[1].heart == "stone", "p1 assigned Blacksmith")
		
		# --- quest engine unit test (common quests & expanded dual-path trials)
		var qe := QuestEngine.new([
			{"id": "first_meal", "name": "A Meal Shared", "vp": 2, "difficulty": "easy"},
			{"id": "shoreline", "name": "Learn the Shore", "vp": 2, "difficulty": "easy"}
		])
		var test_p := PlayerState.new()
		test_p.index = 0
		var dummy_tile := IslandTile.new(Vector2i(1, 0), "wood", 1)
		qe.on_tile_explored(test_p, dummy_tile)
		qe.on_tile_explored(test_p, dummy_tile)
		_check(not qe.is_completed(test_p, "shoreline"), "shoreline requires 3 tiles (at 2)")
		qe.on_tile_explored(test_p, dummy_tile)
		_check(qe.is_completed(test_p, "shoreline") and test_p.vp == 2, "shoreline auto-completes at 3 tiles (+2 VP)")
		
		# Dual-path trial test
		var sample_trial := {
			"quest_id": "trial_01",
			"title": "Trial of the Furnace",
			"light_path": {"reward": {"vp": 2, "light": 2, "items": ["harmony_token_t1"]}},
			"dark_path": {"reward": {"vp": 3, "light": -2, "items": ["shatter_shard_t1"]}}
		}
		var p_trial := PlayerState.new()
		p_trial.index = 0
		var light_res := qe.complete_trial_light(p_trial, sample_trial)
		_check(bool(light_res["success"]) and p_trial.vp == 2 and p_trial.has_item("harmony_token_t1"), "complete_trial_light awards VP and items")

		# Redraw vote test
		var vote := qe.start_redraw_vote(0, 2)
		_check(not bool(vote["resolved"]), "vote pending responder")
		vote = qe.submit_vote(1, true, 2)
		_check(bool(vote["resolved"]) and bool(vote["passed"]), "majority vote passes")

		# --- ActionCards system test
		var cart_levels := ActionCards.default_levels_for("cartographer")
		_check(int(cart_levels["explore"]) == 2 and int(cart_levels["craft"]) == 1, "Cartographer starts with Explore Lvl 2")
		_check(not ActionCards.has_free_trading(test_p), "trading is not free at Guardian Lvl 1")
		ActionCards.level_up(test_p, "guardian")
		ActionCards.level_up(test_p, "guardian")
		_check(ActionCards.get_level(test_p, "guardian") == 3 and ActionCards.has_free_trading(test_p), "trading is free at Guardian Lvl 3")

		# --- TradeSystem test
		var p_trade_a := PlayerState.new()
		var p_trade_b := PlayerState.new()
		p_trade_a.index = 0
		p_trade_b.index = 1
		p_trade_a.add_common("flax", 4)
		p_trade_b.add_common("stone", 1)
		var bundle_a := {"commons": {"flax": 4}, "cards": []}
		var bundle_b := {"commons": {"stone": 1}, "cards": []}
		_check(TradeSystem.calculate_bundle_ce(bundle_a) == 4, "4 commons = 4 CE")
		_check(TradeSystem.calculate_bundle_ce(bundle_b) == 1, "1 common = 1 CE")
		var trade_res := TradeSystem.execute_trade(p_trade_a, p_trade_b, bundle_a, bundle_b)
		_check(bool(trade_res["success"]) and bool(trade_res["generous_a"]), "trade executed (generous: 4 CE vs 1 CE => delta >= 3)")
		_check(p_trade_a.has_common("stone", 1) and p_trade_b.has_common("flax", 4), "resources exchanged properly")

		# --- SkillTree test
		var p_skill := PlayerState.new()
		p_skill.index = 0
		p_skill.add_common("sticks", 10)
		var skill_swift := {"id": "swift_stride", "tier": "common", "ce_cost": 3, "energy_cost": 0, "desc": "+1 move"}
		var m0 := p_skill.move
		_check(SkillTree.can_learn(p_skill, skill_swift), "can learn swift_stride with 3 commons")
		SkillTree.learn_skill(p_skill, skill_swift, rng)
		_check(p_skill.skills.has("swift_stride") and p_skill.move == m0 + 1, "swift_stride learned, +1 move speed applied")

		# --- CreatureEngine test (expanded karma & field moves)
		var test_creature := {
			"id": "puddle_frog", "name": "Puddle-Frog", "element": "wood", "tier": 1, "f": 4,
			"field_move": "Irrigate",
			"karma_interactions": {
				"exalted_light": {"action": "gift", "item_reward": "luminous_algae", "light_change": 2, "flavor": "Reverence."},
				"neutral": {"action": "challenge", "cost": {"item_id": "sweet_berry", "qty": 1}, "flavor": "Curious block."}
			},
			"demand": { "type": "common", "ids": ["wild_berries"], "n": 1 },
			"gift": { "op": "gain_common", "element": "wood", "n": 2 },
			"bite": { "op": "lose_common", "n": 1 }
		}
		var p_wood := PlayerState.new()
		p_wood.heart = "wood"
		_check(int(CreatureEngine.effective_band(p_wood, test_creature)) == int(Game.band_of(p_wood)) + 1, "matching heart shifts effective creature band +1")
		var field_msg := CreatureEngine.execute_field_move(p_wood, test_creature, dummy_tile, rng)
		_check(field_msg.contains("Irrigate"), "creature field move executes successfully")

		p_wood.skills.append("iron_skin")
		var bite_msg := CreatureEngine.apply_effect(p_wood, test_creature["bite"], rng, true)
		_check(bite_msg.contains("Iron Skin protects"), "iron_skin shields player from creature bite")

		# --- BuildingEngine test
		var b_tile := IslandTile.new(Vector2i(0, 0), "wood", 1)
		b_tile.buildings.append("wayside_shrine")
		_check(BuildingEngine.has_building(b_tile, "wayside_shrine"), "tile has wayside_shrine")
		_check(BuildingEngine.get_building_stat_budget("workshop") > 0, "get_building_stat_budget calculated via GameMathEngine")
		p_wood.add_common("wood", 2)
		var b_res := BuildingEngine.interact(p_wood, b_tile, "wayside_shrine", rng)
		_check(bool(b_res["success"]), "interact with wayside_shrine succeeds")

		# --- DarkRaiding test
		var p_dark := PlayerState.new()
		p_dark.index = 0
		p_dark.character_id = "outcast"
		p_dark.pos = Vector2i(0, 0)
		var p_target := PlayerState.new()
		p_target.index = 1
		p_target.pos = Vector2i(0, 0)
		p_target.energy = 0  # no energy left to spend on the block counterplay
		p_target.add_common("flax", 2)
		_check(DarkRaiding.can_raid(p_dark, p_target), "outcast can raid target on same hex")
		var raid_res := DarkRaiding.execute_raid(p_dark, p_target, rng)
		_check(bool(raid_res["success"]) and not bool(raid_res["blocked"]), "unblocked raid successfully steals materials")

		# --- Content drop integration: wild deck, items, trials, eclipse
		var wd: WildDeck = game.wild_deck
		var before_left: int = wd.size_left()
		var wcard := wd.draw()
		_check(not wcard.is_empty() and wd.size_left() == before_left - 1, "wild deck draws and depletes")
		_check(String(wd.draw_ward().get("kind", "")) == "ward", "guardian's whispers can find a ward")

		var p_drop := PlayerState.new()
		p_drop.index = 0
		p_drop.items.append("tool_item_01")
		var tool_res: Dictionary = game.use_best_tool(p_drop)
		_check(int(tool_res.get("bonus", 0)) == 1, "common tool adds +1 common on gather")
		game.use_best_tool(p_drop)
		tool_res = game.use_best_tool(p_drop)
		_check(bool(tool_res.get("broke", false)) and not p_drop.has_item("tool_item_01"), "tool breaks after its durability is spent")

		p_drop.items.append("consumable_item_01")
		var e_before: int = p_drop.energy
		var use_res: Dictionary = game.use_consumable(p_drop, "consumable_item_01")
		_check(int(use_res.get("energy", 0)) == 1 and p_drop.energy == e_before + 1, "consumable restores energy in the care phase")

		p_drop.items.append("gear_item_01")
		p_drop.add_common("sticks", 1)
		var gear_bite := CreatureEngine.apply_effect(p_drop, {"op": "lose_common", "n": 1}, rng, true)
		_check(p_drop.has_common("sticks", 1) and gear_bite.contains("gear"), "catalog gear armor absorbs a small bite")

		p_drop.items.append("relic_item_01")
		var gvp_before: int = p_drop.guardian_vp
		_check(game.offer_relic(p_drop, "relic_item_01") == 2 and p_drop.guardian_vp == gvp_before + 2, "relic offering grants guardian VP")

		var trial: Dictionary = game.decks.bottleneck_for("stone", Vector2i(3, 0))
		p_drop.add_common("stone", 5)
		var t_vp: int = p_drop.vp
		_check(game.resolve_bottleneck(p_drop, trial, false), "bottleneck trial: harmonious path resolves")
		_check(p_drop.vp > t_vp and p_drop.commons_count() == 1, "trial pays scaled VP and consumes the 5-common deposit")
		_check(not game.resolve_bottleneck(p_drop, trial, true), "a faced trial cannot be faced again")

		# Balance invariants (rebalance pass): rewards stay under canon faucet
		# ranges and the per-player trial cap holds.
		var trial_vp_ok := true
		for bq in game.decks.bottleneck_quests:
			if int(bq["light"]["vp"]) > 4 or int(bq["dark"]["vp"]) > 6:
				trial_vp_ok = false
		_check(trial_vp_ok, "trial VP rescaled to canon (light <=4, dark <=6)")
		var p_capped := PlayerState.new()
		p_capped.trials_done = ["quest_01", "quest_02"]
		p_capped.add_common("stone", 9)
		var other_trial: Dictionary = game.decks.bottleneck_for("wood", Vector2i(1, 1))
		_check(not game.resolve_bottleneck(p_capped, other_trial, false), "island tests each wanderer at most twice (cap)")
		var relic_vp_ok := true
		for idef2 in game.decks.items_catalog.values():
			if String(idef2.get("type", "")) == "relic" and int(idef2.get("offer_vp", 0)) > 6:
				relic_vp_ok = false
		_check(relic_vp_ok, "no relic offering exceeds 6 VP")

		game.dark_aggression_rounds = 1
		_check(CreatureEngine.effective_band(p_drop, {}) == Duality.Band.MAX_DARK, "eclipse forces Deep Dark encounters")
		game.dark_aggression_rounds = 0

		var wild_c: Dictionary = {}
		for c2 in game.decks.creatures:
			if String(c2.get("id", "")) == "puddle_frog":
				wild_c = c2
		_check(not wild_c.is_empty() and wild_c.has("reward") and wild_c.has("take"), "wild creature converted with band effects")
		var p_kind := PlayerState.new()
		p_kind.light = 4  # Kind band
		var reward_desc := CreatureEngine.apply_effect(p_kind, wild_c.get("reward", {}), rng)
		_check(p_kind.has_common("luminous_algae", 1) and reward_desc != "", "wild reward grants its mapped common")

		# --- Full asset integration: named items, relic gifts, field moves, wild finds
		var placeholder_names := 0
		for idef in game.decks.items_catalog.values():
			if String(idef.get("name", "")).contains("Item "):
				placeholder_names += 1
		_check(placeholder_names == 0, "all 156 catalog items carry real tiered names")

		var t3_gift_ok := true
		for c3 in game.decks.creatures:
			if String(c3.get("tier", "")) == "rare" and c3.has("flavor"):
				var g: Dictionary = c3.get("gift", {})
				if String(g.get("op", "")) != "gain_item" or game.decks.item_def(String(g.get("id", ""))).is_empty():
					t3_gift_ok = false
		_check(t3_gift_ok, "every rare wild creature gifts a valid catalog relic")

		var p_gift := PlayerState.new()
		CreatureEngine.apply_effect(p_gift, {"op": "gain_item", "id": "relic_item_05"}, rng)
		_check(p_gift.has_item("relic_item_05"), "gain_item op adds the catalog item")

		var fm_tile := IslandTile.new(Vector2i(2, 2), "wood", 1)
		fm_tile.exhausted = true
		var fm_txt := CreatureEngine.apply_field_move(p_gift, wild_c, fm_tile)
		_check(not fm_tile.exhausted and fm_txt.contains("Irrigate"), "field move restores an exhausted tile")
		fm_txt = CreatureEngine.apply_field_move(p_gift, wild_c, fm_tile)
		_check(p_gift.commons_count() >= 1 and fm_txt != "", "field move on living land yields a common")

		var p_find := PlayerState.new()
		var found_it: Dictionary = game.find_catalog_item(p_find, ["tool"])
		_check(not found_it.is_empty() and p_find.items.size() == 1
			and String(game.decks.item_def(String(p_find.items[0])).get("type", "")) == "tool",
			"wild item find adds a catalog tool to the pack")
		var relic_chest_ok := false
		for i in 40:
			var chest_it: Dictionary = game.open_chest(p_find, true)
			if String(chest_it.get("type", "")) == "relic":
				relic_chest_ok = true
				break
		_check(relic_chest_ok, "spirit-ground chests can hold relics")

		# --- Viability Gate & Tiebreaker test
		var p_win_a := PlayerState.new()
		p_win_a.index = 0
		p_win_a.vp = 20
		p_win_a.light = 9
		_check(game.get_victory_way(p_win_a) == "", "unviable without offerings or outcast")
		p_win_a.offerings_made = 1
		_check(game.get_victory_way(p_win_a) == "enlightened", "viable with 1 offering: qualifies for Enlightened")

		var p_win_b := PlayerState.new()
		p_win_b.index = 1
		p_win_b.vp = 20
		p_win_b.light = 8
		p_win_b.offerings_made = 1

		# Tiebreaker 1 test (Light priority)
		var duelists: Array[PlayerState] = [p_win_a, p_win_b]
		game.players = duelists
		game.resolve_round_end_victory()
		_check(game.winner_index == 0 and game.winner_way == "enlightened", "tiebreaker 1: higher light (+9 vs +8) wins")

		# Tiebreaker 3 test (Shared Victory when Light & Guardian VP equal)
		p_win_b.light = 9
		game.resolve_round_end_victory()
		_check(game.winner_index == -2 and game.winner_way == "shared", "tiebreaker 3: equal light and guardian VP resolves in shared victory")

		# The tiebreaker checks left a finished game behind — restart fresh
		# so the turn-engine checks below run from a clean round 1.
		game.new_game(2, chosen)
		var cur: PlayerState = game.current_player()
		cur.add_common("grain", 3)
		var g0: int = cur.energy
		game.care_eat(cur, false)
		_check(cur.energy == g0 + 1, "raw food +1 energy")
		var other: PlayerState = game.players[1]
		var l0: int = cur.light
		game.care_gift(cur, other, "grain")
		game.care_gift(cur, other, "grain")
		_check(cur.light == l0 + 1, "care gift Light capped at +1/phase (S4)")
		cur.add_common("stone", 3)
		var vp0: int = cur.vp
		game.give_back_light(cur)
		_check(cur.vp == vp0 + 1 and cur.light == l0 + 3, "give back: +1 VP, +2 Light")
		var creature := {"f": 3, "element": "wood", "bite": {"op": "energy", "n": -1}}
		var res: Dictionary = game.fight(cur, creature, 0)
		_check(res.has("won") and int(res["f"]) == 2, "fight resolves (Botanist heart affinity F3→F2)")
		game.end_turn()
		_check(game.current == 1, "turn passes left")
		game.end_turn()
		_check(game.round_num == 2 and game.rage >= 1, "round increments; island rage ticks")
		_check(game.has_save() and game.load_game(), "save v2 round-trips")
	else:
		print("  (Game autoload absent; engine checks skipped)")

	if failures == 0:
		print("== ALL CHECKS PASSED ==")
	else:
		print("== %d CHECK(S) FAILED ==" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("  ok   " + label)
	else:
		failures += 1
		printerr("  FAIL " + label)
