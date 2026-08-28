extends SceneTree
## Headless smoke test v2 — canon systems, no UI.
## Run:  godot --headless --path . -s res://tests/smoke.gd

var failures := 0


func _initialize() -> void:
	print("== Into the Wild smoke test v2 (canon) ==")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# --- canon + data load
	var decks := Decks.new(rng)
	for name in Decks.CANON_FILES:
		_check(not (decks.canon.get(name, {}) as Dictionary).is_empty(), "canon/%s.json loads" % name)
	_check(decks.elements.size() == 6, "6 elements")
	_check(decks.ring_element_ids().size() == 5, "5 ring terrains (Spirit is earned)")
	_check(decks.characters.size() == 4, "4 characters")
	_check(decks.creatures.size() >= 12, "creature roster loads (%d)" % decks.creatures.size())

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
	var game: Node = root.get_node_or_null("Game")
	if game != null:
		game.new_game(2, ["botanist", "blacksmith"])
		_check(game.players.size() == 2, "new_game(2)")
		_check(game.players[0].character_id == "botanist" and game.players[0].heart == "wood", "p0 assigned Botanist")
		_check(game.players[1].character_id == "blacksmith" and game.players[1].heart == "stone", "p1 assigned Blacksmith")
		
		# --- quest engine unit test
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

		# --- CreatureEngine test
		var test_creature := {
			"id": "bramblehog", "name": "Bramblehog", "element": "wood", "tier": "common", "f": 4,
			"demand": { "type": "common", "ids": ["wild_berries"], "n": 1 },
			"gift": { "op": "gain_common", "element": "wood", "n": 2 },
			"bite": { "op": "lose_common", "n": 1 }
		}
		var p_wood := PlayerState.new()
		p_wood.heart = "wood"
		_check(int(CreatureEngine.effective_band(p_wood, test_creature)) == int(Game.band_of(p_wood)) + 1, "matching heart shifts effective creature band +1")
		p_wood.skills.append("iron_skin")
		var bite_msg := CreatureEngine.apply_effect(p_wood, test_creature["bite"], rng, true)
		_check(bite_msg.contains("Iron Skin protects"), "iron_skin shields player from creature bite")

		# --- BuildingEngine test
		var b_tile := IslandTile.new(Vector2i(0, 0), "wood", 1)
		b_tile.buildings.append("wayside_shrine")
		_check(BuildingEngine.has_building(b_tile, "wayside_shrine"), "tile has wayside_shrine")
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
		p_target.add_common("flax", 2)
		_check(DarkRaiding.can_raid(p_dark, p_target), "outcast can raid target on same hex")
		var raid_res := DarkRaiding.execute_raid(p_dark, p_target, rng)
		_check(bool(raid_res["success"]) and not bool(raid_res["blocked"]), "unblocked raid successfully steals materials")

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
		game.players = [p_win_a, p_win_b]
		game.resolve_round_end_victory()
		_check(game.winner_index == 0 and game.winner_way == "enlightened", "tiebreaker 1: higher light (+9 vs +8) wins")

		# Tiebreaker 3 test (Shared Victory when Light & Guardian VP equal)
		p_win_b.light = 9
		game.resolve_round_end_victory()
		_check(game.winner_index == -2 and game.winner_way == "shared", "tiebreaker 3: equal light and guardian VP resolves in shared victory")

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
		_check(res.has("won") and int(res["f"]) >= 3, "fight resolves with modifiers")
		game.end_turn()
		_check(game.current == 1, "turn passes left")
		game.end_turn()
		_check(game.round_num == 2 and game.rage >= 1, "round increments; island rage ticks")
		_check(game.has_save() and game.load_game(), "save v2 round-trips")
	else:
		print("  (Game autoload absent in -s mode; engine checks need frames)")

	if failures == 0:
		print("== ALL CHECKS PASSED ==")
	else:
		print("== %d CHECK(S) FAILED ==" % failures)
	quit(1 if failures > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("  ok   " + label)
	else:
		failures += 1
		printerr("  FAIL " + label)
