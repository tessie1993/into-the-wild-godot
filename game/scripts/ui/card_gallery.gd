class_name CardGallery
extends Control
## CardGallery — Storybook Island Compendium & Tome.
## Allows players and developers to explore, search, filter, flip, and inspect
## every rendered card asset and dataset across the entire game.

const CARD_VIEW_SCRIPT: GDScript = preload("res://scripts/ui/card_view.gd")

var _all_cards: Array[Dictionary] = []
var _filtered_cards: Array[Dictionary] = []
var _current_filter: String = "all"
var _search_query: String = ""

var _grid_container: GridContainer
var _count_label: Label
var _search_edit: LineEdit
var _filter_buttons: Dictionary = {}

# Modal Inspector
var _modal_overlay: ColorRect
var _inspect_panel: PanelContainer
var _inspect_card_view: Control
var _inspect_title: Label
var _inspect_category: Label
var _inspect_desc: RichTextLabel
var _inspect_flavor: Label
var _inspect_meta: Label
var _current_inspect_data: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_load_all_cards()
	_apply_filters()


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# 1. Dark Atmospheric Forest Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = UITheme.COLOR_BG_DEEP
	add_child(bg)

	# 2. Ambient Floating Spirit Motes
	UITheme.create_ambient_motes(self, 30)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.offset_left = 28
	main_vbox.offset_top = 20
	main_vbox.offset_right = -28
	main_vbox.offset_bottom = -20
	main_vbox.add_theme_constant_override("separation", 14)
	add_child(main_vbox)

	# 3. Header Bar Panel
	var header_panel := PanelContainer.new()
	var h_style := UITheme.make_panel_style(
		Color(0.08, 0.12, 0.09, 0.92),
		Color(0.35, 0.52, 0.40, 0.5),
		2,
		12,
		10
	)
	header_panel.add_theme_stylebox_override("panel", h_style)
	main_vbox.add_child(header_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	header_panel.add_child(header)

	var back_btn := Button.new()
	back_btn.text = "◂ Main Menu"
	back_btn.custom_minimum_size = Vector2(140, 42)
	UITheme.apply_button_style(back_btn, "secondary", Color("4a7c59"), 16)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "ISLAND COMPENDIUM & CARD ARCHIVE"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
	title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	_count_label = Label.new()
	_count_label.text = "Cards: 0"
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_EMERALD)
	header.add_child(_count_label)

	# 4. Filter Tabs & Search Bar Panel
	var control_panel := PanelContainer.new()
	var c_style := UITheme.make_panel_style(
		Color(0.06, 0.09, 0.07, 0.85),
		Color(0.28, 0.40, 0.32, 0.4),
		1,
		10,
		8
	)
	control_panel.add_theme_stylebox_override("panel", c_style)
	main_vbox.add_child(control_panel)

	var control_bar := HBoxContainer.new()
	control_bar.add_theme_constant_override("separation", 12)
	control_panel.add_child(control_bar)

	var filter_scroll := ScrollContainer.new()
	filter_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	filter_scroll.custom_minimum_size.y = 44

	var filter_box := HBoxContainer.new()
	filter_box.add_theme_constant_override("separation", 8)
	filter_scroll.add_child(filter_box)

	var categories := [
		{"id": "all", "label": "All Cards", "col": Color("7ce8a6")},
		{"id": "action", "label": "Actions", "col": Color("f2d06b")},
		{"id": "deck", "label": "Deck / Fate", "col": Color("5aa7d1")},
		{"id": "event", "label": "Events", "col": Color("e89a5c")},
		{"id": "quest", "label": "Quests", "col": Color("cfc4e8")},
		{"id": "skill", "label": "Skills", "col": Color("4ebd78")},
		{"id": "creatures", "label": "Creatures", "col": Color("2f7d4a")},
		{"id": "item", "label": "Items", "col": Color("b3452e")},
		{"id": "character", "label": "Characters", "col": Color("9a6ad1")},
	]

	for cat in categories:
		var btn := Button.new()
		btn.text = cat["label"]
		btn.toggle_mode = true
		btn.button_pressed = (cat["id"] == "all")
		btn.custom_minimum_size = Vector2(100, 36)
		_update_filter_button_style(btn, btn.button_pressed, cat["col"])
		btn.pressed.connect(_on_filter_button_pressed.bind(cat["id"]))
		filter_box.add_child(btn)
		_filter_buttons[cat["id"]] = {"btn": btn, "col": cat["col"]}

	control_bar.add_child(filter_scroll)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search cards, lore, mechanics..."
	_search_edit.custom_minimum_size = Vector2(280, 38)
	var search_style := UITheme.make_panel_style(
		Color(0.09, 0.13, 0.10, 0.95),
		Color(0.35, 0.48, 0.38, 0.6),
		1,
		8,
		8
	)
	_search_edit.add_theme_stylebox_override("normal", search_style)
	_search_edit.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	_search_edit.text_changed.connect(_on_search_changed)
	control_bar.add_child(_search_edit)

	# 5. Scrollable Card Grid
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(center)

	_grid_container = GridContainer.new()
	_grid_container.columns = 5
	_grid_container.add_theme_constant_override("h_separation", 24)
	_grid_container.add_theme_constant_override("v_separation", 28)
	center.add_child(_grid_container)

	main_vbox.add_child(scroll)

	# 6. Inspector Modal (hidden by default)
	_build_modal_inspector()


func _update_filter_button_style(btn: Button, is_active: bool, col: Color) -> void:
	var style := UITheme.make_pill_style(is_active, col)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_color_override("font_color", Color.WHITE if is_active else UITheme.COLOR_TEXT_MUTED)


func _build_modal_inspector() -> void:
	_modal_overlay = ColorRect.new()
	_modal_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_modal_overlay.color = Color(0.04, 0.06, 0.05, 0.88)
	_modal_overlay.visible = false
	_modal_overlay.gui_input.connect(_on_modal_overlay_input)
	add_child(_modal_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	_modal_overlay.add_child(center)

	_inspect_panel = PanelContainer.new()
	_inspect_panel.custom_minimum_size = Vector2(800, 520)
	var p_style := UITheme.make_panel_style(
		Color(0.10, 0.14, 0.12, 0.98),
		Color(0.85, 0.72, 0.35, 0.85),
		2,
		16,
		28
	)
	_inspect_panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(_inspect_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 32)
	_inspect_panel.add_child(hbox)

	# Left side: Interactive card preview
	var card_col := VBoxContainer.new()
	card_col.add_theme_constant_override("separation", 14)
	hbox.add_child(card_col)

	_inspect_card_view = CARD_VIEW_SCRIPT.new({}, true)
	_inspect_card_view.default_card_size = Vector2(250, 375)
	_inspect_card_view.custom_minimum_size = Vector2(250, 375)
	card_col.add_child(_inspect_card_view)

	var flip_btn := Button.new()
	flip_btn.text = "Flip Card ⟳"
	flip_btn.custom_minimum_size = Vector2(250, 42)
	UITheme.apply_button_style(flip_btn, "gold", Color("d4a337"), 17)
	flip_btn.pressed.connect(_on_inspect_flip_pressed)
	card_col.add_child(flip_btn)

	# Right side: Illuminated Details
	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 10)
	hbox.add_child(info_col)

	_inspect_title = Label.new()
	_inspect_title.add_theme_font_size_override("font_size", 24)
	_inspect_title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
	info_col.add_child(_inspect_title)

	_inspect_category = Label.new()
	_inspect_category.add_theme_font_size_override("font_size", 14)
	_inspect_category.add_theme_color_override("font_color", UITheme.COLOR_TEXT_EMERALD)
	info_col.add_child(_inspect_category)

	var sep := HSeparator.new()
	info_col.add_child(sep)

	_inspect_desc = RichTextLabel.new()
	_inspect_desc.size_flags_vertical = SIZE_EXPAND_FILL
	_inspect_desc.bbcode_enabled = true
	_inspect_desc.add_theme_font_size_override("normal_font_size", 15)
	_inspect_desc.add_theme_color_override("default_color", UITheme.COLOR_TEXT_LIGHT)
	info_col.add_child(_inspect_desc)

	_inspect_flavor = Label.new()
	_inspect_flavor.add_theme_font_size_override("font_size", 13)
	_inspect_flavor.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 0.9))
	_inspect_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_col.add_child(_inspect_flavor)

	_inspect_meta = Label.new()
	_inspect_meta.add_theme_font_size_override("font_size", 12)
	_inspect_meta.add_theme_color_override("font_color", Color(0.55, 0.65, 0.60, 0.8))
	info_col.add_child(_inspect_meta)

	var close_btn := Button.new()
	close_btn.text = "Close Tome"
	close_btn.custom_minimum_size = Vector2(130, 40)
	close_btn.size_flags_horizontal = SIZE_SHRINK_END
	UITheme.apply_button_style(close_btn, "secondary", Color("4a7c59"), 16)
	close_btn.pressed.connect(_close_inspect_modal)
	info_col.add_child(close_btn)


func _load_all_cards() -> void:
	_all_cards.clear()

	# 1. Action Cards
	var action_keys := ["explore", "craft", "creatures", "magic", "guardian"]
	var action_names := {
		"explore": "Explore / Gather",
		"craft": "Building / Craft",
		"creatures": "Creatures",
		"magic": "Magic / Learning",
		"guardian": "Guardian / Association"
	}
	for act_id in action_keys:
		for lvl in range(1, 6):
			_all_cards.append({
				"id": "action_%s_lvl%d" % [act_id, lvl],
				"name": action_names.get(act_id, act_id.capitalize()),
				"category": "action",
				"type": "Action Card (Level %d)" % lvl,
				"level": lvl,
				"rarity": "common" if lvl <= 2 else ("uncommon" if lvl == 3 else ("rare" if lvl == 4 else "legendary")),
				"description": ActionCards.get_perks_text(act_id, lvl),
				"flavor": "Master the core actions of the island to achieve harmony."
			})

	# 2. Deck Cards (from data/deck.json)
	var deck_json: Variant = _load_json_data("res://data/deck.json")
	if deck_json is Array:
		var seen := {}
		for c in deck_json:
			if c is Dictionary:
				var cname: String = String(c.get("name", ""))
				if cname != "" and not seen.has(cname):
					seen[cname] = true
					var d: Dictionary = c.duplicate(true)
					d["category"] = "deck"
					d["rarity"] = "rare" if ("Blessing" in String(d.get("type", "")) or "Ward" in String(d.get("type", ""))) else "uncommon"
					_all_cards.append(d)

	# 3. Events (from data/events.json)
	var events_json: Variant = _load_json_data("res://data/events.json")
	if events_json is Dictionary and events_json.has("events"):
		for ev in events_json["events"]:
			var d := (ev as Dictionary).duplicate(true)
			d["category"] = "event"
			d["description"] = d.get("desc", "")
			_all_cards.append(d)

	# 4. Quests (from data/quests.json)
	var quests_json: Variant = _load_json_data("res://data/quests.json")
	if quests_json is Dictionary:
		var common: Dictionary = quests_json.get("common", {})
		for diff in common.keys():
			for q in common[diff]:
				var d := (q as Dictionary).duplicate(true)
				d["category"] = "quest"
				d["type"] = "Common Quest (%s)" % String(diff).capitalize()
				d["description"] = d.get("desc", "")
				_all_cards.append(d)
		for q in quests_json.get("guardian", []):
			var d := (q as Dictionary).duplicate(true)
			d["category"] = "quest"
			d["type"] = "Guardian Quest"
			d["description"] = d.get("desc", "")
			_all_cards.append(d)

	# 5. Skills (from data/skills.json)
	var skills_json: Variant = _load_json_data("res://data/skills.json")
	if skills_json is Dictionary and skills_json.has("skills"):
		for sk in skills_json["skills"]:
			var d := (sk as Dictionary).duplicate(true)
			d["category"] = "skill"
			d["type"] = "Skill (%s)" % String(d.get("tier", "Common")).capitalize()
			d["description"] = d.get("desc", "")
			_all_cards.append(d)

	# 6. Creatures (Canon + Expanded)
	var cr_json: Variant = _load_json_data("res://data/creatures_canon.json")
	if cr_json is Dictionary and cr_json.has("creatures"):
		for cr in cr_json["creatures"]:
			var d := (cr as Dictionary).duplicate(true)
			d["category"] = "creatures"
			d["type"] = "Tier %s Creature" % String(d.get("tier", "1"))
			d["description"] = "Light Interaction: %s\nDark Interaction: %s" % [
				String(d.get("light_interaction", {}).get("verb", "Commune")),
				String(d.get("dark_interaction", {}).get("verb", "Exploit"))
			]
			_all_cards.append(d)

	# 7. Items (from data/items.json)
	var items_json: Variant = _load_json_data("res://data/items.json")
	if items_json is Array:
		for it in items_json:
			if it is Dictionary:
				var d := (it as Dictionary).duplicate(true)
				d["category"] = "item"
				d["description"] = d.get("desc", d.get("description", ""))
				_all_cards.append(d)

	# 8. Characters (from data/characters.json)
	var chars_json: Variant = _load_json_data("res://data/characters.json")
	if chars_json is Dictionary and chars_json.has("characters"):
		for ch in chars_json["characters"]:
			var d := (ch as Dictionary).duplicate(true)
			d["category"] = "character"
			d["type"] = "Character Identity"
			d["description"] = "Perk: %s\nWeakness: %s" % [
				String(d.get("perk", {}).get("name", "")),
				String(d.get("weakness", {}).get("name", ""))
			]
			_all_cards.append(d)


func _load_json_data(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var txt := file.get_as_text()
	var json := JSON.new()
	if json.parse(txt) == OK:
		return json.data
	return null


func _apply_filters() -> void:
	_filtered_cards.clear()

	for c in _all_cards:
		var cat: String = String(c.get("category", "")).to_lower()
		# Check category match
		if _current_filter != "all":
			if _current_filter == "action" and not (cat == "action" or cat == "craft" or cat == "creatures" or cat == "magic" or cat == "guardian"):
				continue
			elif _current_filter != "action" and cat != _current_filter:
				continue

		# Check search match
		if _search_query != "":
			var q := _search_query.to_lower()
			var name_match: bool = String(c.get("name", "")).to_lower().find(q) != -1
			var desc_match: bool = String(c.get("description", "")).to_lower().find(q) != -1
			var type_match: bool = String(c.get("type", "")).to_lower().find(q) != -1
			var id_match: bool = String(c.get("id", "")).to_lower().find(q) != -1
			if not (name_match or desc_match or type_match or id_match):
				continue

		_filtered_cards.append(c)

	_count_label.text = "Showing: %d / %d Cards" % [_filtered_cards.size(), _all_cards.size()]
	_render_grid()


func _render_grid() -> void:
	for child in _grid_container.get_children():
		child.queue_free()

	for c in _filtered_cards:
		var cv: Control = CARD_VIEW_SCRIPT.new(c, true)
		cv.default_card_size = Vector2(170, 255)
		cv.custom_minimum_size = Vector2(170, 255)
		cv.card_clicked.connect(_on_card_clicked)
		_grid_container.add_child(cv)


func _on_card_clicked(data: Dictionary) -> void:
	_current_inspect_data = data
	_inspect_title.text = String(data.get("name", "Card Detail"))
	_inspect_category.text = "✦ %s • %s ✦" % [
		String(data.get("rarity", "Common")).to_upper(),
		String(data.get("type", data.get("category", "Card"))).to_upper()
	]
	_inspect_desc.text = String(data.get("description", data.get("desc", "")))
	_inspect_flavor.text = '"%s"' % String(data.get("flavor", data.get("personality", ""))) if data.get("flavor") or data.get("personality") else ""
	_inspect_meta.text = "ID: %s   •   Category: %s" % [
		String(data.get("id", data.get("item_id", ""))),
		String(data.get("category", "")).capitalize()
	]
	
	_inspect_card_view.setup(data, true)
	_modal_overlay.visible = true


func _on_inspect_flip_pressed() -> void:
	if _inspect_card_view.has_method("flip_card"):
		_inspect_card_view.flip_card(not _inspect_card_view.is_face_up)


func _close_inspect_modal() -> void:
	_modal_overlay.visible = false


func _on_modal_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = _modal_overlay.get_local_mouse_position()
		if not _inspect_panel.get_global_rect().has_point(mouse_pos):
			_close_inspect_modal()


func _on_filter_button_pressed(cat_id: String) -> void:
	_current_filter = cat_id
	for cid in _filter_buttons.keys():
		var btn_dict: Dictionary = _filter_buttons[cid]
		var btn: Button = btn_dict["btn"]
		var col: Color = btn_dict["col"]
		var is_act: bool = (cid == cat_id)
		btn.button_pressed = is_act
		_update_filter_button_style(btn, is_act, col)
	_apply_filters()


func _on_search_changed(new_text: String) -> void:
	_search_query = new_text.strip_edges()
	_apply_filters()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
