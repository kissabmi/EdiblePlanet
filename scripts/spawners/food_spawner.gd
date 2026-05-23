## FoodSpawner — spawns space food (candy, cake, bonus, lollipops, peppers)
extends Node

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var wave_config: Dictionary = {}
var spawned_counts: Dictionary = {}
var is_active: bool = false

func _ready() -> void:
	WaveManager.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_number: int) -> void:
	wave_config = WaveManager._get_wave_config(WaveManager.current_level, wave_number)
	spawned_counts = {
		"candy": 0, "bug": 0, "butterfly": 0, "cake": 0,
		"lollipop": 0, "pepper": 0, "acid": 0, "bonus": 0
	}
	spawn_interval = maxf(0.5, 2.0 / wave_config.get("speed_mult", 1.0))
	is_active = true

func _process(delta: float) -> void:
	if not is_active:
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_try_spawn()

func _try_spawn() -> void:
	# Check what still needs spawning
	var types: Array = ["candy", "lollipop", "pepper", "cake", "bonus"]
	for type_name in types:
		var target: int = wave_config.get(type_name, 0)
		if spawned_counts.get(type_name, 0) < target:
			_spawn_space_object(type_name)
			spawned_counts[type_name] = spawned_counts.get(type_name, 0) + 1
			return

func _spawn_space_object(type_name: String) -> void:
	var node: Node2D = null
	match type_name:
		"candy":
			var obj: RigidBody2D = RigidBody2D.new()
			obj.set_script(load("res://scripts/food/candy_asteroid.gd"))
			node = obj
		"lollipop":
			var obj: RigidBody2D = RigidBody2D.new()
			obj.set_script(load("res://scripts/hazards/sharp_lollipop.gd"))
			node = obj
		"pepper":
			var obj: RigidBody2D = RigidBody2D.new()
			obj.set_script(load("res://scripts/hazards/pepper_meteor.gd"))
			node = obj
		"cake":
			var obj: RigidBody2D = RigidBody2D.new()
			obj.set_script(load("res://scripts/food/cake_comet.gd"))
			node = obj
		"bonus":
			var obj: RigidBody2D = RigidBody2D.new()
			obj.set_script(load("res://scripts/food/bonus_box.gd"))
			node = obj
	if node:
		get_parent().get_node("FoodGroup").add_child(node)
