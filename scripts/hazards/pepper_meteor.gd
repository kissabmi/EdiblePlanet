## PepperMeteor — explodes on surface, stuns area
extends HazardBase

var explosion_radius: float = 100.0

func _ready() -> void:
	hazard_type = "pepper"
	penalty = -20
	super._ready()
	add_child(_create_meteor_sprite())
	_launch_from_space()

func _launch_from_space() -> void:
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 450)
	var target: Vector2 = Vector2(640, 450) + Vector2(randf_range(-60, 60), randf_range(-60, 60))
	linear_velocity = (target - global_position).normalized() * 120.0

func apply_hazard_effect(planet: Node2D) -> void:
	# Stun: close mouth for 2 sec
	ScoreManager.close_mouth(2.0)
	planet.mouth.close_mouth(2.0)
	# Explosion particles
	_spawn_explosion()

func _spawn_explosion() -> void:
	var p: GPUParticles2D = GPUParticles2D.new()
	p.amount = 20
	p.lifetime = 0.5
	p.explosiveness = 0.95
	p.one_shot = true
	p.position = global_position
	var pm: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 150.0
	pm.initial_velocity_max = 300.0
	pm.gravity = Vector3(0, 200, 0)
	pm.scale_min = 3.0
	pm.scale_max = 6.0
	pm.color = Color(1.0, 0.5, 0.0)
	p.process_material = pm
	p.emitting = true
	get_parent().add_child(p)
	await get_tree().create_timer(0.6).timeout
	p.queue_free()

func _create_meteor_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(22, 22, false, Image.FORMAT_RGBA8)
	# Orange fire ball with glow
	var core: Color = Color(1.0, 0.5, 0.0)
	var edge: Color = Color(0.8, 0.2, 0.0)
	var glow_c: Color = Color(1.0, 0.7, 0.2)
	for y in range(22):
		for x in range(22):
			var dx: float = (x - 11.0) / 11.0
			var dy: float = (y - 11.0) / 11.0
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 0.5:
				img.set_pixel(x, y, core)
			elif d < 0.8:
				img.set_pixel(x, y, edge)
			elif d < 1.0:
				img.set_pixel(x, y, Color(glow_c.r, glow_c.g, glow_c.b, (1.0 - d) * 3.0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s
