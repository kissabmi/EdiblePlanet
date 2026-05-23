## Mouth — eating zone
extends Area2D

const MOUTH_RADIUS: float = 50.0
const AUTO_MOUTH_RADIUS: float = 80.0

var is_auto_mouth: bool = false
var mouth_open: bool = true

func _ready() -> void:
	# Ensure collision shape exists
	var col: CollisionShape2D = get_node_or_null("MouthCollision")
	if not col:
		col = CollisionShape2D.new()
		col.name = "MouthCollision"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = MOUTH_RADIUS
		col.shape = shape
		add_child(col)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not mouth_open:
		return
	if body.has_method("is_food") and body.is_food():
		if is_auto_mouth or not ScoreManager.is_mouth_closed():
			var points: int = body.get_points()
			var pos: Vector2 = body.global_position
			ScoreManager.add_score(points, pos)
			WaveManager.register_food_eaten()
			AudioManager.play_sfx("eat" + str(randi_range(1, 3)))
			if InputManager.magnet_attracting or InputManager.magnet_repelling:
				ScoreManager.register_combo(pos)
			body.queue_free()
	elif body.has_method("is_hazard") and body.is_hazard():
		var planet: Node2D = get_parent()
		if not ScoreManager.is_mouth_closed() and planet and not planet.has_shield:
			var penalty: int = body.get_penalty()
			var hazard_type: String = body.get_hazard_type()
			var pos: Vector2 = body.global_position
			ScoreManager.apply_poison(penalty, hazard_type, pos)
			AudioManager.play_sfx("poison")
			body.apply_hazard_effect(planet)
			body.queue_free()
		elif planet and planet.has_shield:
			body.queue_free()
	elif body.has_method("is_bonus") and body.is_bonus():
		var bonus_type: String = body.get_bonus_type()
		var duration: float = body.get_bonus_duration()
		var planet: Node2D = get_parent()
		if planet:
			planet.activate_bonus(bonus_type, duration)
		AudioManager.play_sfx("bonus")
		body.queue_free()

func set_auto_mouth(active: bool) -> void:
	is_auto_mouth = active
	var col: CollisionShape2D = get_node_or_null("MouthCollision")
	if col and col.shape is CircleShape2D:
		col.shape.radius = AUTO_MOUTH_RADIUS if active else MOUTH_RADIUS

func close_mouth(duration: float) -> void:
	mouth_open = false
	await get_tree().create_timer(duration).timeout
	mouth_open = true
