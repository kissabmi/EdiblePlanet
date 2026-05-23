## SharpLollipop — fast, freezes on contact
extends "res://scripts/hazards/hazard_base.gd"

func _ready() -> void:
	hazard_type = "lollipop"
	penalty = -15
	super._ready()
	_add_sprite()
	var angle: float = randf() * TAU
	global_position = Vector2(cos(angle), sin(angle)) * 700.0 + Vector2(640, 420)
	linear_velocity = (Vector2(640, 420) - global_position).normalized() * 200.0

func apply_hazard_effect(planet: Node2D) -> void:
	ScoreManager.apply_freeze(1.0)
	if planet.has_method("close_mouth"):
		# Close mouth via ScoreManager
		ScoreManager.close_mouth(1.0)

func _add_sprite() -> void:
	var img: Image = Image.create(14, 22, false, Image.FORMAT_RGBA8)
	for y in range(22):
		for x in range(14):
			var nx: float = (x-7)/7.0
			var ny: float = (y-8)/8.0
			var d: float = sqrt(nx*nx + ny*ny)
			if d < 0.8:
				var spiral: float = sin(atan2(ny, nx) * 3 + ny * 8) * 0.5 + 0.5
				img.set_pixel(x, y, Color(0.9, 0.1, 0.1).lerp(Color(1,1,1), spiral))
			elif y > 14 and absf(nx) < 0.15:
				img.set_pixel(x, y, Color(0.9, 0.85, 0.7))
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.z_index = 1
	add_child(s)
