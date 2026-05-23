## Game — main gameplay scene, builds everything in code
extends Node2D

var planet: Node2D
var hud: CanvasLayer
var food_group: Node2D
var food_spawner: Node
var bug_spawner: Node
var boss_node: Node2D

func _ready() -> void:
	add_to_group("game_world")

	# ── Background ──
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.12)
	bg.size = Vector2(1280, 720)
	bg.z_index = -100
	add_child(bg)
	_spawn_stars(bg)

	# ── Planet ──
	planet = Node2D.new()
	planet.name = "Planet"
	planet.position = Vector2(640, 420)
	planet.set_script(load("res://scripts/planet/planet.gd"))
	add_child(planet)

	# Planet sprite
	var planet_sprite: Sprite2D = Sprite2D.new()
	planet_sprite.name = "PlanetSprite"
	planet_sprite.texture = _make_planet_texture()
	planet.add_child(planet_sprite)

	# Mouth
	var mouth: Area2D = Area2D.new()
	mouth.name = "Mouth"
	mouth.position = Vector2(0, -130)
	mouth.set_script(load("res://scripts/planet/mouth.gd"))
	var mouth_col: CollisionShape2D = CollisionShape2D.new()
	var mouth_shape: CircleShape2D = CircleShape2D.new()
	mouth_shape.radius = 50.0
	mouth_col.shape = mouth_shape
	mouth_col.name = "MouthCollision"
	mouth.add_child(mouth_col)
	mouth.collision_mask = 0
	mouth.set_collision_mask_value(2, true)  # food
	mouth.set_collision_mask_value(3, true)  # hazard
	planet.add_child(mouth)

	# Tilt controller
	var tilt: Node2D = Node2D.new()
	tilt.name = "TiltController"
	tilt.position = Vector2(0, -130)
	tilt.set_script(load("res://scripts/planet/tilt_controller.gd"))
	planet.add_child(tilt)

	# Magnet controller
	var magnet_ctrl: Node2D = Node2D.new()
	magnet_ctrl.name = "MagnetController"
	magnet_ctrl.set_script(load("res://scripts/planet/magnet_controller.gd"))
	planet.add_child(magnet_ctrl)

	# Magnet cursor
	var magnet_cursor: Sprite2D = Sprite2D.new()
	magnet_cursor.name = "MagnetCursor"
	magnet_cursor.position = Vector2(0, -200)
	magnet_cursor.z_index = 5
	planet.add_child(magnet_cursor)

	# Magnet zone
	var magnet_zone: Area2D = Area2D.new()
	magnet_zone.name = "MagnetZone"
	magnet_zone.position = Vector2(0, -200)
	magnet_zone.set_collision_mask_value(2, true)
	magnet_zone.set_collision_mask_value(3, true)
	planet.add_child(magnet_zone)

	# ── Spawners ──
	food_spawner = Node.new()
	food_spawner.name = "FoodSpawner"
	food_spawner.set_script(load("res://scripts/spawners/food_spawner.gd"))
	add_child(food_spawner)

	bug_spawner = Node.new()
	bug_spawner.name = "BugSpawner"
	bug_spawner.set_script(load("res://scripts/spawners/bug_spawner.gd"))
	add_child(bug_spawner)

	# ── Food group ──
	food_group = Node2D.new()
	food_group.name = "FoodGroup"
	add_child(food_group)

	# ── HUD ──
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	hud.set_script(load("res://scripts/ui/hud.gd"))
	add_child(hud)

	# ── Connect signals ──
	WaveManager.boss_spawned.connect(_on_boss_spawned)
	WaveManager.level_completed.connect(_on_level_completed)
	WaveManager.all_levels_done.connect(_on_all_done)
	ScoreManager.combo_changed.connect(_on_combo_changed)

	# ── Start level 1 ──
	WaveManager.start_level(1)

func _spawn_stars(parent: Node) -> void:
	for i in range(60):
		var star: Sprite2D = Sprite2D.new()
		star.position = Vector2(randf() * 1280, randf() * 720)
		var b: float = randf_range(0.3, 1.0)
		var img: Image = Image.create(3, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color(b, b, b + 0.1, randf_range(0.3, 1.0)))
		star.texture = ImageTexture.create_from_image(img)
		parent.add_child(star)

func _make_planet_texture() -> ImageTexture:
	var img: Image = Image.create(300, 300, false, Image.FORMAT_RGBA8)
	var donut: Color = Color(1.0, 0.75, 0.5)
	var icing: Color = Color(1.0, 0.4, 0.7)
	var hole: Color = Color(0.05, 0.02, 0.12)
	var mouth_c: Color = Color(0.3, 0.0, 0.1)
	var eye_c: Color = Color(1.0, 1.0, 1.0)
	var pupil: Color = Color(0, 0, 0)
	for y in range(300):
		for x in range(300):
			var dx: float = (x - 150.0) / 150.0
			var dy: float = (y - 150.0) / 150.0
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 0.9 and d > 0.38:
				if dy < -0.1:
					var sprinkle: float = sin(dx * 30.0) * cos(dy * 20.0)
					if sprinkle > 0.5:
						var sc: Color = Color(0.3 + randf() * 0.7, 0.3 + randf() * 0.7, 0.5 + randf() * 0.5)
						img.set_pixel(x, y, sc)
					else:
						img.set_pixel(x, y, icing)
				else:
					img.set_pixel(x, y, donut)
			elif d <= 0.38:
				img.set_pixel(x, y, hole)
			# Eyes
			if sqrt((dx + 0.2) ** 2 + (dy - 0.12) ** 2) < 0.07:
				img.set_pixel(x, y, eye_c)
				if sqrt((dx + 0.2) ** 2 + (dy - 0.12) ** 2) < 0.035:
					img.set_pixel(x, y, pupil)
			if sqrt((dx - 0.2) ** 2 + (dy - 0.12) ** 2) < 0.07:
				img.set_pixel(x, y, eye_c)
				if sqrt((dx - 0.2) ** 2 + (dy - 0.12) ** 2) < 0.035:
					img.set_pixel(x, y, pupil)
			# Mouth
			if dy > 0.25 and dy < 0.45 and absf(dx) < 0.18:
				img.set_pixel(x, y, mouth_c)
	return ImageTexture.create_from_image(img)

func _on_boss_spawned(boss_data: Dictionary) -> void:
	var boss_script_path: String
	match boss_data.level:
		1: boss_script_path = "res://scripts/bosses/lollipop_leviathan.gd"
		2: boss_script_path = "res://scripts/bosses/chocolate_chthon.gd"
		3: boss_script_path = "res://scripts/bosses/caramel_kraken.gd"
		_: return
	boss_node = RigidBody2D.new()
	boss_node.set_script(load(boss_script_path))
	boss_node.global_position = Vector2(640, -200)
	food_group.add_child(boss_node)
	boss_node.activate()

func _on_level_completed(stars: int, stats: Dictionary) -> void:
	SaveManager.set_stars(WaveManager.current_level, stars)
	SaveManager.set_high_score(WaveManager.current_level, stats.score)
	await get_tree().create_timer(1.0).timeout
	_show_results(stars, stats)

func _on_all_done(stats: Dictionary) -> void:
	SaveManager.set_stars(3, 1)
	await get_tree().create_timer(2.0).timeout
	_show_results(3, stats, true)

func _show_results(stars: int, stats: Dictionary, is_final: bool = false) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.size = Vector2(1280, 720)
	overlay.z_index = 50
	add_child(overlay)

	var container: VBoxContainer = VBoxContainer.new()
	container.position = Vector2(340, 120)
	container.size = Vector2(600, 480)
	container.z_index = 51
	add_child(container)

	var title: Label = _label("LEVEL COMPLETE!" if not is_final else "CONGRATULATIONS!", 48, Color(1, 0.85, 0))
	container.add_child(title)

	var stars_text: String = ""
	for i in range(3):
		stars_text += "*" if i < stars else "o"
	container.add_child(_label(stars_text, 56, Color(1, 0.85, 0)))

	container.add_child(_label("Score: %d" % stats.score, 28, Color.WHITE))
	container.add_child(_label("Eaten: %d | Poisoned: %d" % [stats.eaten, stats.poisoned], 22, Color(0.8, 0.8, 0.8)))
	container.add_child(_label("Max Combo: %dx | Vortexes: %d | Bonuses: %d" % [stats.max_combo, stats.vortexes, stats.bonuses], 20, Color(0.7, 0.7, 0.7)))

	var next_btn: Button = Button.new()
	next_btn.text = "NEXT LEVEL" if not is_final else "MAIN MENU"
	next_btn.custom_minimum_size = Vector2(250, 50)
	next_btn.pressed.connect(_on_next.bind(is_final))
	container.add_child(next_btn)

	var retry_btn: Button = Button.new()
	retry_btn.text = "RETRY"
	retry_btn.custom_minimum_size = Vector2(250, 50)
	retry_btn.pressed.connect(_on_retry)
	container.add_child(retry_btn)

func _on_next(is_final: bool) -> void:
	if is_final or WaveManager.current_level >= 3:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		WaveManager.start_level(WaveManager.current_level + 1)
		get_tree().reload_current_scene()

func _on_retry() -> void:
	WaveManager.start_level(WaveManager.current_level)
	get_tree().reload_current_scene()

func _on_combo_changed(multiplier: float, count: int) -> void:
	if hud and hud.has_method("update_combo"):
		hud.update_combo(multiplier, count)

func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size = Vector2(600, size + 10)
	return l
