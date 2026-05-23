## CandyAsteroid — pink candy from space
extends "res://scripts/food/food_base.gd"

func _ready() -> void:
	food_type = "candy"
	points = 10
	super._ready()
	_add_candy_sprite()
	_launch()

func _launch() -> void:
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 420)
	var target: Vector2 = Vector2(640, 420) + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	linear_velocity = (target - global_position).normalized() * randf_range(80, 150)

func _add_candy_sprite() -> void:
	var img: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var c1: Color = Color(1.0, 0.4, 0.7)
	var c2: Color = Color(1.0, 0.7, 0.9)
	for y in range(24):
		for x in range(24):
			var d: float = sqrt(((x-12)/12.0)**2 + ((y-12)/12.0)**2)
			if d < 0.7:
				img.set_pixel(x, y, c1)
			elif d < 1.0:
				img.set_pixel(x, y, c2)
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 1
	add_child(s)
