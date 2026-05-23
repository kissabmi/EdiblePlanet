## Planet — the main character: a donut with a mouth
extends Node2D

const PLANET_RADIUS: float = 150.0
const MAX_TILT_ANGLE: float = 30.0

@onready var planet_sprite: Sprite2D = $PlanetSprite
@onready var mouth: Area2D = $Mouth
@onready var tilt_controller: Node2D = $TiltController
@onready var magnet_controller: Node2D = $MagnetController
@onready var magnet_cursor: Sprite2D = $MagnetCursor
@onready var magnet_zone: Area2D = $MagnetZone

var tilt_angle: float = 0.0
var gravity_angle: float = 0.0  # direction objects slide toward mouth
var planet_center: Vector2 = Vector2(640, 450)
var shake_offset: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0

# Bonus state
var active_bonus: String = ""
var bonus_timer: float = 0.0
var magnet_radius_mult: float = 1.0
var has_shield: bool = false

# Vortex detection
var vortex_active: bool = false
var vortex_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	position = planet_center
	InputManager.tilt_changed.connect(_on_tilt_changed)
	InputManager.magnet_moved.connect(_on_magnet_moved)
	InputManager.magnet_attract_started.connect(_on_magnet_attract)
	InputManager.magnet_attract_stopped.connect(_on_magnet_attract_stop)
	InputManager.magnet_repel_started.connect(_on_magnet_repel)
	InputManager.magnet_repel_stopped.connect(_on_magnet_repel_stop)
	ScoreManager.food_eaten.connect(_on_food_eaten)
	ScoreManager.poison_hit.connect(_on_poison_hit)

func _process(delta: float) -> void:
	# Smooth tilt visual
	rotation_degrees = lerp(rotation_degrees, tilt_angle * MAX_TILT_ANGLE, delta * 8.0)
	# Screen shake decay
	if shake_intensity > 0:
		shake_intensity -= delta * 20.0
		shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
		position = planet_center + shake_offset
	else:
		position = planet_center
	# Bonus timer
	if bonus_timer > 0:
		bonus_timer -= delta
		if bonus_timer <= 0:
			_deactivate_bonus()
	# Update magnet cursor position
	magnet_cursor.position = magnet_controller.get_magnet_world_pos() - position
	magnet_zone.position = magnet_cursor.position
	# Magnet fatigue
	if InputManager.magnet_attracting:
		var elapsed: float = magnet_controller.attract_duration
		if elapsed > 3.0:
			magnet_radius_mult = maxf(0.8, 1.0 - (elapsed - 3.0) * 0.05)
	else:
		magnet_radius_mult = lerp(magnet_radius_mult, 1.0, delta * 2.0)
	# Vortex check
	_check_vortex()

func _on_tilt_changed(direction: Vector2) -> void:
	tilt_angle = direction.x
	gravity_angle = direction.angle()

func _on_magnet_moved(pos: Vector2) -> void:
	magnet_controller.update_position(pos)

func _on_magnet_attract() -> void:
	magnet_controller.start_attract()
	AudioManager.play_sfx("magnet_on")

func _on_magnet_attract_stop() -> void:
	magnet_controller.stop_attract()
	AudioManager.play_sfx("magnet_off")

func _on_magnet_repel() -> void:
	magnet_controller.start_repel()
	AudioManager.play_sfx("magnet_on")

func _on_magnet_repel_stop() -> void:
	magnet_controller.stop_repel()
	AudioManager.play_sfx("magnet_off")

func _on_food_eaten(_type: String, _points: int, pos: Vector2) -> void:
	# Chomp animation
	_do_chomp_animation()
	_spawn_eat_particles(pos)

func _on_poison_hit(_type: String, _penalty: int, _pos: Vector2) -> void:
	shake_intensity = 8.0
	if not has_shield:
		_do_hurt_animation()

func _do_chomp_animation() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(planet_sprite, "scale", Vector2(1.05, 0.95), 0.05)
	tween.tween_property(planet_sprite, "scale", Vector2(0.98, 1.02), 0.05)
	tween.tween_property(planet_sprite, "scale", Vector2(1.0, 1.0), 0.05)

func _do_hurt_animation() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(planet_sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(planet_sprite, "modulate", Color.WHITE, 0.3)

func _spawn_eat_particles(pos: Vector2) -> void:
	# Particle effect at eat position
	var particles: GPUParticles2D = _create_confetti_particles()
	particles.position = pos - position
	particles.emitting = true
	add_child(particles)
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

func _create_confetti_particles() -> GPUParticles2D:
	var p: GPUParticles2D = GPUParticles2D.new()
	p.amount = 12
	p.lifetime = 0.4
	p.explosiveness = 0.9
	p.one_shot = true
	var pm: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 100.0
	pm.initial_velocity_max = 200.0
	pm.gravity = Vector3(0, 200, 0)
	pm.scale_min = 2.0
	pm.scale_max = 4.0
	pm.color = Color(1, 0.8, 0.9)
	# Random color via curve
	var color_ramp: Gradient = Gradient.new()
	color_ramp.colors = PackedColorArray([Color(1, 0.5, 0.8), Color(0.5, 0.8, 1), Color(1, 1, 0.5), Color(0.8, 1, 0.5)])
	pm.color_ramp = color_ramp
	p.process_material = pm
	return p

func _check_vortex() -> void:
	# Vortex = magnet attracting toward one point while tilt pushes same object from opposite
	# Simplified: if magnet is active and tilt direction points objects toward magnet cursor
	if InputManager.magnet_attracting and absf(tilt_angle) > 0.2:
		vortex_active = true
		vortex_position = magnet_controller.get_magnet_world_pos()
	else:
		vortex_active = false

func activate_bonus(bonus_type: String, duration: float) -> void:
	active_bonus = bonus_type
	bonus_timer = duration
	ScoreManager.add_bonus()
	match bonus_type:
		"double_magnet":
			magnet_radius_mult = 2.0
		"slow_time":
			Engine.time_scale = 0.5
			await get_tree().create_timer(duration).timeout
			Engine.time_scale = 1.0
		"auto_mouth":
			mouth.set_auto_mouth(true)
		"shield":
			has_shield = true
		"beacon":
			magnet_controller.activate_beacon()
	AudioManager.play_sfx("bonus")

func _deactivate_bonus() -> void:
	match active_bonus:
		"double_magnet":
			magnet_radius_mult = 1.0
		"auto_mouth":
			mouth.set_auto_mouth(false)
		"shield":
			has_shield = false
		"beacon":
			magnet_controller.deactivate_beacon()
	active_bonus = ""

func get_gravity_direction() -> Vector2:
	return Vector2(cos(gravity_angle), sin(gravity_angle)) * 200.0

func get_magnet_force(pos: Vector2) -> Vector2:
	return magnet_controller.get_force_at(pos)

func is_vortex_active() -> bool:
	return vortex_active

func get_vortex_pos() -> Vector2:
	return vortex_position
