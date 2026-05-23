## CakeComet — slow, huge, adds time bonus
extends RigidBody2D

var points: int = 50
var time_bonus: float = 3.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 5
	contact_monitor = true
	max_contacts_reported = 4
	mass = 3.0
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 25.0
	col.shape = shape
	add_child(col)
	add_child(_create_cake_sprite())
	_launch_from_space()

func _launch_from_space() -> void:
	var angle: float = randf() * TAU
	var start: Vector2 = Vector2(cos(angle), sin(angle)) * 700.0
	global_position = start + Vector2(640, 450)
	var target: Vector2 = Vector2(640, 450) + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	var direction: Vector2 = (target - global_position).normalized()
	linear_velocity = direction * 40.0  # Slow!

func _physics_process(_delta: float) -> void:
	var planet: Node2D = _get_planet()
	if planet:
		apply_central_force(planet.get_gravity_direction() * 0.3)
		apply_central_force(planet.get_magnet_force(global_position))
		var to_planet: Vector2 = planet.global_position - global_position
		apply_central_force(to_planet.normalized() * 80.0)

func _create_cake_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(50, 40, false, Image.FORMAT_RGBA8)
	# Birthday cake: cream base, layers, candle
	var cream: Color = Color(1.0, 0.95, 0.8)
	var layer1: Color = Color(0.9, 0.6, 0.3)
	var layer2: Color = Color(0.8, 0.4, 0.2)
	var candle: Color = Color(1.0, 0.2, 0.2)
	var flame: Color = Color(1.0, 0.8, 0.0)
	for y in range(40):
		for x in range(50):
			var nx: float = (x - 25.0) / 25.0
			var ny: float = (y - 20.0) / 20.0
			# Bottom layer
			if ny > 0.0 and ny < 0.5 and absf(nx) < 0.8:
				img.set_pixel(x, y, layer1)
			# Top layer
			elif ny > -0.2 and ny < 0.2 and absf(nx) < 0.6:
				img.set_pixel(x, y, layer2)
			# Frosting on top
			elif ny > -0.4 and ny < -0.1 and absf(nx) < 0.65:
				img.set_pixel(x, y, cream)
			# Candle
			elif absf(nx) < 0.05 and ny > -0.8 and ny < -0.4:
				img.set_pixel(x, y, candle)
			# Flame
			elif absf(nx) < 0.08 and ny > -0.95 and ny < -0.75:
				img.set_pixel(x, y, flame)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s

func is_food() -> bool:
	return true

func get_points() -> int:
	return points

func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null
