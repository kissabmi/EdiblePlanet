## Planet — the donut with a mouth
extends Node2D

var tilt_angle: float = 0.0
var gravity_angle: float = 0.0
var planet_center: Vector2 = Vector2(640, 420)
var shake_offset: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0

# Bonus
var active_bonus: String = ""
var bonus_timer: float = 0.0
var magnet_radius_mult: float = 1.0
var has_shield: bool = false
var vortex_active: bool = false
var vortex_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	InputManager.tilt_changed.connect(_on_tilt_changed)
	InputManager.magnet_moved.connect(_on_magnet_moved)
	InputManager.magnet_attract_started.connect(_on_magnet_attract)
	InputManager.magnet_attract_stopped.connect(_on_magnet_attract_stop)
	InputManager.magnet_repel_started.connect(_on_magnet_repel)
	InputManager.magnet_repel_stopped.connect(_on_magnet_repel_stop)
	ScoreManager.food_eaten.connect(_on_food_eaten)
	ScoreManager.poison_hit.connect(_on_poison_hit)

func _get_magnet_controller() -> Node2D:
	return get_node_or_null("MagnetController") as Node2D

func _get_magnet_cursor() -> Sprite2D:
	return get_node_or_null("MagnetCursor") as Sprite2D

func _get_mouth() -> Area2D:
	return get_node_or_null("Mouth") as Area2D

func _get_planet_sprite() -> Sprite2D:
	return get_node_or_null("PlanetSprite") as Sprite2D

func _process(delta: float) -> void:
	# Tilt visual
	rotation_degrees = lerp(rotation_degrees, tilt_angle * 30.0, delta * 8.0)
	# Shake
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
	# Magnet cursor
	var mc: Node2D = _get_magnet_controller()
	var cursor: Sprite2D = _get_magnet_cursor()
	if mc and cursor:
		cursor.position = mc.get_magnet_world_pos() - global_position
	# Magnet fatigue
	if InputManager.magnet_attracting:
		if mc:
			var elapsed: float = mc.attract_duration
			if elapsed > 3.0:
				magnet_radius_mult = maxf(0.8, 1.0 - (elapsed - 3.0) * 0.05)
	else:
		magnet_radius_mult = lerp(magnet_radius_mult, 1.0, delta * 2.0)
	# Vortex check
	vortex_active = InputManager.magnet_attracting and absf(tilt_angle) > 0.2
	if vortex_active and mc:
		vortex_position = mc.get_magnet_world_pos()

func _on_tilt_changed(direction: Vector2) -> void:
	tilt_angle = direction.x
	gravity_angle = direction.angle()

func _on_magnet_moved(pos: Vector2) -> void:
	var mc: Node2D = _get_magnet_controller()
	if mc:
		mc.update_position(pos)

func _on_magnet_attract() -> void:
	var mc: Node2D = _get_magnet_controller()
	if mc: mc.start_attract()
	AudioManager.play_sfx("magnet_on")

func _on_magnet_attract_stop() -> void:
	var mc: Node2D = _get_magnet_controller()
	if mc: mc.stop_attract()
	AudioManager.play_sfx("magnet_off")

func _on_magnet_repel() -> void:
	var mc: Node2D = _get_magnet_controller()
	if mc: mc.start_repel()
	AudioManager.play_sfx("magnet_on")

func _on_magnet_repel_stop() -> void:
	var mc: Node2D = _get_magnet_controller()
	if mc: mc.stop_repel()
	AudioManager.play_sfx("magnet_off")

func _on_food_eaten(_type: String, _points: int, pos: Vector2) -> void:
	var ps: Sprite2D = _get_planet_sprite()
	if ps:
		var tween: Tween = create_tween()
		tween.tween_property(ps, "scale", Vector2(1.05, 0.95), 0.05)
		tween.tween_property(ps, "scale", Vector2(0.98, 1.02), 0.05)
		tween.tween_property(ps, "scale", Vector2(1.0, 1.0), 0.05)

func _on_poison_hit(_type: String, _penalty: int, _pos: Vector2) -> void:
	shake_intensity = 8.0
	if not has_shield:
		var ps: Sprite2D = _get_planet_sprite()
		if ps:
			var tween: Tween = create_tween()
			tween.tween_property(ps, "modulate", Color(1, 0.5, 0.5), 0.1)
			tween.tween_property(ps, "modulate", Color.WHITE, 0.3)

func activate_bonus(bonus_type: String, duration: float) -> void:
	active_bonus = bonus_type
	bonus_timer = duration
	ScoreManager.add_bonus()
	match bonus_type:
		"double_magnet":
			magnet_radius_mult = 2.0
		"slow_time":
			Engine.time_scale = 0.5
		"auto_mouth":
			var m: Area2D = _get_mouth()
			if m: m.set_auto_mouth(true)
		"shield":
			has_shield = true
		"beacon":
			var mc: Node2D = _get_magnet_controller()
			if mc: mc.activate_beacon()
	AudioManager.play_sfx("bonus")

func _deactivate_bonus() -> void:
	match active_bonus:
		"double_magnet":
			magnet_radius_mult = 1.0
		"slow_time":
			Engine.time_scale = 1.0
		"auto_mouth":
			var m: Area2D = _get_mouth()
			if m: m.set_auto_mouth(false)
		"shield":
			has_shield = false
		"beacon":
			var mc: Node2D = _get_magnet_controller()
			if mc: mc.deactivate_beacon()
	active_bonus = ""

func get_gravity_direction() -> Vector2:
	return Vector2(cos(gravity_angle), sin(gravity_angle)) * 200.0

func get_magnet_force(pos: Vector2) -> Vector2:
	var mc: Node2D = _get_magnet_controller()
	if mc:
		return mc.get_force_at(pos)
	return Vector2.ZERO
