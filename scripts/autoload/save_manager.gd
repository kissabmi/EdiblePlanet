## SaveManager — saves progress, records, settings
extends Node

const SAVE_PATH: String = "user://edible_planet_save.json"

var save_data: Dictionary = {
	"high_scores": [0, 0, 0],
	"stars": [0, 0, 0],
	"levels_unlocked": 1,
	"control_mode": 1,
	"music_volume": 0,
	"sfx_volume": 0,
}

func _ready() -> void:
	_load()

func save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func _load() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json: JSON = JSON.new()
			var err: Error = json.parse(file.get_as_text())
			if err == OK:
				var loaded: Dictionary = json.data
				for key in loaded:
					save_data[key] = loaded[key]
			file.close()

func set_high_score(level: int, score: int) -> void:
	if level >= 1 and level <= 3:
		if score > save_data.high_scores[level - 1]:
			save_data.high_scores[level - 1] = score
			save()

func set_stars(level: int, star_count: int) -> void:
	if level >= 1 and level <= 3:
		if star_count > save_data.stars[level - 1]:
			save_data.stars[level - 1] = star_count
		if level < 3 and star_count > 0 and save_data.levels_unlocked <= level:
			save_data.levels_unlocked = level + 1
		save()

func unlock_level(level: int) -> void:
	if level > save_data.levels_unlocked:
		save_data.levels_unlocked = level
		save()

func get_high_score(level: int) -> int:
	if level >= 1 and level <= 3:
		return save_data.high_scores[level - 1]
	return 0

func get_stars(level: int) -> int:
	if level >= 1 and level <= 3:
		return save_data.stars[level - 1]
	return 0

func is_level_unlocked(level: int) -> bool:
	return level <= save_data.levels_unlocked

func set_control_mode(mode: int) -> void:
	save_data.control_mode = mode
	save()

func get_control_mode() -> int:
	return save_data.control_mode
