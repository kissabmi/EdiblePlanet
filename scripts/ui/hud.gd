## HUD — heads-up display during gameplay
extends CanvasLayer

var score_label: Label
var combo_label: Label
var wave_label: Label
var timer_bar: ProgressBar
var boss_hp_bar: ProgressBar
var boss_hp_label: Label
var bonus_icon: Label
var bonus_timer_label: Label
var magnet_cursor: Sprite2D
var tilt_indicator: Node2D
var tutorial_label: Label

var combo_anim_timer: float = 0.0

func _ready() -> void:
	layer = 5
	_build_hud()
	ScoreManager.score_changed.connect(_on_score_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.timer_updated.connect(_on_timer_updated)
	WaveManager.boss_spawned.connect(_on_boss_spawned)

func _build_hud() -> void:
	# Score
	score_label = Label.new()
	score_label.text = "0"
	score_label.position = Vector2(20, 10)
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	add_child(score_label)

	# Combo
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.position = Vector2(20, 50)
	combo_label.add_theme_font_size_override("font_size", 28)
	combo_label.add_theme_color_override("font_color", Color(1, 0.5, 0.9))
	add_child(combo_label)

	# Wave
	wave_label = Label.new()
	wave_label.text = "Wave 1/10"
	wave_label.position = Vector2(540, 10)
	wave_label.add_theme_font_size_override("font_size", 24)
	wave_label.add_theme_color_override("font_color", Color.WHITE)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.custom_minimum_size = Vector2(200, 30)
	add_child(wave_label)

	# Timer bar
	timer_bar = ProgressBar.new()
	timer_bar.position = Vector2(390, 45)
	timer_bar.size = Vector2(500, 16)
	timer_bar.max_value = 50
	timer_bar.value = 50
	timer_bar.show_percentage = false
	var style_bg: StyleBoxFlat = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.1, 0.3)
	timer_bar.add_theme_stylebox_override("background", style_bg)
	var style_fill: StyleBoxFlat = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.5, 0.8, 1.0)
	timer_bar.add_theme_stylebox_override("fill", style_fill)
	add_child(timer_bar)

	# Boss HP bar (hidden initially)
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.position = Vector2(340, 80)
	boss_hp_bar.size = Vector2(600, 20)
	boss_hp_bar.max_value = 500
	boss_hp_bar.value = 500
	boss_hp_bar.visible = false
	boss_hp_bar.show_percentage = false
	var boss_bg: StyleBoxFlat = StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.3, 0.05, 0.05)
	boss_hp_bar.add_theme_stylebox_override("background", boss_bg)
	var boss_fill: StyleBoxFlat = StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.9, 0.1, 0.1)
	boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)
	add_child(boss_hp_bar)

	boss_hp_label = Label.new()
	boss_hp_label.text = ""
	boss_hp_label.position = Vector2(540, 100)
	boss_hp_label.add_theme_font_size_override("font_size", 18)
	boss_hp_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.visible = false
	add_child(boss_hp_label)

	# Bonus indicator
	bonus_icon = Label.new()
	bonus_icon.text = ""
	bonus_icon.position = Vector2(1200, 600)
	bonus_icon.add_theme_font_size_override("font_size", 20)
	bonus_icon.add_theme_color_override("font_color", Color(1, 0.85, 0))
	add_child(bonus_icon)

	bonus_timer_label = Label.new()
	bonus_timer_label.text = ""
	bonus_timer_label.position = Vector2(1200, 630)
	bonus_timer_label.add_theme_font_size_override("font_size", 16)
	bonus_timer_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	add_child(bonus_timer_label)

	# Magnet cursor (pink/blue ring)
	magnet_cursor = Sprite2D.new()
	magnet_cursor.position = Vector2(640, 300)
	magnet_cursor.z_index = 10
	_update_cursor_sprite(false)
	add_child(magnet_cursor)

	# Tutorial label
	tutorial_label = Label.new()
	tutorial_label.text = ""
	tutorial_label.position = Vector2(340, 650)
	tutorial_label.add_theme_font_size_override("font_size", 22)
	tutorial_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	tutorial_label.custom_minimum_size = Vector2(600, 30)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(tutorial_label)

func _process(delta: float) -> void:
	# Combo animation
	if combo_anim_timer > 0:
		combo_anim_timer -= delta
		combo_label.scale = Vector2(1, 1) * (1.0 + combo_anim_timer * 0.5)
	# Update bonus indicator
	if get_tree().get_first_node_in_group("game_world"):
		var planet: Node2D = get_tree().get_first_node_in_group("game_world").get_node_or_null("Planet")
		if planet and planet.active_bonus != "":
			bonus_icon.text = _bonus_icon_text(planet.active_bonus)
			bonus_timer_label.text = "%.1fs" % planet.bonus_timer
		else:
			bonus_icon.text = ""
			bonus_timer_label.text = ""
	# Update magnet cursor color based on state
	_update_cursor_sprite(InputManager.magnet_repelling)
	magnet_cursor.position = InputManager.magnet_position

func _update_cursor_sprite(is_repel: bool) -> void:
	var color: Color = Color(1, 0.5, 0.8) if not is_repel else Color(0.5, 0.8, 1.0)
	var size: int = 60
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: float = size / 2.0
	var radius: float = size / 2.0 - 4.0
	for y in range(size):
		for x in range(size):
			var dx: float = (x - center)
			var dy: float = (y - center)
			var d: float = sqrt(dx * dx + dy * dy)
			if d > radius - 4 and d < radius:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, 0.7))
			elif d > radius - 8 and d < radius - 4:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, 0.3))
			# Center dot
			elif d < 4:
				img.set_pixel(x, y, color)
	magnet_cursor.texture = ImageTexture.create_from_image(img)

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Wave %d/10" % wave_number
	boss_hp_bar.visible = (wave_number == 10)
	boss_hp_label.visible = (wave_number == 10)
	# Tutorial hints for first waves
	if WaveManager.current_level == 1:
		match wave_number:
			1: tutorial_label.text = "Player 1: Tilt the planet! (WASD or Mouse)"
			2: tutorial_label.text = "Player 2: Use the magnet! (Mouse click or Arrows+Space)"
			3: tutorial_label.text = "Watch out for the sharp lollipops!"
			4: tutorial_label.text = "Coordinate for COMBO bonuses!"
			5: tutorial_label.text = "Grab the bonus boxes for power-ups!"
			_: tutorial_label.text = ""

func _on_timer_updated(time_left: float, time_total: float) -> void:
	timer_bar.max_value = time_total
	timer_bar.value = time_left
	# Color shift when low
	var pct: float = time_left / time_total if time_total > 0 else 0
	var fill: StyleBoxFlat = timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		if pct > 0.5:
			fill.bg_color = Color(0.5, 0.8, 1.0)
		elif pct > 0.25:
			fill.bg_color = Color(1.0, 0.8, 0.3)
		else:
			fill.bg_color = Color(1.0, 0.3, 0.3)

func _on_boss_spawned(boss_data: Dictionary) -> void:
	boss_hp_bar.visible = true
	boss_hp_label.visible = true
	boss_hp_label.text = boss_data.name
	boss_hp_bar.max_value = boss_data.hp
	boss_hp_bar.value = boss_data.hp

func show_boss_hp(hp: int) -> void:
	boss_hp_bar.max_value = hp
	boss_hp_bar.value = hp

func update_combo(multiplier: float, count: int) -> void:
	combo_label.text = "COMBO x%.0f (%d)" % [multiplier, count]
	combo_anim_timer = 0.5
	# Color based on multiplier
	if multiplier >= 8:
		combo_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	elif multiplier >= 5:
		combo_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	elif multiplier >= 3:
		combo_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	else:
		combo_label.add_theme_color_override("font_color", Color(1, 0.5, 0.9))

func update_magnet_cursor(pos: Vector2) -> void:
	magnet_cursor.position = pos

func update_boss_hp(current: int, maximum: int) -> void:
	boss_hp_bar.value = current

func _bonus_icon_text(type: String) -> String:
	match type:
		"double_magnet": return "⚡ DOUBLE MAGNET"
		"slow_time": return "🕐 SLOW TIME"
		"auto_mouth": return "👄 AUTO MOUTH"
		"shield": return "🛡 SHIELD"
		"beacon": return "📡 BEACON"
		_: return type.to_upper()
