extends Control
## MainMenu — Storybook Title Screen for 'Into the Wild'.
## Implements the painterly storybook art direction with ambient light motes,
## ornate parchment crests, and gilded emerald buttons.

const MIN_PLAYERS := 1
const MAX_PLAYERS := 4

var _player_count := 2
var _count_label: Label
var _player_dots_container: HBoxContainer
var _continue_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 1. Dark Atmospheric Forest Background
	var bg := ColorRect.new()
	bg.color = UITheme.COLOR_BG_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Gentle vignette & warm light glow overlay
	var vignette := ColorRect.new()
	vignette.color = Color(0.08, 0.16, 0.11, 0.45)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)

	# 2. Ambient Floating Spirit Motes
	UITheme.create_ambient_motes(self, 40)

	# 3. Main Center Container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Main Card Box with storybook framing
	var main_panel := PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(580, 680)
	var panel_style := UITheme.make_panel_style(
		Color(0.09, 0.14, 0.11, 0.92),
		Color(0.38, 0.58, 0.44, 0.65),
		3,
		18,
		32
	)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(main_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	main_panel.add_child(box)

	# Title Banner Emblem
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 6)
	box.add_child(title_box)

	var emblem_top := Label.new()
	emblem_top.text = "✦  A TALE OF HARMONY & SURVIVAL  ✦"
	emblem_top.add_theme_font_size_override("font_size", 14)
	emblem_top.add_theme_color_override("font_color", UITheme.COLOR_TEXT_EMERALD)
	emblem_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(emblem_top)

	var title := Label.new()
	title.text = "INTO THE WILD"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title)

	var sub := Label.new()
	sub.text = "Explore. Craft. Give back. The island is watching."
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(sub)

	var sep := HSeparator.new()
	box.add_child(sep)

	# 4. Player Count Selector Card
	var selector_panel := PanelContainer.new()
	var sel_style := UITheme.make_panel_style(
		Color(0.06, 0.09, 0.07, 0.8),
		Color(0.30, 0.44, 0.35, 0.5),
		1,
		12,
		14
	)
	selector_panel.add_theme_stylebox_override("panel", sel_style)
	box.add_child(selector_panel)

	var sel_vbox := VBoxContainer.new()
	sel_vbox.add_theme_constant_override("separation", 10)
	selector_panel.add_child(sel_vbox)

	var sel_title := Label.new()
	sel_title.text = "PARTY EXPEDITION"
	sel_title.add_theme_font_size_override("font_size", 13)
	sel_title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	sel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel_vbox.add_child(sel_title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	sel_vbox.add_child(row)

	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(48, 48)
	UITheme.apply_button_style(minus, "secondary", Color("4a7c59"), 24)
	minus.pressed.connect(_on_count.bind(-1))
	row.add_child(minus)

	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 22)
	_count_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	_count_label.custom_minimum_size = Vector2(220, 0)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_count_label)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(48, 48)
	UITheme.apply_button_style(plus, "secondary", Color("4a7c59"), 24)
	plus.pressed.connect(_on_count.bind(1))
	row.add_child(plus)

	# Player Colored Halos indicator
	_player_dots_container = HBoxContainer.new()
	_player_dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_player_dots_container.add_theme_constant_override("separation", 12)
	sel_vbox.add_child(_player_dots_container)

	# 5. Buttons Menu List
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	box.add_child(btn_box)

	var start := Button.new()
	start.text = "Wash Ashore  ▸"
	start.custom_minimum_size = Vector2(380, 62)
	UITheme.apply_button_style(start, "primary", Color("3a8c56"), 22)
	start.pressed.connect(_on_start)
	btn_box.add_child(start)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue Journey  ⌛"
	_continue_btn.custom_minimum_size = Vector2(380, 52)
	UITheme.apply_button_style(_continue_btn, "gold", Color("d4a337"), 19)
	_continue_btn.pressed.connect(_on_continue)
	_continue_btn.visible = Game.has_save()
	btn_box.add_child(_continue_btn)

	var gallery_btn := Button.new()
	var is_dev := OS.is_debug_build()
	gallery_btn.text = "Island Compendium & Cards  🕮"
	gallery_btn.custom_minimum_size = Vector2(380, 48)
	UITheme.apply_button_style(gallery_btn, "secondary", Color("4a7c59"), 17)
	gallery_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/card_gallery.tscn"))
	btn_box.add_child(gallery_btn)

	var quit := Button.new()
	quit.text = "Leave Island"
	quit.custom_minimum_size = Vector2(380, 44)
	UITheme.apply_button_style(quit, "secondary", Color("4a7c59"), 16)
	quit.pressed.connect(func() -> void: get_tree().quit())
	btn_box.add_child(quit)

	# Version Label
	var ver_label := Label.new()
	ver_label.text = "Into the Wild v0.1 • Storybook Edition"
	ver_label.add_theme_font_size_override("font_size", 12)
	ver_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.45, 0.7))
	ver_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ver_label)

	_update_count()


func _on_count(delta: int) -> void:
	_player_count = clampi(_player_count + delta, MIN_PLAYERS, MAX_PLAYERS)
	_update_count()


func _update_count() -> void:
	if _player_count == 1:
		_count_label.text = "1 Wanderer (Solo)"
	else:
		_count_label.text = "%d Wanderers" % _player_count

	# Rebuild player colored indicator pills
	for child in _player_dots_container.get_children():
		child.queue_free()

	for i in _player_count:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(16, 16)
		var style := StyleBoxFlat.new()
		var pcol: Color = UITheme.PLAYER_COLORS[i % UITheme.PLAYER_COLORS.size()]
		style.bg_color = pcol
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(1, 1, 1, 0.5)
		dot.add_theme_stylebox_override("panel", style)
		_player_dots_container.add_child(dot)


func _on_start() -> void:
	Game.pending_player_count = _player_count
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _on_continue() -> void:
	if Game.load_game():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		_continue_btn.visible = false
