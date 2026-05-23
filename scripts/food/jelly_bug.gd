## JellyBug — green bug on planet surface
extends CharacterBody2D

var points: int = 15
var move_speed: float = 60.0
var direction: Vector2 = Vector2.RIGHT
var dir_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 32
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	_add_bug_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(640, 420) + Vector2(cos(angle), sin(angle)) * 130.0
	direction = Vector2.from_angle(randf() * TAU)

func _physics_process(delta: float) -> void:
	dir_timer += delta
	if dir_timer >= 2.0:
		direction = Vector2.from_angle(randf() * TAU)
		dir_timer = 0.0
	var planet: Node2D = _get_planet()
	if planet:
		var mf: Vector2 = planet.get_magnet_force(global_position)
		if mf.length() > 50:
			direction = -mf.normalized()
			move_speed = 100.0
		else:
			move_speed = 60.0
		velocity = direction * move_speed + planet.get_gravity_direction() * 0.3 + mf * 0.5
		velocity += (planet.global_position - global_position).normalized() * 80.0
	move_and_slide()

func _add_bug_sprite() -> void:
	var img: Image = Image.create(18, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(18):
			var d: float = sqrt(((x-9)/9.0)**2 + ((y-8)/8.0)**2)
			if d < 0.6:
				img.set_pixel(x, y, Color(0.2, 0.9, 0.3))
			elif d < 0.7:
				img.set_pixel(x, y, Color(0.1, 0.7, 0.2))
			if (absf(x-6.0) < 2 and absf(y-4.0) < 2) or (absf(x-12.0) < 2 and absf(y-4.0) < 2):
				img.set_pixel(x, y, Color.WHITE)
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
