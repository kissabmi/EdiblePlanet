## CaramelKraken — Level 3 boss: 8 tentacles, shooting, rotation, rage phase
extends "res://scripts/bosses/boss_base.gd"

var tentacle_count: int = 8
var rotation_speed: float = 0.5
var current_rotation: float = 0.0
var tentacle_timer: float = 0.0
var tentacle_attack_interval: float = 1.5

func _ready() -> void:
	boss_name = "Caramel Kraken"
	boss_hp = 1200
	boss_max_hp = 1200
	attack_interval = 2.0
	super._ready()
	add_child(_create_kraken_sprite())

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_active:
		current_rotation += rotation_speed * delta * (2.0 if is_enraged else 1.0)
		# Tentacle attacks on their own timer
		tentacle_timer -= delta
		if tentacle_timer <= 0:
			_tentacle_shoot()
			tentacle_timer = tentacle_attack_interval * (0.5 if is_enraged else 1.0)

func _do_attack() -> void:
	var attack_type: int = randi() % 3
	match attack_type:
		0: _tentacle_sweep()
		1: _caramel_barrage()
		2: _ink_cloud()

func _tentacle_sweep() -> void:
	# Sweep lollipops in an arc from each tentacle
	for i in range(tentacle_count):
		var angle: float = current_rotation + TAU * i / tentacle_count
		var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
		var proj: RigidBody2D = RigidBody2D.new()
		proj.set_script(lollipop_script)
		var tentacle_pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * 60.0
		proj.global_position = tentacle_pos
		proj.linear_velocity = Vector2(cos(angle), sin(angle)) * 220.0
		get_parent().add_child(proj)

func _caramel_barrage() -> void:
	# Rapid fire toward planet
	var planet_center: Vector2 = Vector2(640, 450)
	for i in range(10):
		var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
		var proj: RigidBody2D = RigidBody2D.new()
		proj.set_script(lollipop_script)
		proj.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var dir: Vector2 = (planet_center - global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))).normalized()
		proj.linear_velocity = dir * 280.0
		get_parent().add_child(proj)

func _ink_cloud() -> void:
	# Spawn acid jellies around planet
	for i in range(5):
		var acid_script: GDScript = load("res://scripts/hazards/acid_jelly.gd")
		var acid: CharacterBody2D = CharacterBody2D.new()
		acid.set_script(acid_script)
		var angle: float = randf() * TAU
		acid.global_position = Vector2(640, 450) + Vector2(cos(angle), sin(angle)) * 160.0
		get_parent().add_child(acid)

func _tentacle_shoot() -> void:
	# Single tentacle fires a lollipop
	var tent_idx: int = randi() % tentacle_count
	var angle: float = current_rotation + TAU * tent_idx / tentacle_count
	var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
	var proj: RigidBody2D = RigidBody2D.new()
	proj.set_script(lollipop_script)
	proj.global_position = global_position + Vector2(cos(angle), sin(angle)) * 55.0
	var planet_center: Vector2 = Vector2(640, 450)
	proj.linear_velocity = (planet_center - proj.global_position).normalized() * 200.0
	get_parent().add_child(proj)

func _enter_rage() -> void:
	super._enter_rage()
	rotation_speed = 1.2
	attack_interval = 1.0
	tentacle_attack_interval = 0.7
	# Extra tentacle attacks + pepper meteors
	_spawn_rage_particles()

func _spawn_rage_particles() -> void:
	var p: GPUParticles2D = GPUParticles2D.new()
	p.amount = 30
	p.lifetime = 1.0
	p.explosiveness = 0.8
	p.one_shot = true
	p.position = Vector2.ZERO
	var pm: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 50.0
	pm.initial_velocity_max = 150.0
	pm.scale_min = 4.0
	pm.scale_max = 8.0
	pm.color = Color(0.8, 0.3, 0.0)
	p.process_material = pm
	p.emitting = true
	add_child(p)

func _create_kraken_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(120, 120, false, Image.FORMAT_RGBA8)
	# Giant caramel octopus — amber/gold with tentacles and big eyes
	var body_c: Color = Color(0.85, 0.55, 0.15)
	var tent_c: Color = Color(0.75, 0.45, 0.1)
	var eye_c: Color = Color(1.0, 0.3, 0.0)
	var pupil: Color = Color(0.0, 0.0, 0.0)
	var sucker: Color = Color(0.65, 0.35, 0.08)
	for y in range(120):
		for x in range(120):
			var nx: float = (x - 60.0) / 60.0
			var ny: float = (y - 60.0) / 60.0
			# Central body
			var d: float = sqrt(nx ** 2 + (ny * 1.2) ** 2)
			if d < 0.35:
				img.set_pixel(x, y, body_c)
			# Eyes
			if sqrt((nx - 0.12) ** 2 + (ny - 0.1) ** 2) < 0.08:
				img.set_pixel(x, y, eye_c)
				if sqrt((nx - 0.12) ** 2 + (ny - 0.1) ** 2) < 0.04:
					img.set_pixel(x, y, pupil)
			if sqrt((nx + 0.12) ** 2 + (ny - 0.1) ** 2) < 0.08:
				img.set_pixel(x, y, eye_c)
				if sqrt((nx + 0.12) ** 2 + (ny - 0.1) ** 2) < 0.04:
					img.set_pixel(x, y, pupil)
			# Tentacles — 8 curved appendages
			for t in range(8):
				var t_angle: float = TAU * t / 8.0
				var t_len: float = 0.7
				for seg in range(10):
					var seg_f: float = seg / 10.0
					var tx: float = nx - cos(t_angle) * (0.35 + seg_f * t_len) * 0.5
					var ty: float = ny - sin(t_angle) * (0.35 + seg_f * t_len) * 0.5
					var td: float = sqrt(tx ** 2 + ty ** 2)
					if td < 0.04 * (1.0 - seg_f * 0.5):
						img.set_pixel(x, y, tent_c)
						# Suckers
						if seg % 2 == 0 and td < 0.025:
							img.set_pixel(x, y, sucker)
			# Mouth
			if ny > 0.15 and ny < 0.3 and absf(nx) < 0.15:
				img.set_pixel(x, y, Color(0.2, 0.05, 0.0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s
