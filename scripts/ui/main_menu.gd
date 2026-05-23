## MainMenu — title screen with options
extends Control

var title_label: Label
var play_btn: Button
var controls_btn: Button
var records_btn: Button
var quit_btn: Button
var planet_preview: Sprite2D
var stars_display: HBoxContainer

func _ready() -> void:
	# Full-screen dark background with stars
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.12)
	bg.size = Vector2(1280, 720)
	bg.position = Vector2(0, 0)
	add_child(bg)

	# Star field background
	_spawn_star_field()

	# Planet preview (animated donut)
	planet_preview = Sprite2D.new()
	planet_preview.position = Vector2(640, 350)
	planet_preview.texture = _make_planet_texture()
	add_child(planet_preview)

	# Title
	title_label = Label.new()
	title_label.text = "EDIBLE PLANET"
	title_label.position = Vector2(190, 50)
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(1, 0.6, 0.85))
	add_child(title_label)

	# Subtitle
	var sub: Label = Label.new()
	sub.text = "COSMIC FEAST"
	sub.position = Vector2(390, 130)
	sub.add_theme_font_size_override("font_size", 36)
	sub.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	add_child(sub)

	# Stars display
	stars_display = HBoxContainer.new()
	stars_display.position = Vector2(440, 170)
	_update_stars()
	add_child(stars_display)

	# Buttons
	var btn_container: VBoxContainer = VBoxContainer.new()
	btn_container.position = Vector2(490, 500)
	btn_container.size = Vector2(300, 200)
	add_child(btn_container)

	play_btn = _make_button("PLAY", Color(0.4, 0.9, 0.5))
	play_btn.pressed.connect(_on_play)
	btn_container.add_child(play_btn)

	controls_btn = _make_button("CONTROLS", Color(0.5, 0.7, 0.9))
	controls_btn.pressed.connect(_on_controls)
	btn_container.add_child(controls_btn)

	records_btn = _make_button("RECORDS", Color(0.9, 0.8, 0.5))
	records_btn.pressed.connect(_on_records)
	btn_container.add_child(records_btn)

	quit_btn = _make_button("QUIT", Color(0.8, 0.4, 0.4))
	quit_btn.pressed.connect(_on_quit)
	btn_container.add_child(quit_btn)

func _process(delta: float) -> void:
	planet_preview.rotation += delta * 0.3
	# Gentle bobbing
	planet_preview.position.y = 350 + sin(Time.get_ticks_msec() / 500.0) * 10.0

func _spawn_star_field() -> void:
	for i in range(80):
		var star: Sprite2D = Sprite2D.new()
		star.position = Vector2(randf() * 1280, randf() * 720)
		var img: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		var brightness: float = randf_range(0.3, 1.0)
		img.fill(Color(brightness, brightness, brightness + 0.1, randf_range(0.3, 1.0)))
		star.texture = ImageTexture.create_from_image(img)
		add_child(star)

func _make_button(text: String, color: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 45)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = color
	btn.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5)
	btn.add_theme_stylebox_override("hover", hover)
	return btn

func _make_planet_texture() -> ImageTexture:
	var img: Image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
	# Donut planet with face
	var donut_outer: Color = Color(1.0, 0.75, 0.5)  # Donut color
	var donut_inner: Color = Color(0.85, 0.5, 0.25)
	var icing: Color = Color(1.0, 0.4, 0.7)
	var hole: Color = Color(0, 0, 0, 0)
	var mouth_c: Color = Color(0.3, 0.0, 0.1)
	var eye_c: Color = Color(1.0, 1.0, 1.0)
	var pupil: Color = Color(0, 0, 0)
	for y in range(200):
		for x in range(200):
			var dx: float = (x - 100.0) / 100.0
			var dy: float = (y - 100.0) / 100.0
			var d: float = sqrt(dx * dx + dy * dy)
			# Outer ring
			if d < 0.85 and d > 0.35:
				# Frosting on top half
				if dy < -0.1:
					var sprinkle: float = sin(dx * 30) * cos(dy * 20)
					if sprinkle > 0.5:
						img.set_pixel(x, y, Color(randf(), randf(), 1.0))
					else:
						img.set_pixel(x, y, icing)
				else:
					img.set_pixel(x, y, donut_outer)
			elif d <= 0.35:
				img.set_pixel(x, y, donut_inner)
			# Eyes
			if sqrt((dx + 0.2) ** 2 + (dy - 0.15) ** 2) < 0.08:
				img.set_pixel(x, y, eye_c)
				if sqrt((dx + 0.2) ** 2 + (dy - 0.15) ** 2) < 0.04:
					img.set_pixel(x, y, pupil)
			if sqrt((dx - 0.2) ** 2 + (dy - 0.15) ** 2) < 0.08:
				img.set_pixel(x, y, eye_c)
				if sqrt((dx - 0.2) ** 2 + (dy - 0.15) ** 2) < 0.04:
					img.set_pixel(x, y, pupil)
			# Mouth
			if dy > 0.3 and dy < 0.5 and absf(dx) < 0.2:
				img.set_pixel(x, y, mouth_c)
	return ImageTexture.create_from_image(img)

func _update_stars() -> void:
	for child in stars_display.get_children():
		child.queue_free()
	for level in range(1, 4):
		var stars: int = SaveManager.get_stars(level)
		var text: String = "L%d:" % level
		for i in range(3):
			text += "★" if i < stars else "☆"
		var l: Label = Label.new()
		l.text = text + "  "
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Color(1, 0.85, 0))
		stars_display.add_child(l)

func _on_play() -> void:
	AudioManager.play_sfx("wave_start")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_controls() -> void:
	get_tree().change_scene_to_file("res://scenes/input_select.tscn")

func _on_records() -> void:
	# Show records overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.size = Vector2(1280, 720)
	add_child(overlay)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(390, 150)
	vbox.size = Vector2(500, 400)
	add_child(vbox)
	var title: Label = Label.new()
	title.text = "HIGH SCORES"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(500, 50)
	vbox.add_child(title)
	for level in range(1, 4):
		var l: Label = Label.new()
		l.text = "Level %d: %d  ★%d" % [level, SaveManager.get_high_score(level), SaveManager.get_stars(level)]
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(500, 40)
		vbox.add_child(l)
	var close_btn: Button = Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(func(): overlay.queue_free(); vbox.queue_free())
	vbox.add_child(close_btn)

func _on_quit() -> void:
	get_tree().quit()
