## ChocoButterfly — brown flying butterfly
extends RigidBody2D

var points: int = 25

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 32
	contact_monitor = true
	max_contacts_reported = 4
	gravity_scale = -0.1
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)
	_add_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(640, 420) + Vector2(cos(angle), sin(angle)) * 200.0
	linear_velocity = Vector2.from_angle(randf() * TAU) * 80.0

func _physics_process(_delta: float) -> void:
	linear_velocity += Vector2.from_angle(randf() * TAU) * 5.0
	var dist: float = global_position.distance_to(Vector2(640, 420))
	if dist > 400:
		apply_central_force((Vector2(640, 420) - global_position).normalized() * 100.0)
	var planet: Node2D = _get_planet()
	if planet:
		apply_central_force(planet.get_gravity_direction() * 0.3)
		apply_central_force(planet.get_magnet_force(global_position))
		apply_central_force((planet.global_position - global_position).normalized() * 60.0)

func _add_sprite() -> void:
	var img: Image = Image.create(22, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(22):
			var dx: float = (x - 11.0) / 11.0
			var dy: float = (y - 8.0) / 8.0
			var lw: float = sqrt(((dx+0.3)*2)**2 + dy**2)
			var rw: float = sqrt(((dx-0.3)*2)**2 + dy**2)
			if lw < 1.0 or rw < 1.0:
				img.set_pixel(x, y, Color(0.5, 0.25, 0.1))
			elif absf(dx) < 0.1:
				img.set_pixel(x, y, Color(0.3, 0.15, 0.05))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 1
	add_child(s)

func is_food() -> bool: return true
func get_points() -> int: return points
func _get_planet() -> Node2D:
	var g: Node = get_tree().get_first_node_in_group("game_world")
	if g: return g.get_node_or_null("Planet")
	return null
