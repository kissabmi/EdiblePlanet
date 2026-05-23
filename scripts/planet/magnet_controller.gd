## MagnetController — handles magnet attraction/repulsion zones
extends Node2D

const BASE_ATTRACT_RADIUS: float = 120.0
const BASE_REPEL_RADIUS: float = 150.0
const ATTRACT_STRENGTH: float = 400.0
const REPEL_STRENGTH: float = 500.0

var is_attracting: bool = false
var is_repelling: bool = false
var magnet_world_pos: Vector2 = Vector2(640, 300)
var attract_duration: float = 0.0

# Beacon (auto-collect)
var beacon_active: bool = false
var beacon_position: Vector2 = Vector2.ZERO
var beacon_radius: float = 200.0

signal force_applied(position: Vector2, force: Vector2, type: String)

func _process(delta: float) -> void:
	if is_attracting:
		attract_duration += delta
	else:
		attract_duration = 0.0

func update_position(screen_pos: Vector2) -> void:
	magnet_world_pos = screen_pos

func get_magnet_world_pos() -> Vector2:
	return magnet_world_pos

func start_attract() -> void:
	is_attracting = true

func stop_attract() -> void:
	is_attracting = false

func start_repel() -> void:
	is_repelling = true

func stop_repel() -> void:
	is_repelling = false

func get_force_at(pos: Vector2) -> Vector2:
	var total_force: Vector2 = Vector2.ZERO
	var radius_mult: float = get_parent().magnet_radius_mult if get_parent() else 1.0

	if is_attracting:
		var attract_r: float = BASE_ATTRACT_RADIUS * radius_mult
		var dist: float = pos.distance_to(magnet_world_pos)
		if dist < attract_r and dist > 5.0:
			var direction: Vector2 = (magnet_world_pos - pos).normalized()
			var falloff: float = 1.0 - (dist / attract_r)
			total_force += direction * ATTRACT_STRENGTH * falloff

	if is_repelling:
		var repel_r: float = BASE_REPEL_RADIUS * radius_mult
		var dist: float = pos.distance_to(magnet_world_pos)
		if dist < repel_r and dist > 5.0:
			var direction: Vector2 = (pos - magnet_world_pos).normalized()
			var falloff: float = 1.0 - (dist / repel_r)
			total_force += direction * REPEL_STRENGTH * falloff

	# Beacon force
	if beacon_active:
		var bdist: float = pos.distance_to(beacon_position)
		if bdist < beacon_radius and bdist > 5.0:
			var direction: Vector2 = (beacon_position - pos).normalized()
			var falloff: float = 1.0 - (bdist / beacon_radius)
			total_force += direction * ATTRACT_STRENGTH * 0.6 * falloff

	return total_force

func activate_beacon() -> void:
	beacon_active = true
	beacon_position = magnet_world_pos

func deactivate_beacon() -> void:
	beacon_active = false

func is_attracting() -> bool:
	return is_attracting

func is_repelling() -> bool:
	return is_repelling
