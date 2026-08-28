extends Control
## Title screen. All UI is built in code so agents can iterate without
## touching .tscn files (project convention — see AGENTS.md).

const MIN_PLAYERS := 1
const MAX_PLAYERS := 4

var _player_count := 2
var _count_label: Label
var _continue_btn: Button


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("152318")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var title := Label.new()
	title.text = "INTO THE WILD"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color("bfe8cf"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Explore. Craft. Give back. The island is watching."
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color("7fa88e"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	box.add_child(spacer)

	# Player count picker (local pass-and-play, 1-4 wanderers).
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)

	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(72, 72)
	minus.add_theme_font_size_override("font_size", 36)
	minus.pressed.connect(_on_count.bind(-1))
	row.add_child(minus)

	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 32)
	_count_label.custom_minimum_size = Vector2(260, 0)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_count_label)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(72, 72)
	plus.add_theme_font_size_override("font_size", 36)
	plus.pressed.connect(_on_count.bind(1))
	row.add_child(plus)

	var start := Button.new()
	start.text = "Wash Ashore"
	start.custom_minimum_size = Vector2(360, 84)
	start.add_theme_font_size_override("font_size", 30)
	start.pressed.connect(_on_start)
	box.add_child(start)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue Journey"
	_continue_btn.custom_minimum_size = Vector2(360, 64)
	_continue_btn.add_theme_font_size_override("font_size", 24)
	_continue_btn.pressed.connect(_on_continue)
	_continue_btn.visible = Game.has_save()
	box.add_child(_continue_btn)

	var quit := Button.new()
	quit.text = "Leave"
	quit.custom_minimum_size = Vector2(360, 56)
	quit.add_theme_font_size_override("font_size", 20)
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)

	_update_count()


func _on_count(delta: int) -> void:
	_player_count = clampi(_player_count + delta, MIN_PLAYERS, MAX_PLAYERS)
	_update_count()


func _update_count() -> void:
	if _player_count == 1:
		_count_label.text = "1 wanderer (solo)"
	else:
		_count_label.text = "%d wanderers" % _player_count


func _on_start() -> void:
	Game.new_game(_player_count)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_continue() -> void:
	if Game.load_game():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		_continue_btn.visible = false
