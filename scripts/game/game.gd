extends Node2D
## The play scene, v2 — the canon turn: CARE phase (free bonuses) then one of
## six MAIN actions (canon/actions.json). Rules live in Game + systems/*;
## this scene is the table.

const PLAYER_COLORS: Array[Color] = [
	Color("e4b74a"), Color("d16a5a"), Color("5aa7d1"), Color("9a6ad1"),
]
const FACEDOWN_COLORS: Dictionary = {1: Color("39404a"), 2: Color("2b3038"), 3: Color("241f30")}
const PAWN_OFFSETS: Array[Vector2] = [
	Vector2(-14, -10), Vector2(14, -10), Vector2(-14, 12), Vector2(14, 12),
]

var hex_size := 64.0

# --- world
var board_layer: Node2D
var pawn_layer: Node2D
var camera: Camera2D
var tile_fills: Dictionary = {}
var tile_marks: Dictionary = {}
var pawns: Array = []

# --- turn view-state
var mode := "idle"            ## idle | explore
var moves_left := 0
var flipped_this_move := false
var turn_over := false
var action_taken := ""

# --- HUD
var hud: CanvasLayer
var lbl_turn: Label
var lbl_stats: Label
var lbl_inv: Label
var lbl_quests: Label
var lbl_toast: Label
var care_bar: HBoxContainer
var action_bar: HBoxContainer
var buttons: Dictionary = {}
var modal_root: CenterContainer
var modal_title: Label
var modal_body: Label
var modal_buttons: VBoxContainer
var winner_overlay: Control
var winner_label: Label

var _pressing := false
var _drag_moved := false
var _toast_token := 0


func _ready() -> void:
	if not Game.started and not Game.load_game():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	hex_size = 64.0
	_build_world()
	_build_hud()
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.message.connect(_toast)
	EventBus.game_won.connect(_on_game_won)
	EventBus.light_changed.connect(func(_i: int, _v: int) -> void: _refresh_hud())
	EventBus.vp_changed.connect(func(_i: int, _v: int) -> void: _refresh_hud())
	EventBus.inventory_changed.connect(func(_i: int) -> void: _refresh_hud())
	EventBus.rage_changed.connect(func(_v: int) -> void: _refresh_hud())
	EventBus.quest_completed.connect(func(p_idx: int, q: Dictionary) -> void:
		if p_idx == Game.current:
			_toast("★ Quest Complete: %s (+%d VP)!" % [String(q.get("name", "")), int(q.get("vp", 0))])
		_refresh_quests()
		_refresh_hud()
	)
	EventBus.quests_redrawn.connect(func(_new_quests: Array) -> void:
		_refresh_quests()
		_refresh_hud()
	)
	Game.begin_turn_for_current()
	_begin_turn()
	if Game.winner_index >= 0:
		_on_game_won(Game.winner_index, Game.winner_way)


# ================================================================= WORLD

func _build_world() -> void:
	var world_bg := ColorRect.new()
	world_bg.color = Color("101b22")
	world_bg.size = Vector2(8000, 8000)
	world_bg.position = Vector2(-4000, -4000)
	world_bg.z_index = -10
	add_child(world_bg)
	board_layer = Node2D.new()
	add_child(board_layer)
	pawn_layer = Node2D.new()
	pawn_layer.z_index = 5
	add_child(pawn_layer)
	for axial in Game.board.tiles.keys():
		_spawn_tile_nodes(axial)
	for p in Game.players:
		var pawn := Node2D.new()
		var dot := Polygon2D.new()
		dot.polygon = _circle_points(hex_size * 0.22, 12)
		dot.color = PLAYER_COLORS[p.index % PLAYER_COLORS.size()]
		pawn.add_child(dot)
		var rim := Line2D.new()
		rim.points = _circle_points(hex_size * 0.22, 12)
		rim.closed = true
		rim.width = 3.0
		rim.default_color = Color("10151a")
		pawn.add_child(rim)
		pawn_layer.add_child(pawn)
		pawns.append(pawn)
		_place_pawn(p)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.8, 0.8)
	add_child(camera)
	camera.make_current()


func _spawn_tile_nodes(axial: Vector2i) -> void:
	var center := Hex.to_pixel(axial, hex_size)
	var outline := Polygon2D.new()
	outline.polygon = Hex.corners(center, hex_size * 0.98)
	outline.color = Color("0c1116")
	board_layer.add_child(outline)
	var fill := Polygon2D.new()
	fill.polygon = Hex.corners(center, hex_size * 0.90)
	board_layer.add_child(fill)
	tile_fills[axial] = fill
	var mark := Label.new()
	mark.add_theme_font_size_override("font_size", 26)
	mark.add_theme_color_override("font_color", Color("f2d06b"))
	mark.position = center - Vector2(14, 20)
	mark.text = ""
	board_layer.add_child(mark)
	tile_marks[axial] = mark
	_refresh_tile(axial)


func _refresh_tile(axial: Vector2i) -> void:
	var tile: IslandTile = Game.board.get_tile(axial)
	var fill: Polygon2D = tile_fills[axial]
	var mark: Label = tile_marks[axial]
	if tile.explored:
		var e: Dictionary = Game.decks.elements_by_id.get(tile.element_id, {})
		var key := "t2_color" if tile.tier >= 2 else "color"
		fill.color = Color(String(e.get(key, "#666666")))
		var glyphs := ""
		if tile.has_guardian:
			glyphs += "✦"
		if tile.has_building("homebase"):
			glyphs += "⌂"
		if tile.has_building("workshop"):
			glyphs += "⚒"
		if tile.exhausted:
			glyphs += "×"
		mark.text = glyphs
	else:
		fill.color = FACEDOWN_COLORS.get(tile.tier, Color("333333"))
		mark.text = ""


func _place_pawn(p: PlayerState) -> void:
	var node: Node2D = pawns[p.index]
	node.position = Hex.to_pixel(p.pos, hex_size) + PAWN_OFFSETS[p.index % PAWN_OFFSETS.size()]


func _circle_points(radius: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


# ================================================================= HUD

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var top_left := _panel()
	top_left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 14)
	var tl := VBoxContainer.new()
	top_left.add_child(tl)
	lbl_turn = _label(24, "b8d8c4")
	tl.add_child(lbl_turn)
	lbl_stats = _label(19, "e8e2cf")
	tl.add_child(lbl_stats)

	var top_right := _panel()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 14)
	lbl_quests = _label(15, "cfc7ae")
	top_right.add_child(lbl_quests)

	var bottom_right := _panel()
	bottom_right.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 14)
	lbl_inv = _label(16, "d8e6da")
	bottom_right.add_child(lbl_inv)

	# Care bar and Action bar share the bottom center; visibility toggles by phase.
	var bar_panel := _panel()
	bar_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
	var bars := VBoxContainer.new()
	bar_panel.add_child(bars)
	care_bar = HBoxContainer.new()
	care_bar.add_theme_constant_override("separation", 8)
	bars.add_child(care_bar)
	for def in [["eat", "Eat"], ["sleep", "Sleep (+2⚡, skip action)"], ["meditate", "Meditate (1⚡)"], ["care_gift", "Gift"], ["begin_action", "Begin Action ▸"]]:
		_add_button(care_bar, String(def[0]), String(def[1]), _on_care)
	action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	bars.add_child(action_bar)
	for def in [["explore", "Explore/Gather"], ["craft", "Craft"], ["magic", "Magic"], ["learn", "Learn"], ["quest", "Quest"], ["give_back", "Give Back"], ["end", "End Turn"]]:
		_add_button(action_bar, String(def[0]), String(def[1]), _on_action)

	lbl_toast = _label(19, "f2d06b")
	lbl_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 14)
	hud.add_child(lbl_toast)

	modal_root = CenterContainer.new()
	modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.visible = false
	hud.add_child(modal_root)
	var mp := PanelContainer.new()
	modal_root.add_child(mp)
	var mbox := VBoxContainer.new()
	mbox.custom_minimum_size = Vector2(600, 0)
	mbox.add_theme_constant_override("separation", 10)
	mp.add_child(mbox)
	modal_title = _label(26, "f2d06b")
	mbox.add_child(modal_title)
	modal_body = _label(19, "e8e2cf")
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.custom_minimum_size = Vector2(600, 0)
	mbox.add_child(modal_body)
	modal_buttons = VBoxContainer.new()
	modal_buttons.add_theme_constant_override("separation", 6)
	mbox.add_child(modal_buttons)

	winner_overlay = ColorRect.new()
	(winner_overlay as ColorRect).color = Color(0.04, 0.07, 0.05, 0.93)
	winner_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	winner_overlay.visible = false
	hud.add_child(winner_overlay)
	var wc := CenterContainer.new()
	wc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	winner_overlay.add_child(wc)
	var wbox := VBoxContainer.new()
	wbox.add_theme_constant_override("separation", 18)
	wc.add_child(wbox)
	winner_label = _label(40, "bfe8cf")
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wbox.add_child(winner_label)
	var back := Button.new()
	back.text = "Return to Shore"
	back.custom_minimum_size = Vector2(320, 70)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_back_to_menu)
	wbox.add_child(back)

	_refresh_quests()


func _add_button(bar: HBoxContainer, id: String, text: String, handler: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 58)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(handler.bind(id))
	bar.add_child(b)
	buttons[id] = b


func _back_to_menu() -> void:
	Game.started = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	hud.add_child(p)
	return p


func _label(size: int, color_hex: String) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(color_hex))
	return l


func _toast(text: String) -> void:
	lbl_toast.text = text
	_toast_token += 1
	var token := _toast_token
	get_tree().create_timer(4.5).timeout.connect(func() -> void:
		if token == _toast_token:
			lbl_toast.text = "")


func _refresh_quests() -> void:
	if Game.players.is_empty():
		return
	var p := Game.current_player()
	var lines: Array = ["Common Quests (open to all):"]
	for q in Game.common_quests:
		var qid := String(q.get("id", ""))
		var qname := String(q.get("name", ""))
		var vp := int(q.get("vp", 0))
		var diff := String(q.get("difficulty", "?")).capitalize()
		if p.completed_quests.has(qid):
			lines.append("• [%s] %s (✓ +%d VP)" % [diff, qname, vp])
		else:
			var target: int = int(QuestEngine.COMMON_QUEST_TARGETS.get(qid, 1))
			var cur: int = int(p.quest_progress.get(qid, 0))
			if target > 1:
				lines.append("• [%s] %s [%d/%d] (%d VP)" % [diff, qname, mini(cur, target), target, vp])
			else:
				lines.append("• [%s] %s (%d VP)" % [diff, qname, vp])
	lines.append("")
	lines.append("Ways to win:  Capable 16VP & Light≥3")
	lines.append("Enlightened 10VP & Light≥8 · Dark 18VP & Light≤−8")
	lbl_quests.text = "\n".join(lines)


func _refresh_hud() -> void:
	if Game.players.is_empty():
		return
	var p := Game.current_player()
	var band := Game.band_of(p)
	lbl_turn.text = "Round %d — %s   [%s phase]" % [Game.round_num, p.display_name, Game.phase.capitalize()]
	var move_txt := "  ·  Moves %d" % moves_left if mode == "explore" else ""
	var hyp := Duality.hypocrisy_energy_penalty(p.vp, p.light)
	var hyp_txt := "  ·  ⚠hypocrisy −%d⚡gain" % hyp if hyp > 0 else ""
	lbl_stats.text = "⚡%d/5 · Light %d (%s) · VP %d/20 · Island Rage %d/10%s%s" % [
		p.energy, p.light, Duality.band_name(band), p.vp, Game.rage, move_txt, hyp_txt]
	var lines: Array = []
	lines.append("Pouch (%d commons):" % p.commons_count())
	for id in p.commons.keys():
		lines.append("  %s ×%d" % [Game.decks.display_name_of(String(id)), int(p.commons[id])])
	lines.append("Cards (%d/%d):" % [p.cards.size(), p.hand_limit])
	for c in p.cards:
		lines.append("  [%s] %s" % [String(c.get("tier", "?")).left(1).to_upper(), Game.decks.display_name_of(String(c.get("id", "")))])
	lines.append("Items (%d/%d):" % [p.items.size(), p.pack_size])
	for it in p.items:
		lines.append("  %s" % Game.decks.display_name_of(String(it)))
	lbl_inv.text = "\n".join(lines)
	_refresh_bars(p)


func _refresh_bars(p: PlayerState) -> void:
	var in_care := Game.phase == "care"
	care_bar.visible = in_care
	action_bar.visible = not in_care
	if in_care:
		(buttons["meditate"] as Button).disabled = p.meditated or p.energy < 1
		(buttons["care_gift"] as Button).disabled = Game.players.size() < 2 or p.commons_count() == 0
	else:
		var done := turn_over
		for id in ["explore", "craft", "magic", "learn", "quest", "give_back"]:
			(buttons[id] as Button).disabled = done
		if not done:
			(buttons["learn"] as Button).disabled = not p.meditated
			(buttons["magic"] as Button).disabled = p.energy < 1
			(buttons["give_back"] as Button).disabled = p.commons_count() < 3
			(buttons["quest"] as Button).disabled = not _quest_available(p)
			# WEAKNESS — Cartographer "Restless": no repeating last turn's action.
			if p.character_id == "cartographer" and p.last_action != "":
				(buttons[p.last_action] as Button).disabled = true
		(buttons["end"] as Button).disabled = false


func _quest_available(p: PlayerState) -> bool:
	var tile: IslandTile = Game.board.get_tile(p.pos)
	if tile == null or not tile.has_guardian or not tile.explored:
		return false
	return p.has_item("offering_bundle") or Duality.corrupt_gate_open(Game.band_of(p))


# ================================================================= TURN FLOW

func _on_turn_started(_i: int) -> void:
	_begin_turn()


func _begin_turn() -> void:
	mode = "idle"
	moves_left = 0
	flipped_this_move = false
	turn_over = false
	action_taken = ""
	var p := Game.current_player()
	camera.position = Hex.to_pixel(p.pos, hex_size)
	_refresh_hud()
	_toast("%s — Care phase: eat, sleep, meditate or gift. Then act." % p.display_name)


func _finish_main_action() -> void:
	turn_over = true
	mode = "idle"
	var p := Game.current_player()
	if action_taken != "":
		p.last_action = action_taken
	_refresh_hud()


# ================================================================= CARE PHASE

func _on_care(id: String) -> void:
	if modal_root.visible or winner_overlay.visible:
		return
	var p := Game.current_player()
	match id:
		"eat":
			_open_eat(p)
		"sleep":
			var gained := Game.care_sleep(p)
			_toast("You sleep. +%d⚡ — the Action phase passes you by." % gained)
			Game.end_care_phase()
			turn_over = true
			_refresh_hud()
		"meditate":
			if Game.care_meditate(p):
				_toast("You sit with the island. Learning is open to you this turn.")
			_refresh_hud()
		"care_gift":
			_open_gift(p)
		"begin_action":
			Game.end_care_phase()
			_toast("Choose one action: Explore/Gather, Craft, Magic, Learn, Quest, or Give Back.")
			_refresh_hud()


func _open_eat(p: PlayerState) -> void:
	var entries: Array = []
	if p.has_item("cooked_meal"):
		entries.append(["Cooked Meal (+3⚡)", _eat_pick.bind(p, "cooked_meal", true)])
	var foods := ["wild_berries", "grain", "fish", "mushroom", "fresh_water"]
	for f in foods:
		if p.has_common(String(f)):
			entries.append(["%s (+1⚡)" % Game.decks.display_name_of(String(f)), _eat_pick.bind(p, String(f), false)])
	if entries.is_empty():
		_toast("Nothing edible. Gather food commons or cook a meal.")
		return
	entries.append(["Never mind", _close_modal])
	_show_modal("Eat / Drink", "Care phase: restore Energy (cap 5). Hypocrisy reduces gains.", entries)


func _eat_pick(p: PlayerState, id: String, cooked: bool) -> void:
	_close_modal()
	if cooked:
		p.remove_item("cooked_meal")
	else:
		p.spend_common(id, 1)
	var gained := Game.care_eat(p, cooked)
	_toast("+%d⚡" % gained if gained > 0 else "It restores nothing — your success sits heavy (hypocrisy).")
	_refresh_hud()


func _open_gift(p: PlayerState) -> void:
	var entries: Array = []
	for other in Game.players:
		if other.index == p.index:
			continue
		var target: PlayerState = other
		entries.append([target.display_name, _gift_target.bind(p, target)])
	entries.append(["Never mind", _close_modal])
	_show_modal("Gift (Care phase)", "First gift each Care phase: +1 Light (the island notices).", entries)


func _gift_target(p: PlayerState, target: PlayerState) -> void:
	_close_modal()
	var entries: Array = []
	for id in p.commons.keys():
		var cid := String(id)
		entries.append(["%s ×%d" % [Game.decks.display_name_of(cid), int(p.commons[id])], _gift_item.bind(p, target, cid)])
	entries.append(["Never mind", _close_modal])
	_show_modal("Give what?", "Choose a common from your pouch:", entries)


func _gift_item(p: PlayerState, target: PlayerState, id: String) -> void:
	_close_modal()
	if Game.care_gift(p, target, id):
		_toast("%s receives %s." % [target.display_name, Game.decks.display_name_of(id)])
	_refresh_hud()


# ================================================================= MAIN ACTIONS

func _on_action(id: String) -> void:
	if modal_root.visible or winner_overlay.visible:
		return
	var p := Game.current_player()
	if id == "end":
		Game.end_turn()
		return
	if turn_over:
		_toast("Your action is done — End Turn.")
		return
	match id:
		"explore":
			action_taken = "explore"
			mode = "explore"
			flipped_this_move = false
			moves_left = maxi(0, p.move - p.slow_penalty)
			p.slow_penalty = 0
			_toast("Move (tap adjacent tiles), then Finish to gather — or flip the unknown. ⚡: tap your own tile to Push +1 move.")
			_refresh_hud()
		"craft":
			_open_craft(p)
		"magic":
			_cast_signature(p)
		"learn":
			_open_learn(p)
		"quest":
			_do_quest(p)
		"give_back":
			action_taken = "give_back"
			if Game.give_back_light(p):
				_toast("You give back. +2 Light, −1 Island Rage, +1 VP.")
				_finish_main_action()


# ----------------------------------------------------------------- explore

func _try_step(axial: Vector2i) -> void:
	var p := Game.current_player()
	if axial == p.pos:
		# Push: spend 1 energy for +1 move (canon energy spend).
		if p.energy >= 1:
			Game.add_energy(p, -1)
			moves_left += 1
			_toast("Push! +1 move (⚡%d left)." % p.energy)
			_refresh_hud()
		return
	var tile: IslandTile = Game.board.get_tile(axial)
	if tile == null or Hex.distance(p.pos, axial) != 1 or moves_left <= 0:
		return
	if tile.tier == 3 and not Duality.sanctum_open(Game.band_of(p)):
		_toast("The Guardian Gate stays closed — only the Radiant may enter.")
		return
	var cost := _step_cost(p, tile)
	if cost > moves_left:
		_toast("Not enough movement (%s costs %d)." % [_terrain_name(tile), cost])
		return
	p.pos = axial
	moves_left -= cost
	_place_pawn(p)
	EventBus.player_moved.emit(p.index, axial)
	if not tile.explored:
		_reveal(tile, p)
	elif moves_left <= 0:
		_gather(p, tile)
	else:
		_refresh_hud()


func _step_cost(p: PlayerState, tile: IslandTile) -> int:
	if tile.tier == 1:
		return 1
	var cost := 2
	if p.has_item("trail_cloak"):
		cost = 1
	# PERK — Cartographer "Pathfinding": explored T2 costs 1.
	if p.character_id == "cartographer" and tile.explored:
		cost = 1
	return cost


func _terrain_name(tile: IslandTile) -> String:
	var e: Dictionary = Game.decks.elements_by_id.get(tile.element_id, {})
	return String(e.get("t2_name" if tile.tier >= 2 else "name", tile.element_id))


## Flipping a face-down tile ends movement: +1 Event card +1 Resource card (canon).
func _reveal(tile: IslandTile, p: PlayerState) -> void:
	flipped_this_move = true
	tile.explored = true
	_refresh_tile(tile.axial)
	EventBus.tile_explored.emit(tile.axial)
	if Game.quest_engine != null:
		Game.quest_engine.on_tile_explored(p, tile)
	_toast("You step into %s." % _terrain_name(tile))
	var card := Game.decks.draw_card(tile.element_id, tile.tier)
	if not card.is_empty():
		if p.add_card(card):
			if Game.quest_engine != null:
				Game.quest_engine.on_gather_card(p, tile.tier, String(card.get("tier", "")))
			_toast("Found: [%s] %s." % [String(card["tier"]), Game.decks.display_name_of(String(card["id"]))])
		else:
			_toast("Hand full — the find slips away.")
	if Game.rng.randf() < 0.5:
		_resolve_creature(Game.decks.creature_for(tile.element_id, tile.tier), p, tile)
	else:
		_resolve_event(Game.decks.random_event(), p, tile)
	_finish_main_action()


## Gather at the end tile (no flip): commons + ring-deck draw (canon rates).
func _gather(p: PlayerState, tile: IslandTile) -> void:
	if tile.exhausted:
		_toast("This land is stripped bare. It gives nothing now.")
		_finish_main_action()
		return
	if bool(Game.decks.elements_by_id.get(tile.element_id, {}).get("earned_not_gathered", false)):
		_toast("Spirit is earned, not gathered.")
		_finish_main_action()
		return
	_show_modal("Gather — %s" % _terrain_name(tile),
		"Gently: 2 commons + a deck draw.\nStrip the land: DOUBLE, but the tile dies. −1 Light, +1 Island Rage.", [
		["Gather gently", _gather_do.bind(p, tile, false)],
		["Strip the land", _gather_do.bind(p, tile, true)],
	])


func _gather_do(p: PlayerState, tile: IslandTile, exploit: bool) -> void:
	_close_modal()
	var mult := 2 if exploit else 1
	var n_commons := 2 * mult
	# PERK/WEAKNESS hooks
	if p.character_id == "botanist" and (tile.element_id == "wood" or tile.element_id == "grain"):
		n_commons += 1
	if p.character_id == "botanist" and tile.element_id == "stone":
		n_commons = maxi(1, n_commons - 1)
	if p.has_item("stone_axe") and (tile.element_id == "wood" or tile.element_id == "stone"):
		n_commons += 1
	if p.skills.has("scavengers_eye"):
		n_commons += 1
	var got: Dictionary = {}
	for i in n_commons:
		var c := Game.decks.random_common(tile.element_id)
		if c != "":
			p.add_common(c, 1)
			got[c] = int(got.get(c, 0)) + 1
	var draws := (2 if tile.tier >= 2 else 1) * mult
	var card := Game.decks.draw_card_keep_best(tile.element_id, tile.tier, draws)
	var card_txt := ""
	if not card.is_empty() and p.add_card(card):
		if Game.quest_engine != null:
			Game.quest_engine.on_gather_card(p, tile.tier, String(card.get("tier", "")))
		card_txt = " + [%s] %s" % [String(card["tier"]), Game.decks.display_name_of(String(card["id"]))]
	if exploit:
		tile.exhausted = true
		_refresh_tile(tile.axial)
		Game.shift_light(p, "exploit_tile")
		Game.add_rage(Rage.delta_for("exploit_tile"))
		_toast("The land cracks. Yield doubled%s. −1 Light, +1 Rage." % card_txt)
	else:
		_toast("Gathered %d commons%s." % [n_commons, card_txt])
	_finish_main_action()


# ----------------------------------------------------------------- craft

func _open_craft(p: PlayerState) -> void:
	var tile: IslandTile = Game.board.get_tile(p.pos)
	var bench := tile.has_building("homebase")
	var workshop := tile.has_building("workshop")
	var entries: Array = []
	for r in Game.decks.recipes:
		var recipe: Dictionary = r
		if not Crafting.bench_ok(recipe, bench, workshop):
			continue
		if not Crafting.can_craft(recipe, p):
			continue
		var label := "%s (%s) — %s" % [String(recipe["name"]), String(recipe["tier"]), Crafting.cost_text(recipe, Game.decks)]
		entries.append([label, _craft_pick.bind(recipe, p, tile)])
	if entries.is_empty():
		_toast("Nothing craftable here. Uncommon+ needs a Homebase bench on your tile.")
		return
	entries.append(["Never mind", _close_modal])
	_show_modal("Craft", "Materials decide quality (canon budgets: 2-3 / 6 / 18 / 54 CE).", entries)


func _craft_pick(recipe: Dictionary, p: PlayerState, tile: IslandTile) -> void:
	_close_modal()
	action_taken = "craft"
	var kind := Crafting.craft(recipe, p, Game.rng)
	if kind == "":
		_toast("Crafting failed (pack full or materials short).")
		return
	if Game.quest_engine != null:
		Game.quest_engine.on_item_crafted(p, String(recipe["id"]))
	if kind == "building":
		tile.buildings.append(String(recipe["id"]))
		_refresh_tile(tile.axial)
		_toast("%s built on this tile." % String(recipe["name"]))
	else:
		_toast("Crafted: %s." % String(recipe["name"]))
	EventBus.inventory_changed.emit(p.index)
	_finish_main_action()


# ----------------------------------------------------------------- magic

## Signature abilities — each expresses the character AND the Duality (canon action 3).
func _cast_signature(p: PlayerState) -> void:
	action_taken = "magic"
	match p.character_id:
		"cartographer":
			Game.add_energy(p, -1)
			var seen: Array = []
			for n in Hex.neighbors(p.pos):
				var t: IslandTile = Game.board.get_tile(n)
				if t != null and not t.explored:
					seen.append(_terrain_name(t))
			_show_modal("Mapmaker's Sight", "The charts whisper. Adjacent unknown lands: %s." % (", ".join(seen) if not seen.is_empty() else "none — all charted"), [["Continue", _close_modal]])
			_finish_main_action()
		"botanist":
			var entries: Array = [["Myself (+2⚡)", _botanist_heal.bind(p, p)]]
			for other in Game.players:
				if other.index != p.index and other.pos == p.pos:
					var target: PlayerState = other
					entries.append(["%s (+2⚡, +1 Light for you)" % target.display_name, _botanist_heal.bind(p, target)])
			_show_modal("Flora Whispering", "Life answers her. Restore energy:", entries)
		"blacksmith":
			Game.add_energy(p, -1)
			var tile: IslandTile = Game.board.get_tile(p.pos)
			var el := tile.element_id if not bool(Game.decks.elements_by_id.get(tile.element_id, {}).get("earned_not_gathered", false)) else "stone"
			for i in 2:
				p.add_common(Game.decks.random_common(el), 1)
			_show_modal("Metal Tempering", "He reads the ground like grain in wood: +2 commons.", [["Continue", _close_modal]])
			EventBus.inventory_changed.emit(p.index)
			_finish_main_action()
		"outcast":
			var entries2: Array = []
			for other in Game.players:
				if other.index != p.index and other.pos == p.pos and other.commons_count() > 0:
					var target2: PlayerState = other
					entries2.append(["Drain %s (−2 Light, +1 Rage)" % target2.display_name, _outcast_drain.bind(p, target2)])
			if entries2.is_empty():
				_toast("No one on your tile to drain. (Dark magic needs a victim.)")
				action_taken = ""
				return
			entries2.append(["Never mind", _close_modal])
			_show_modal("Survivalist Guile", "Take what isn't given.", entries2)


func _botanist_heal(p: PlayerState, target: PlayerState) -> void:
	_close_modal()
	Game.add_energy(p, -1)
	Game.add_energy(target, 2)
	if target.index != p.index:
		Game.shift_light(p, "cast_light_spell")
		_toast("You mend %s. +1 Light." % target.display_name)
	else:
		_toast("You mend yourself. +2⚡.")
	_finish_main_action()


func _outcast_drain(p: PlayerState, target: PlayerState) -> void:
	_close_modal()
	Game.add_energy(p, -1)
	var lost := target.spend_any_commons(2, Game.rng)
	for id in lost:
		p.add_common(String(id), 1)
	Game.shift_light(p, "cast_dark_spell")
	Game.add_rage(Rage.delta_for("cast_dark_spell"))
	EventBus.inventory_changed.emit(target.index)
	_toast("You take %d commons from %s. −2 Light, +1 Rage." % [lost.size(), target.display_name])
	_finish_main_action()


# ----------------------------------------------------------------- learn

func _open_learn(p: PlayerState) -> void:
	var entries: Array = []
	if not p.skills.has("scavengers_eye") and p.commons_count() >= 3:
		entries.append(["Scavenger's Eye (3 CE): +1 common on gathers", _learn_pick.bind(p, "scavengers_eye", 3)])
	if p.skills.has("scavengers_eye") and not p.skills.has("sturdy_pack") and p.commons_count() >= 6:
		entries.append(["Sturdy Pack (6 CE): +2 hand limit", _learn_pick.bind(p, "sturdy_pack", 6)])
	if entries.is_empty():
		_toast("No affordable skill right now (Common 3 CE, Uncommon 6 CE — canon).")
		return
	entries.append(["Never mind", _close_modal])
	_show_modal("Learning", "Meditation opened the way. Spend commons as CE:", entries)


func _learn_pick(p: PlayerState, skill: String, ce: int) -> void:
	_close_modal()
	action_taken = "learn"
	p.spend_any_commons(ce, Game.rng)
	p.skills.append(skill)
	if skill == "sturdy_pack":
		p.hand_limit += 2
	_toast("Learned: %s." % Game.decks.display_name_of(skill))
	EventBus.inventory_changed.emit(p.index)
	_finish_main_action()


# ----------------------------------------------------------------- quest

func _do_quest(p: PlayerState) -> void:
	var tile: IslandTile = Game.board.get_tile(p.pos)
	var is_guardian_tile := tile.has_guardian or tile.tier == 3
	var sanctum := tile.tier == 3
	var entries: Array = []

	if is_guardian_tile:
		if p.has_item("offering_bundle"):
			entries.append(["★ Make an Offering (+2 Light, +%d VP, −1 Rage)" % (4 if sanctum else 2), _quest_offer.bind(p, sanctum)])
		if Duality.corrupt_gate_open(Game.band_of(p)):
			entries.append(["☠ Defile the site (−3 Light, +2 VP, +1 Rage)", _quest_defile.bind(p)])

	entries.append(["⚅ Call Quest Redraw Vote", _on_call_quest_redraw_vote.bind(p)])
	entries.append(["Close", _close_modal])

	var q_lines: Array = ["Active Island Quests:"]
	for q in Game.common_quests:
		var qid := String(q.get("id", ""))
		var qname := String(q.get("name", ""))
		var qdesc := String(q.get("desc", ""))
		var vp := int(q.get("vp", 0))
		var diff := String(q.get("difficulty", "?")).capitalize()
		var status_str := "Completed ✓" if p.completed_quests.has(qid) else "In Progress"
		q_lines.append("\n[%s] %s (%d VP) — %s\n  %s" % [diff, qname, vp, status_str, qdesc])
	
	if is_guardian_tile:
		q_lines.append("\n✦ You stand at an ancient Guardian site.")

	_show_modal("Quests & Guardians", "\n".join(q_lines), entries)


func _on_call_quest_redraw_vote(p: PlayerState) -> void:
	_close_modal()
	if Game.players.size() == 1:
		Game.redraw_common_quests()
		_toast("Quests redrawn!")
		return
	
	Game.start_quest_redraw_vote(p.index)
	_toast("%s called for a Common Quest redraw vote." % p.display_name)
	_prompt_next_redraw_vote(p.index, 0)


func _prompt_next_redraw_vote(caller_idx: int, check_idx: int) -> void:
	if check_idx >= Game.players.size():
		return
	if check_idx == caller_idx:
		_prompt_next_redraw_vote(caller_idx, check_idx + 1)
		return
	
	var voter: PlayerState = Game.players[check_idx]
	var entries: Array = [
		["Agree (Vote YES to redraw)", _cast_redraw_vote_choice.bind(caller_idx, check_idx, true)],
		["Disagree (Vote NO)", _cast_redraw_vote_choice.bind(caller_idx, check_idx, false)],
	]
	_show_modal(
		"Quest Redraw Vote",
		"Player %s wants to redraw the 3 Common Quests.\n\n%s, do you agree?" % [Game.players[caller_idx].display_name, voter.display_name],
		entries
	)


func _cast_redraw_vote_choice(caller_idx: int, voter_idx: int, agree: bool) -> void:
	_close_modal()
	var status := Game.submit_quest_redraw_vote(voter_idx, agree)
	if bool(status.get("resolved", false)):
		if bool(status.get("passed", false)):
			_toast("Redraw vote PASSED (%d/%d). New quests drawn!" % [int(status.get("yes_count", 0)), int(status.get("total_players", 0))])
		else:
			_toast("Redraw vote FAILED. Quests remain unchanged.")
		_refresh_quests()
	else:
		_prompt_next_redraw_vote(caller_idx, voter_idx + 1)


func _quest_offer(p: PlayerState, sanctum: bool) -> void:
	_close_modal()
	if Game.guardian_offering(p, sanctum):
		_toast("The Guardian accepts. The island exhales.")
	_finish_main_action()


func _quest_defile(p: PlayerState) -> void:
	_close_modal()
	Game.shift_light(p, "dark_quest")
	Game.add_rage(1)
	Game.add_vp(p, 2, true)
	_toast("You take what was never offered. The island remembers.")
	_finish_main_action()


# ================================================================= ENCOUNTERS

func _resolve_creature(creature: Dictionary, p: PlayerState, tile: IslandTile) -> void:
	if creature.is_empty():
		return
	var band := Game.band_of(p)
	var cname := String(creature.get("name", "A creature"))
	var f := int(creature.get("f", 4))
	var demand: Dictionary = creature.get("demand", {})
	var demand_txt := _demand_text(demand)
	var entries: Array = []
	var body := "F%d · Demand: %s" % [f, demand_txt]

	match band:
		Duality.Band.MAX_LIGHT:
			_apply_op(creature.get("gift", {}), p, tile)
			body += "\n\nIt greets you like an old friend — its Gift is already yours."
			if _demand_affordable(demand, p):
				entries.append(["Befriend (pay demand · +1 Light, +1 draw)", _befriend.bind(p, creature, tile)])
		Duality.Band.LIGHT:
			body += "\n\nIt watches you kindly."
			if _demand_affordable(demand, p):
				entries.append(["Befriend (pay demand · +1 Light, +1 draw)", _befriend.bind(p, creature, tile)])
			entries.append(["Fight (fate draw vs F%d)" % f, _fight_menu.bind(p, creature, tile)])
		Duality.Band.NEUTRAL:
			body += "\n\nIt offers its Demand as a challenge: meet it, or take from it."
			if _demand_affordable(demand, p):
				entries.append(["Meet the Demand (+1 Light)", _befriend.bind(p, creature, tile)])
			entries.append(["Exploit it (−1 Light, +1 Rage, +1 draw)", _exploit_creature.bind(p, creature, tile)])
			entries.append(["Fight (fate draw vs F%d)" % f, _fight_menu.bind(p, creature, tile)])
		Duality.Band.DARK:
			body += "\n\nIt sees what you are. It strikes first."
			_apply_op(creature.get("bite", {}), p, tile)
			entries.append(["Fight back (+1 F for your darkness)", _fight_menu.bind(p, creature, tile)])
		Duality.Band.MAX_DARK:
			body += "\n\nEven the island's patience ends. It savages you — twice."
			_apply_op(creature.get("bite", {}), p, tile)
			_apply_op(creature.get("bite", {}), p, tile)
			entries.append(["Fight back (+1 F)", _fight_menu.bind(p, creature, tile)])
	entries.append(["Leave quietly", _close_modal])
	_show_modal(cname, body, entries)


func _demand_text(demand: Dictionary) -> String:
	match String(demand.get("type", "free")):
		"common":
			var ids: Array = demand.get("ids", [])
			if ids.is_empty():
				return "any 1 common"
			var names: Array = []
			for id in ids:
				names.append(Game.decks.display_name_of(String(id)))
			return "%d× %s" % [int(demand.get("n", 1)), " / ".join(names)]
		"item": return "any crafted item"
		"give_common": return String(demand.get("desc", "give a common away"))
		"free": return String(demand.get("desc", "a small kindness (free)"))
	return "?"


func _demand_affordable(demand: Dictionary, p: PlayerState) -> bool:
	match String(demand.get("type", "free")):
		"common":
			var ids: Array = demand.get("ids", [])
			if ids.is_empty():
				return p.commons_count() >= int(demand.get("n", 1))
			for id in ids:
				if p.has_common(String(id), int(demand.get("n", 1))):
					return true
			return false
		"item": return not p.items.is_empty()
		"give_common": return p.commons_count() >= 1
		"free": return true
	return true


func _pay_demand(demand: Dictionary, p: PlayerState) -> void:
	match String(demand.get("type", "free")):
		"common":
			var ids: Array = demand.get("ids", [])
			var n := int(demand.get("n", 1))
			if ids.is_empty():
				p.spend_any_commons(n, Game.rng)
			else:
				for id in ids:
					if p.spend_common(String(id), n):
						break
		"item":
			if not p.items.is_empty():
				p.items.remove_at(0)
		"give_common":
			p.spend_any_commons(1, Game.rng)


func _befriend(p: PlayerState, creature: Dictionary, tile: IslandTile) -> void:
	_close_modal()
	_pay_demand(creature.get("demand", {}), p)
	Game.shift_light(p, "befriend_creature")
	var card := Game.decks.draw_card(tile.element_id, tile.tier)
	var extra := ""
	if not card.is_empty() and p.add_card(card):
		extra = " It leads you to: [%s] %s." % [String(card["tier"]), Game.decks.display_name_of(String(card["id"]))]
	_toast("Befriended. +1 Light.%s" % extra)
	EventBus.inventory_changed.emit(p.index)


func _exploit_creature(p: PlayerState, creature: Dictionary, tile: IslandTile) -> void:
	_close_modal()
	Game.add_light(p, -1)
	Game.add_rage(1)
	var card := Game.decks.draw_card(tile.element_id, tile.tier)
	if not card.is_empty():
		p.add_card(card)
	_toast("You take advantage. −1 Light, +1 Island Rage. It flees, angry.")
	EventBus.inventory_changed.emit(p.index)


func _fight_menu(p: PlayerState, creature: Dictionary, tile: IslandTile) -> void:
	_close_modal()
	var entries: Array = [["Draw fate", _fight_do.bind(p, creature, tile, 0)]]
	if p.energy >= 1:
		entries.append(["Draw fate +1 (spend 1⚡)", _fight_do.bind(p, creature, tile, 1)])
	if p.energy >= 2:
		entries.append(["Draw fate +2 (spend 2⚡)", _fight_do.bind(p, creature, tile, 2)])
	_show_modal("Fight — the only gamble", "One fate card against its Fight number. Win: 2 loot draws (and a Dark lean). Lose: the Bite.", entries)


func _fight_do(p: PlayerState, creature: Dictionary, tile: IslandTile, energy: int) -> void:
	_close_modal()
	var result := Game.fight(p, creature, energy)
	var wild_txt := " (a Spirit card — the island judged you by your Light)" if bool(result["wild"]) else ""
	if bool(result["won"]):
		var loot: Array = []
		for i in 2:
			var card := Game.decks.draw_card(tile.element_id, tile.tier)
			if not card.is_empty() and p.add_card(card):
				loot.append(Game.decks.display_name_of(String(card["id"])))
		_show_modal("Victory — of a kind", "Fate %d%s vs F%d. You win. Loot: %s.\n−1 Light — the island felt that." % [int(result["value"]), wild_txt, int(result["f"]), ", ".join(loot) if not loot.is_empty() else "nothing you could carry"], [["Continue", _close_modal]])
	else:
		var bite: Dictionary = creature.get("bite", {})
		if p.has_item("healing_salve"):
			p.remove_item("healing_salve")
			_show_modal("The Bite — salved", "Fate %d%s vs F%d. You lose — but the salve turns the wound." % [int(result["value"]), wild_txt, int(result["f"])], [["Continue", _close_modal]])
		else:
			_apply_op(bite, p, tile)
			_show_modal("The Bite", "Fate %d%s vs F%d. %s" % [int(result["value"]), wild_txt, int(result["f"]), String(bite.get("desc", "It answers your violence."))], [["Continue", _close_modal]])
	EventBus.inventory_changed.emit(p.index)


## Execute a creature/event op (the small op vocabulary in creatures_canon.json).
func _apply_op(op: Dictionary, p: PlayerState, tile: IslandTile) -> void:
	match String(op.get("op", "none")):
		"gain_common":
			var n := int(op.get("n", 1))
			var id := String(op.get("id", ""))
			var el := String(op.get("element", tile.element_id))
			for i in n:
				p.add_common(id if id != "" else Game.decks.random_common(el), 1)
		"lose_common":
			Game.lose_commons(p, int(op.get("n", 1)))
		"energy":
			Game.add_energy(p, int(op.get("n", 0)))
		"move":
			var n2 := int(op.get("n", 0))
			if n2 < 0:
				p.slow_penalty += -n2
			else:
				moves_left += n2
		"light":
			Game.add_light(p, int(op.get("n", 0)))
		"draw_card":
			var card := Game.decks.draw_card(tile.element_id, tile.tier)
			if not card.is_empty():
				p.add_card(card)
		"lose_card":
			if not p.cards.is_empty():
				p.cards.remove_at(Game.rng.randi_range(0, p.cards.size() - 1))
		"shield_event":
			p.skills.append("shield_event")
	EventBus.inventory_changed.emit(p.index)


func _resolve_event(ev: Dictionary, p: PlayerState, tile: IslandTile) -> void:
	if ev.is_empty():
		return
	if p.skills.has("shield_event"):
		p.skills.erase("shield_event")
		_show_modal("Sidestepped", "The Tidecrab's gift: you slip past what was waiting here.", [["Continue", _close_modal]])
		return
	var title := String(ev.get("name", "Something happens"))
	var desc := String(ev.get("desc", ""))
	var amount := int(ev.get("amount", 1))
	match String(ev.get("type", "")):
		"gain_resource":
			for i in amount:
				p.add_common(Game.decks.random_common(tile.element_id), 1)
			desc += "\n\n+%d common(s)." % amount
		"lose_resource":
			var lost := Game.lose_commons(p, amount)
			desc += "\n\nLost %d common(s)." % lost.size()
		"light_delta":
			Game.add_light(p, amount)
			desc += "\n\nLight %+d." % amount
		"vp_delta":
			Game.add_vp(p, amount)
			desc += "\n\n%+d VP." % amount
		"slow_next_turn":
			var slow := amount
			if p.character_id == "blacksmith":
				slow += 1  # WEAKNESS — Heavy Gear
			p.slow_penalty += slow
			desc += "\n\nNext turn: −%d movement." % slow
	_show_modal(title, desc, [["Continue", _close_modal]])
	EventBus.inventory_changed.emit(p.index)


# ================================================================= MODAL / WIN

func _show_modal(title: String, body: String, entries: Array) -> void:
	modal_title.text = title
	modal_body.text = body
	for child in modal_buttons.get_children():
		child.queue_free()
	for entry in entries:
		var b := Button.new()
		b.text = String(entry[0])
		b.custom_minimum_size = Vector2(480, 52)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(entry[1])
		modal_buttons.add_child(b)
	modal_root.visible = true


func _close_modal() -> void:
	modal_root.visible = false
	_refresh_hud()


func _on_game_won(index: int, way: String) -> void:
	var p: PlayerState = Game.players[index]
	match way:
		"enlightened":
			winner_label.text = "%s\nwalks the Enlightened Path.\nThe island keeps them as one of its own." % p.display_name
		"capable":
			winner_label.text = "%s\nwalks the Capable Path.\nSkilled hands, and light enough to trust." % p.display_name
		"endgame":
			winner_label.text = "The seasons turn.\n%s came furthest on their path.\nThe island remembers everyone." % p.display_name
		_:
			winner_label.text = "%s\ntakes the island in shadow.\nA hollow kind of crown." % p.display_name
	winner_overlay.visible = true


# ================================================================= INPUT

func _unhandled_input(event: InputEvent) -> void:
	if winner_overlay != null and winner_overlay.visible:
		return
	if modal_root != null and modal_root.visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_drag_moved = false
			else:
				if _pressing and not _drag_moved:
					_handle_tap()
				_pressing = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom(1.1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom(0.9)
	elif event is InputEventMouseMotion and _pressing:
		var mm := event as InputEventMouseMotion
		if mm.relative.length() > 2.0:
			_drag_moved = true
		camera.position -= mm.relative / camera.zoom.x


func _zoom(factor: float) -> void:
	var z: float = clampf(camera.zoom.x * factor, 0.35, 2.2)
	camera.zoom = Vector2(z, z)


func _handle_tap() -> void:
	var world := get_global_mouse_position()
	var axial := Hex.from_pixel(world, hex_size)
	var tile: IslandTile = Game.board.get_tile(axial)
	if tile == null:
		return
	if mode == "explore" and not turn_over:
		var p := Game.current_player()
		if axial == p.pos and moves_left >= 0 and not flipped_this_move:
			# Tap own tile: choose Push or Finish&Gather.
			_show_modal("Here?", "Finish here and gather — or push on (1⚡ per extra move).", [
				["Finish & Gather", _finish_gather.bind(p)],
				["Push +1 move (1⚡)", _push_move.bind(p)],
				["Keep moving", _close_modal],
			])
			return
		_try_step(axial)
	else:
		if tile.explored:
			var extra := "  ·  Guardian site ✦" if tile.has_guardian else ""
			_toast("%s (Tier %d)%s" % [_terrain_name(tile), tile.tier, extra])
		else:
			_toast("Unexplored land. Take Explore/Gather to venture there.")


func _finish_gather(p: PlayerState) -> void:
	_close_modal()
	_gather(p, Game.board.get_tile(p.pos))


func _push_move(p: PlayerState) -> void:
	_close_modal()
	if p.energy >= 1:
		Game.add_energy(p, -1)
		moves_left += 1
		_toast("Push! +1 move (⚡%d)." % p.energy)
	_refresh_hud()
