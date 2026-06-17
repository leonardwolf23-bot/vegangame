extends Node2D
## Bürger: holt Ressourcen ab und liefert sie an ein Zielgebäude.


const ARRIVE_DISTANCE: float = 12.0

@export var walk_speed: float = 90.0
@export var idle_anim: StringName = &"idle"
@export var walk_anim: StringName = &"walk"
@export var carry_anim: StringName = &"carry_walk"

var _job: Dictionary = {}
var _state: String = "idle"
var _carry_resource: String = ""
var _carry_amount: float = 0.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _label: Label = $Label


func _ready() -> void:
	_play_idle()


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
		_play_idle()
		return true

	global_position += offset.normalized() * walk_speed * delta
	_update_walk_animation(offset)
	return false


func _update_walk_animation(offset: Vector2) -> void:
	if not _anim or not _anim.sprite_frames:
		return

	var anim := carry_anim if _carry_amount > 0.0 else walk_anim
	if not _has_animation(anim):
		anim = walk_anim

	# Richtungs-Animationen: walk_south, walk_north, walk_east, walk_west
	var dir_anim := _direction_anim_name(anim, offset)
	if _has_animation(dir_anim):
		_anim.play(dir_anim)
	elif _has_animation(anim):
		_anim.play(anim)
		_anim.flip_h = offset.x < 0.0


func _direction_anim_name(base: StringName, offset: Vector2) -> StringName:
	var suffix := "south"
	if absf(offset.x) > absf(offset.y):
		suffix = "east" if offset.x > 0.0 else "west"
	else:
		suffix = "south" if offset.y > 0.0 else "north"
	return StringName("%s_%s" % [base, suffix])


func _has_animation(anim_name: StringName) -> bool:
	return _anim.sprite_frames != null and _anim.sprite_frames.has_animation(anim_name)


func _play_idle() -> void:
	if _anim and _anim.sprite_frames and _has_animation(idle_anim):
		_anim.play(idle_anim)


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
	_play_idle()


func _update_label() -> void:
	if not _label:
		return
	if _carry_resource.is_empty():
		_label.text = ""
	else:
		_label.text = "%s%.0f" % [_carry_resource.left(1).to_upper(), _carry_amount]
