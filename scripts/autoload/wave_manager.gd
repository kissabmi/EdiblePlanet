## WaveManager — controls waves, spawning, timers, bosses
extends Node

signal wave_started(wave_number: int)
signal wave_completed(score: int, stats: Dictionary)
signal boss_spawned(boss_data: Dictionary)
signal level_completed(stars: int, stats: Dictionary)
signal all_levels_done(stats: Dictionary)
signal timer_updated(time_left: float, time_total: float)

var current_level: int = 1
var current_wave: int = 0
var wave_timer: float = 0.0
var wave_time_total: float = 50.0
var wave_active: bool = false
var is_boss_wave: bool = false
var boss_defeated: bool = false
var total_food_in_wave: int = 0
var food_eaten_in_wave: int = 0

# Wave data per level
var level_configs: Array = []

func _ready() -> void:
	_build_level_configs()

func _process(delta: float) -> void:
	if not wave_active:
		return
	wave_timer -= delta
	timer_updated.emit(maxf(0, wave_timer), wave_time_total)
	if wave_timer <= 0 and not is_boss_wave:
		_complete_wave()
	# Boss wave: wait for boss defeat
	if is_boss_wave and boss_defeated:
		_complete_wave()

func start_level(level: int) -> void:
	current_level = level
	current_wave = 0
	ScoreManager.reset()
	_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	if current_wave > 10:
		_complete_level()
		return
	is_boss_wave = (current_wave == 10)
	boss_defeated = false
	wave_active = true

	var cfg: Dictionary = _get_wave_config(current_level, current_wave)
	wave_time_total = cfg.get("time", 50.0)
	wave_timer = wave_time_total
	total_food_in_wave = cfg.get("total_food", 20)
	food_eaten_in_wave = 0

	wave_started.emit(current_wave)
	if is_boss_wave:
		var boss_data: Dictionary = _get_boss_config(current_level)
		boss_spawned.emit(boss_data)

func _complete_wave() -> void:
	wave_active = false
	var stats: Dictionary = ScoreManager.get_stats()
	wave_completed.emit(ScoreManager.score, stats)

	# Small delay then next wave
	await get_tree().create_timer(2.0).timeout
	_start_next_wave()

func _complete_level() -> void:
	wave_active = false
	var stats: Dictionary = ScoreManager.get_stats()
	var stars: int = _calculate_stars(stats)
	level_completed.emit(stars, stats)
	if current_level < 3:
		# Will transition to next level via UI
		pass
	else:
		all_levels_done.emit(stats)

func _calculate_stars(stats: Dictionary) -> int:
	var stars: int = 1
	if stats.eaten > total_food_in_wave * 0.7 and stats.poisoned < 5:
		stars = 2
	if stats.eaten > total_food_in_wave * 0.9 and stats.poisoned < 2 and stats.max_combo >= 10:
		stars = 3
	return stars

func register_food_eaten() -> void:
	food_eaten_in_wave += 1

func notify_boss_defeated() -> void:
	boss_defeated = true

func _get_wave_config(level: int, wave: int) -> Dictionary:
	if level - 1 < level_configs.size() and wave - 1 < level_configs[level - 1].size():
		return level_configs[level - 1][wave - 1]
	return {"time": 50.0, "total_food": 20, "speed_mult": 1.0}

func _get_boss_config(level: int) -> Dictionary:
	var bosses: Array = [
		{"name": "Lollipop Leviathan", "hp": 500, "level": 1},
		{"name": "Chocolate Chthon", "hp": 800, "level": 2},
		{"name": "Caramel Kraken", "hp": 1200, "level": 3}
	]
	return bosses[level - 1]

func _build_level_configs() -> void:
	# Level 1: Milky Valley — gradual introduction
	level_configs.append([
		{"time": 50, "total_food": 10, "speed_mult": 1.0, "candy": 10, "bug": 0, "butterfly": 0, "cake": 0, "lollipop": 0, "pepper": 0, "acid": 0, "bonus": 0},
		{"time": 50, "total_food": 12, "speed_mult": 1.0, "candy": 8, "bug": 4, "butterfly": 0, "cake": 0, "lollipop": 0, "pepper": 0, "acid": 0, "bonus": 0},
		{"time": 48, "total_food": 17, "speed_mult": 1.1, "candy": 10, "bug": 6, "butterfly": 1, "cake": 0, "lollipop": 2, "pepper": 0, "acid": 0, "bonus": 0},
		{"time": 48, "total_food": 21, "speed_mult": 1.2, "candy": 10, "bug": 8, "butterfly": 3, "cake": 0, "lollipop": 3, "pepper": 0, "acid": 0, "bonus": 1},
		{"time": 45, "total_food": 29, "speed_mult": 1.3, "candy": 14, "bug": 10, "butterfly": 4, "cake": 1, "lollipop": 4, "pepper": 1, "acid": 0, "bonus": 1},
		{"time": 45, "total_food": 32, "speed_mult": 1.4, "candy": 14, "bug": 12, "butterfly": 6, "cake": 0, "lollipop": 5, "pepper": 2, "acid": 0, "bonus": 0},
		{"time": 42, "total_food": 37, "speed_mult": 1.5, "candy": 18, "bug": 14, "butterfly": 5, "cake": 0, "lollipop": 6, "pepper": 3, "acid": 0, "bonus": 1},
		{"time": 42, "total_food": 42, "speed_mult": 1.6, "candy": 18, "bug": 16, "butterfly": 8, "cake": 1, "lollipop": 7, "pepper": 4, "acid": 1, "bonus": 1},
		{"time": 40, "total_food": 48, "speed_mult": 1.8, "candy": 22, "bug": 18, "butterfly": 8, "cake": 0, "lollipop": 8, "pepper": 5, "acid": 2, "bonus": 1},
		{"time": 90, "total_food": 50, "speed_mult": 1.0, "candy": 0, "bug": 0, "butterfly": 0, "cake": 0, "lollipop": 0, "pepper": 0, "acid": 0, "bonus": 0},  # Boss wave
	])
	# Level 2: Chocolate Jungle
	level_configs.append([
		{"time": 45, "total_food": 25, "speed_mult": 1.3, "candy": 12, "bug": 10, "butterfly": 3, "cake": 0, "lollipop": 5, "pepper": 3, "acid": 1, "bonus": 1},
		{"time": 45, "total_food": 30, "speed_mult": 1.4, "candy": 14, "bug": 12, "butterfly": 4, "cake": 0, "lollipop": 6, "pepper": 4, "acid": 2, "bonus": 1},
		{"time": 42, "total_food": 35, "speed_mult": 1.5, "candy": 16, "bug": 14, "butterfly": 5, "cake": 1, "lollipop": 7, "pepper": 5, "acid": 2, "bonus": 1},
		{"time": 42, "total_food": 38, "speed_mult": 1.6, "candy": 16, "bug": 16, "butterfly": 6, "cake": 0, "lollipop": 8, "pepper": 6, "acid": 3, "bonus": 1},
		{"time": 40, "total_food": 42, "speed_mult": 1.7, "candy": 18, "bug": 18, "butterfly": 6, "cake": 1, "lollipop": 9, "pepper": 7, "acid": 3, "bonus": 2},
		{"time": 40, "total_food": 45, "speed_mult": 1.8, "candy": 20, "bug": 18, "butterfly": 7, "cake": 0, "lollipop": 10, "pepper": 8, "acid": 4, "bonus": 1},
		{"time": 38, "total_food": 48, "speed_mult": 1.9, "candy": 22, "bug": 20, "butterfly": 6, "cake": 1, "lollipop": 11, "pepper": 9, "acid": 4, "bonus": 1},
		{"time": 38, "total_food": 52, "speed_mult": 2.0, "candy": 22, "bug": 22, "butterfly": 8, "cake": 1, "lollipop": 12, "pepper": 10, "acid": 5, "bonus": 2},
		{"time": 35, "total_food": 55, "speed_mult": 2.1, "candy": 24, "bug": 22, "butterfly": 9, "cake": 1, "lollipop": 13, "pepper": 11, "acid": 5, "bonus": 1},
		{"time": 100, "total_food": 60, "speed_mult": 1.0, "candy": 0, "bug": 0, "butterfly": 0, "cake": 0, "lollipop": 0, "pepper": 0, "acid": 0, "bonus": 0},
	])
	# Level 3: Caramel Cosmos
	level_configs.append([
		{"time": 40, "total_food": 35, "speed_mult": 1.5, "candy": 16, "bug": 14, "butterfly": 5, "cake": 1, "lollipop": 8, "pepper": 6, "acid": 3, "bonus": 2},
		{"time": 38, "total_food": 40, "speed_mult": 1.6, "candy": 18, "bug": 16, "butterfly": 6, "cake": 1, "lollipop": 9, "pepper": 7, "acid": 4, "bonus": 2},
		{"time": 36, "total_food": 45, "speed_mult": 1.7, "candy": 20, "bug": 18, "butterfly": 7, "cake": 1, "lollipop": 10, "pepper": 8, "acid": 4, "bonus": 1},
		{"time": 36, "total_food": 48, "speed_mult": 1.8, "candy": 20, "bug": 20, "butterfly": 8, "cake": 1, "lollipop": 11, "pepper": 9, "acid": 5, "bonus": 2},
		{"time": 34, "total_food": 52, "speed_mult": 1.9, "candy": 22, "bug": 22, "butterfly": 8, "cake": 2, "lollipop": 12, "pepper": 10, "acid": 5, "bonus": 2},
		{"time": 34, "total_food": 55, "speed_mult": 2.0, "candy": 24, "bug": 22, "butterfly": 9, "cake": 1, "lollipop": 13, "pepper": 11, "acid": 6, "bonus": 1},
		{"time": 32, "total_food": 58, "speed_mult": 2.1, "candy": 26, "bug": 24, "butterfly": 8, "cake": 1, "lollipop": 14, "pepper": 12, "acid": 6, "bonus": 2},
		{"time": 32, "total_food": 62, "speed_mult": 2.2, "candy": 26, "bug": 26, "butterfly": 10, "cake": 2, "lollipop": 15, "pepper": 13, "acid": 7, "bonus": 2},
		{"time": 30, "total_food": 65, "speed_mult": 2.4, "candy": 28, "bug": 26, "butterfly": 11, "cake": 2, "lollipop": 16, "pepper": 14, "acid": 7, "bonus": 2},
		{"time": 120, "total_food": 70, "speed_mult": 1.0, "candy": 0, "bug": 0, "butterfly": 0, "cake": 0, "lollipop": 0, "pepper": 0, "acid": 0, "bonus": 0},
	])
