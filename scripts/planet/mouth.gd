## Mouth — the eating zone on the planet
extends Area2D

const MOUTH_RADIUS: float = 50.0
const AUTO_MOUTH_RADIUS: float = 80.0

var is_auto_mouth: bool = false
var mouth_open: bool = true

func _ready() -> void:
	# Create collision shape for mouth
	var col: CollisionShape2D = CollisionShape2D.new()
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
			# Check combo
			if _is_combo_eat(body):
				ScoreManager.register_combo(pos)
			body.queue_free()
	elif body.has_method("is_hazard") and body.is_hazard():
		if not ScoreManager.is_mouth_closed() and not get_parent().has_shield:
			var penalty: int = body.get_penalty()
			var hazard_type: String = body.get_hazard_type()
			var pos: Vector2 = body.global_position
			ScoreManager.apply_poison(penalty, hazard_type, pos)
			AudioManager.play_sfx("poison")
			# Apply hazard special effects
			body.apply_hazard_effect(get_parent())
			body.queue_free()
		elif get_parent().has_shield:
			# Shield blocks the poison — just destroy it
			body.queue_free()
	elif body.has_method("is_bonus") and body.is_bonus():
		var bonus_type: String = body.get_bonus_type()
		var duration: float = body.get_bonus_duration()
		get_parent().activate_bonus(bonus_type, duration)
		AudioManager.play_sfx("bonus")
		body.queue_free()

func _is_combo_eat(_body: Node2D) -> bool:
	# Combo if magnet was recently affecting this food type
	return InputManager.magnet_attracting or InputManager.magnet_repelling

func set_auto_mouth(active: bool) -> void:
	is_auto_mouth = active
	if active:
		# Expand collision radius
		var col: CollisionShape2D = get_child(0) as CollisionShape2D
		if col and col.shape is CircleShape2D:
			col.shape.radius = AUTO_MOUTH_RADIUS
	else:
		var col: CollisionShape2D = get_child(0) as CollisionShape2D
		if col and col.shape is CircleShape2D:
			col.shape.radius = MOUTH_RADIUS

func close_mouth(duration: float) -> void:
	mouth_open = false
	await get_tree().create_timer(duration).timeout
	mouth_open = true
