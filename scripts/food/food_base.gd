## FoodBase — base class for all edible objects
extends RigidBody2D

class_name FoodBase

var food_type: String = "candy"
var points: int = 10
var is_on_surface: bool = false
var combo_eligible: bool = false
var magnet_affected: bool = false
var tilt_affected: bool = false

func _ready() -> void:
	# Set collision layer to food (layer 2), mask for planet/magnet
	collision_layer = 2
	collision_mask = 1 | 5  # planet + magnet_zone
	contact_monitor = true
	max_contacts_reported = 4
	# Create collision shape
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)
	# Create sprite placeholder
	var sprite: Sprite2D = _create_sprite()
	add_child(sprite)

func _physics_process(_delta: float) -> void:
	if not is_inside_tree():
		return
	# Apply tilt gravity
	var planet: Node2D = _get_planet()
	if planet:
		var tilt_force: Vector2 = planet.get_gravity_direction()
		apply_central_force(tilt_force * 0.5)
		# Apply magnet force
		var magnet_force: Vector2 = planet.get_magnet_force(global_position)
		if magnet_force.length() > 0:
			apply_central_force(magnet_force)
			magnet_affected = true
		else:
			magnet_affected = false
		# Apply surface gravity (pull toward planet surface)
		var to_planet: Vector2 = planet.global_position - global_position
		var dist: float = to_planet.length()
		if dist > 0:
			var surface_gravity: Vector2 = to_planet.normalized() * 150.0
			apply_central_force(surface_gravity)

func _create_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(_get_food_color())
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s

func _get_food_color() -> Color:
	match food_type:
		"candy": return Color(1.0, 0.4, 0.7)  # Pink
		"bug": return Color(0.2, 0.9, 0.3)    # Green
		"butterfly": return Color(0.6, 0.3, 0.1) # Brown
		"cake": return Color(1.0, 0.9, 0.6)    # Cream
		"bonus": return Color(1.0, 0.85, 0.0)  # Gold
		_: return Color.WHITE

func is_food() -> bool:
	return true

func get_points() -> int:
	return points

func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null

func set_food_type(type_name: String, pts: int) -> void:
	food_type = type_name
	points = pts
