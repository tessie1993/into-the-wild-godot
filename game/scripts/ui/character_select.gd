extends Control
## Character Selection Screen — Storybook Wanderer Showcase.
## Allows 1-4 players to choose distinct wanderers before washing ashore.
## Displays high-res character card portraits, attributes, affinities, perks, and weaknesses.

const CHAR_THEME_COLORS: Dictionary = {
	"cartographer": Color("3b82f6"),
	"botanist": Color("2f7d4a"),
	"blacksmith": Color("b3452e"),
	"outcast": Color("8b5cf6"),
}

var _player_count := 2
var _current_picking_player := 0
var _chosen_characters: Array[String] = []  ## player_index -> character_id

var _header_label: Label
var _sub_label: Label
var _cards_container: HBoxContainer
var _selection_status_label: Label
var _start_button: Button
var _card_buttons: Dictionary = {}          ## character_id -> Button
var _card_panels: Dictionary = {}           ## character_id -> PanelContainer
var _decks: Decks


func _ready() -> void:
	_player_count = Game.pending_player_count if Game.pending_player_count > 0 else 2
	_chosen_characters.resize(_player_count)
	for i in _player_count:
		_chosen_characters[i] = ""
	
	_decks = Decks.new(Game.rng)
	_build_ui()
	_update_view()


func _build_ui() -> void:
	# 1. Dark Atmospheric Background
	var bg := ColorRect.new()
	bg.color = UITheme.COLOR_BG_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Ambient Floating Spirit Motes
	UITheme.create_ambient_motes(self, 35)

	# 3. Main Layout Margin
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(root_vbox)

	# --- Header Banner
	var title_panel := PanelContainer.new()
	var t_style := UITheme.make_panel_style(
		Color(0.08, 0.12, 0.09, 0.9),
		Color(0.35, 0.52, 0.40, 0.5),
		2,
		14,
		12
	)
	title_panel.add_theme_stylebox_override("panel", t_style)
	root_vbox.add_child(title_panel)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 4)
	title_panel.add_child(title_box)

	_header_label = Label.new()
	_header_label.text = "CHOOSE YOUR WANDERERS"
	_header_label.add_theme_font_size_override("font_size", 32)
	_header_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(_header_label)

	_sub_label = Label.new()
	_sub_label.add_theme_font_size_override("font_size", 18)
	_sub_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_EMERALD)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(_sub_label)

	# --- Cards Row Scroll
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var center_cards := CenterContainer.new()
	center_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_cards)

	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 24)
	center_cards.add_child(_cards_container)

	for c in _decks.characters:
		var card := _create_character_card(c)
		_cards_container.add_child(card)

	# --- Bottom Navigation Bar
	var bottom_panel := PanelContainer.new()
	var b_style := UITheme.make_panel_style(
		Color(0.08, 0.12, 0.09, 0.9),
		Color(0.35, 0.52, 0.40, 0.5),
		2,
		14,
		12
	)
	bottom_panel.add_theme_stylebox_override("panel", b_style)
	root_vbox.add_child(bottom_panel)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 20)
	bottom_panel.add_child(bottom_bar)

	var back_btn := Button.new()
	back_btn.text = "◂ Back to Shore"
	back_btn.custom_minimum_size = Vector2(200, 52)
	UITheme.apply_button_style(back_btn, "secondary", Color("4a7c59"), 18)
	back_btn.pressed.connect(_on_back_pressed)
	bottom_bar.add_child(back_btn)

	_selection_status_label = Label.new()
	_selection_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_status_label.add_theme_font_size_override("font_size", 18)
	_selection_status_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	_selection_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_bar.add_child(_selection_status_label)

	_start_button = Button.new()
	_start_button.text = "Wash Ashore ▸"
	_start_button.custom_minimum_size = Vector2(220, 52)
	UITheme.apply_button_style(_start_button, "primary", Color("3a8c56"), 20)
	_start_button.pressed.connect(_on_start_pressed)
	bottom_bar.add_child(_start_button)


func _create_character_card(c: Dictionary) -> Control:
	var cid := String(c["id"])
	var cname := String(c["name"])
	var personality := String(c.get("personality", ""))
	var heart := String(c.get("heart", "")).capitalize()
	var cross := String(c.get("cross", "")).capitalize()
	var move := int(c.get("move", 3))
	var pack := int(c.get("pack_size", 5))
	var hand := int(c.get("hand_limit", 7))
	var perk: Dictionary = c.get("perk", {})
	var weakness: Dictionary = c.get("weakness", {})
	var accent: Color = CHAR_THEME_COLORS.get(cid, Color("4a7c59"))

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 680)
	
	var style := UITheme.make_panel_style(
		Color(0.09, 0.13, 0.10, 0.96),
		Color(accent.r, accent.g, accent.b, 0.65),
		2,
		14,
		16
	)
	panel.add_theme_stylebox_override("panel", style)
	_card_panels[cid] = panel

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 1. Top Character Portrait Frame
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(328, 220)
	portrait_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var port_style := StyleBoxFlat.new()
	port_style.bg_color = Color(0.05, 0.08, 0.06, 1.0)
	port_style.corner_radius_top_left = 10
	port_style.corner_radius_top_right = 10
	port_style.corner_radius_bottom_right = 10
	port_style.corner_radius_bottom_left = 10
	port_style.border_width_left = 1
	port_style.border_width_top = 1
	port_style.border_width_right = 1
	port_style.border_width_bottom = 1
	port_style.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	portrait_container.add_theme_stylebox_override("panel", port_style)
	vbox.add_child(portrait_container)

	var portrait_tex := TextureRect.new()
	portrait_tex.set_anchors_preset(PRESET_FULL_RECT)
	portrait_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_tex.mouse_filter = MOUSE_FILTER_IGNORE
	var card_img_path := "res://assets/cards/characters/%s.png" % cid
	if ResourceLoader.exists(card_img_path):
		var tex: Texture2D = load(card_img_path)
		portrait_tex.texture = tex
	portrait_container.add_child(portrait_tex)

	# 2. Name & Title
	var lbl_name := Label.new()
	lbl_name.text = cname
	lbl_name.add_theme_font_size_override("font_size", 22)
	lbl_name.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_name)

	var lbl_desc := Label.new()
	lbl_desc.text = personality
	lbl_desc.add_theme_font_size_override("font_size", 13)
	lbl_desc.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_desc)

	# 3. Affinities Row (Pills)
	var aff_box := HBoxContainer.new()
	aff_box.alignment = BoxContainer.ALIGNMENT_CENTER
	aff_box.add_theme_constant_override("separation", 14)
	vbox.add_child(aff_box)

	var lbl_heart := Label.new()
	lbl_heart.text = "♥ %s Affinity" % heart
	lbl_heart.add_theme_font_size_override("font_size", 13)
	lbl_heart.add_theme_color_override("font_color", UITheme.COLOR_TEXT_EMERALD)
	aff_box.add_child(lbl_heart)

	var lbl_cross := Label.new()
	lbl_cross.text = "✗ %s Aversion" % cross
	lbl_cross.add_theme_font_size_override("font_size", 13)
	lbl_cross.add_theme_color_override("font_color", UITheme.COLOR_TEXT_CRIMSON)
	aff_box.add_child(lbl_cross)

	# 4. Stats Row
	var stats_panel := PanelContainer.new()
	var stat_style := UITheme.make_panel_style(
		Color(0.06, 0.09, 0.07, 0.8),
		Color(0.28, 0.38, 0.30, 0.4),
		1,
		8,
		6
	)
	stats_panel.add_theme_stylebox_override("panel", stat_style)
	vbox.add_child(stats_panel)

	var stats_lbl := Label.new()
	stats_lbl.text = "🏃 Move: %d   🎒 Pack: %d   ✋ Hand: %d" % [move, pack, hand]
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_lbl.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(stats_lbl)

	# 5. Perk Banner
	var perk_panel := PanelContainer.new()
	var p_style := UITheme.make_panel_style(
		Color(0.08, 0.16, 0.10, 0.8),
		Color(0.35, 0.70, 0.45, 0.6),
		1,
		8,
		8
	)
	perk_panel.add_theme_stylebox_override("panel", p_style)
	vbox.add_child(perk_panel)

	var perk_vbox := VBoxContainer.new()
	perk_vbox.add_theme_constant_override("separation", 2)
	perk_panel.add_child(perk_vbox)

	var perk_title := Label.new()
	perk_title.text = "✦ Perk: %s" % String(perk.get("name", ""))
	perk_title.add_theme_font_size_override("font_size", 13)
	perk_title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_EMERALD)
	perk_vbox.add_child(perk_title)

	var perk_desc := Label.new()
	perk_desc.text = String(perk.get("desc", ""))
	perk_desc.add_theme_font_size_override("font_size", 11)
	perk_desc.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	perk_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	perk_vbox.add_child(perk_desc)

	# 6. Weakness Banner
	var weak_panel := PanelContainer.new()
	var w_style := UITheme.make_panel_style(
		Color(0.18, 0.09, 0.09, 0.8),
		Color(0.70, 0.35, 0.35, 0.6),
		1,
		8,
		8
	)
	weak_panel.add_theme_stylebox_override("panel", w_style)
	vbox.add_child(weak_panel)

	var weak_vbox := VBoxContainer.new()
	weak_vbox.add_theme_constant_override("separation", 2)
	weak_panel.add_child(weak_vbox)

	var weak_title := Label.new()
	weak_title.text = "⚠ Weakness: %s" % String(weakness.get("name", ""))
	weak_title.add_theme_font_size_override("font_size", 13)
	weak_title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_CRIMSON)
	weak_vbox.add_child(weak_title)

	var weak_desc := Label.new()
	weak_desc.text = String(weakness.get("desc", ""))
	weak_desc.add_theme_font_size_override("font_size", 11)
	weak_desc.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	weak_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weak_vbox.add_child(weak_desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 7. Select Button
	var btn := Button.new()
	btn.text = "Select"
	btn.custom_minimum_size = Vector2(0, 46)
	UITheme.apply_button_style(btn, "primary", accent, 17)
	btn.pressed.connect(_on_character_picked.bind(cid))
	vbox.add_child(btn)
	_card_buttons[cid] = btn

	return panel


func _update_view() -> void:
	var current_p_color: Color = UITheme.PLAYER_COLORS[_current_picking_player % UITheme.PLAYER_COLORS.size()]
	_sub_label.text = "Player %d of %d — Select your Wanderer Identity" % [_current_picking_player + 1, _player_count]
	_sub_label.add_theme_color_override("font_color", current_p_color)

	var status_parts: Array = []
	for i in _player_count:
		var cid: String = _chosen_characters[i]
		if cid != "":
			var cname := String(_decks.characters_by_id.get(cid, {}).get("name", cid))
			status_parts.append("Player %d: %s" % [i + 1, cname])
		else:
			status_parts.append("Player %d: [Choosing...]" % [i + 1])
	_selection_status_label.text = "  ✦  ".join(status_parts)

	var all_selected := true
	for i in _player_count:
		if _chosen_characters[i] == "":
			all_selected = false
			break
	_start_button.disabled = not all_selected

	# Update card buttons and highlights
	for cid in _card_buttons.keys():
		var btn: Button = _card_buttons[cid]
		var panel: PanelContainer = _card_panels[cid]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		
		var claimed_by := -1
		for i in _player_count:
			if _chosen_characters[i] == cid:
				claimed_by = i
				break
		
		if claimed_by >= 0:
			var col: Color = UITheme.PLAYER_COLORS[claimed_by % UITheme.PLAYER_COLORS.size()]
			btn.text = "Chosen by Player %d ✓" % (claimed_by + 1)
			btn.disabled = (claimed_by != _current_picking_player)
			style.border_color = col
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
			style.shadow_color = Color(col.r, col.g, col.b, 0.4)
			style.shadow_size = 12
		else:
			btn.text = "Select as Player %d" % (_current_picking_player + 1)
			btn.disabled = false
			var default_accent: Color = CHAR_THEME_COLORS.get(cid, Color("4a7c59"))
			style.border_color = Color(default_accent.r, default_accent.g, default_accent.b, 0.5)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.shadow_color = Color(0, 0, 0, 0.35)
			style.shadow_size = 6


func _on_character_picked(cid: String) -> void:
	_chosen_characters[_current_picking_player] = cid
	var next_p := -1
	for i in range(_current_picking_player + 1, _player_count):
		if _chosen_characters[i] == "":
			next_p = i
			break
	if next_p == -1:
		for i in _player_count:
			if _chosen_characters[i] == "":
				next_p = i
				break
	if next_p != -1:
		_current_picking_player = next_p
	_update_view()


func _on_start_pressed() -> void:
	var final_characters: Array[String] = []
	for cid in _chosen_characters:
		final_characters.append(cid)
	Game.new_game(_player_count, final_characters)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
