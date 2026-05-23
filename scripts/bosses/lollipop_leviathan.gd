## LollipopLeviathan — Level 1 boss: shoots sharp lollipops, tail meteor
extends "res://scripts/bosses/boss_base.gd"

func _ready() -> void:
	boss_name = "Lollipop Leviathan"
	boss_hp = 500
	boss_max_hp = 500
	attack_interval = 3.0
	super._ready()
	add_child(_create_leviathan_sprite())

func _do_attack() -> void:
	var attack_type: int = randi() % 3
	match attack_type:
		0: _shoot_lollipops()
		1: _tail_meteor()
		2: _spin_attack()

func _shoot_lollipops() -> void:
	# Fire 3 sharp lollipops toward planet
	for i in range(3):
		var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
		var proj: RigidBody2D = RigidBody2D.new()
		proj.set_script(lollipop_script)
		proj.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var planet_center: Vector2 = Vector2(640, 450)
		var dir: Vector2 = (planet_center - global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))).normalized()
		proj.linear_velocity = dir * 250.0
		get_parent().add_child(proj)

func _tail_meteor() -> void:
	# Launch a pepper meteor
	var meteor_script: GDScript = load("res://scripts/hazards/pepper_meteor.gd")
	var meteor: RigidBody2D = RigidBody2D.new()
	meteor.set_script(meteor_script)
	meteor.global_position = global_position
	var planet_center: Vector2 = Vector2(640, 450)
	meteor.linear_velocity = (planet_center - global_position).normalized() * 180.0
	get_parent().add_child(meteor)

func _spin_attack() -> void:
	# Spin and launch lollipops in all directions
	for i in range(8):
		var angle: float = TAU * i / 8.0
		var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
		var proj: RigidBody2D = RigidBody2D.new()
		proj.set_script(lollipop_script)
		proj.global_position = global_position
		proj.linear_velocity = Vector2(cos(angle), sin(angle)) * 200.0
		get_parent().add_child(proj)

func _enter_rage() -> void:
	super._enter_rage()
	# Extra: acid jipples every attack
	attack_interval = 2.0

func _create_leviathan_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(100, 80, false, Image.FORMAT_RGBA8)
	# Giant candy serpent — red/pink/white with lollipop features
	var body_c: Color = Color(0.9, 0.15, 0.2)
	var stripe_c: Color = Color(1.0, 0.9, 0.95)
	var eye_c: Color = Color(1.0, 1.0, 0.0)
	for y in range(80):
		for x in range(100):
			var nx: float = (x - 50.0) / 50.0
			var ny: float = (y - 40.0) / 40.0
			# Worm body
			var d: float = sqrt((nx * 1.5) ** 2 + ny ** 2)
			if d < 1.0:
				# Stripe pattern
				var stripe: float = sin(ny * 12.0) * 0.5 + 0.5
				img.set_pixel(x, y, body_c.lerp(stripe_c, stripe * 0.5))
			# Eyes
			if sqrt((nx - 0.3) ** 2 + (ny - 0.3) ** 2) < 0.12:
				img.set_pixel(x, y, eye_c)
			if sqrt((nx + 0.3) ** 2 + (ny - 0.3) ** 2) < 0.12:
				img.set_pixel(x, y, eye_c)
			# Mouth
			if ny > 0.5 and absf(nx) < 0.3 and ny < 0.7:
				img.set_pixel(x, y, Color(0.2, 0.0, 0.0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s
