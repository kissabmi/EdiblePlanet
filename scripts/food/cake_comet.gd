## CakeComet — slow big cake
extends "res://scripts/food/food_base.gd"

func _ready() -> void:
	food_type = "cake"
	points = 50
	super._ready()
	mass = 3.0
	_add_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 420)
	linear_velocity = (Vector2(640, 420) - global_position).normalized() * 40.0

func _add_sprite() -> void:
	var img: Image = Image.create(40, 36, false, Image.FORMAT_RGBA8)
	for y in range(36):
		for x in range(40):
			var nx: float = (x-20)/20.0
			var ny: float = (y-18)/18.0
			if ny > 0.0 and ny < 0.5 and absf(nx) < 0.8:
				img.set_pixel(x, y, Color(0.9, 0.6, 0.3))
			elif ny > -0.2 and ny < 0.2 and absf(nx) < 0.6:
				img.set_pixel(x, y, Color(0.8, 0.4, 0.2))
			elif ny > -0.4 and ny < -0.1 and absf(nx) < 0.65:
				img.set_pixel(x, y, Color(1.0, 0.95, 0.8))
			elif absf(nx) < 0.05 and ny < -0.4 and ny > -0.8:
				img.set_pixel(x, y, Color(1.0, 0.2, 0.2))
			elif absf(nx) < 0.08 and ny < -0.8 and ny > -0.95:
				img.set_pixel(x, y, Color(1.0, 0.8, 0.0))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 1
	add_child(s)
