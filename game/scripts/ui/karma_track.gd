class_name KarmaTrack
extends Control
## The Karma Track HUD ribbon (mockup pass): moon on the dark end, sun on the
## light end, band boundaries ticked, and a glowing marker at the current
## player's Light. Pure _draw — no assets.

const TRACK_W := 380.0
const TRACK_H := 12.0

var _light: int = 0
var _band: Duality.Band = Duality.Band.NEUTRAL


func _init() -> void:
	custom_minimum_size = Vector2(TRACK_W + 56, 34)


func set_light(light: int, band: Duality.Band) -> void:
	_light = light
	_band = band
	queue_redraw()


func _band_color() -> Color:
	match _band:
		Duality.Band.MAX_LIGHT:
			return UITheme.GOLD
		Duality.Band.LIGHT:
			return Color("9fdc7f")
		Duality.Band.NEUTRAL:
			return UITheme.PARCHMENT
		Duality.Band.DARK:
			return Color("9a6ad1")
		_:
			return Color("6b5a9e")


func _draw() -> void:
	var font := get_theme_default_font()
	var x0 := 28.0
	var y := size.y * 0.5
	var track := Rect2(x0, y - TRACK_H * 0.5, TRACK_W, TRACK_H)
	# End glyphs: the dark moon and the radiant sun.
	draw_string(font, Vector2(2, y + 7), "☾", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("8f7fc9"))
	draw_string(font, Vector2(x0 + TRACK_W + 8, y + 7), "☀", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UITheme.GOLD)
	# The ribbon: dark violet to gold, in segments.
	var segs := 24
	for i in segs:
		var t := float(i) / float(segs - 1)
		var col := Color("463a63").lerp(UITheme.GOLD_DEEP, t)
		col.a = 0.9
		var seg_w := TRACK_W / float(segs)
		draw_rect(Rect2(x0 + seg_w * i, track.position.y, seg_w + 1.0, TRACK_H), col)
	# Frame + band-boundary ticks (canon bands: −8, −2, +2, +8).
	draw_rect(track, UITheme.BRONZE, false, 2.0)
	var lo := float(Duality.track_min())
	var hi := float(Duality.track_max())
	for boundary in [-8, -2, 2, 8]:
		var bx := x0 + TRACK_W * (float(boundary) - lo) / (hi - lo)
		draw_line(Vector2(bx, track.position.y - 3), Vector2(bx, track.end.y + 3), Color(0, 0, 0, 0.45), 2.0)
	# The marker: a glowing medallion at the current Light.
	var mx := x0 + TRACK_W * (float(_light) - lo) / (hi - lo)
	var mcol := _band_color()
	draw_circle(Vector2(mx, y), 11.0, Color(mcol.r, mcol.g, mcol.b, 0.28))
	draw_circle(Vector2(mx, y), 7.0, mcol)
	draw_arc(Vector2(mx, y), 7.0, 0.0, TAU, 20, Color(0, 0, 0, 0.55), 1.5)
