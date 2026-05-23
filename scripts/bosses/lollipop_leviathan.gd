## LollipopLeviathan — Level 1 boss
extends "res://scripts/bosses/boss_base.gd"

func _ready() -> void:
	boss_name = "Lollipop Leviathan"
	boss_hp = 500
	boss_max_hp = 500
	attack_interval = 3.0
	super._ready()
	_add_sprite()

func _do_attack() -> void:
	match randi() % 3:
		0:
			for i in range(3):
				var dir: Vector2 = (Vector2(640,420) - global_position + Vector2(randf_range(-60,60), randf_range(-60,60))).normalized()
				_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", global_position + Vector2(randf_range(-20,20), randf_range(-20,20)), dir * 250)
		1:
			var dir: Vector2 = (Vector2(640,420) - global_position).normalized()
			_spawn_hazard_at("res://scripts/hazards/pepper_meteor.gd", global_position, dir * 180)
		2:
			for i in range(8):
				var a: float = TAU * i / 8.0
				_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", global_position, Vector2(cos(a), sin(a)) * 200)

func _add_sprite() -> void:
	var img: Image = Image.create(80, 60, false, Image.FORMAT_RGBA8)
	for y in range(60):
		for x in range(80):
			var nx: float = (x-40)/40.0
			var ny: float = (y-30)/30.0
			var d: float = sqrt((nx*1.5)**2 + ny**2)
			if d < 1.0:
				var s: float = sin(ny*12.0)*0.5+0.5
				img.set_pixel(x, y, Color(0.9,0.15,0.2).lerp(Color(1,0.9,0.95), s*0.5))
			if sqrt((nx-0.3)**2+(ny-0.3)**2) < 0.1: img.set_pixel(x, y, Color(1,1,0))
			if sqrt((nx+0.3)**2+(ny-0.3)**2) < 0.1: img.set_pixel(x, y, Color(1,1,0))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 3
	add_child(s)
