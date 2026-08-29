class_name UITheme
extends RefCounted
## UITheme — Centralized design system and storybook style authority for 'Into the Wild'.
## Implements the painterly storybook art direction: soft watercolor tones,
## warm parchment, gilded accents, rounded shapes, and wonder over grit.

# --- Storybook Color Palette ---
const COLOR_BG_DEEP := Color("0b130e")        ## Darkest forest slate
const COLOR_BG_DARK := Color("121d16")        ## Forest background
const COLOR_BG_PANEL := Color("17261d")       ## Standard slate panel
const COLOR_BG_PARCHMENT := Color("f5eedc")   ## Warm storybook paper
const COLOR_BG_PARCHMENT_DARK := Color("232c25") ## Darkened parchment panel

const COLOR_TEXT_LIGHT := Color("f4eedb")     ## Cream white text
const COLOR_TEXT_MUTED := Color("9ab0a0")     ## Soft sage text
const COLOR_TEXT_GOLD := Color("f2d06b")      ## Illuminated warm gold
const COLOR_TEXT_EMERALD := Color("7ce8a6")   ## Verdant island green
const COLOR_TEXT_AMBER := Color("e89a5c")     ## Warm amber
const COLOR_TEXT_CRIMSON := Color("e8685c")   ## Soft crimson (warning/cost)
const COLOR_TEXT_VIOLET := Color("bfa4f0")    ## Moon & ether violet

# --- Island Element Colors ---
const ELEMENT_COLORS: Dictionary = {
	"wood": Color("2f7d4a"),      ## Jungle
	"grain": Color("c9a227"),     ## Meadow
	"stone": Color("b3452e"),     ## Mountain
	"water": Color("2e6fae"),     ## Lakeshore
	"ether": Color("7a5fae"),     ## Swamp
	"spirit": Color("cfc4e8"),    ## Spirit Grove / Sanctum
}

# --- Player Theme Accents ---
const PLAYER_COLORS: Array[Color] = [
	Color("e4b74a"),  ## P1: Sunlit Amber Gold
	Color("d16a5a"),  ## P2: Terracotta Coral
	Color("5aa7d1"),  ## P3: Lakeshore Azure
	Color("9a6ad1"),  ## P4: Spirit Amethyst
]

# --- Rarity Colors ---
const RARITY_COLORS: Dictionary = {
	"common": Color("8da895"),
	"uncommon": Color("4ebd78"),
	"rare": Color("4a9ee4"),
	"legendary": Color("f2a438"),
}


# ================================================================= STYLE GENERATORS

## Creates a rounded storybook panel style box
static func make_panel_style(
	bg_color: Color = Color(0.09, 0.14, 0.11, 0.94),
	border_color: Color = Color(0.35, 0.52, 0.40, 0.6),
	border_width: int = 2,
	corner_radius: int = 12,
	margin: int = 14
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


## Creates an ornate storybook parchment panel
static func make_parchment_style(
	border_accent: Color = Color("d4a337"),
	is_dark: bool = true,
	corner_radius: int = 12
) -> StyleBoxFlat:
	var bg: Color = Color(0.12, 0.16, 0.13, 0.96) if is_dark else Color("f5eedc")
	var border := Color(border_accent.r, border_accent.g, border_accent.b, 0.75)
	var style := make_panel_style(bg, border, 2, corner_radius, 16)
	if not is_dark:
		style.shadow_color = Color(0.1, 0.1, 0.1, 0.15)
	return style


## Applies a stylized storybook look to any standard Button
static func apply_button_style(
	button: Button,
	variant: String = "primary",  ## primary | secondary | gold | danger | card
	accent_color: Color = Color("3a8c56"),
	font_size: int = 18
) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	
	var base_bg: Color
	var border_col: Color
	var text_col: Color
	var hover_bg: Color
	var press_bg: Color
	
	match variant:
		"gold":
			base_bg = Color(0.26, 0.20, 0.08, 0.95)
			border_col = Color(0.95, 0.80, 0.35, 0.9)
			text_col = Color("fff5d4")
			hover_bg = Color(0.38, 0.30, 0.12, 0.98)
			press_bg = Color(0.20, 0.15, 0.06, 1.0)
		"secondary":
			base_bg = Color(0.12, 0.16, 0.14, 0.9)
			border_col = Color(0.42, 0.55, 0.46, 0.6)
			text_col = Color("dce8df")
			hover_bg = Color(0.18, 0.24, 0.20, 0.95)
			press_bg = Color(0.09, 0.12, 0.10, 1.0)
		"danger":
			base_bg = Color(0.22, 0.10, 0.10, 0.92)
			border_col = Color(0.85, 0.35, 0.35, 0.8)
			text_col = Color("ffe0e0")
			hover_bg = Color(0.32, 0.14, 0.14, 0.98)
			press_bg = Color(0.15, 0.06, 0.06, 1.0)
		"card":
			base_bg = Color(0.11, 0.15, 0.13, 0.95)
			border_col = Color(accent_color.r, accent_color.g, accent_color.b, 0.7)
			text_col = Color("f4eedb")
			hover_bg = Color(accent_color.r * 0.3 + 0.1, accent_color.g * 0.3 + 0.1, accent_color.b * 0.3 + 0.1, 0.98)
			press_bg = Color(0.08, 0.10, 0.09, 1.0)
		_: # primary emerald
			base_bg = Color(0.10, 0.22, 0.14, 0.95)
			border_col = Color(0.40, 0.82, 0.52, 0.85)
			text_col = Color("eefcf2")
			hover_bg = Color(0.15, 0.32, 0.20, 0.98)
			press_bg = Color(0.07, 0.16, 0.10, 1.0)
	
	# Normal state
	var st_normal := make_panel_style(base_bg, border_col, 2, 8, 8)
	button.add_theme_stylebox_override("normal", st_normal)
	button.add_theme_color_override("font_color", text_col)
	
	# Hover state
	var st_hover := make_panel_style(hover_bg, border_col.lightened(0.2), 2, 8, 8)
	st_hover.shadow_size = 8
	button.add_theme_stylebox_override("hover", st_hover)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	
	# Pressed state
	var st_pressed := make_panel_style(press_bg, border_col.darkened(0.2), 2, 8, 8)
	st_pressed.shadow_size = 2
	button.add_theme_stylebox_override("pressed", st_pressed)
	button.add_theme_color_override("font_pressed_color", text_col.darkened(0.15))
	
	# Disabled state
	var st_disabled := make_panel_style(Color(0.08, 0.10, 0.09, 0.5), Color(0.25, 0.30, 0.27, 0.3), 1, 8, 8)
	button.add_theme_stylebox_override("disabled", st_disabled)
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.52, 0.48, 0.6))
	
	# Focus state (border highlight)
	var st_focus := make_panel_style(Color(0,0,0,0), Color(0.95, 0.8, 0.3, 0.8), 2, 8, 8)
	button.add_theme_stylebox_override("focus", st_focus)


## Creates a decorative pill/tab button style
static func make_pill_style(is_active: bool, accent_color: Color = Color("4ebd78")) -> StyleBoxFlat:
	var bg := Color(accent_color.r * 0.3, accent_color.g * 0.3, accent_color.b * 0.3, 0.9) if is_active else Color(0.10, 0.13, 0.11, 0.85)
	var border := accent_color if is_active else Color(0.3, 0.38, 0.32, 0.45)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2 if is_active else 1
	style.border_width_top = 2 if is_active else 1
	style.border_width_right = 2 if is_active else 1
	style.border_width_bottom = 2 if is_active else 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


## Creates an ambient particle node (floating spirit motes / pollen) for scenes
static func create_ambient_motes(parent: Node, count: int = 36) -> Node2D:
	var container := Node2D.new()
	container.name = "AmbientMotes"
	container.z_index = 1
	parent.add_child(container)
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var colors: Array[Color] = [
		Color(0.85, 0.95, 0.80, 0.45),  ## Soft green spore
		Color(0.98, 0.90, 0.55, 0.40),  ## Golden sunbeam mote
		Color(0.80, 0.88, 1.00, 0.35),  ## Lake mist wisp
		Color(0.90, 0.80, 0.98, 0.35),  ## Spirit violet glow
	]
	
	for i in count:
		var dot := Polygon2D.new()
		var radius := rng.randf_range(2.0, 5.5)
		var pts := PackedVector2Array()
		for p in 8:
			var angle := TAU * float(p) / 8.0
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		dot.polygon = pts
		dot.color = colors[rng.randi_range(0, colors.size() - 1)]
		
		# Start position across 1920x1080 canvas
		var start_pos := Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080))
		dot.position = start_pos
		container.add_child(dot)
		
		# Ambient wandering tween
		_animate_mote(dot, start_pos, rng)
		
	return container


static func _animate_mote(dot: Polygon2D, origin: Vector2, rng: RandomNumberGenerator) -> void:
	var tween := dot.create_tween().set_loops()
	var dur := rng.randf_range(4.0, 8.5)
	var offset_x := rng.randf_range(-60.0, 60.0)
	var offset_y := rng.randf_range(-90.0, -20.0)
	var target_pos := origin + Vector2(offset_x, offset_y)
	
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dot, "position", target_pos, dur * 0.5)
	tween.parallel().tween_property(dot, "modulate:a", rng.randf_range(0.5, 0.9), dur * 0.5)
	tween.tween_property(dot, "position", origin, dur * 0.5)
	tween.parallel().tween_property(dot, "modulate:a", rng.randf_range(0.2, 0.4), dur * 0.5)


# ================================================================= MOCKUP-PASS API
# The second style surface (mockup pass 2026-08-28) — kept alongside the
# storybook generators above so both UI generations compile; new code may use
# either. Constants mirror docs/art-direction.md palette anchors.

const INK := Color("0b1712")             ## deepest background
const PANEL_BG := Color(0.055, 0.12, 0.095, 0.94)
const PANEL_BG_RAISED := Color(0.08, 0.15, 0.12, 0.96)
const PARCHMENT := Color("e8dcc0")       ## body text
const PARCHMENT_DIM := Color("b7ab8d")
const GOLD := Color("f2d06b")            ## titles, marks
const GOLD_DEEP := Color("c9a227")
const BRONZE := Color("8a6d3b")          ## panel borders
const GLOW := Color("57d8c4")            ## selection / sanctum glow
const LEAF := Color("2f7d4a")            ## primary action green
const LEAF_DEEP := Color("1f4a30")
const DANGER := Color("d16a5a")
const RUNE_FAINT := Color(0.55, 0.64, 0.66, 0.55)

## The four element medallions on the menu (palette anchors, art-direction.md).
const MEDALLIONS: Array[Color] = [
	Color("c9a227"), Color("b3452e"), Color("2e6fae"), Color("7a5fae"),
]

## Facedown-tile sigils — widely-covered glyphs that read as arcane etchings.
const RUNES: Array[String] = ["✧", "❖", "◇", "△", "▽", "✕"]


static func panel_style(border: Color = BRONZE, bg: Color = PANEL_BG, radius: int = 12, bw: int = 2, margin: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


## Ornate button styling. kind: "default" | "primary" (the glowing green CTA)
## | "danger". Keeps whatever size/font the caller set.
static func style_button(b: Button, kind: String = "default") -> void:
	var bg := PANEL_BG_RAISED
	var border := BRONZE
	var text := PARCHMENT
	var text_hover := GOLD
	match kind:
		"primary":
			bg = LEAF_DEEP
			border = GOLD_DEEP
			text = GOLD
			text_hover = Color("ffe9a8")
		"danger":
			border = DANGER
	var normal := panel_style(border, bg, 10, 2, 8)
	var hover := panel_style(border.lightened(0.25), bg.lightened(0.06), 10, 2, 8)
	var pressed := panel_style(border.darkened(0.2), bg.darkened(0.15), 10, 2, 8)
	var disabled := panel_style(Color(border.r, border.g, border.b, 0.25), Color(bg.r, bg.g, bg.b, 0.5), 10, 2, 8)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", text)
	b.add_theme_color_override("font_hover_color", text_hover)
	b.add_theme_color_override("font_pressed_color", text)
	b.add_theme_color_override("font_disabled_color", Color(text.r, text.g, text.b, 0.35))
	b.add_theme_color_override("font_focus_color", text_hover)


## A gold storybook title with a soft ink shadow.
static func title_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Small ornamented section heading: ❖ TEXT ❖
static func heading_label(text: String, size: int = 18) -> Label:
	var l := Label.new()
	l.text = "❖ %s ❖" % text.to_upper()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", GOLD_DEEP)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Shield-style stat chip (character cards): tiny caps title over a big value.
static func stat_chip(title: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(72, 60)
	chip.add_theme_stylebox_override("panel", panel_style(BRONZE, Color(0.04, 0.08, 0.07, 0.95), 8, 2, 4))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	chip.add_child(v)
	var t := Label.new()
	t.text = title.to_upper()
	t.add_theme_font_size_override("font_size", 10)
	t.add_theme_color_override("font_color", PARCHMENT_DIM)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", PARCHMENT)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(val)
	return chip


## Round element medallion (menu party row, card headers).
static func medallion(col: Color, d: float = 26.0) -> PanelContainer:
	var m := PanelContainer.new()
	m.custom_minimum_size = Vector2(d, d)
	var s := panel_style(GOLD_DEEP, col, int(d / 2.0), 2, 0)
	m.add_theme_stylebox_override("panel", s)
	return m


## The rune a facedown tile shows, stable per coordinate.
static func rune_for(axial: Vector2i) -> String:
	return RUNES[absi(axial.x * 31 + axial.y * 17) % RUNES.size()]
