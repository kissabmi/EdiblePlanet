## BugSpawner — spawns surface creatures
extends Node

var spawn_timer: float = 0.0
var spawn_interval: float = 3.0
var wave_config: Dictionary = {}
var spawned: Dictionary = {}
var is_active: bool = false

func _ready() -> void:
	WaveManager.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_number: int) -> void:
	wave_config = WaveManager._get_wave_config(WaveManager.current_level, wave_number)
	spawned = {"bug": 0, "butterfly": 0, "acid": 0}
	spawn_interval = maxf(1.0, 3.0 / wave_config.get("speed_mult", 1.0))
	is_active = true

func _process(delta: float) -> void:
	if not is_active: return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_try_spawn()

func _try_spawn() -> void:
	for type_name in ["bug", "butterfly", "acid"]:
		var target: int = wave_config.get(type_name, 0)
		if spawned.get(type_name, 0) < target:
			_spawn(type_name)
			spawned[type_name] = spawned.get(type_name, 0) + 1
			return

func _spawn(type_name: String) -> void:
	var node: Node2D = null
	match type_name:
		"bug":
			node = CharacterBody2D.new()
			node.set_script(load("res://scripts/food/jelly_bug.gd"))
		"butterfly":
			node = RigidBody2D.new()
			node.set_script(load("res://scripts/food/choco_butterfly.gd"))
		"acid":
			node = CharacterBody2D.new()
			node.set_script(load("res://scripts/hazards/acid_jelly.gd"))
	if node:
		var fg: Node2D = _get_food_group()
		if fg: fg.add_child(node)

func _get_food_group() -> Node2D:
	var g: Node = get_tree().get_first_node_in_group("game_world")
	if g: return g.get_node_or_null("FoodGroup")
	return null
