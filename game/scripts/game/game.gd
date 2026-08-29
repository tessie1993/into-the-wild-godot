extends Node2D
## The play scene, v2 — Painterly Storybook Table & HUD.
## The canon turn: CARE phase (free bonuses) then one of six MAIN actions (canon/actions.json).
## Rules live in Game + systems/*; this scene is the illustrated view table.

const FACEDOWN_COLORS: Dictionary = {
	1: Color("28322e"),  ## Outer ring slate green
	2: Color("202824"),  ## Middle ring deep slate
	3: Color("1a1f26"),  ## Inner sanctum shadow
}
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
var p_crest_panel: PanelContainer
var lbl_turn: Label
var lbl_stats: Label
var lbl_inv: Label
var lbl_quests: Label
var lbl_toast: Label
var toast_panel: PanelContainer
var care_bar: HBoxContainer
var action_bar: HBoxContainer
var karma_track: KarmaTrack
var buttons: Dictionary = {}

# Modal System
var modal_root: CenterContainer
var modal_panel: PanelContainer
var modal_card_img: TextureRect
var modal_title: Label
var modal_body: RichTextLabel
var modal_buttons: VBoxContainer

# Winner Overlay
var winner_overlay: ColorRect
var winner_panel: PanelContainer
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
	world_bg.color = UITheme.COLOR_BG_DEEP
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
	_add_sanctum_glow()
	for p in Game.players:
		var pawn := Node2D.new()
		var p_col: Color = UITheme.PLAYER_COLORS[p.index % UITheme.PLAYER_COLORS.size()]
		
		# Outer soft glow ring
		var glow := Line2D.new()
		glow.points = _circle_points(hex_size * 0.28, 16)
		glow.closed = true
		glow.width = 4.0
		glow.default_color = Color(p_col.r, p_col.g, p_col.b, 0.4)
		pawn.add_child(glow)

		# Inner token dot
		var dot := Polygon2D.new()
		dot.polygon = _circle_points(hex_size * 0.22, 16)
		dot.color = p_col
		pawn.add_child(dot)

		# Dark rim
		var rim := Line2D.new()
		rim.points = _circle_points(hex_size * 0.22, 16)
		rim.closed = true
		rim.width = 2.5
		rim.default_color = Color(0.08, 0.12, 0.10, 0.95)
		pawn.add_child(rim)

		pawn_layer.add_child(pawn)
		pawns.append(pawn)
		_place_pawn(p)

	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	add_child(camera)
	camera.make_current()


func _spawn_tile_nodes(axial: Vector2i) -> void:
	var center := Hex.to_pixel(axial, hex_size)
	
	# Drop shadow / outer bevel
	var shadow := Polygon2D.new()
	shadow.polygon = Hex.corners(center + Vector2(0, 3), hex_size * 0.98)
	shadow.color = Color(0.04, 0.07, 0.05, 0.5)
	board_layer.add_child(shadow)

	# Border outline
	var outline := Polygon2D.new()
	outline.polygon = Hex.corners(center, hex_size * 0.98)
	outline.color = Color(0.12, 0.17, 0.14, 0.95)
	board_layer.add_child(outline)

	# Inner tile fill
	var fill := Polygon2D.new()
	fill.polygon = Hex.corners(center, hex_size * 0.90)
	board_layer.add_child(fill)
	tile_fills[axial] = fill

	# Marker glyph
	var mark := Label.new()
	mark.add_theme_font_size_override("font_size", 26)
	mark.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
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
		fill.color = Color(String(e.get(key, "#4a7c59")))
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
		fill.color = FACEDOWN_COLORS.get(tile.tier, Color("222b26"))
		# Facedown tiles bear faint rune etchings (mockup: the unexplored dark hexes).
		mark.add_theme_color_override("font_color", UITheme.RUNE_FAINT)
		mark.text = UITheme.rune_for(axial)
		return
	mark.add_theme_color_override("font_color", UITheme.GOLD)


## The Sanctum breathes light at the island's heart (mockup: the glowing center).
func _add_sanctum_glow() -> void:
	var center := Hex.to_pixel(Vector2i.ZERO, hex_size)
	var glow := Polygon2D.new()
	glow.polygon = Hex.corners(center, hex_size * 1.25)
	glow.color = Color(UITheme.GLOW.r, UITheme.GLOW.g, UITheme.GLOW.b, 0.10)
	glow.z_index = 1
	board_layer.add_child(glow)
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "color:a", 0.26, 1.6)
	tween.tween_property(glow, "color:a", 0.10, 1.6)


func _place_pawn(p: PlayerState) -> void:
	var node: Node2D = pawns[p.index]
	var target_pos := Hex.to_pixel(p.pos, hex_size) + PAWN_OFFSETS[p.index % PAWN_OFFSETS.size()]
	if node.position == Vector2.ZERO or not is_inside_tree():
		node.position = target_pos
	else:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position", target_pos, 0.22)


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

	# 1. Top-Left Player Identity & Turn Banner
	p_crest_panel = _panel(Control.PRESET_TOP_LEFT, 16)
	var tl_vbox := VBoxContainer.new()
	tl_vbox.add_theme_constant_override("separation", 6)
	p_crest_panel.add_child(tl_vbox)

	lbl_turn = _label(22, UITheme.COLOR_TEXT_GOLD)
	tl_vbox.add_child(lbl_turn)

	lbl_stats = _label(17, UITheme.COLOR_TEXT_LIGHT)
	tl_vbox.add_child(lbl_stats)

	# 2. Top-Right Quests Scroll
	var top_right := _panel(Control.PRESET_TOP_RIGHT, 16)
	var tr_vbox := VBoxContainer.new()
	tr_vbox.add_theme_constant_override("separation", 6)
	top_right.add_child(tr_vbox)

	var q_header := _label(16, UITheme.COLOR_TEXT_GOLD)
	q_header.text = "✦ ISLAND QUESTS ✦"
	tr_vbox.add_child(q_header)

	lbl_quests = _label(14, UITheme.COLOR_TEXT_MUTED)
	tr_vbox.add_child(lbl_quests)

	# 3. Bottom-Right Inventory Pouch
	var bottom_right := _panel(Control.PRESET_BOTTOM_RIGHT, 16)
	var br_vbox := VBoxContainer.new()
	br_vbox.add_theme_constant_override("separation", 6)
	bottom_right.add_child(br_vbox)

	var inv_header := _label(16, UITheme.COLOR_TEXT_EMERALD)
	inv_header.text = "🎒 POUCH & CARDS"
	br_vbox.add_child(inv_header)

	lbl_inv = _label(14, UITheme.COLOR_TEXT_LIGHT)
	br_vbox.add_child(lbl_inv)

	# Karma Track ribbon, top center (mockup).
	var karma_panel := _panel(Control.PRESET_CENTER_TOP, 16)
	var karma_box := VBoxContainer.new()
	karma_box.add_theme_constant_override("separation", 2)
	karma_panel.add_child(karma_box)
	karma_box.add_child(UITheme.heading_label("Karma Track", 13))
	karma_track = KarmaTrack.new()
	karma_box.add_child(karma_track)

	# 4. Bottom-Center Care & Action Dock
	var dock_panel := _panel(Control.PRESET_CENTER_BOTTOM, 16)
	var dock_box := VBoxContainer.new()
	dock_box.add_theme_constant_override("separation", 8)
	dock_panel.add_child(dock_box)

	care_bar = HBoxContainer.new()
	care_bar.add_theme_constant_override("separation", 10)
	dock_box.add_child(care_bar)
	for def in [
		["eat", "Eat (⚡)", "secondary"],
		["sleep", "Sleep (+2⚡)", "secondary"],
		["meditate", "Meditate 🧘", "secondary"],
		["trade", "Trade & Gift ⇄", "gold"],
		["wild_care", "Wild 🃏", "gold"],
		["begin_action", "Begin Action ▸", "primary"]
	]:
		_add_dock_button(care_bar, String(def[0]), String(def[1]), String(def[2]), _on_care)

	action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 10)
	dock_box.add_child(action_bar)
	for def in [
		["explore", "Explore", "primary"],
		["craft", "Craft", "primary"],
		["creatures", "Creatures", "primary"],
		["magic", "Magic/Learn", "primary"],
		["guardian", "Guardian", "gold"],
		["give_back", "Give Back ✦", "gold"],
		["raid", "Raid ☠", "danger"],
		["trade_free", "Trade ⇄", "secondary"],
		["wild", "Wild 🃏", "gold"],
		["end", "End Turn", "secondary"]
	]:
		_add_dock_button(action_bar, String(def[0]), String(def[1]), String(def[2]), _on_action)

	# 5. Toast Notification Banner
	toast_panel = _panel(Control.PRESET_BOTTOM_LEFT, 16)
	toast_panel.visible = false
	lbl_toast = _label(16, UITheme.COLOR_TEXT_GOLD)
	toast_panel.add_child(lbl_toast)

	# 6. Storybook Encounter & Choice Modal
	modal_root = CenterContainer.new()
	modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.visible = false
	hud.add_child(modal_root)
	var modal_backdrop := ColorRect.new()
	modal_backdrop.color = Color(0.04, 0.06, 0.05, 0.85)
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(modal_backdrop)

	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(680, 480)
	var m_style := UITheme.make_panel_style(
		Color(0.10, 0.14, 0.11, 0.98),
		Color(0.85, 0.72, 0.35, 0.9),
		3,
		16,
		24
	)
	modal_panel.add_theme_stylebox_override("panel", m_style)
	modal_root.add_child(modal_panel)

	var m_main_box := HBoxContainer.new()
	m_main_box.add_theme_constant_override("separation", 24)
	modal_panel.add_child(m_main_box)

	# Card Illustration on left
	modal_card_img = TextureRect.new()
	modal_card_img.custom_minimum_size = Vector2(200, 300)
	modal_card_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	modal_card_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	modal_card_img.visible = false
	m_main_box.add_child(modal_card_img)

	# Right Column: Content & Buttons
	var mbox := VBoxContainer.new()
	mbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mbox.add_theme_constant_override("separation", 12)
	m_main_box.add_child(mbox)

	modal_title = _label(24, UITheme.COLOR_TEXT_GOLD)
	mbox.add_child(modal_title)

	var m_sep := HSeparator.new()
	mbox.add_child(m_sep)

	modal_body = RichTextLabel.new()
	modal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.bbcode_enabled = true
	modal_body.add_theme_font_size_override("normal_font_size", 16)
	modal_body.add_theme_color_override("default_color", UITheme.COLOR_TEXT_LIGHT)
	mbox.add_child(modal_body)

	modal_buttons = VBoxContainer.new()
	modal_buttons.add_theme_constant_override("separation", 8)
	mbox.add_child(modal_buttons)

	# 7. Winner Chronicle Overlay
	winner_overlay = ColorRect.new()
	(winner_overlay as ColorRect).color = Color(0.04, 0.06, 0.05, 0.94)
	winner_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	winner_overlay.visible = false
	hud.add_child(winner_overlay)

	var wc := CenterContainer.new()
	wc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	winner_overlay.add_child(wc)

	winner_panel = PanelContainer.new()
	winner_panel.custom_minimum_size = Vector2(720, 480)
	var win_style := UITheme.make_panel_style(
		Color(0.09, 0.14, 0.11, 0.98),
		Color(0.95, 0.80, 0.35, 0.95),
		3,
		18,
		32
	)
	winner_panel.add_theme_stylebox_override("panel", win_style)
	wc.add_child(winner_panel)

	var wbox := VBoxContainer.new()
	wbox.add_theme_constant_override("separation", 20)
	winner_panel.add_child(wbox)

	var win_title := _label(22, UITheme.COLOR_TEXT_GOLD)
	win_title.text = "✦  CHRONICLE OF THE ISLAND  ✦"
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wbox.add_child(win_title)

	winner_label = _label(28, UITheme.COLOR_TEXT_LIGHT)
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wbox.add_child(winner_label)

	var back := Button.new()
	back.text = "Return to Shore  ⛵"
	back.custom_minimum_size = Vector2(300, 56)
	UITheme.apply_button_style(back, "primary", Color("3a8c56"), 20)
	back.pressed.connect(_back_to_menu)
	wbox.add_child(back)

	_refresh_quests()


func _panel(preset: Control.LayoutPreset, margin: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var style := UITheme.make_panel_style(
		Color(0.08, 0.12, 0.09, 0.94),
		Color(0.35, 0.52, 0.40, 0.65),
		2,
		12,
		12
	)
	p.add_theme_stylebox_override("panel", style)
	p.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, margin)
	hud.add_child(p)
	return p


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _add_dock_button(bar: HBoxContainer, id: String, text: String, variant: String, handler: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 52)
	UITheme.apply_button_style(b, variant, Color("3a8c56"), 16)
	b.pressed.connect(handler.bind(id))
	bar.add_child(b)
	buttons[id] = b


func _toast(text: String) -> void:
	lbl_toast.text = text
	toast_panel.visible = (text != "")
	_toast_token += 1
	var token := _toast_token
	get_tree().create_timer(4.5).timeout.connect(func() -> void:
		if token == _toast_token:
			lbl_toast.text = ""
			toast_panel.visible = false
	)


func _refresh_quests() -> void:
	if Game.players.is_empty():
		return
	var p := Game.current_player()
	var lines: Array = []
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
	lines.append("\nPaths to Victory:")
	lines.append("★ Capable: 16 VP & Light ≥ 3")
	lines.append("★ Enlightened: 10 VP & Light ≥ 8")
	lines.append("☠ Dark: 18 VP & Light ≤ −8")
	lbl_quests.text = "\n".join(lines)


func _refresh_hud() -> void:
	if Game.players.is_empty():
		return
	var p := Game.current_player()
	var band := Game.band_of(p)
	var p_col: Color = UITheme.PLAYER_COLORS[p.index % UITheme.PLAYER_COLORS.size()]

	# Player Crest Border Accent
	var st: StyleBoxFlat = p_crest_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if st != null:
		st.border_color = Color(p_col.r, p_col.g, p_col.b, 0.8)

	lbl_turn.text = "Round %d  •  %s  [%s phase]" % [Game.round_num, p.display_name, Game.phase.capitalize()]
	var move_txt := "  ·  Moves: %d" % moves_left if mode == "explore" else ""
	var hyp := Duality.hypocrisy_energy_penalty(p.vp, p.light)
	var hyp_txt := "  ·  ⚠ Hypocrisy −%d⚡" % hyp if hyp > 0 else ""

	lbl_stats.text = "⚡ %d/5   •   Light %d (%s)   •   ★ %d/20 VP   •   Island Rage %d/10%s%s" % [
		p.energy, p.light, Duality.band_name(band), p.vp, Game.rage, move_txt, hyp_txt
	]
	if karma_track != null:
		karma_track.set_light(p.light, band)
	var lines: Array = []
	lines.append("Pouch (%d commons):" % p.commons_count())
	for id in p.commons.keys():
		lines.append("  • %s ×%d" % [Game.decks.display_name_of(String(id)), int(p.commons[id])])
	lines.append("Cards (%d/%d):" % [p.cards.size(), p.hand_limit])
	for c in p.cards:
		lines.append("  • [%s] %s" % [String(c.get("tier", "?")).left(1).to_upper(), Game.decks.display_name_of(String(c.get("id", "")))])
	lines.append("Items (%d/%d):" % [p.items.size(), p.pack_size])
	for it in p.items:
		lines.append("  • %s" % Game.decks.display_name_of(String(it)))
	lbl_inv.text = "\n".join(lines)
	_refresh_bars(p)


func _refresh_bars(p: PlayerState) -> void:
	var in_care := Game.phase == "care"
	care_bar.visible = in_care
	action_bar.visible = not in_care
	if in_care:
		(buttons["meditate"] as Button).disabled = p.meditated or p.energy < 1
		(buttons["trade"] as Button).disabled = Game.players.size() < 2
		(buttons["wild_care"] as Button).visible = not p.wild_cards.is_empty()
	else:
		var done := turn_over
		for id in ["explore", "craft", "creatures", "magic", "guardian", "give_back", "raid", "trade_free"]:
			if buttons.has(id):
				(buttons[id] as Button).disabled = done
		(buttons["wild"] as Button).visible = not p.wild_cards.is_empty()
		(buttons["wild"] as Button).text = "🃏 Wild (%d)" % p.wild_cards.size()
		if not done:
			(buttons["give_back"] as Button).disabled = p.commons_count() < 3
			if buttons.has("trade_free"):
				(buttons["trade_free"] as Button).visible = ActionCards.has_free_trading(p)
			if buttons.has("raid"):
				var can_any_raid := false
				for other in Game.players:
					if DarkRaiding.can_raid(p, other):
						can_any_raid = true
						break
				(buttons["raid"] as Button).visible = can_any_raid
			# Update dynamic level text
			(buttons["explore"] as Button).text = "🧭 Explore (%d)" % ActionCards.get_level(p, "explore")
			(buttons["craft"] as Button).text = "🔨 Craft (%d)" % ActionCards.get_level(p, "craft")
			(buttons["creatures"] as Button).text = "🦌 Creatures (%d)" % ActionCards.get_level(p, "creatures")
			(buttons["magic"] as Button).text = "✨ Magic (%d)" % ActionCards.get_level(p, "magic")
			(buttons["guardian"] as Button).text = "🛡 Guardian (%d)" % ActionCards.get_level(p, "guardian")
			# WEAKNESS — Cartographer "Restless": no repeating last turn's action.
			if p.character_id == "cartographer" and p.last_action != "":
				if buttons.has(p.last_action):
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
				if ActionCards.get_level(p, "magic") >= 3:
					var tile: IslandTile = Game.board.get_tile(p.pos)
					var com := Game.decks.random_common(tile.element_id)
					if com != "":
						p.add_common(com, 1)
						_toast("Sponsor Perk (Magic Lvl 3): gained +1 %s." % Game.decks.display_name_of(com))
			_refresh_hud()
		"trade":
			_open_trade(p)
		"wild_care":
			_open_wild_menu(p)
		"begin_action":
			Game.end_care_phase()
			_toast("Choose an action card: Explore, Craft, Creatures, Magic, Guardian, or Give Back.")
			_refresh_hud()


func _open_eat(p: PlayerState) -> void:
	var entries: Array = []
	if p.has_item("cooked_meal"):
		entries.append(["Cooked Meal (+3⚡)", _eat_pick.bind(p, "cooked_meal", true)])
	var foods := ["wild_berries", "grain", "fish", "mushroom", "fresh_water"]
	for f in foods:
		if p.has_common(String(f)):
			entries.append(["%s (+1⚡)" % Game.decks.display_name_of(String(f)), _eat_pick.bind(p, String(f), false)])
	# Catalog consumables (content drop) are eaten here too.
	for id in p.items.duplicate():
		var it := Game.decks.item_def(String(id))
		if String(it.get("type", "")) == "consumable":
			var lbl := "%s (+%d⚡%s)" % [String(it.get("name", id)), int(it.get("use_energy", 1)),
				", +%d☀" % int(it.get("use_light", 0)) if int(it.get("use_light", 0)) > 0 else ""]
			entries.append([lbl, _eat_consumable.bind(p, String(id))])
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


func _eat_consumable(p: PlayerState, id: String) -> void:
	_close_modal()
	var res := Game.use_consumable(p, id)
	if res.is_empty():
		return
	var txt := "+%d⚡" % int(res["energy"])
	if int(res["light"]) > 0:
		txt += ", +%d Light" % int(res["light"])
	_toast("%s. %s" % [Game.decks.display_name_of(id), txt])
	_refresh_hud()


# ----------------------------------------------------------------- trade & bilateral exchange

func _open_trade(p: PlayerState) -> void:
	var other_players: Array = []
	for pl in Game.players:
		if pl.index != p.index:
			other_players.append(pl)
	if other_players.is_empty():
		_toast("No other wanderers to trade with.")
		return
	if other_players.size() == 1:
		_start_trade_with(p, other_players[0] as PlayerState)
		return
	var entries: Array = []
	for other in other_players:
		var target: PlayerState = other
		entries.append([target.display_name, _start_trade_with.bind(p, target)])
	entries.append(["Cancel", _close_modal])
	_show_modal("Trade & Gift", "Select a trade partner:", entries)


func _start_trade_with(p: PlayerState, target: PlayerState) -> void:
	_close_modal()
	_show_trade_builder(p, target, {}, [], {}, [])


func _show_trade_builder(p: PlayerState, target: PlayerState, offer_commons: Dictionary, offer_cards: Array, req_commons: Dictionary, req_cards: Array) -> void:
	var bundle_a := {"commons": offer_commons, "cards": offer_cards}
	var bundle_b := {"commons": req_commons, "cards": req_cards}
	var ce_a := TradeSystem.calculate_bundle_ce(bundle_a)
	var ce_b := TradeSystem.calculate_bundle_ce(bundle_b)
	var delta := ce_a - ce_b

	var lines: Array = ["Trading with %s" % target.display_name]
	lines.append("\nYour Offer (%d CE):" % ce_a)
	if offer_commons.is_empty() and offer_cards.is_empty():
		lines.append("  • (nothing offered)")
	else:
		for cid in offer_commons.keys():
			lines.append("  • %s ×%d (%d CE)" % [Game.decks.display_name_of(String(cid)), int(offer_commons[cid]), int(offer_commons[cid])])
		for c in offer_cards:
			lines.append("  • [%s] %s (%d CE)" % [String(c.get("tier", "?")), Game.decks.display_name_of(String(c.get("id", ""))), int(TradeSystem.CE_BY_TIER.get(String(c.get("tier", "common")), 1))])

	lines.append("\nYour Request (%d CE):" % ce_b)
	if req_commons.is_empty() and req_cards.is_empty():
		lines.append("  • (nothing requested)")
	else:
		for cid in req_commons.keys():
			lines.append("  • %s ×%d (%d CE)" % [Game.decks.display_name_of(String(cid)), int(req_commons[cid]), int(req_commons[cid])])
		for c in req_cards:
			lines.append("  • [%s] %s (%d CE)" % [String(c.get("tier", "?")), Game.decks.display_name_of(String(c.get("id", ""))), int(TradeSystem.CE_BY_TIER.get(String(c.get("tier", "common")), 1))])

	lines.append("\nNet Balance: %+d CE" % delta)
	if delta >= 3:
		lines.append("★ Generous trade: grants +1 Light reward to you!")

	var entries: Array = []
	entries.append(["+ Add to Your Offer", _trade_pick_item.bind(p, target, offer_commons, offer_cards, req_commons, req_cards, true)])
	entries.append(["+ Request from %s" % target.display_name, _trade_pick_item.bind(p, target, offer_commons, offer_cards, req_commons, req_cards, false)])
	if ce_a > 0 or ce_b > 0:
		entries.append(["✓ Propose Trade", _trade_confirm_send.bind(p, target, bundle_a, bundle_b)])
	entries.append(["Cancel Trade", _close_modal])

	_show_modal("Bilateral Trade", "\n".join(lines), entries)


func _trade_pick_item(p: PlayerState, target: PlayerState, offer_commons: Dictionary, offer_cards: Array, req_commons: Dictionary, req_cards: Array, offering: bool) -> void:
	_close_modal()
	var source_p := p if offering else target
	var current_commons := offer_commons if offering else req_commons
	var current_cards := offer_cards if offering else req_cards

	var entries: Array = []
	for cid in source_p.commons.keys():
		var total_has := int(source_p.commons[cid])
		var already := int(current_commons.get(cid, 0))
		if total_has > already:
			var item_id := String(cid)
			entries.append(["%s (have %d)" % [Game.decks.display_name_of(item_id), total_has - already], func() -> void:
				current_commons[item_id] = already + 1
				_show_trade_builder(p, target, offer_commons, offer_cards, req_commons, req_cards)
			])

	for c in source_p.cards:
		var cdict: Dictionary = c
		var already_added := false
		for ac in current_cards:
			if String(ac.get("id", "")) == String(cdict.get("id", "")):
				already_added = true
				break
		if not already_added:
			entries.append(["Card: [%s] %s" % [String(cdict.get("tier", "?")), Game.decks.display_name_of(String(cdict.get("id", "")))], func() -> void:
				current_cards.append(cdict)
				_show_trade_builder(p, target, offer_commons, offer_cards, req_commons, req_cards)
			])

	entries.append(["Back", _show_trade_builder.bind(p, target, offer_commons, offer_cards, req_commons, req_cards)])
	_show_modal("Choose item to %s" % ("offer" if offering else "request"), "Select resource or card:", entries)


func _trade_confirm_send(p: PlayerState, target: PlayerState, bundle_a: Dictionary, bundle_b: Dictionary) -> void:
	_close_modal()
	var ce_a := TradeSystem.calculate_bundle_ce(bundle_a)
	var ce_b := TradeSystem.calculate_bundle_ce(bundle_b)
	var entries: Array = [
		["Accept Trade (%d CE for %d CE)" % [ce_a, ce_b], _trade_resolve_choice.bind(p, target, bundle_a, bundle_b, true)],
		["Decline Trade", _trade_resolve_choice.bind(p, target, bundle_a, bundle_b, false)],
	]
	_show_modal(
		"Trade Proposal from %s" % p.display_name,
		"%s wants to trade!\n\nThey offer (%d CE):\n%s\n\nIn exchange for (%d CE):\n%s" % [
			p.display_name, ce_a, _bundle_summary(bundle_a), ce_b, _bundle_summary(bundle_b)
		],
		entries
	)


func _bundle_summary(b: Dictionary) -> String:
	var parts: Array = []
	var commons: Dictionary = b.get("commons", {})
	for cid in commons.keys():
		parts.append("  • %s ×%d" % [Game.decks.display_name_of(String(cid)), int(commons[cid])])
	var cards: Array = b.get("cards", [])
	for c in cards:
		parts.append("  • [%s] %s" % [String(c.get("tier", "?")), Game.decks.display_name_of(String(c.get("id", "")))])
	return "\n".join(parts) if not parts.is_empty() else "  • (nothing)"


func _trade_resolve_choice(p: PlayerState, target: PlayerState, bundle_a: Dictionary, bundle_b: Dictionary, accept: bool) -> void:
	_close_modal()
	if not accept:
		_toast("Trade proposal was declined.")
		return
	var res := TradeSystem.execute_trade(p, target, bundle_a, bundle_b)
	if bool(res.get("success", false)):
		var extra := " (Generous! +1 Light to %s)" % p.display_name if bool(res.get("generous_a", false)) else ""
		_toast("Trade agreed!%s" % extra)
	else:
		_toast(String(res.get("message", "Trade failed.")))
	_refresh_hud()


# ----------------------------------------------------------------- dark raiding

func _open_raid_menu(p: PlayerState) -> void:
	var entries: Array = []
	for other in Game.players:
		if DarkRaiding.can_raid(p, other):
			var target: PlayerState = other
			var loc := "Same Hex" if Hex.distance(p.pos, target.pos) == 0 else "Adjacent Hex"
			entries.append(["Raid %s (%s)" % [target.display_name, loc], _execute_raid_action.bind(p, target)])
	if entries.is_empty():
		_toast("No eligible targets within 1 hex to raid.")
		return
	entries.append(["Cancel", _close_modal])
	_show_modal("Dark Raiding ☠", "Shadows creep. Rob a nearby wanderer (−2 Light, +1 Rage):", entries)


func _execute_raid_action(p: PlayerState, target: PlayerState) -> void:
	_close_modal()
	action_taken = "raid"
	var res := DarkRaiding.execute_raid(p, target, Game.rng)
	_toast(String(res.get("message", "Raid resolved.")))
	_finish_main_action()


# ================================================================= MAIN ACTIONS

func _on_action(id: String) -> void:
	if modal_root.visible or winner_overlay.visible:
		return
	var p := Game.current_player()
	if id == "end":
		Game.end_turn()
		return
	if id == "wild":
		# Wild cards may be played even after the action resolves (Double Down).
		_open_wild_menu(p)
		return
	if turn_over:
		_toast("Your action is done — End Turn.")
		return
	match id:
		"explore":
			action_taken = "explore"
			mode = "explore"
			flipped_this_move = false
			var base_move := p.move
			if ActionCards.get_level(p, "explore") >= 2:
				base_move += 1
			moves_left = maxi(0, base_move - p.slow_penalty)
			p.slow_penalty = 0
			_toast("Explore (Lvl %d) — Move (%d moves left) or tap tile to finish/gather." % [ActionCards.get_level(p, "explore"), moves_left])
			_refresh_hud()
		"craft":
			_open_craft(p)
		"creatures":
			_do_creatures(p)
		"magic":
			_open_magic_menu(p)
		"guardian":
			_do_quest(p)
		"give_back":
			action_taken = "give_back"
			if Game.give_back_light(p):
				_toast("You give back. +2 Light, −1 Island Rage, +1 VP.")
				_finish_main_action()
		"raid":
			_open_raid_menu(p)
		"trade_free":
			_open_trade(p)


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
		# Sanctum Key blessing (Wild Deck): one pass through the Light gate.
		if p.wards.has("sanctum_key"):
			p.wards.erase("sanctum_key")
			_toast("The Sanctum Key turns — the Guardian Gate opens this once.")
		else:
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
	# Thermal Cloak blessing (Wild Deck): harsh terrain costs nothing extra.
	if p.wards.has("thermal_cloak"):
		cost = 1
	# Catalog gear (content drop): immunity to its element's harsh terrain.
	for id in p.items:
		if String(Game.decks.item_def(String(id)).get("immunity_element", "")) == tile.element_id:
			cost = 1
			break
	# Action Card Explore Lvl 4+: immune to T2 penalty
	if ActionCards.get_level(p, "explore") >= 4:
		cost = 1
	# PERK — Cartographer "Pathfinding": explored T2 costs 1.
	elif p.character_id == "cartographer" and tile.explored:
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
	if tile_fills.has(tile.axial):
		var fill: Polygon2D = tile_fills[tile.axial]
		var center := Hex.to_pixel(tile.axial, hex_size)
		fill.pivot_offset = center
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(fill, "scale", Vector2(1.08, 1.08), 0.12)
		tween.tween_property(fill, "scale", Vector2(1.0, 1.0), 0.12)
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
	# Explore Lvl 3+ perk: draw bonus card on reveal
	if ActionCards.get_level(p, "explore") >= 3:
		var bonus_card := Game.decks.draw_card(tile.element_id, tile.tier)
		if not bonus_card.is_empty() and p.add_card(bonus_card):
			if Game.quest_engine != null:
				Game.quest_engine.on_gather_card(p, tile.tier, String(bonus_card.get("tier", "")))
			_toast("Explore Lvl 3 bonus: found [%s] %s." % [String(bonus_card["tier"]), Game.decks.display_name_of(String(bonus_card["id"]))])
	if p.wards.has("mist_ward"):
		_toast("The mist ward folds around you — nothing on this tile notices your arrival.")
	elif Game.rng.randf() < float(Game.decks.config.get("wild", {}).get("card_chance", 0.35)):
		_resolve_wild_card(Game.wild_deck.draw(), p, tile)
	elif Game.rng.randf() < 0.5:
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
			["Strip the land (selfish)", _gather_do.bind(p, tile, true)],
			["Cancel", _close_modal],
		])


func _gather_do(p: PlayerState, tile: IslandTile, selfish: bool) -> void:
	_close_modal()
	action_taken = "explore"
	var mult := 2 if selfish else 1
	var n_commons := 2 * mult
	# Explore Lvl 2+ perk: +1 common on gathers
	if ActionCards.get_level(p, "explore") >= 2:
		n_commons += 1
	# PERK/WEAKNESS hooks
	if p.character_id == "botanist" and (tile.element_id == "wood" or tile.element_id == "grain"):
		n_commons += 1
	if p.character_id == "botanist" and tile.element_id == "stone":
		n_commons = maxi(1, n_commons - 1)
	if p.has_item("stone_axe") and (tile.element_id == "wood" or tile.element_id == "stone"):
		n_commons += 1
	if p.skills.has("scavengers_eye"):
		n_commons += 1
	# Catalog tool (content drop): the best harvesting tool adds commons and wears out.
	var tool := Game.use_best_tool(p)
	if not tool.is_empty():
		n_commons += int(tool["bonus"])
		if bool(tool["broke"]):
			_toast("%s gives its last — the tool breaks apart." % Game.decks.display_name_of(String(tool["id"])))
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
	# Harsh ground hides made things (content drop): T2+ gathers can unearth an item.
	if tile.tier >= 2 and Game.rng.randf() < float(Game.decks.config.get("wild", {}).get("gather_item_chance", 0.2)):
		var found := Game.find_catalog_item(p, ["tool", "gear", "consumable"])
		if not found.is_empty():
			card_txt += " — and half-buried in the ground: [%s] %s!" % [String(found["rarity"]), String(found["name"])]
	if selfish:
		tile.exhausted = true
		_refresh_tile(tile.axial)
		Game.shift_light(p, "exploit_tile")
		Game.add_rage(Rage.delta_for("exploit_tile"))
		_toast("The land cracks. Yield doubled%s. −1 Light, +1 Rage." % card_txt)
	else:
		_toast("Gathered %d commons%s." % [n_commons, card_txt])
	_finish_main_action()


# ----------------------------------------------------------------- crafting & base building

func _open_craft(p: PlayerState) -> void:
	# Ancient Trap (Wild Deck): the mechanism jammed your next Craft.
	if p.craft_locked:
		p.craft_locked = false
		_toast("Your tools are still tangled from the ancient trap — Craft is locked this time.")
		return
	var tile: IslandTile = Game.board.get_tile(p.pos)
	var craft_lvl := ActionCards.get_level(p, "craft")
	var bench := tile.has_building("homebase") or craft_lvl >= 3
	var workshop := tile.has_building("workshop") or craft_lvl >= 5
	var entries: Array = []

	# Tile building interactions
	if BuildingEngine.has_building(tile, "wayside_shrine"):
		entries.append(["✦ Offer at Wayside Shrine (1 Common -> +1 Light)", func() -> void:
			_close_modal()
			var res := BuildingEngine.interact(p, tile, "wayside_shrine", Game.rng)
			_toast(String(res.get("message", "")))
			_finish_main_action()
		])
	if BuildingEngine.has_building(tile, "campfire"):
		entries.append(["♨ Cook Food at Campfire (Free)", func() -> void:
			_close_modal()
			var res := BuildingEngine.interact(p, tile, "campfire", Game.rng)
			_toast(String(res.get("message", "")))
			_refresh_hud()
		])

	for r in Game.decks.recipes:
		var recipe: Dictionary = r
		if not Crafting.bench_ok(recipe, bench, workshop):
			continue
		if not Crafting.can_craft(recipe, p):
			continue
		var label := "%s (%s) — %s" % [String(recipe["name"]), String(recipe["tier"]), Crafting.cost_text(recipe, Game.decks)]
		entries.append([label, _craft_pick.bind(recipe, p, tile)])
	if craft_lvl < 5 and (p.energy >= 1 or p.commons_count() >= 3):
		entries.append(["Empower Crafting Card (Level Up)", func() -> void:
			_close_modal()
			if p.energy >= 1:
				Game.add_energy(p, -1)
			else:
				p.spend_any_commons(3, Game.rng)
			ActionCards.level_up(p, "craft")
			_toast("Crafting Action Card leveled up to Lvl %d!" % ActionCards.get_level(p, "craft"))
			_finish_main_action()
		])
	if entries.is_empty():
		_toast("Nothing craftable here. (Craft Lvl %d)" % craft_lvl)
		return
	entries.append(["Never mind", _close_modal])
	var body_txt := "Materials decide quality:\n%s" % ActionCards.get_perks_text("craft", craft_lvl)
	_show_modal("Building & Crafting (Lvl %d)" % craft_lvl, body_txt, entries)


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


# ----------------------------------------------------------------- creatures & wildlife

func _do_creatures(p: PlayerState) -> void:
	action_taken = "creatures"
	var tile: IslandTile = Game.board.get_tile(p.pos)
	var clvl := ActionCards.get_level(p, "creatures")
	var entries: Array = []
	var creature := Game.decks.creature_for(tile.element_id, tile.tier)
	if not creature.is_empty():
		entries.append(["Track Creature (%s)" % String(creature.get("name", "Creature")), func() -> void:
			_close_modal()
			_resolve_creature(creature, p, tile)
			_finish_main_action()
		])
	if clvl >= 4:
		entries.append(["Familiar Commune (+1⚡)", func() -> void:
			_close_modal()
			Game.add_energy(p, 1)
			_toast("Your familiar hums with life: +1⚡.")
			_finish_main_action()
		])
	if clvl < 5 and (p.energy >= 1 or p.commons_count() >= 3):
		entries.append(["Empower Creatures Card (Level Up)", func() -> void:
			_close_modal()
			if p.energy >= 1:
				Game.add_energy(p, -1)
			else:
				p.spend_any_commons(3, Game.rng)
			ActionCards.level_up(p, "creatures")
			_toast("Creatures Action Card leveled up to Lvl %d!" % ActionCards.get_level(p, "creatures"))
			_finish_main_action()
		])
	entries.append(["Step back", _close_modal])
	_show_modal("Creatures & Wildlife (Lvl %d)" % clvl, "Observe and commune with the living island:\n%s" % ActionCards.get_perks_text("creatures", clvl), entries)


# ----------------------------------------------------------------- magic & learning

func _open_magic_menu(p: PlayerState) -> void:
	var mlvl := ActionCards.get_level(p, "magic")
	var entries: Array = []
	entries.append(["Cast Signature Ability", func() -> void:
		_close_modal()
		_cast_signature(p)
	])
	if p.meditated:
		entries.append(["Learn a Skill Perk", func() -> void:
			_close_modal()
			_open_learn(p)
		])
	if mlvl < 5 and (p.energy >= 1 or p.commons_count() >= 3):
		entries.append(["Empower Magic Card (Level Up)", func() -> void:
			_close_modal()
			if p.energy >= 1:
				Game.add_energy(p, -1)
			else:
				p.spend_any_commons(3, Game.rng)
			ActionCards.level_up(p, "magic")
			_toast("Magic/Learn Action Card leveled up to Lvl %d!" % ActionCards.get_level(p, "magic"))
			_finish_main_action()
		])
	entries.append(["Step back", _close_modal])
	_show_modal("Magic & Learning (Lvl %d)" % mlvl, "Channel elemental power or expand your knowledge:\n%s" % ActionCards.get_perks_text("magic", mlvl), entries)


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


# ----------------------------------------------------------------- learn & skill tree

func _open_learn(p: PlayerState) -> void:
	var magic_lvl := ActionCards.get_level(p, "magic")
	var learnable := SkillTree.get_learnable_skills(p, Game.decks.skills)
	var entries: Array = []
	for s in learnable:
		var skill: Dictionary = s
		var costs := SkillTree.get_cost(p, skill)
		var ce_cost: int = costs["ce"]
		var energy_cost: int = costs["energy"]
		var cost_str := "%d CE" % ce_cost
		if energy_cost > 0:
			cost_str += " + %d⚡" % energy_cost
		var tier_str := String(skill.get("tier", "common")).capitalize()
		var sname := String(skill.get("name", ""))
		var sdesc := String(skill.get("desc", ""))
		if SkillTree.can_learn(p, skill):
			entries.append(["[%s] %s (%s) — %s" % [tier_str, sname, cost_str, sdesc], _learn_pick.bind(p, skill)])
		else:
			entries.append(["(Need %s) [%s] %s" % [cost_str, tier_str, sname], func() -> void:
				_toast("Requires %s and prerequisite skills." % cost_str)
			])
	if entries.is_empty():
		_toast("All available skills in this branch already mastered!")
		return
	entries.append(["Never mind", _close_modal])
	_show_modal("Skill Tree (Magic Lvl %d)" % magic_lvl, "Meditation opens the mind. Master new perks:\n" + ActionCards.get_perks_text("magic", magic_lvl), entries)


func _learn_pick(p: PlayerState, skill: Dictionary) -> void:
	_close_modal()
	action_taken = "magic"
	if SkillTree.learn_skill(p, skill, Game.rng):
		_toast("Learned: %s!" % String(skill.get("name", "Skill")))
		_finish_main_action()
	else:
		_toast("Could not learn skill (materials or energy short).")


# ----------------------------------------------------------------- guardian & association

func _do_quest(p: PlayerState) -> void:
	var tile: IslandTile = Game.board.get_tile(p.pos)
	var is_guardian_tile := tile.has_guardian or tile.tier == 3
	var sanctum := tile.tier == 3
	var glvl := ActionCards.get_level(p, "guardian")
	var bonus_vp := 1 if glvl >= 2 else 0
	var entries: Array = []

	if is_guardian_tile:
		if p.has_item("offering_bundle"):
			entries.append(["★ Make an Offering (+2 Light, +%d VP, −1 Rage)" % (4 + bonus_vp if sanctum else 2 + bonus_vp), _quest_offer.bind(p, sanctum)])
		# Catalog relics (content drop) can be laid on the altar too.
		var relic_seen: Array = []
		for id in p.items:
			var it := Game.decks.item_def(String(id))
			if String(it.get("type", "")) == "relic" and not relic_seen.has(String(id)):
				relic_seen.append(String(id))
				entries.append(["✧ Offer %s (+%d VP, +1 Light)" % [String(it.get("name", id)), int(it.get("offer_vp", 0))], _offer_relic_pick.bind(p, String(id))])
		# Bottleneck trial (content drop): the island tests you at its sites,
		# but only so many times per journey (balance cap, config wild).
		var trial := Game.decks.bottleneck_for(tile.element_id, tile.axial)
		var trial_cap := int(Game.decks.config.get("wild", {}).get("trials_per_player", 2))
		if not trial.is_empty() and not p.trials_done.has(String(trial.get("id", ""))) and p.trials_done.size() < trial_cap:
			entries.append(["⚖ Face the Island's Trial…", _open_trial.bind(p, trial)])
		if Duality.corrupt_gate_open(Game.band_of(p)):
			entries.append(["☠ Defile the site (−3 Light, +2 VP, +1 Rage)", _quest_defile.bind(p)])

	if glvl < 5 and (p.energy >= 1 or p.commons_count() >= 3):
		entries.append(["Empower Any Action Card (Worker Placement)", _open_action_level_up.bind(p)])

	entries.append(["⚅ Call Quest Redraw Vote", _on_call_quest_redraw_vote.bind(p)])
	entries.append(["Close", _close_modal])

	var q_lines: Array = ["Guardian & Community (Lvl %d)\n%s\n\nActive Island Quests:" % [glvl, ActionCards.get_perks_text("guardian", glvl)]]
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
	_show_modal("Guardian / Association", "\n".join(q_lines), entries)


func _open_action_level_up(p: PlayerState) -> void:
	_close_modal()
	var entries: Array = []
	for aid in ActionCards.ACTION_IDS:
		var lvl := ActionCards.get_level(p, aid)
		if lvl < 5:
			var aname := String(ActionCards.ACTION_NAMES.get(aid, aid))
			entries.append(["%s: Lvl %d -> Lvl %d" % [aname, lvl, lvl + 1], func() -> void:
				_close_modal()
				if p.energy >= 1:
					Game.add_energy(p, -1)
				else:
					p.spend_any_commons(3, Game.rng)
				ActionCards.level_up(p, aid)
				_toast("%s leveled up to Lvl %d!" % [aname, lvl + 1])
				_finish_main_action()
			])
	entries.append(["Cancel", _close_modal])
	_show_modal("Empower Action Card", "Spend 1⚡ or 3 Commons to level up an action:", entries)


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


func _offer_relic_pick(p: PlayerState, item_id: String) -> void:
	_close_modal()
	var vp := Game.offer_relic(p, item_id)
	if vp > 0:
		action_taken = "guardian"
		_toast("✧ The Guardian accepts the relic. +%d VP, +1 Light." % vp)
		_finish_main_action()


## Bottleneck trial (content drop): a dual-path quest posed at a Guardian site.
func _open_trial(p: PlayerState, trial: Dictionary) -> void:
	_close_modal()
	var lp: Dictionary = trial.get("light", {})
	var dp: Dictionary = trial.get("dark", {})
	var body := "%s\n\n☀ The Way of Harmony — deposit %d commons:\n%s\n→ +%d VP, +%d Light, %s\n\n☠ The Way of Force — free, but the island remembers:\n%s\n→ +%d VP, %d Light, +%d Rage, %s" % [
		String(trial.get("desc", "")),
		int(lp.get("cost_commons", 5)), String(lp.get("objective", "")),
		int(lp.get("vp", 0)), int(lp.get("light", 0)), Game.decks.display_name_of(String(lp.get("item", ""))),
		String(dp.get("objective", "")),
		int(dp.get("vp", 0)), int(dp.get("light", 0)), int(dp.get("rage", 2)), Game.decks.display_name_of(String(dp.get("item", ""))),
	]
	var entries: Array = []
	if p.commons_count() >= int(lp.get("cost_commons", 5)):
		entries.append(["☀ Resolve in harmony (%d commons)" % int(lp.get("cost_commons", 5)), _trial_resolve.bind(p, trial, false)])
	else:
		body += "\n\n(You lack the %d commons for the harmonious way.)" % int(lp.get("cost_commons", 5))
	entries.append(["☠ Force it", _trial_resolve.bind(p, trial, true)])
	entries.append(["Step back", _close_modal])
	_show_modal("⚖ %s" % String(trial.get("title", "The Island's Trial")), body, entries)


func _trial_resolve(p: PlayerState, trial: Dictionary, dark: bool) -> void:
	_close_modal()
	if not Game.resolve_bottleneck(p, trial, dark):
		_toast("The trial slips away unresolved.")
		return
	action_taken = "guardian"
	var path: Dictionary = trial.get("dark" if dark else "light", {})
	if dark:
		_toast("☠ Forced. +%d VP — but the island's Light drains (%d) and its Rage grows." % [int(path.get("vp", 0)), int(path.get("light", 0))])
	else:
		_toast("☀ Resolved in harmony! +%d VP, +%d Light." % [int(path.get("vp", 0)), int(path.get("light", 0))])
	_finish_main_action()


# ================================================================= ENCOUNTERS

func _resolve_creature(creature: Dictionary, p: PlayerState, tile: IslandTile) -> void:
	if creature.is_empty():
		return
	var band := CreatureEngine.effective_band(p, creature)
	var cname := String(creature.get("name", "A creature"))
	var cid := String(creature.get("id", "")).to_lower()
	var f := int(creature.get("f", 4))
	var demand: Dictionary = creature.get("demand", {})
	var demand_txt := _demand_text(demand)
	var entries: Array = []
	var body := "Fight Rating: F%d  •  Demand: %s" % [f, demand_txt]
	
	var k_inter := CreatureEngine.get_karma_interaction(creature, band)
	if not k_inter.is_empty():
		var flavor := String(k_inter.get("flavor", ""))
		if flavor != "":
			body = flavor

	var field_move := String(creature.get("field_move", ""))
	if field_move != "":
		body += "\n\n✦ Field Ability: %s" % field_move
		entries.append(["Activate %s" % field_move, func() -> void:
			_close_modal()
			var msg := CreatureEngine.execute_field_move(p, creature, tile, Game.rng)
			_toast(msg)
		])

	var flavor: Dictionary = creature.get("flavor", {})
	match band:
		Duality.Band.MAX_LIGHT, Duality.Band.LIGHT:
			# Wild roster: the Kind band gets the smaller "reward" effect, Radiant the full gift.
			var effect: Dictionary = creature.get("gift", {})
			if band == Duality.Band.LIGHT and creature.has("reward"):
				effect = creature.get("reward", {})
			var gift_desc := CreatureEngine.apply_effect(p, effect, Game.rng)
			if not k_inter.is_empty() and k_inter.has("item_reward"):
				gift_desc = String(k_inter.get("item_reward", gift_desc))
			body += "\n\nIt greets you in pure harmony — its Gift is yours:\n★ %s" % gift_desc
			var f_line := String(flavor.get("radiant" if band == Duality.Band.MAX_LIGHT else "kind", ""))
			if f_line != "":
				body += "\n%s" % f_line
			if CreatureEngine.can_fulfill_demand(p, creature, band):
				entries.append(["Commune deeper (pay demand · +1 Light)", _befriend.bind(p, creature, tile)])
		Duality.Band.NEUTRAL:
			body += "\n\nIt offers its Demand as a trial of balance: meet it, commune, or fight."
			if flavor.has("neutral"):
				body += "\n%s" % String(flavor["neutral"])
			if CreatureEngine.can_fulfill_demand(p, creature, band):
				entries.append(["Meet the Demand (+1 Light, claim Gift)", _befriend.bind(p, creature, tile)])
			if p.energy >= 1:
				entries.append(["Soothe with Spirit (1⚡ · claim Gift)", func() -> void:
					_close_modal()
					Game.add_energy(p, -1)
					var gift_desc := CreatureEngine.apply_effect(p, creature.get("gift", {}), Game.rng)
					Game.shift_light(p, "care_gift")
					_toast("Soothed: %s (+1 Light)." % gift_desc)
					EventBus.inventory_changed.emit(p.index)
				])
			entries.append(["Exploit it (−1 Light, +1 Rage, double cards)", _exploit_creature.bind(p, creature, tile)])
			entries.append(["Fight (fate draw vs F%d)" % f, _fight_menu.bind(p, creature, tile)])
		Duality.Band.DARK:
			body += "\n\nIt eyes you warily, growling in defense."
			if flavor.has("shadowed"):
				body += "\n%s" % String(flavor["shadowed"])
			if CreatureEngine.can_fulfill_demand(p, creature, band):
				entries.append(["Tribute (pay demand to appease)", _befriend.bind(p, creature, tile)])
			entries.append(["Endure the Bite", func() -> void:
				_close_modal()
				# Wild roster: the Shadowed band takes from your pack rather than striking.
				var take_effect: Dictionary = creature.get("take", creature.get("bite", {}))
				var bite_desc := CreatureEngine.apply_effect(p, take_effect, Game.rng, true)
				_toast("Bite suffered: %s." % bite_desc)
			])
			entries.append(["Fight back (fate draw vs F%d)" % f, _fight_menu.bind(p, creature, tile)])
		_: # MAX_DARK
			body += "\n\nIt sees the corruption in you and attacks on sight!"
			if flavor.has("dark"):
				body += "\n%s" % String(flavor["dark"])
			var bite_desc := CreatureEngine.apply_effect(p, creature.get("bite", {}), Game.rng, true)
			body += "\n⚠ Hostile Bite: %s" % bite_desc
			entries.append(["Fight back (+1 F for dark karma)", _fight_menu.bind(p, creature, tile)])

	entries.append(["Step away", _close_modal])

	# Try to find creature card illustration
	var card_path := "res://assets/cards/creatures/%s.png" % cid
	_show_modal(cname, body, entries, card_path)


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


func _befriend(p: PlayerState, creature: Dictionary, tile: IslandTile) -> void:
	_close_modal()
	var band := CreatureEngine.effective_band(p, creature)
	CreatureEngine.fulfill_demand(p, creature, Game.rng, band)
	Game.shift_light(p, "befriend_creature")
	var gift_desc := CreatureEngine.apply_effect(p, creature.get("gift", {}), Game.rng)
	var card := Game.decks.draw_card(tile.element_id, tile.tier)
	var extra := ""
	if not card.is_empty() and p.add_card(card):
		extra = " Found: [%s] %s." % [String(card["tier"]), Game.decks.display_name_of(String(card["id"]))]
	# A befriended wild creature works its field move on this tile (content drop).
	var field_txt := CreatureEngine.apply_field_move(p, creature, tile)
	if field_txt != "":
		_refresh_tile(tile.axial)
		extra += " " + field_txt
	_toast("Befriended! %s%s" % [gift_desc, extra])
	EventBus.inventory_changed.emit(p.index)


func _exploit_creature(p: PlayerState, creature: Dictionary, tile: IslandTile) -> void:
	_close_modal()
	Game.add_light(p, -1)
	Game.add_rage(1)
	var card := Game.decks.draw_card(tile.element_id, tile.tier)
	if not card.is_empty():
		p.add_card(card)
	var bite_desc := CreatureEngine.apply_effect(p, creature.get("bite", {}), Game.rng, true)
	_toast("Exploited (−1 Light, +1 Rage). Bite suffered: %s." % bite_desc)
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
		# Stronger creatures carry made things (content drop): item loot chance.
		if String(creature.get("tier", "common")) != "common" and Game.rng.randf() < 0.5:
			var it := Game.find_catalog_item(p, ["tool", "consumable"])
			if not it.is_empty():
				loot.append("[%s] %s" % [String(it["rarity"]), String(it["name"])])
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
				slow += 1
			p.slow_penalty += slow
			desc += "\n\nNext turn: −%d movement." % slow

	var ev_id := String(ev.get("id", "")).to_lower()
	var card_path := "res://assets/cards/events/%s.png" % ev_id
	_show_modal(title, desc, [["Continue", _close_modal]], card_path)
	EventBus.inventory_changed.emit(p.index)


# ================================================================= WILD DECK (content drop)

## A tile reveal drew from the Wild Deck. fate/ward cards go to the hand;
## encounter/loot cards resolve immediately through _apply_wild_ops.
func _resolve_wild_card(card: Dictionary, p: PlayerState, tile: IslandTile) -> void:
	if card.is_empty():
		return
	var kind := String(card.get("kind", ""))
	var cname := String(card.get("name", "A wild card"))
	var text := String(card.get("text", ""))
	if kind == "fate" or kind == "ward":
		var cap := int(Game.decks.config.get("wild", {}).get("hand_cap", 3))
		if p.wild_cards.size() >= cap:
			_show_modal("🃏 " + cname, text + "\n\nYour hands are full — the card blows away on the wind.", [["Continue", _close_modal]])
			return
		p.wild_cards.append(String(card.get("id", "")))
		_show_modal("🃏 " + cname, text + "\n\nAdded to your Wild Cards — play it from the Wild menu.", [["Continue", _close_modal]])
	else:
		var lines: Array = [text]
		_apply_wild_ops(card.get("ops", []), p, tile, lines)
		_show_modal(("☄ " if kind == "encounter" else "✦ ") + cname, "\n".join(lines), [["Continue", _close_modal]])
	EventBus.inventory_changed.emit(p.index)


## The Wild Deck op vocabulary (see data/wild_deck.json).
func _apply_wild_ops(ops: Array, p: PlayerState, tile: IslandTile, lines: Array) -> void:
	for op_v in ops:
		var op: Dictionary = op_v
		match String(op.get("op", "")):
			"gain_common":
				var id := String(op.get("id", ""))
				var n := int(op.get("n", 1))
				for i in n:
					p.add_common(id if id != "" else Game.decks.random_common(tile.element_id), 1)
				lines.append("+%d %s." % [n, Game.decks.display_name_of(id) if id != "" else "common(s)"])
			"gain_card":
				p.add_card({"id": String(op.get("id", "")), "tier": String(op.get("tier", "uncommon")), "element": String(op.get("element", tile.element_id))})
				lines.append("Found: [%s] %s." % [String(op.get("tier", "uncommon")), Game.decks.display_name_of(String(op.get("id", "")))])
			"energy":
				Game.add_energy(p, int(op.get("n", 0)))
				lines.append("Energy %+d." % int(op.get("n", 0)))
			"light":
				Game.add_light(p, int(op.get("n", 0)))
				lines.append("Light %+d." % int(op.get("n", 0)))
			"slow":
				p.slow_penalty += int(op.get("n", 1))
				lines.append("Next turn: −%d movement." % int(op.get("n", 1)))
			"rage":
				Game.add_rage(int(op.get("n", 1)))
				lines.append("Island Rage %+d." % int(op.get("n", 1)))
			"chest":
				var it := Game.open_chest(p, tile.element_id == "spirit")
				if it.is_empty() or p.items.size() >= p.pack_size:
					p.add_common(Game.decks.random_common(tile.element_id), 1)
					lines.append("The chest holds only scraps (+1 common).")
				else:
					p.items.append(String(it["id"]))
					lines.append("The chest opens: [%s] %s!" % [String(it["rarity"]), String(it["name"])])
			"draw_ward":
				var ward := Game.wild_deck.draw_ward()
				var cap := int(Game.decks.config.get("wild", {}).get("hand_cap", 3))
				if not ward.is_empty() and p.wild_cards.size() < cap:
					p.wild_cards.append(String(ward["id"]))
					lines.append("A blessing answers: %s joins your Wild Cards." % String(ward["name"]))
				else:
					lines.append("The blessing stirs, but cannot reach you.")
			"creature":
				var el := String(op.get("element", tile.element_id))
				lines.append("Something stirs...")
				_close_modal()
				_resolve_creature(Game.decks.creature_for(el, tile.tier), p, tile)
				return
			"mirage":
				var r := int(op.get("radius", 2))
				var flipped := 0
				for axial in Game.board.tiles.keys():
					var t: IslandTile = Game.board.tiles[axial]
					if t.explored and t.tier < 3 and axial != p.pos and Hex.distance(p.pos, axial) <= r:
						t.explored = false
						_refresh_tile(axial)
						flipped += 1
				lines.append("The mirage swallows %d explored tile(s) — the island forgets them." % flipped)
			"dark_aggression":
				Game.dark_aggression_rounds = int(op.get("rounds", 2))
				lines.append("Every wild creature turns hostile for %d rounds!" % int(op.get("rounds", 2)))
			"craft_lock":
				p.craft_locked = true
				lines.append("Your next Craft action is locked.")
			"fate_check":
				var draw := Game.fate.draw(Game.band_of(p), Game.decks.canon.get("fate", {}))
				var value := int(draw["value"])
				var vs := int(op.get("vs", 4))
				if value >= vs:
					lines.append("Fate draw %d vs %d — you slip free!" % [value, vs])
				else:
					lines.append("Fate draw %d vs %d — it catches you." % [value, vs])
					_apply_wild_ops(op.get("fail", []), p, tile, lines)
			"if_band_kind":
				var band := Game.band_of(p)
				var kind_plus := band == Duality.Band.LIGHT or band == Duality.Band.MAX_LIGHT
				_apply_wild_ops(op.get("then", []) if kind_plus else op.get("else", []), p, tile, lines)
			"if_element":
				var els: Array = op.get("elements", [])
				_apply_wild_ops(op.get("then", []) if els.has(tile.element_id) else op.get("else", []), p, tile, lines)
			"unless_heart":
				if p.heart != String(op.get("heart", "")):
					_apply_wild_ops(op.get("ops", []), p, tile, lines)
				else:
					lines.append("Your %s heart knows these waters — no harm done." % p.heart)
			"unless_item":
				if not p.has_item(String(op.get("item", ""))):
					_apply_wild_ops(op.get("ops", []), p, tile, lines)
				else:
					lines.append("Your %s holds the cold at bay." % Game.decks.display_name_of(String(op.get("item", ""))))


## The Wild Cards menu: play held fate cards and wards.
func _open_wild_menu(p: PlayerState) -> void:
	if p.wild_cards.is_empty():
		_toast("No Wild Cards in hand — they turn up while exploring.")
		return
	var entries: Array = []
	var body_lines: Array = []
	for id in p.wild_cards.duplicate():
		var card: Dictionary = Game.wild_deck.defs.get(String(id), {})
		if card.is_empty():
			continue
		var cname := String(card.get("name", id))
		body_lines.append("• %s — %s" % [cname, String(card.get("text", ""))])
		if String(card.get("kind", "")) == "ward":
			var band := Game.band_of(p)
			var kind_plus := band == Duality.Band.LIGHT or band == Duality.Band.MAX_LIGHT
			if kind_plus:
				entries.append(["Invoke: " + cname, _play_ward.bind(p, String(id))])
			else:
				body_lines.append("   (needs Kind or Radiant karma to invoke)")
		else:
			entries.append(["Play: " + cname, _play_fate_card.bind(p, String(id))])
	entries.append(["Close", _close_modal])
	_show_modal("🃏 Wild Cards (%d/%d)" % [p.wild_cards.size(), int(Game.decks.config.get("wild", {}).get("hand_cap", 3))], "\n".join(body_lines), entries)


func _play_ward(p: PlayerState, id: String) -> void:
	_close_modal()
	var card: Dictionary = Game.wild_deck.defs.get(id, {})
	p.wild_cards.erase(id)
	p.wards[String(card.get("ward", id))] = int(card.get("turns", 1))
	_toast("✨ %s takes hold." % String(card.get("name", id)))
	_refresh_hud()


func _play_fate_card(p: PlayerState, id: String) -> void:
	_close_modal()
	var card: Dictionary = Game.wild_deck.defs.get(id, {})
	match String(card.get("play", "")):
		"double_down":
			if action_taken != "explore":
				_toast("Double Down works on Explore/Gather — take that action first.")
				return
			p.wild_cards.erase(id)
			turn_over = false
			action_taken = ""
			_toast("🃏 Double Down! The island holds its breath — act again.")
		"unshackled":
			p.wild_cards.erase(id)
			p.slow_penalty = 0
			if not turn_over and action_taken != "":
				action_taken = ""
				mode = "idle"
				_toast("🃏 Unshackled — your action choice is free again, and your stride is light.")
			else:
				_toast("🃏 Unshackled — every lock on your movement falls away.")
		"focus_shift":
			if turn_over or action_taken == "":
				_toast("Focus Shift is for switching an action in progress.")
				return
			p.wild_cards.erase(id)
			action_taken = ""
			mode = "idle"
			_toast("🃏 Focus Shift — you switch freely; the island waits without judgment.")
		"swift_step":
			if mode != "explore":
				_toast("Swift Step is played during Explore, when the extra strides count.")
				return
			p.wild_cards.erase(id)
			moves_left += 2
			_toast("🃏 Swift Step — +2 movement now.")
	_refresh_hud()


# ================================================================= MODAL / WIN

func _show_modal(title: String, body: String, entries: Array, card_image_path: String = "") -> void:
	modal_title.text = title
	modal_body.text = body
	
	if card_image_path != "" and ResourceLoader.exists(card_image_path):
		var tex: Texture2D = load(card_image_path)
		modal_card_img.texture = tex
		modal_card_img.visible = true
	else:
		modal_card_img.texture = null
		modal_card_img.visible = false

	for child in modal_buttons.get_children():
		child.queue_free()

	for entry in entries:
		var b := Button.new()
		b.text = String(entry[0])
		b.custom_minimum_size = Vector2(360, 46)
		var is_cancel := ("cancel" in b.text.to_lower() or "never mind" in b.text.to_lower() or "step away" in b.text.to_lower() or "close" in b.text.to_lower())
		var is_dark := ("exploit" in b.text.to_lower() or "defile" in b.text.to_lower() or "drain" in b.text.to_lower() or "raid" in b.text.to_lower())
		var variant := "danger" if is_dark else ("secondary" if is_cancel else "primary")
		UITheme.apply_button_style(b, variant, Color("3a8c56"), 16)
		b.pressed.connect(entry[1])
		modal_buttons.add_child(b)

	modal_root.visible = true


func _close_modal() -> void:
	modal_root.visible = false
	_refresh_hud()


func _on_game_won(index: int, way: String) -> void:
	if index == -2 or way == "shared":
		winner_label.text = "★ Shared Victory! ★\n\nIn the spirit of harmony and island balance,\nthe wanderers finish equal in kindness and skill.\nCooperation was the journey all along."
		winner_overlay.visible = true
		return
	if index < 0 or index >= Game.players.size():
		return
	var p: PlayerState = Game.players[index]
	match way:
		"enlightened":
			winner_label.text = "%s\nwalks the Enlightened Path.\nThe island keeps them as one of its own." % p.display_name
		"capable":
			winner_label.text = "%s\nwalks the Capable Path.\nSkilled hands, and light enough to trust." % p.display_name
		"endgame":
			winner_label.text = "The seasons turn.\n%s came furthest on their path.\nThe island remembers everyone." % p.display_name
		"dark":
			winner_label.text = "%s\ntakes the island in shadow.\nA hollow kind of crown." % p.display_name
		_:
			winner_label.text = "%s claims victory on the island!" % p.display_name
	winner_overlay.visible = true


# ================================================================= INPUT & PLATFORM

var _touch_points: Dictionary = {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if modal_root != null and modal_root.visible:
			_close_modal()
		elif winner_overlay != null and winner_overlay.visible:
			_back_to_menu()
		else:
			_show_modal("Return to Shore?", "Leave the current session and return to the main menu?", [
				["Return to Menu", _back_to_menu],
				["Keep Playing", _close_modal],
			])


func _unhandled_input(event: InputEvent) -> void:
	if winner_overlay != null and winner_overlay.visible:
		return
	if modal_root != null and modal_root.visible:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touch_points[st.index] = st.position
			if _touch_points.size() == 1:
				_pressing = true
				_drag_moved = false
		else:
			_touch_points.erase(st.index)
			if _touch_points.is_empty():
				if _pressing and not _drag_moved:
					_handle_tap()
				_pressing = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touch_points[sd.index] = sd.position
		if _touch_points.size() >= 2:
			# Mobile pinch-to-zoom
			var pkeys := _touch_points.keys()
			var p1: Vector2 = _touch_points[pkeys[0]]
			var p2: Vector2 = _touch_points[pkeys[1]]
			var cur_dist := p1.distance_to(p2)
			var prev_dist := (p1 - sd.relative).distance_to(p2)
			if prev_dist > 0.0:
				var factor := cur_dist / prev_dist
				_zoom(factor)
		elif _pressing:
			if sd.relative.length() > 2.0:
				_drag_moved = true
			camera.position -= sd.relative / camera.zoom.x
	elif event is InputEventMouseButton:
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


func _back_to_menu() -> void:
	Game.started = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
