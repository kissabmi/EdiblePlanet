## TiltController — applies gravity direction based on tilt input
extends Node2D

var tilt_direction: Vector2 = Vector2.ZERO
var tilt_strength: float = 200.0

func _ready() -> void:
	# Position mouth at top of planet (where food slides to)
	position = Vector2(0, -140)

func apply_tilt_force(body: Node2D) -> Vector2:
	if tilt_direction == Vector2.ZERO:
		return Vector2.ZERO
	var force: Vector2 = tilt_direction * tilt_strength
	return force
