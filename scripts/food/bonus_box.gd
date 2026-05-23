## BonusBox — gives superpowers
extends "res://scripts/food/food_base.gd"

var bonus_type: String = ""
var bonus_duration: float = 8.0

const BONUS_TYPES: Array[String] = ["double_magnet", "slow_time", "auto_mouth", "shield", "beacon"]
const BONUS_DURATIONS: Dictionary = {"double_magnet": 10.0, "slow_time": 8.0, "auto_mouth": 8.0, "shield": 6.0, "beacon": 10.0}

func _ready() -> void:
	bonus_type = BONUS_TYPES[randi() % BONUS_TYPES.size()]
	bonus_duration = BONUS_DURATIONS.get(bonus_type, 8.0)
	super._ready()
	_add_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 420)
	linear_velocity = (Vector2(640, 420) - global_position).normalized() * 60.0

func _add_sprite() -> void:
	var img: Image = Image.create(28, 28, false, Image.FORMAT_RGBA8)
	for y in range(28):
		for x in range(28):
			var nx: float = (x-14)/14.0
			var ny: float = (y-14)/14.0
			if absf(nx) < 0.8 and absf(ny) < 0.8:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.0))
			if absf(nx) < 0.15 and absf(ny) < 0.85:
				img.set_pixel(x, y, Color(0.9, 0.1, 0.1))
			if absf(ny) < 0.15 and absf(nx) < 0.85:
				img.set_pixel(x, y, Color(0.9, 0.1, 0.1))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 2
	add_child(s)

func is_bonus() -> bool: return true
func get_bonus_type() -> String: return bonus_type
func get_bonus_duration() -> float: return bonus_duration
