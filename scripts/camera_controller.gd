extends Camera2D
## Kamera: folgt dem Spieler oder manuelles Schwenken/Zoom.


@export var pan_speed: float = 500.0
@export var zoom_min: float = 0.3
@export var zoom_max: float = 2.0
@export var zoom_step: float = 0.1
@export var drag_pan_enabled: bool = true
@export var follow_smoothing: float = 8.0

var follow_target: Node2D
var _is_dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _manual_offset: Vector2 = Vector2.ZERO


func set_follow_target(target: Node2D) -> void:
	follow_target = target
	_manual_offset = Vector2.ZERO
	if follow_target:
		global_position = follow_target.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_step)
		elif drag_pan_enabled and event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_dragging = true
				_drag_start = event.position
			else:
				_is_dragging = false


func _input(event: InputEvent) -> void:
	if not _is_dragging or not event is InputEventMouseMotion:
		return
	_manual_offset -= (event.position - _drag_start) / zoom
	_drag_start = event.position


func _process(delta: float) -> void:
	if follow_target and is_instance_valid(follow_target):
		var target_pos := follow_target.global_position + _manual_offset
		global_position = global_position.lerp(target_pos, follow_smoothing * delta)
		return

	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction != Vector2.ZERO:
		position += direction.normalized() * pan_speed * delta / zoom


func _apply_zoom(amount: float) -> void:
	var new_zoom := clampf(zoom.x + amount, zoom_min, zoom_max)
	zoom = Vector2(new_zoom, new_zoom)
