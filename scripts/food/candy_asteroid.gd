## CandyAsteroid — flies from space toward the planet
extends FoodBase

func _ready() -> void:
	food_type = "candy"
	points = 10
	super._ready()
	# Star-shaped candy — pink with sparkles
	_remove_default_sprite()
	add_child(_create_candy_sprite())
	# Launch from random edge of screen toward planet
	_launch_from_space()

func _launch_from_space() -> void:
	var angle: float = randf() * TAU
	var dist: float = 700.0
	var start: Vector2 = Vector2(cos(angle), sin(angle)) * dist
	global_position = start + Vector2(640, 450)
	# Velocity toward planet center with slight randomness
	var target: Vector2 = Vector2(640, 450) + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var direction: Vector2 = (target - global_position).normalized()
	var speed: float = randf_range(80, 150)
	linear_velocity = direction * speed

func _create_candy_sprite() -> Node2D:
	var container: Node2D = Node2D.new()
	# Main candy body
	var body: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	# Draw a simple star/candy shape
	var color: Color = Color(1.0, 0.4, 0.7)
	for y in range(20):
		for x in range(20):
			var dx: float = (x - 10.0) / 10.0
			var dy: float = (y - 10.0) / 10.0
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 0.8:
				img.set_pixel(x, y, color)
			elif d < 1.0 and (absf(dx) > 0.6 or absf(dy) > 0.6):
				img.set_pixel(x, y, Color(1.0, 0.7, 0.9))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	body.texture = tex
	container.add_child(body)
	# Glow
	var glow: Sprite2D = Sprite2D.new()
	var glow_img: Image = Image.create(28, 28, false, Image.FORMAT_RGBA8)
	glow_img.fill(Color(0, 0, 0, 0))
	for y in range(28):
		for x in range(28):
			var dx: float = (x - 14.0) / 14.0
			var dy: float = (y - 14.0) / 14.0
			var d: float = sqrt(dx * dx + dy * dy)
			if d < 1.0:
				glow_img.set_pixel(x, y, Color(1, 0.6, 0.8, 0.3 * (1.0 - d)))
	var glow_tex: ImageTexture = ImageTexture.create_from_image(glow_img)
	glow.texture = glow_tex
	glow.position = Vector2(-4, -4)
	container.add_child(glow)
	return container

func _remove_default_sprite() -> void:
	for child in get_children():
		if child is Sprite2D and not child.get_parent() is Node2D:
			if child.texture and child.texture.get_width() == 24:
				remove_child(child)
				child.queue_free()
				break
