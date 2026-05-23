## ChocolateChthon — Level 2 boss
extends "res://scripts/bosses/boss_base.gd"

var regen_rate: float = 5.0
var regen_acc: float = 0.0

func _ready() -> void:
	boss_name = "Chocolate Chthon"
	boss_hp = 800
	boss_max_hp = 800
	attack_interval = 2.5
	super._ready()
	_add_sprite()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_active:
		regen_acc += delta
		if regen_acc >= 1.0:
			regen_acc = 0.0
			if boss_hp < boss_max_hp:
				boss_hp = mini(boss_hp + int(regen_rate), boss_max_hp)
				hp_changed.emit(boss_hp, boss_max_hp)

func _do_attack() -> void:
	match randi() % 3:
		0:
			for i in range(3):
				var dir: Vector2 = (Vector2(640,420) - global_position).normalized()
				var acid: CharacterBody2D = CharacterBody2D.new()
				acid.set_script(load("res://scripts/hazards/acid_jelly.gd"))
				acid.global_position = global_position + Vector2(randf_range(-30,30), 30)
				acid.velocity = dir * 100
				var fg: Node2D = _get_food_group()
				if fg: fg.add_child(acid)
		1:
			for i in range(4):
				var a: float = randf() * TAU
				_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", global_position + Vector2(randf_range(-40,40), randf_range(-40,40)), Vector2(cos(a), sin(a)) * 150)
			boss_hp -= 20
			hp_changed.emit(boss_hp, boss_max_hp)
		2:
			for i in range(6):
				_spawn_hazard_at("res://scripts/hazards/sharp_lollipop.gd", Vector2(randf_range(200,1080), -50), Vector2(0, 200))

func _add_sprite() -> void:
	var img: Image = Image.create(80, 70, false, Image.FORMAT_RGBA8)
	for y in range(70):
		for x in range(80):
			var nx: float = (x-40)/40.0
			var ny: float = (y-35)/35.0
			var d: float = sqrt((nx*1.3)**2 + ny**2)
			if d < 1.0:
				var c: float = sin(nx*8.0+ny*5.0)*0.5+0.5
				img.set_pixel(x, y, Color(0.35,0.18,0.08).lerp(Color(0.6,0.3,0.12), c*0.4))
			if sqrt((nx-0.25)**2+(ny-0.25)**2) < 0.1: img.set_pixel(x, y, Color(1,0.6,0))
			if sqrt((nx+0.25)**2+(ny-0.25)**2) < 0.1: img.set_pixel(x, y, Color(1,0.6,0))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 3
	add_child(s)
