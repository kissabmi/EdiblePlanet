## BossBase — shared logic for all bosses
extends RigidBody2D

var boss_name: String = "Unknown"
var boss_hp: int = 500
var boss_max_hp: int = 500
var is_active: bool = false
var attack_timer: float = 0.0
var attack_interval: float = 3.0
var is_enraged: bool = false

signal hp_changed(current: int, maximum: int)
signal boss_died()

func _ready() -> void:
	collision_layer = 8  # boss layer (bit 4)
	collision_mask = 1 | 16  # planet + magnet
	contact_monitor = true
	max_contacts_reported = 8
	mass = 10.0
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	add_child(col)

func activate() -> void:
	is_active = true
	boss_hp = boss_max_hp
	attack_timer = attack_interval
	global_position = Vector2(640, -200)
	linear_velocity = Vector2(0, 30)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	attack_timer -= delta
	if attack_timer <= 0:
		_do_attack()
		attack_timer = attack_interval * (0.5 if is_enraged else 1.0)
	var planet_center: Vector2 = Vector2(640, 420)
	apply_central_force((planet_center - global_position).normalized() * 50.0)
	if InputManager.magnet_attracting:
		var mc: Node2D = _get_magnet_ctrl()
		if mc:
			var mpos: Vector2 = mc.get_magnet_world_pos()
			var dist: float = global_position.distance_to(mpos)
			if dist < 200.0:
				take_damage(int(2 * (1.0 - dist / 200.0)))

func _get_magnet_ctrl() -> Node2D:
	var g: Node = get_tree().get_first_node_in_group("game_world")
	if g:
		var p: Node2D = g.get_node_or_null("Planet")
		if p:
			return p.get_node_or_null("MagnetController")
	return null

func take_damage(amount: int) -> void:
	boss_hp -= amount
	hp_changed.emit(boss_hp, boss_max_hp)
	AudioManager.play_sfx("boss_hit")
	_spawn_chunk()
	if boss_hp <= boss_max_hp * 0.3 and not is_enraged:
		is_enraged = true
		attack_interval *= 0.6
	if boss_hp <= 0:
		_die()

func _spawn_chunk() -> void:
	var chunk: RigidBody2D = RigidBody2D.new()
	chunk.set_script(load("res://scripts/food/candy_asteroid.gd"))
	chunk.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	chunk.linear_velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var fg: Node2D = _get_food_group()
	if fg: fg.add_child(chunk)

func _die() -> void:
	is_active = false
	boss_died.emit()
	WaveManager.notify_boss_defeated()
	AudioManager.play_sfx("boss_die")
	for i in range(15):
		_spawn_chunk()
	var bonus: RigidBody2D = RigidBody2D.new()
	bonus.set_script(load("res://scripts/food/bonus_box.gd"))
	bonus.global_position = global_position
	var fg: Node2D = _get_food_group()
	if fg: fg.add_child(bonus)
	queue_free()

func _do_attack() -> void:
	pass

func _get_food_group() -> Node2D:
	var g: Node = get_tree().get_first_node_in_group("game_world")
	if g: return g.get_node_or_null("FoodGroup")
	return null

func _spawn_hazard_at(script_path: String, pos: Vector2, vel: Vector2) -> void:
	var obj: RigidBody2D = RigidBody2D.new()
	obj.set_script(load(script_path))
	obj.global_position = pos
	obj.linear_velocity = vel
	var fg: Node2D = _get_food_group()
	if fg: fg.add_child(obj)
