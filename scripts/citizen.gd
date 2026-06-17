extends Node2D
## Bürger: holt Ressourcen ab und liefert sie an ein Zielgebäude.


const ARRIVE_DISTANCE: float = 12.0

@export var walk_speed: float = 90.0

var _job: Dictionary = {}
var _state: String = "idle"
var _carry_resource: String = ""
var _carry_amount: float = 0.0

var _sprite: ColorRect
var _label: Label


func _ready() -> void:
	y_sort_enabled = true
	z_index = 50

	_sprite = ColorRect.new()
	_sprite.size = Vector2(10, 14)
	_sprite.position = Vector2(-5, -14)
	_sprite.color = Color(0.2, 0.75, 1.0)
	add_child(_sprite)

	_label = Label.new()
	_label.position = Vector2(-6, -28)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)


func is_idle() -> bool:
	return _state == "idle"


func assign_job(job: Dictionary) -> void:
	_job = job.duplicate()
	_state = "to_source"
	_carry_resource = ""
	_carry_amount = 0.0
	_update_label()


func _physics_process(delta: float) -> void:
	match _state:
		"idle":
			return
		"to_source":
			if _walk_toward(ProductionManager.get_building_world_pos(_job["from_anchor"]), delta):
				_pickup()
		"to_dest":
			if _walk_toward(ProductionManager.get_building_world_pos(_job["to_anchor"]), delta):
				_deliver()


func _walk_toward(target: Vector2, delta: float) -> bool:
	var offset := target - global_position
	if offset.length() <= ARRIVE_DISTANCE:
		global_position = target
		return true
	global_position += offset.normalized() * walk_speed * delta
	return false


func _pickup() -> void:
	var taken: float = ProductionManager.take_from_local(
		_job["from_anchor"],
		_job["resource"],
		_job["amount"]
	)
	if taken <= 0.0:
		ProductionManager.release_job(_job)
		_reset_idle()
		return
	_carry_resource = _job["resource"]
	_carry_amount = taken
	if taken < float(_job["amount"]):
		var leftover := _job.duplicate()
		leftover["amount"] = float(_job["amount"]) - taken
		ProductionManager.release_job(leftover)
	_state = "to_dest"
	_update_label()


func _deliver() -> void:
	if _carry_amount > 0.0:
		ProductionManager.add_to_local(_job["to_anchor"], _carry_resource, _carry_amount)
	_carry_resource = ""
	_carry_amount = 0.0
	_reset_idle()


func _reset_idle() -> void:
	_state = "idle"
	_job = {}
	_update_label()


func _update_label() -> void:
	if _carry_resource.is_empty():
		_label.text = ""
	else:
		_label.text = "%s%.0f" % [_carry_resource.left(1).to_upper(), _carry_amount]
