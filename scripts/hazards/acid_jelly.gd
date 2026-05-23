## AcidJelly — crawls toward the mouth on the planet surface
extends CharacterBody2D

var hazard_type: String = "acid"
var penalty: int = -30
var crawl_speed: float = 30.0

func _ready() -> void:
	# Collision: hazard layer
	collision_layer = 3
	collision_mask = 1 | 5 | 6
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	add_child(_create_jelly_sprite())
	_place_on_surface()

func _physics_process(_delta: float) -> void:
	var planet: Node2D = _get_planet()
	if planet:
		# Crawl toward mouth (top of planet)
		var mouth_pos: Vector2 = planet.global_position + Vector2(0, -140)
		var to_mouth: Vector2 = (mouth_pos - global_position).normalized()
		velocity = to_mouth * crawl_speed
		# Magnet affects it
		var magnet_force: Vector2 = planet.get_magnet_force(global_position)
		velocity += magnet_force * 0.3
		# Tilt
		velocity += planet.get_gravity_direction() * 0.2
		# Surface gravity
		var to_planet: Vector2 = planet.global_position - global_position
		velocity += to_planet.normalized() * 100.0
	move_and_slide()

func _place_on_surface() -> void:
	var angle: float = randf() * TAU
	global_position = Vector2(640, 450) + Vector2(cos(angle), sin(angle)) * 135.0

func apply_hazard_effect(planet: Node2D) -> void:
	# Close mouth for 3 seconds
	ScoreManager.close_mouth(3.0)
	planet.mouth.close_mouth(3.0)

func _create_jelly_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(20, 16, false, Image.FORMAT_RGBA8)
	# Green slime blob with bubbles
	var jelly: Color = Color(0.2, 0.9, 0.1)
	var dark: Color = Color(0.1, 0.6, 0.05)
	var bubble: Color = Color(0.5, 1.0, 0.3)
	for y in range(16):
		for x in range(20):
			var dx: float = (x - 10.0) / 10.0
			var dy: float = (y - 10.0) / 8.0
			var d: float = sqrt(dx * dx * 1.5 + dy * dy)
			if d < 0.8:
				img.set_pixel(x, y, jelly)
			elif d < 1.0:
				img.set_pixel(x, y, dark)
			# Bubbles
			if (absf(x - 6.0) < 2 and absf(y - 4.0) < 2) or (absf(x - 14.0) < 2 and absf(y - 6.0) < 2):
				img.set_pixel(x, y, bubble)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s

func is_hazard() -> bool:
	return true
func is_food() -> bool:
	return false
func get_penalty() -> int:
	return penalty
func get_hazard_type() -> String:
	return hazard_type
func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null
