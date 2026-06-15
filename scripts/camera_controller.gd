extends Camera2D
## Einfache Kamera-Steuerung für den City Builder.
## An deine bestehende Camera2D hängen.


@export var pan_speed: float = 500.0
@export var zoom_min: float = 0.3
@export var zoom_max: float = 2.0
@export var zoom_step: float = 0.1
@export var drag_pan_enabled: bool = true

var _is_dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# Mausrad → Zoom rein/raus
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_step)

		# Mittlere Maustaste → Kamera ziehen
		elif drag_pan_enabled and event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_dragging = true
				_drag_start = event.position
			else:
				_is_dragging = false


func _input(event: InputEvent) -> void:
	if not _is_dragging or not event is InputEventMouseMotion:
		return
	# Kamera in entgegengesetzte Richtung der Mausbewegung schieben
	position -= (event.position - _drag_start) / zoom
	_drag_start = event.position


func _process(delta: float) -> void:
	# WASD + Pfeiltasten → Kamera bewegen (ohne Input Map nötig)
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
