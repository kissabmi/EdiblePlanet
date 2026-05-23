## PepperMeteor — explodes, stuns area
extends "res://scripts/hazards/hazard_base.gd"

func _ready() -> void:
	hazard_type = "pepper"
	penalty = -20
	super._ready()
	_add_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 420)
	linear_velocity = (Vector2(640, 420) - global_position).normalized() * 120.0

func apply_hazard_effect(planet: Node2D) -> void:
	ScoreManager.close_mouth(2.0)

func _add_sprite() -> void:
	var img: Image = Image.create(22, 22, false, Image.FORMAT_RGBA8)
	for y in range(22):
		for x in range(22):
			var d: float = sqrt(((x-11)/11.0)**2 + ((y-11)/11.0)**2)
			if d < 0.5:
				img.set_pixel(x, y, Color(1.0, 0.5, 0.0))
			elif d < 0.8:
				img.set_pixel(x, y, Color(0.8, 0.2, 0.0))
			elif d < 1.0:
				img.set_pixel(x, y, Color(1.0, 0.7, 0.2, (1.0 - d) * 3.0))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 1
	add_child(s)
