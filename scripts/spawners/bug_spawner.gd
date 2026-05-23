## BugSpawner — spawns surface creatures (jelly bugs, butterflies, acid jelly)
extends Node

var spawn_timer: float = 0.0
var spawn_interval: float = 3.0
var wave_config: Dictionary = {}
var spawned_counts: Dictionary = {}
var is_active: bool = false

func _ready() -> void:
	WaveManager.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_number: int) -> void:
	wave_config = WaveManager._get_wave_config(WaveManager.current_level, wave_number)
	spawned_counts = {"bug": 0, "butterfly": 0, "acid": 0}
	spawn_interval = maxf(1.0, 3.0 / wave_config.get("speed_mult", 1.0))
	is_active = true

func _process(delta: float) -> void:
	if not is_active:
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_try_spawn()

func _try_spawn() -> void:
	var types: Array = ["bug", "butterfly", "acid"]
	for type_name in types:
		var target: int = wave_config.get(type_name, 0)
		if spawned_counts.get(type_name, 0) < target:
			_spawn_surface_object(type_name)
			spawned_counts[type_name] = spawned_counts.get(type_name, 0) + 1
			return

func _spawn_surface_object(type_name: String) -> void:
	var node: Node2D = null
	match type_name:
		"bug":
			var obj: CharacterBody2D = CharacterBody2D.new()
			obj.set_script(load("res://scripts/food/jelly_bug.gd"))
			node = obj
		"butterfly":
			var obj: RigidBody2D = RigidBody2D.new()
			obj.set_script(load("res://scripts/food/choco_butterfly.gd"))
			node = obj
		"acid":
			var obj: CharacterBody2D = CharacterBody2D.new()
			obj.set_script(load("res://scripts/hazards/acid_jelly.gd"))
			node = obj
	if node:
		get_parent().get_node("FoodGroup").add_child(node)
