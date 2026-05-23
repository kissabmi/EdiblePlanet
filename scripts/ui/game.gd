## Game scene — main gameplay
extends Node2D

@onready var planet: Node2D = $Planet
@onready var hud: CanvasLayer = $HUD

var boss_node: Node2D = null

func _ready() -> void:
	add_to_group("game_world")
	WaveManager.boss_spawned.connect(_on_boss_spawned)
	WaveManager.level_completed.connect(_on_level_completed)
	WaveManager.all_levels_done.connect(_on_all_done)
	ScoreManager.combo_changed.connect(_on_combo_changed)
	InputManager.magnet_moved.connect(_on_magnet_moved)
	# Start level 1
	WaveManager.start_level(1)

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
	$FoodGroup.add_child(boss_node)
	boss_node.activate()
	# Show boss HP bar
	if hud:
		hud.show_boss_hp(boss_data.hp)

func _on_level_completed(stars: int, stats: Dictionary) -> void:
	SaveManager.set_stars(WaveManager.current_level, stars)
	SaveManager.set_high_score(WaveManager.current_level, stats.score)
	# Transition to results
	await get_tree().create_timer(1.0).timeout
	_show_results(stars, stats)

func _on_all_done(stats: Dictionary) -> void:
	SaveManager.set_stars(3, _calc_final_stars(stats))
	await get_tree().create_timer(2.0).timeout
	_show_results(3, stats, true)

func _calc_final_stars(stats: Dictionary) -> int:
	if stats.score > 5000 and stats.poisoned < 5: return 3
	if stats.score > 3000: return 2
	return 1

func _show_results(stars: int, stats: Dictionary, is_final: bool = false) -> void:
	# Create results overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = Vector2(1280, 720)
	overlay.position = Vector2(0, 0)
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	canvas.add_child(overlay)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(340, 100)
	vbox.size = Vector2(600, 500)
	canvas.add_child(vbox)

	# Title
	var title: Label = _make_label("LEVEL COMPLETE!" if not is_final else "YOU WIN!", 48, Color(1, 0.85, 0))
	vbox.add_child(title)

	# Stars
	var stars_text: String = ""
	for i in range(3):
		stars_text += "★" if i < stars else "☆"
	var stars_label: Label = _make_label(stars_text, 64, Color(1, 0.85, 0) if stars >= 3 else Color(0.7, 0.7, 0.7))
	vbox.add_child(stars_label)

	# Stats
	var stats_text: String = "Score: %d\nEaten: %d\nPoisoned: %d\nMax Combo: %dx\nVortexes: %d\nBonuses: %d" % [
		stats.score, stats.eaten, stats.poisoned, stats.max_combo, stats.vortexes, stats.bonuses
	]
	var stats_label: Label = _make_label(stats_text, 24, Color.WHITE)
	vbox.add_child(stats_label)

	# Buttons
	var btn_next: Button = Button.new()
	btn_next.text = "Next Level" if not is_final else "Main Menu"
	btn_next.custom_minimum_size = Vector2(200, 50)
	btn_next.pressed.connect(_on_results_next.bind(is_final))
	vbox.add_child(btn_next)

	var btn_retry: Button = Button.new()
	btn_retry.text = "Retry"
	btn_retry.custom_minimum_size = Vector2(200, 50)
	btn_retry.pressed.connect(_on_retry)
	vbox.add_child(btn_retry)

func _on_results_next(is_final: bool) -> void:
	if is_final or WaveManager.current_level >= 3:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		# Restart scene with next level
		WaveManager.start_level(WaveManager.current_level + 1)
		get_tree().reload_current_scene()

func _on_retry() -> void:
	WaveManager.start_level(WaveManager.current_level)
	get_tree().reload_current_scene()

func _on_combo_changed(multiplier: float, count: int) -> void:
	if hud:
		hud.update_combo(multiplier, count)
	if multiplier >= 5.0:
		# Slow-mo effect
		Engine.time_scale = 0.8
		await get_tree().create_timer(0.3).timeout
		Engine.time_scale = 1.0

func _on_magnet_moved(pos: Vector2) -> void:
	if hud:
		hud.update_magnet_cursor(pos)

func _make_label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size = Vector2(600, size + 10)
	return l
