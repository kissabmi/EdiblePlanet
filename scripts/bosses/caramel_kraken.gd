## CaramelKraken — Level 3 boss
extends "res://scripts/bosses/boss_base.gd"

var current_rotation: float = 0.0
var rotation_speed: float = 0.5
var tent_timer: float = 0.0
var tent_interval: float = 1.5

func _ready() -> void:
	boss_name = "Caramel Kraken"
	boss_hp = 1200
	boss_max_hp = 1200
	attack_interval = 2.0
	super._ready()
	_add_sprite()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_active:
		current_rotation += rotation_speed * delta * (2.0 if is_enraged else 1.0)
		tent_timer -= delta
		if tent_timer <= 0:
			var t: int = randi() % 8
			var a: float = current_rotation + TAU * t / 8.0
			var dir: Vector2 = (Vector2(640,420) - global_position).normalized()
			_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", global_position + Vector2(cos(a), sin(a)) * 55, dir * 200)
			tent_timer = tent_interval * (0.5 if is_enraged else 1.0)

func _do_attack() -> void:
	match randi() % 3:
		0:
			for i in range(8):
				var a: float = current_rotation + TAU * i / 8.0
				_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", global_position + Vector2(cos(a), sin(a)) * 60, Vector2(cos(a), sin(a)) * 220)
		1:
			for i in range(10):
				var dir: Vector2 = (Vector2(640,420) - global_position + Vector2(randf_range(-80,80), randf_range(-80,80))).normalized()
				_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", global_position + Vector2(randf_range(-30,30), randf_range(-30,30)), dir * 280)
		2:
			for i in range(5):
				var acid: CharacterBody2D = CharacterBody2D.new()
				acid.set_script(load("res://scripts/hazards/acid_jelly.gd"))
				var a: float = randf() * TAU
				acid.global_position = Vector2(640, 420) + Vector2(cos(a), sin(a)) * 160
				var fg: Node2D = _get_food_group()
				if fg: fg.add_child(acid)

func _add_sprite() -> void:
	var img: Image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	for y in range(100):
		for x in range(100):
			var nx: float = (x-50)/50.0
			var ny: float = (y-50)/50.0
			var d: float = sqrt(nx**2 + (ny*1.2)**2)
			if d < 0.35:
				img.set_pixel(x, y, Color(0.85, 0.55, 0.15))
			if sqrt((nx-0.12)**2+(ny-0.1)**2) < 0.08: img.set_pixel(x, y, Color(1,0.3,0))
			if sqrt((nx-0.12)**2+(ny-0.1)**2) < 0.04: img.set_pixel(x, y, Color(0,0,0))
			if sqrt((nx+0.12)**2+(ny-0.1)**2) < 0.08: img.set_pixel(x, y, Color(1,0.3,0))
			if sqrt((nx+0.12)**2+(ny-0.1)**2) < 0.04: img.set_pixel(x, y, Color(0,0,0))
			for t in range(8):
				var ta: float = TAU * t / 8.0
				var tl: float = 0.7
				for seg in range(8):
					var sf: float = seg / 8.0
					var tx: float = nx - cos(ta)*(0.35+sf*tl)*0.5
					var ty: float = ny - sin(ta)*(0.35+sf*tl)*0.5
					if sqrt(tx**2+ty**2) < 0.04*(1.0-sf*0.5):
						img.set_pixel(x, y, Color(0.75,0.45,0.1))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 3
	add_child(s)
