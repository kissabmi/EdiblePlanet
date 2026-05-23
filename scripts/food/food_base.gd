## FoodBase — base for all edible objects
extends RigidBody2D

var food_type: String = "candy"
var points: int = 10
var sprite_created: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 32  # planet + mouth (bit 6)
	contact_monitor = true
	max_contacts_reported = 4
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

func _physics_process(_delta: float) -> void:
	var planet: Node2D = _get_planet()
	if not planet:
		return
	apply_central_force(planet.get_gravity_direction() * 0.5)
	apply_central_force(planet.get_magnet_force(global_position))
	var to_planet: Vector2 = planet.global_position - global_position
	apply_central_force(to_planet.normalized() * 150.0)

func is_food() -> bool:
	return true

func get_points() -> int:
	return points

func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null
