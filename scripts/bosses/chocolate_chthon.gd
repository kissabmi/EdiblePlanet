## ChocolateChthon — Level 2 boss: breaks into chunks, regenerates, acid pools
extends "res://scripts/bosses/boss_base.gd"

var chunk_spawned: bool = false
var regen_timer: float = 0.0
var regen_rate: float = 5.0  # HP per second

func _ready() -> void:
	boss_name = "Chocolate Chthon"
	boss_hp = 800
	boss_max_hp = 800
	attack_interval = 2.5
	super._ready()
	add_child(_create_chthon_sprite())

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_active:
		# Regenerate slowly
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			if boss_hp < boss_max_hp:
				boss_hp = mini(boss_hp + int(regen_rate), boss_max_hp)
				hp_changed.emit(boss_hp, boss_max_hp)

func _do_attack() -> void:
	var attack_type: int = randi() % 3
	match attack_type:
		0: _acid_spray()
		1: _chunk_burst()
		2: _chocolate_rain()

func _acid_spray() -> void:
	# Spray 3 acid jellies onto planet surface
	for i in range(3):
		var acid_script: GDScript = load("res://scripts/hazards/acid_jelly.gd")
		var acid: CharacterBody2D = CharacterBody2D.new()
		acid.set_script(acid_script)
		acid.global_position = global_position + Vector2(randf_range(-30, 30), 30)
		var planet_center: Vector2 = Vector2(640, 450)
		acid.velocity = (planet_center - global_position).normalized() * 100.0
		get_parent().add_child(acid)

func _chunk_burst() -> void:
	# Break off chunks that become hazards
	for i in range(4):
		var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
		var chunk: RigidBody2D = RigidBody2D.new()
		chunk.set_script(lollipop_script)
		chunk.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var angle: float = randf() * TAU
		chunk.linear_velocity = Vector2(cos(angle), sin(angle)) * 150.0
		get_parent().add_child(chunk)
	# Also damage self a bit (chunk torn off)
	boss_hp -= 20
	hp_changed.emit(boss_hp, boss_max_hp)

func _chocolate_rain() -> void:
	# Rain sharp lollipops from above
	for i in range(6):
		var lollipop_script: GDScript = load("res://scripts/hazards/sharp_lollipop.gd")
		var proj: RigidBody2D = RigidBody2D.new()
		proj.set_script(lollipop_script)
		proj.global_position = Vector2(randf_range(200, 1080), -50)
		proj.linear_velocity = Vector2(0, 200.0)
		get_parent().add_child(proj)

func _enter_rage() -> void:
	super._enter_rage()
	regen_rate = 15.0  # Faster regen when enraged
	attack_interval = 1.5

func _create_chthon_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(110, 90, false, Image.FORMAT_RGBA8)
	# Giant chocolate monster — brown with cracks, dripping
	var dark_choc: Color = Color(0.35, 0.18, 0.08)
	var milk_choc: Color = Color(0.6, 0.3, 0.12)
	var crack: Color = Color(0.8, 0.4, 0.1)
	var drip: Color = Color(0.45, 0.22, 0.1)
	var eye_c: Color = Color(1.0, 0.6, 0.0)
	for y in range(90):
		for x in range(110):
			var nx: float = (x - 55.0) / 55.0
			var ny: float = (y - 45.0) / 45.0
			var d: float = sqrt((nx * 1.3) ** 2 + ny ** 2)
			if d < 1.0:
				# Crack pattern
				var c: float = sin(nx * 8.0 + ny * 5.0) * 0.5 + 0.5
				img.set_pixel(x, y, dark_choc.lerp(milk_choc, c * 0.4))
				# Visible cracks
				if absf(sin(nx * 12.0)) < 0.1 or absf(sin(ny * 10.0)) < 0.1:
					img.set_pixel(x, y, crack)
			# Dripping chocolate at bottom
			if ny > 0.85 and absf(nx) < 0.6 and fmod(x, 12.0) < 6.0:
				img.set_pixel(x, y, drip)
			# Eyes
			if sqrt((nx - 0.25) ** 2 + (ny - 0.25) ** 2) < 0.1:
				img.set_pixel(x, y, eye_c)
			if sqrt((nx + 0.25) ** 2 + (ny - 0.25) ** 2) < 0.1:
				img.set_pixel(x, y, eye_c)
			# Mouth
			if ny > 0.4 and ny < 0.6 and absf(nx) < 0.35:
				img.set_pixel(x, y, Color(0.15, 0.05, 0.0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s
