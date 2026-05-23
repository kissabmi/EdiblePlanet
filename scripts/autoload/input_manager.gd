## InputManager — handles control mode selection and two-mouse support
extends Node

enum ControlMode { MOUSE_MOUSE, MOUSE_KEYBOARD, KEYBOARD_KEYBOARD }

var current_mode: ControlMode = ControlMode.MOUSE_KEYBOARD
var mouse1_device: int = 0
var mouse2_device: int = -1

# Tilt state
var tilt_direction: Vector2 = Vector2.ZERO
# Magnet state
var magnet_position: Vector2 = Vector2(640, 360)
var magnet_attracting: bool = false
var magnet_repelling: bool = false

# For two-mouse: track separate cursor positions
var mouse1_pos: Vector2 = Vector2(640, 360)
var mouse2_pos: Vector2 = Vector2(640, 360)

signal tilt_changed(direction: Vector2)
signal magnet_moved(position: Vector2)
signal magnet_attract_started()
signal magnet_attract_stopped()
signal magnet_repel_started()
signal magnet_repel_stopped()

func _ready() -> void:
	set_process_unhandled_input(true)

func set_control_mode(mode: ControlMode) -> void:
	current_mode = mode
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mode != ControlMode.MOUSE_MOUSE else Input.MOUSE_MODE_HIDDEN)

func _unhandled_input(event: InputEvent) -> void:
	match current_mode:
		ControlMode.MOUSE_MOUSE:
			_handle_mouse_mouse(event)
		ControlMode.MOUSE_KEYBOARD:
			_handle_mouse_keyboard(event)
		ControlMode.KEYBOARD_KEYBOARD:
			_handle_keyboard_keyboard(event)

func _handle_mouse_mouse(event: InputEvent) -> void:
	# Player 1: mouse1 horizontal = tilt
	if event is InputEventMouseMotion:
		var dev: int = event.device
		if dev == mouse1_device:
			mouse1_pos = event.position
			# Tilt based on horizontal position relative to screen center
			var tilt_x: float = (event.position.x - 640.0) / 640.0
			var tilt_y: float = (event.position.y - 360.0) / 360.0
			tilt_direction = Vector2(clampf(tilt_x, -1.0, 1.0), clampf(tilt_y, -1.0, 1.0))
			tilt_changed.emit(tilt_direction)
		elif dev == mouse2_device || mouse2_device == -1:
			mouse2_pos = event.position
			magnet_position = event.position
			magnet_moved.emit(magnet_position)
	elif event is InputEventMouseButton:
		var dev: int = event.device
		if dev == mouse2_device || mouse2_device == -1:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					magnet_attracting = true
					magnet_attract_started.emit()
				else:
					magnet_attracting = false
					magnet_attract_stopped.emit()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if event.pressed:
					magnet_repelling = true
					magnet_repel_started.emit()
				else:
					magnet_repelling = false
					magnet_repel_stopped.emit()

func _handle_mouse_keyboard(event: InputEvent) -> void:
	# Player 2: mouse = magnet cursor + click
	if event is InputEventMouseMotion:
		magnet_position = event.position
		magnet_moved.emit(magnet_position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				magnet_attracting = true
				magnet_attract_started.emit()
			else:
				magnet_attracting = false
				magnet_attract_stopped.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				magnet_repelling = true
				magnet_repel_started.emit()
			else:
				magnet_repelling = false
				magnet_repel_stopped.emit()
	# Player 1: WASD = tilt
	if event.is_action("tilt_left") or event.is_action("tilt_right") or event.is_action("tilt_up") or event.is_action("tilt_down"):
		var dir: Vector2 = Vector2.ZERO
		if Input.is_action_pressed("tilt_left"): dir.x -= 1
		if Input.is_action_pressed("tilt_right"): dir.x += 1
		if Input.is_action_pressed("tilt_up"): dir.y -= 1
		if Input.is_action_pressed("tilt_down"): dir.y += 1
		tilt_direction = dir
		tilt_changed.emit(tilt_direction)

func _handle_keyboard_keyboard(event: InputEvent) -> void:
	# Player 1: WASD = tilt
	if event.is_action("tilt_left") or event.is_action("tilt_right") or event.is_action("tilt_up") or event.is_action("tilt_down"):
		var dir: Vector2 = Vector2.ZERO
		if Input.is_action_pressed("tilt_left"): dir.x -= 1
		if Input.is_action_pressed("tilt_right"): dir.x += 1
		if Input.is_action_pressed("tilt_up"): dir.y -= 1
		if Input.is_action_pressed("tilt_down"): dir.y += 1
		tilt_direction = dir
		tilt_changed.emit(tilt_direction)
	# Player 2: Arrows = magnet cursor, Space = attract, Shift = repel
	if event.is_action("magnet_left") or event.is_action("magnet_right") or event.is_action("magnet_up") or event.is_action("magnet_down"):
		if Input.is_action_pressed("magnet_left"): magnet_position.x -= 8
		if Input.is_action_pressed("magnet_right"): magnet_position.x += 8
		if Input.is_action_pressed("magnet_up"): magnet_position.y -= 8
		if Input.is_action_pressed("magnet_down"): magnet_position.y += 8
		magnet_position = magnet_position.clamp(Vector2.ZERO, Vector2(1280, 720))
		magnet_moved.emit(magnet_position)
	if event.is_action("magnet_attract"):
		if event.pressed:
			magnet_attracting = true
			magnet_attract_started.emit()
		else:
			magnet_attracting = false
			magnet_attract_stopped.emit()
	if event.is_action("magnet_repel"):
		if event.pressed:
			magnet_repelling = true
			magnet_repel_started.emit()
		else:
			magnet_repelling = false
			magnet_repel_stopped.emit()
