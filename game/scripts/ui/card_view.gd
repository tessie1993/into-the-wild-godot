class_name CardView
extends Control
## CardView — Reusable Godot 4 card component for 'Into the Wild'.
## Dynamically loads high-res rendered PNG card textures from res://assets/cards/
## or provides procedural in-engine card styling as a fallback.
## Supports hover lift/glow, card selection, and 3D-like flip animations via Tween.

signal card_clicked(card_data: Dictionary)
signal card_hovered(card_data: Dictionary)
signal card_unhovered(card_data: Dictionary)

@export var is_face_up: bool = true:
	set(val):
		is_face_up = val
		_update_visuals()

@export var is_interactive: bool = true
@export var default_card_size: Vector2 = Vector2(180, 270)

var card_data: Dictionary = {}
var is_selected: bool = false:
	set(val):
		is_selected = val
		_update_selection_highlight()

var _card_panel: PanelContainer
var _texture_rect: TextureRect
var _highlight_panel: Panel
var _fallback_container: VBoxContainer
var _title_label: Label
var _type_label: Label
var _desc_label: RichTextLabel
var _tween: Tween

const CARD_BACK_PATH: String = "res://assets/cards/card_back.png"


func _init(data: Dictionary = {}, face_up: bool = true) -> void:
	custom_minimum_size = default_card_size
	size = default_card_size
	pivot_offset = default_card_size / 2.0
	mouse_filter = MOUSE_FILTER_PASS
	if not data.is_empty():
		card_data = data
	is_face_up = face_up


func _ready() -> void:
	_build_ui()
	_update_visuals()
	
	if is_interactive:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		gui_input.connect(_on_gui_input)


func setup(data: Dictionary, face_up: bool = true) -> void:
	card_data = data
	is_face_up = face_up
	_update_visuals()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Card container panel with rounded corners and drop shadow
	_card_panel = PanelContainer.new()
	_card_panel.set_anchors_preset(PRESET_FULL_RECT)
	_card_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.11, 0.09, 0.98)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.28, 0.38, 0.32, 0.7)
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_top_right = 10
	bg_style.corner_radius_bottom_right = 10
	bg_style.corner_radius_bottom_left = 10
	bg_style.shadow_color = Color(0, 0, 0, 0.35)
	bg_style.shadow_size = 6
	bg_style.shadow_offset = Vector2(0, 3)
	_card_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_card_panel)

	# Base texture display
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_card_panel.add_child(_texture_rect)

	# Highlight / Outline Overlay
	_highlight_panel = Panel.new()
	_highlight_panel.set_anchors_preset(PRESET_FULL_RECT)
	_highlight_panel.mouse_filter = MOUSE_FILTER_IGNORE
	_highlight_panel.visible = false
	var hl_style := StyleBoxFlat.new()
	hl_style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	hl_style.border_width_left = 3
	hl_style.border_width_top = 3
	hl_style.border_width_right = 3
	hl_style.border_width_bottom = 3
	hl_style.border_color = Color(0.95, 0.82, 0.35, 0.95)
	hl_style.corner_radius_top_left = 10
	hl_style.corner_radius_top_right = 10
	hl_style.corner_radius_bottom_right = 10
	hl_style.corner_radius_bottom_left = 10
	hl_style.shadow_color = Color(0.95, 0.82, 0.35, 0.4)
	hl_style.shadow_size = 8
	_highlight_panel.add_theme_stylebox_override("panel", hl_style)
	add_child(_highlight_panel)

	# Fallback Container for procedural text if texture is not found
	_fallback_container = VBoxContainer.new()
	_fallback_container.set_anchors_preset(PRESET_FULL_RECT)
	_fallback_container.offset_left = 12
	_fallback_container.offset_top = 12
	_fallback_container.offset_right = -12
	_fallback_container.offset_bottom = -12
	_fallback_container.mouse_filter = MOUSE_FILTER_IGNORE
	_fallback_container.visible = false

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_GOLD)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback_container.add_child(_title_label)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 11)
	_type_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	_fallback_container.add_child(_type_label)

	_desc_label = RichTextLabel.new()
	_desc_label.size_flags_vertical = SIZE_EXPAND_FILL
	_desc_label.bbcode_enabled = true
	_desc_label.mouse_filter = MOUSE_FILTER_IGNORE
	_desc_label.add_theme_font_size_override("normal_font_size", 11)
	_desc_label.add_theme_color_override("default_color", UITheme.COLOR_TEXT_LIGHT)
	_fallback_container.add_child(_desc_label)

	add_child(_fallback_container)


func _update_visuals() -> void:
	if not is_inside_tree() or _texture_rect == null:
		return

	if not is_face_up:
		_fallback_container.visible = false
		var back_tex: Texture2D = _load_texture(CARD_BACK_PATH)
		if back_tex != null:
			_texture_rect.texture = back_tex
		else:
			_texture_rect.texture = null
		return

	var path: String = get_card_texture_path()
	var tex: Texture2D = _load_texture(path)
	if tex != null:
		_texture_rect.texture = tex
		_fallback_container.visible = false
	else:
		_texture_rect.texture = null
		_render_fallback_card()


func get_card_texture_path() -> String:
	var cid: String = String(card_data.get("id", card_data.get("item_id", card_data.get("quest_id", "")))).to_lower()
	var category: String = String(card_data.get("category", "deck")).to_lower()
	var level: int = int(card_data.get("level", 0))

	# Clean ID for lookup
	var clean_id := cid
	if clean_id.begins_with("action_"):
		clean_id = clean_id.trim_prefix("action_")
	
	# Strip trailing level suffix if separate
	if clean_id.find("_lvl") != -1:
		clean_id = clean_id.split("_lvl")[0]
	
	# Strip trailing numeric index (e.g. action_double_down_0 -> double_down)
	var parts := clean_id.split("_")
	if parts.size() > 1 and parts[-1].is_valid_int():
		parts.remove_at(parts.size() - 1)
		clean_id = "_".join(parts)

	# Category-specific folder paths
	var candidates: Array[String] = []

	if category == "action" or category == "craft" or category == "creatures" or category == "magic" or category == "guardian":
		if level > 0:
			candidates.append("res://assets/cards/actions/%s_lvl%d.png" % [clean_id, level])
		candidates.append("res://assets/cards/actions/%s.png" % clean_id)
	elif category == "deck":
		candidates.append("res://assets/cards/deck/%s.png" % clean_id)
	elif category == "event":
		candidates.append("res://assets/cards/events/%s.png" % clean_id)
	elif category == "quest":
		candidates.append("res://assets/cards/quests/%s.png" % clean_id)
	elif category == "skill":
		candidates.append("res://assets/cards/skills/%s.png" % clean_id)
	elif category == "creature" or category == "creatures":
		candidates.append("res://assets/cards/creatures/%s.png" % clean_id)
	elif category == "item" or category == "items":
		candidates.append("res://assets/cards/items/%s.png" % clean_id)
	elif category == "character" or category == "characters":
		candidates.append("res://assets/cards/characters/%s.png" % clean_id)

	# Universal fallbacks across all subfolders
	candidates.append("res://assets/cards/deck/%s.png" % clean_id)
	candidates.append("res://assets/cards/items/%s.png" % clean_id)
	candidates.append("res://assets/cards/actions/%s.png" % clean_id)
	candidates.append("res://assets/cards/creatures/%s.png" % clean_id)
	candidates.append("res://assets/cards/quests/%s.png" % clean_id)
	candidates.append("res://assets/cards/events/%s.png" % clean_id)
	candidates.append("res://assets/cards/skills/%s.png" % clean_id)
	candidates.append("res://assets/cards/characters/%s.png" % clean_id)

	for p in candidates:
		if ResourceLoader.exists(p):
			return p

	return ""


func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			return res
	return null


func _render_fallback_card() -> void:
	_fallback_container.visible = true
	_title_label.text = String(card_data.get("name", "Unknown Card"))
	_type_label.text = String(card_data.get("type", "Card")).to_upper()
	_desc_label.text = String(card_data.get("description", card_data.get("desc", "")))


func _update_selection_highlight() -> void:
	if _highlight_panel != null:
		_highlight_panel.visible = is_selected


func flip_card(to_face_up: bool = true, duration: float = 0.25) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "scale:x", 0.0, duration * 0.5)
	_tween.tween_callback(func():
		is_face_up = to_face_up
		_update_visuals()
	)
	_tween.tween_property(self, "scale:x", 1.0, duration * 0.5)


func _on_mouse_entered() -> void:
	if not is_interactive:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.18)
	_tween.parallel().tween_property(self, "position:y", position.y - 8.0, 0.18)
	z_index = 10
	card_hovered.emit(card_data)


func _on_mouse_exited() -> void:
	if not is_interactive:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	_tween.parallel().tween_property(self, "position:y", position.y + 8.0, 0.15)
	z_index = 0
	card_unhovered.emit(card_data)


func _on_gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(card_data)
