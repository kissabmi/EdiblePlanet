## InputSelect — choose control mode (mouse+mouse, mouse+keyboard, keyboard+keyboard)
extends Control

func _ready() -> void:
	# Background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.12)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	# Title
	var title: Label = Label.new()
	title.text = "CONTROLS"
	title.position = Vector2(390, 40)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	add_child(title)

	# Subtitle
	var sub: Label = Label.new()
	sub.text = "Choose how you and your partner will play"
	sub.position = Vector2(290, 100)
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(sub)

	# Control mode cards
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(240, 170)
	vbox.size = Vector2(800, 400)
	add_child(vbox)

	var current_mode: int = SaveManager.get_control_mode()

	# Mode 1: Mouse + Mouse
	vbox.add_child(_make_mode_card(
		"MOUSE + MOUSE",
		"Player 1: Mouse 1 horizontal = tilt planet\nPlayer 2: Mouse 2 LMB/RMB = attract/repel magnet",
		0, current_mode
	))

	# Mode 2: Mouse + Keyboard
	vbox.add_child(_make_mode_card(
		"MOUSE + KEYBOARD",
		"Player 1: WASD = tilt planet\nPlayer 2: Mouse LMB/RMB = attract/repel magnet",
		1, current_mode
	))

	# Mode 3: Keyboard + Keyboard
	vbox.add_child(_make_mode_card(
		"KEYBOARD + KEYBOARD",
		"Player 1: WASD = tilt planet\nPlayer 2: Arrows = move magnet, Space = attract, Shift = repel",
		2, current_mode
	))

	# Back button
	var back: Button = Button.new()
	back.text = "BACK"
	back.position = Vector2(540, 620)
	back.custom_minimum_size = Vector2(200, 45)
	back.pressed.connect(_on_back)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.3)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.5, 0.9)
	back.add_theme_stylebox_override("normal", style)
	add_child(back)

func _make_mode_card(title_text: String, desc_text: String, mode: int, current: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(800, 100)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var is_selected: bool = (mode == current)
	style.bg_color = Color(0.15, 0.08, 0.25) if not is_selected else Color(0.25, 0.15, 0.4)
	style.set_corner_radius_all(12)
	style.set_border_width_all(3)
	style.border_color = Color(0.5, 0.3, 0.8) if not is_selected else Color(1, 0.6, 0.9)
	card.add_theme_stylebox_override("panel", style)

	var inner: VBoxContainer = VBoxContainer.new()
	card.add_child(inner)

	var hbox: HBoxContainer = HBoxContainer.new()
	inner.add_child(hbox)

	var title_l: Label = Label.new()
	title_l.text = title_text
	title_l.add_theme_font_size_override("font_size", 26)
	title_l.add_theme_color_override("font_color", Color(1, 0.6, 0.9) if is_selected else Color(0.8, 0.6, 0.8))
	title_l.custom_minimum_size = Vector2(350, 35)
	hbox.add_child(title_l)

	if is_selected:
		var sel: Label = Label.new()
		sel.text = "  ✓ SELECTED"
		sel.add_theme_font_size_override("font_size", 20)
		sel.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		hbox.add_child(sel)

	var desc: Label = Label.new()
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc.custom_minimum_size = Vector2(800, 40)
	inner.add_child(desc)

	# Click to select
	var btn: Button = Button.new()
	btn.text = "SELECT"
	btn.custom_minimum_size = Vector2(120, 30)
	if not is_selected:
		btn.pressed.connect(_select_mode.bind(mode))
		inner.add_child(btn)

	return card

func _select_mode(mode: int) -> void:
	SaveManager.set_control_mode(mode)
	InputManager.set_control_mode(mode as InputManager.ControlMode)
	AudioManager.play_sfx("bonus")
	# Refresh scene
	get_tree().reload_current_scene()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
