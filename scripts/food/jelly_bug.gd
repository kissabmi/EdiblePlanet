## JellyBug — runs on the planet surface
extends CharacterBody2D

var bug_type: String = "jelly_bug"
var points: int = 15
var move_speed: float = 60.0
var direction: Vector2 = Vector2.RIGHT
var direction_timer: float = 0.0
var direction_change_interval: float = 2.0
var is_magnet_panic: bool = false

func _ready() -> void:
	# Collision: food layer
	collision_layer = 2
	collision_mask = 1 | 5
	# Create collision shape
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	# Create bug sprite
	add_child(_create_bug_sprite())
	# Place on planet surface
	_place_on_surface()
	# Random initial direction
	direction = Vector2.from_angle(randf() * TAU)

func _physics_process(delta: float) -> void:
	# Change direction periodically
	direction_timer += delta
	if direction_timer >= direction_change_interval:
		direction = Vector2.from_angle(randf() * TAU)
		direction_timer = 0.0
		direction_change_interval = randf_range(1.5, 3.0)

	# Check for magnet — panic!
	var planet: Node2D = _get_planet()
	if planet:
		var magnet_force: Vector2 = planet.get_magnet_force(global_position)
		if magnet_force.length() > 50:
			is_magnet_panic = true
			direction = -magnet_force.normalized()  # Run away from magnet
			move_speed = 100.0
		else:
			is_magnet_panic = false
			move_speed = 60.0
		# Tilt force
		var tilt_force: Vector2 = planet.get_gravity_direction()
		velocity = direction * move_speed + tilt_force * 0.3 + magnet_force * 0.5
		# Surface gravity
		var to_planet: Vector2 = planet.global_position - global_position
		velocity += to_planet.normalized() * 80.0

	move_and_slide()

func _place_on_surface() -> void:
	var angle: float = randf() * TAU
	global_position = Vector2(640, 450) + Vector2(cos(angle), sin(angle)) * 130.0

func _create_bug_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(18, 16, false, Image.FORMAT_RGBA8)
	# Draw a cute jelly bug — green body, legs, eyes
	var body_color: Color = Color(0.2, 0.9, 0.3)
	var eye_color: Color = Color(1.0, 1.0, 1.0)
	for y in range(16):
		for x in range(18):
			var dx: float = (x - 9.0) / 9.0
			var dy: float = (y - 8.0) / 8.0
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 0.6:
				img.set_pixel(x, y, body_color)
			elif d < 0.7:
				img.set_pixel(x, y, Color(0.1, 0.7, 0.2))
			# Eyes
			if (absf(x - 6.0) < 2 and absf(y - 4.0) < 2) or (absf(x - 12.0) < 2 and absf(y - 4.0) < 2):
				img.set_pixel(x, y, eye_color)
				if d < 0.3:
					img.set_pixel(x, y, Color(0, 0, 0))
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
