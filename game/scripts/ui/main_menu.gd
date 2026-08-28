extends Control
## Title screen (mockup pass — painterly storybook, docs/art-direction.md).
## All UI is built in code so agents can iterate without touching .tscn files
## (project convention — see AGENTS.md).

const MIN_PLAYERS := 1
const MAX_PLAYERS := 4

var _player_count := 2
var _count_label: Label
var _continue_btn: Button


func _ready() -> void:
	# Night-forest ground: deep ink with a moonlit gradient falling from above.
	var bg := ColorRect.new()
	bg.color = UITheme.INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var glow_tex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.10, 0.24, 0.19, 0.8), Color(0.03, 0.09, 0.07, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	glow_tex.gradient = grad
	glow_tex.fill_from = Vector2(0.5, 0.0)
	glow_tex.fill_to = Vector2(0.5, 1.0)
	var glow := TextureRect.new()
	glow.texture = glow_tex
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(glow)
	_add_fireflies()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	box.add_child(UITheme.title_label("INTO THE WILD", 76))
	var sub := Label.new()
	sub.text = "A Tale of Harmony & Survival"
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", UITheme.PARCHMENT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	box.add_child(spacer)

	# The ornate expedition panel (mockup: Party Expedition card).
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.GOLD_DEEP, UITheme.PANEL_BG, 16, 2, 26))
	box.add_child(panel)
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 14)
	pbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(pbox)

	pbox.add_child(UITheme.heading_label("Party Expedition", 17))

	# Player count picker (local pass-and-play, 1-4 wanderers).
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	pbox.add_child(row)

	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(64, 64)
	minus.add_theme_font_size_override("font_size", 32)
	UITheme.style_button(minus)
	minus.pressed.connect(_on_count.bind(-1))
	row.add_child(minus)

	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 28)
	_count_label.add_theme_color_override("font_color", UITheme.PARCHMENT)
	_count_label.custom_minimum_size = Vector2(230, 0)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_count_label)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(64, 64)
	plus.add_theme_font_size_override("font_size", 32)
	UITheme.style_button(plus)
	plus.pressed.connect(_on_count.bind(1))
	row.add_child(plus)

	# The four element medallions (mockup: party row).
	var meds := HBoxContainer.new()
	meds.alignment = BoxContainer.ALIGNMENT_CENTER
	meds.add_theme_constant_override("separation", 12)
	pbox.add_child(meds)
	for col in UITheme.MEDALLIONS:
		meds.add_child(UITheme.medallion(col, 30.0))

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 6)
	pbox.add_child(sep)

	var start := Button.new()
	start.text = "Wash Ashore  ⛵"
	start.custom_minimum_size = Vector2(360, 80)
	start.add_theme_font_size_override("font_size", 28)
	UITheme.style_button(start, "primary")
	start.pressed.connect(_on_start)
	pbox.add_child(start)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue Journey  ⌛"
	_continue_btn.custom_minimum_size = Vector2(360, 60)
	_continue_btn.add_theme_font_size_override("font_size", 22)
	UITheme.style_button(_continue_btn)
	_continue_btn.pressed.connect(_on_continue)
	_continue_btn.visible = Game.has_save()
	pbox.add_child(_continue_btn)

	var quit := Button.new()
	quit.text = "Leave the Shore"
	quit.custom_minimum_size = Vector2(360, 52)
	quit.add_theme_font_size_override("font_size", 18)
	UITheme.style_button(quit)
	quit.pressed.connect(func() -> void: get_tree().quit())
	pbox.add_child(quit)

	_update_count()


## Drifting gold motes — the island is alive even on the title screen.
func _add_fireflies() -> void:
	var flies := CPUParticles2D.new()
	flies.amount = 28
	flies.lifetime = 7.0
	flies.preprocess = 7.0
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(960, 540)
	flies.position = Vector2(960, 540)
	flies.direction = Vector2(0, -1)
	flies.spread = 180.0
	flies.gravity = Vector2.ZERO
	flies.initial_velocity_min = 4.0
	flies.initial_velocity_max = 14.0
	flies.scale_amount_min = 1.5
	flies.scale_amount_max = 3.5
	flies.color = Color(0.95, 0.85, 0.45, 0.55)
	add_child(flies)


func _on_count(delta: int) -> void:
	_player_count = clampi(_player_count + delta, MIN_PLAYERS, MAX_PLAYERS)
	_update_count()


func _update_count() -> void:
	if _player_count == 1:
		_count_label.text = "1 Wanderer (solo)"
	else:
		_count_label.text = "%d Wanderers" % _player_count


func _on_start() -> void:
	Game.pending_player_count = _player_count
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _on_continue() -> void:
	if Game.load_game():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		_continue_btn.visible = false
