class_name UITheme
extends RefCounted
## The painterly-storybook UI kit (docs/art-direction.md, mockup pass 2026-08-28).
## All UI is built in code; these helpers keep every screen in one visual
## language: deep-forest panels, bronze-gold ornament, parchment text, and a
## soft teal glow for selection. Final painted assets slot in later without
## changing any layout.

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
