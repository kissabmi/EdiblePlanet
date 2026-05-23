## HazardBase — base class for all poison/danger objects
extends RigidBody2D

class_name HazardBase

var hazard_type: String = "generic"
var penalty: int = -15

func _ready() -> void:
	collision_layer = 3  # hazard layer
	collision_mask = 1 | 5 | 6  # planet + magnet + mouth
	contact_monitor = true
	max_contacts_reported = 4
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

func _physics_process(_delta: float) -> void:
	var planet: Node2D = _get_planet()
	if planet:
		apply_central_force(planet.get_gravity_direction() * 0.3)
		apply_central_force(planet.get_magnet_force(global_position))
		var to_planet: Vector2 = planet.global_position - global_position
		apply_central_force(to_planet.normalized() * 80.0)

func is_hazard() -> bool:
	return true

func is_food() -> bool:
	return false

func get_penalty() -> int:
	return penalty

func get_hazard_type() -> String:
	return hazard_type

func apply_hazard_effect(planet: Node2D) -> void:
	pass  # Override in subclasses

func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null
