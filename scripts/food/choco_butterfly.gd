## ChocoButterfly — flies erratically above the planet
extends RigidBody2D

var points: int = 25
var fly_speed: float = 80.0
var flutter_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 5
	contact_monitor = true
	max_contacts_reported = 4
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)
	add_child(_create_butterfly_sprite())
	# Start above planet
	var angle: float = randf() * TAU
	global_position = Vector2(640, 450) + Vector2(cos(angle), sin(angle)) * 200.0
	linear_velocity = Vector2.from_angle(randf() * TAU) * fly_speed
	gravity_scale = -0.1  # slight float

func _physics_process(delta: float) -> void:
	# Flutter — random direction changes
	flutter_timer += delta
	if flutter_timer > 0.5:
		flutter_timer = 0.0
		linear_velocity += Vector2.from_angle(randf() * TAU) * 40.0
	# Keep within bounds
	var dist: float = global_position.distance_to(Vector2(640, 450))
	if dist > 400:
		var to_center: Vector2 = (Vector2(640, 450) - global_position).normalized()
		apply_central_force(to_center * 100.0)
	# Planet forces
	var planet: Node2D = _get_planet()
	if planet:
		apply_central_force(planet.get_gravity_direction() * 0.3)
		apply_central_force(planet.get_magnet_force(global_position))
		# Surface gravity
		var to_planet: Vector2 = planet.global_position - global_position
		apply_central_force(to_planet.normalized() * 60.0)

func _create_butterfly_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(22, 16, false, Image.FORMAT_RGBA8)
	# Chocolate brown butterfly with wings
	var wing_color: Color = Color(0.5, 0.25, 0.1)
	var body_color: Color = Color(0.3, 0.15, 0.05)
	for y in range(16):
		for x in range(22):
			var dx: float = (x - 11.0) / 11.0
			var dy: float = (y - 8.0) / 8.0
			# Wings (two ovals)
			var left_wing: float = sqrt((dx + 0.3) ** 2 * 4 + dy ** 2)
			var right_wing: float = sqrt((dx - 0.3) ** 2 * 4 + dy ** 2)
			if left_wing < 1.0 or right_wing < 1.0:
				img.set_pixel(x, y, wing_color)
			elif absf(dx) < 0.1:
				img.set_pixel(x, y, body_color)
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
