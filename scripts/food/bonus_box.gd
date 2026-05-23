## BonusBox — gives superpowers when eaten
extends RigidBody2D

var bonus_type: String = ""
var bonus_duration: float = 8.0

const BONUS_TYPES: Array[String] = ["double_magnet", "slow_time", "auto_mouth", "shield", "beacon"]
const BONUS_DURATIONS: Dictionary = {
	"double_magnet": 10.0,
	"slow_time": 8.0,
	"auto_mouth": 8.0,
	"shield": 6.0,
	"beacon": 10.0,
}

func _ready() -> void:
	bonus_type = BONUS_TYPES[randi() % BONUS_TYPES.size()]
	bonus_duration = BONUS_DURATIONS.get(bonus_type, 8.0)
	collision_layer = 2
	collision_mask = 1 | 5
	contact_monitor = true
	max_contacts_reported = 4
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	add_child(col)
	add_child(_create_box_sprite())
	_launch_from_space()

func _launch_from_space() -> void:
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 450)
	var target: Vector2 = Vector2(640, 450) + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	linear_velocity = (target - global_position).normalized() * 60.0

func _physics_process(_delta: float) -> void:
	var planet: Node2D = _get_planet()
	if planet:
		apply_central_force(planet.get_magnet_force(global_position))
		var to_planet: Vector2 = planet.global_position - global_position
		apply_central_force(to_planet.normalized() * 100.0)

func _create_box_sprite() -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(28, 28, false, Image.FORMAT_RGBA8)
	# Gift box — gold with red ribbon
	var box_color: Color = Color(1.0, 0.85, 0.0)
	var ribbon: Color = Color(0.9, 0.1, 0.1)
	for y in range(28):
		for x in range(28):
			var nx: float = (x - 14.0) / 14.0
			var ny: float = (y - 14.0) / 14.0
			if absf(nx) < 0.8 and absf(ny) < 0.8:
				img.set_pixel(x, y, box_color)
			# Vertical ribbon
			if absf(nx) < 0.15 and absf(ny) < 0.85:
				img.set_pixel(x, y, ribbon)
			# Horizontal ribbon
			if absf(ny) < 0.15 and absf(nx) < 0.85:
				img.set_pixel(x, y, ribbon)
			# Bow on top
			if ny < -0.7 and absf(nx) < 0.3:
				img.set_pixel(x, y, ribbon)
	# Glow
	var glow: Sprite2D = Sprite2D.new()
	var glow_img: Image = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	for y in range(36):
		for x in range(36):
			var dx: float = (x - 18.0) / 18.0
			var dy: float = (y - 18.0) / 18.0
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 1.0:
				glow_img.set_pixel(x, y, Color(1, 0.9, 0.3, 0.2 * (1.0 - d)))
	var glow_tex: ImageTexture = ImageTexture.create_from_image(glow_img)
	glow.texture = glow_tex
	glow.position = Vector2(-4, -4)
	add_child(glow)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	s.texture = tex
	return s

func is_food() -> bool:
	return true

func get_points() -> int:
	return 0

func is_bonus() -> bool:
	return true

func get_bonus_type() -> String:
	return bonus_type

func get_bonus_duration() -> float:
	return bonus_duration

func _get_planet() -> Node2D:
	var game: Node = get_tree().get_first_node_in_group("game_world")
	if game:
		return game.get_node_or_null("Planet") as Node2D
	return null
