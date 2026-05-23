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
	collision_layer = 4  # boss layer
	collision_mask = 1 | 5  # planet + magnet
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
	_enter_scene()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	attack_timer -= delta
	if attack_timer <= 0:
		_do_attack()
		attack_timer = attack_interval * (0.5 if is_enraged else 1.0)
	# Orbit around planet
	var planet_center: Vector2 = Vector2(640, 450)
	var to_planet: Vector2 = planet_center - global_position
	apply_central_force(to_planet.normalized() * 50.0)
	# Magnet can pull chunks off
	_apply_magnet_damage()

func _apply_magnet_damage() -> void:
	var planet: Node2D = _get_planet()
	if planet and InputManager.magnet_attracting:
		var magnet_pos: Vector2 = planet.magnet_controller.get_magnet_world_pos()
		var dist: float = global_position.distance_to(magnet_pos)
		if dist < 200.0:
			# Pull a chunk — damage boss + spawn food
			var dmg: int = int(2 * (1.0 - dist / 200.0))
			take_damage(dmg)

func take_damage(amount: int) -> void:
	boss_hp -= amount
	hp_changed.emit(boss_hp, boss_max_hp)
	AudioManager.play_sfx("boss_hit")
	# Spawn food chunk at random position near boss
	_spawn_chunk()
	if boss_hp <= boss_max_hp * 0.3 and not is_enraged:
		is_enraged = true
		_enter_rage()
	if boss_hp <= 0:
		_die()

func _spawn_chunk() -> void:
	# Spawn a candy as a "chunk" torn from the boss
	var candy_script: GDScript = load("res://scripts/food/candy_asteroid.gd")
	var chunk: RigidBody2D = RigidBody2D.new()
	chunk.set_script(candy_script)
	chunk.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	chunk.linear_velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	get_parent().add_child(chunk)

func _die() -> void:
	is_active = false
	boss_died.emit()
	WaveManager.notify_boss_defeated()
	AudioManager.play_sfx("boss_die")
	# Big explosion of food
	for i in range(15):
		_spawn_chunk()
	# Spawn bonus
	var bonus_script: GDScript = load("res://scripts/food/bonus_box.gd")
	var bonus: RigidBody2D = RigidBody2D.new()
	bonus.set_script(bonus_script)
	bonus.global_position = global_position
	get_parent().add_child(bonus)
	queue_free()

func _enter_scene() -> void:
	global_position = Vector2(640, -200)
	linear_velocity = Vector2(0, 30)

func _do_attack() -> void:
	pass  # Override in subclass

func _enter_rage() -> void:
	attack_interval *= 0.6

func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null
