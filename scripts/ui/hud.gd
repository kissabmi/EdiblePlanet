## HUD — built entirely in code
extends CanvasLayer

var score_label: Label
var combo_label: Label
var wave_label: Label
var timer_bar: ProgressBar
var boss_bar: ProgressBar
var boss_label: Label
var bonus_label: Label
var magnet_cursor: Sprite2D
var tutorial_label: Label

func _ready() -> void:
	layer = 10

	score_label = _make_label("0", 32, Color(1, 0.85, 0), Vector2(20, 10))
	add_child(score_label)

	combo_label = _make_label("", 28, Color(1, 0.5, 0.9), Vector2(20, 50))
	add_child(combo_label)

	wave_label = _make_label("Wave 1/10", 24, Color.WHITE, Vector2(540, 10))
	add_child(wave_label)

	timer_bar = ProgressBar.new()
	timer_bar.position = Vector2(390, 45)
	timer_bar.size = Vector2(500, 16)
	timer_bar.max_value = 50
	timer_bar.value = 50
	timer_bar.show_percentage = false
	add_child(timer_bar)

	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(340, 80)
	boss_bar.size = Vector2(600, 20)
	boss_bar.max_value = 500
	boss_bar.value = 500
	boss_bar.visible = false
	boss_bar.show_percentage = false
	add_child(boss_bar)

	boss_label = _make_label("", 18, Color(1, 0.5, 0.5), Vector2(540, 100))
	boss_label.visible = false
	add_child(boss_label)

	bonus_label = _make_label("", 20, Color(1, 0.85, 0), Vector2(1100, 600))
	add_child(bonus_label)

	tutorial_label = _make_label("", 22, Color(1, 1, 1, 0.7), Vector2(340, 650))
	tutorial_label.custom_minimum_size = Vector2(600, 30)
	add_child(tutorial_label)

	# Magnet cursor
	magnet_cursor = Sprite2D.new()
	magnet_cursor.z_index = 20
	add_child(magnet_cursor)
	_update_cursor(false)

	# Connect signals
	ScoreManager.score_changed.connect(_on_score)
	WaveManager.wave_started.connect(_on_wave)
	WaveManager.timer_updated.connect(_on_timer)
	WaveManager.boss_spawned.connect(_on_boss)
	ScoreManager.combo_changed.connect(_on_combo)

func _process(_delta: float) -> void:
	magnet_cursor.position = InputManager.magnet_position
	_update_cursor(InputManager.magnet_repelling)
	# Bonus display
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		var planet: Node2D = game.get_node_or_null("Planet")
		if planet and planet.active_bonus != "":
			bonus_label.text = "%s (%.1fs)" % [planet.active_bonus.replace("_", " ").to_upper(), planet.bonus_timer]
		else:
			bonus_label.text = ""

func _update_cursor(is_repel: bool) -> void:
	var color: Color = Color(1, 0.5, 0.8) if not is_repel else Color(0.5, 0.8, 1)
	var size: int = 50
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: float = size / 2.0
	for y in range(size):
		for x in range(size):
			var d: float = sqrt((x-center)**2 + (y-center)**2)
			if d > 18 and d < 22:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, 0.7))
			elif d < 4:
				img.set_pixel(x, y, color)
	magnet_cursor.texture = ImageTexture.create_from_image(img)

func _on_score(s: int) -> void: score_label.text = str(s)

func _on_wave(w: int) -> void:
	wave_label.text = "Wave %d/10" % w
	boss_bar.visible = (w == 10)
	boss_label.visible = (w == 10)
	if WaveManager.current_level == 1:
		match w:
			1: tutorial_label.text = "Player 1: WASD = tilt planet"
			2: tutorial_label.text = "Player 2: Mouse LMB/RMB = magnet"
			3: tutorial_label.text = "Avoid the red lollipops!"
			4: tutorial_label.text = "Coordinate for COMBO bonuses!"
			5: tutorial_label.text = "Grab the gold bonus boxes!"
			_: tutorial_label.text = ""

func _on_timer(left: float, total: float) -> void:
	timer_bar.max_value = total
	timer_bar.value = left

func _on_boss(data: Dictionary) -> void:
	boss_bar.visible = true
	boss_label.visible = true
	boss_label.text = data.name
	boss_bar.max_value = data.hp
	boss_bar.value = data.hp

func _on_combo(mult: float, count: int) -> void:
	combo_label.text = "COMBO x%.0f (%d)" % [mult, count]
	if mult >= 5: combo_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	elif mult >= 3: combo_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	else: combo_label.add_theme_color_override("font_color", Color(1, 0.5, 0.9))

func update_combo(mult: float, count: int) -> void:
	_on_combo(mult, count)

func _make_label(text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
