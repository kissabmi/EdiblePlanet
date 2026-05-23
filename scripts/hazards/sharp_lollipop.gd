## SharpLollipop — fast, freezes on contact
extends HazardBase

func _ready() -> void:
	hazard_type = "lollipop"
	penalty = -15
	super._ready()
	add_child(_create_lollipop_sprite())
	_launch_from_space()

func _launch_from_space() -> void:
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 450)
	var target: Vector2 = Vector2(640, 450) + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	linear_velocity = (target - global_position).normalized() * 200.0  # Fast!

func apply_hazard_effect(planet: Node2D) -> void:
	ScoreManager.apply_freeze(1.0)
	planet.mouth.close_mouth(1.0)

func _create_lollipop_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(16, 24, false, Image.FORMAT_RGBA8)
	# Red-white sharp candy with stick
	var candy: Color = Color(0.9, 0.1, 0.1)
	var white: Color = Color(1.0, 1.0, 1.0)
	var stick: Color = Color(0.9, 0.85, 0.7)
	for y in range(24):
		for x in range(16):
			var nx: float = (x - 8.0) / 8.0
			var ny: float = (y - 8.0) / 8.0
			var d: float = sqrt(nx * nx + ny * ny)
			if d < 0.8:
				# Spiral pattern
				var spiral: float = sin(atan2(ny, nx) * 3 + ny * 8) * 0.5 + 0.5
				img.set_pixel(x, y, candy.lerp(white, spiral))
			elif y > 14 and absf(nx) < 0.15:
				img.set_pixel(x, y, stick)
			# Spike at top
			elif ny < -0.7 and absf(nx) < 0.2 + (0.8 + ny) * 0.5:
				img.set_pixel(x, y, candy)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s
