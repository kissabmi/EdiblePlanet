## AcidJelly — crawls toward mouth
extends CharacterBody2D

var hazard_type: String = "acid"
var penalty: int = -30
var crawl_speed: float = 30.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 32
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	_add_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(640, 420) + Vector2(cos(angle), sin(angle)) * 135.0

func _physics_process(_delta: float) -> void:
	var planet: Node2D = _get_planet()
	if planet:
		var mouth_pos: Vector2 = planet.global_position + Vector2(0, -130)
		velocity = (mouth_pos - global_position).normalized() * crawl_speed
		velocity += planet.get_magnet_force(global_position) * 0.3
		velocity += planet.get_gravity_direction() * 0.2
		velocity += (planet.global_position - global_position).normalized() * 100.0
	move_and_slide()

func apply_hazard_effect(_planet: Node2D) -> void:
	ScoreManager.close_mouth(3.0)

func _add_sprite() -> void:
	var img: Image = Image.create(20, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(20):
			var d: float = sqrt(((x-10)/10.0)**2 + ((y-10)/8.0)**2)
			if d < 0.8:
				img.set_pixel(x, y, Color(0.2, 0.9, 0.1))
			elif d < 1.0:
				img.set_pixel(x, y, Color(0.1, 0.6, 0.05))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 1
	add_child(s)

func is_hazard() -> bool: return true
func is_food() -> bool: return false
func get_penalty() -> int: return penalty
func get_hazard_type() -> String: return hazard_type

func _get_planet() -> Node2D:
	var g: Node = get_tree().get_first_node_in_group("game_world")
	if g: return g.get_node_or_null("Planet")
	return null
