extends Node2D
## Bürger: holt Ressourcen ab und liefert sie an ein Zielgebäude.
## Läuft nur entlang des isometrischen Tile-Grids (4 Richtungen, kein Schräg-Shortcut).


const ARRIVE_DISTANCE: float = 2.0

const ISO_WALK_SUFFIXES: Array[StringName] = [
	&"northeast",
	&"southeast",
	&"southwest",
	&"northwest",
]

@export var walk_speed: float = 90.0
@export var sprite_frames: SpriteFrames
@export var anim_node_path: NodePath = ^"AnimatedSprite2D"
@export var idle_anim: StringName = &"idle"
@export var walk_anim: StringName = &"walk"
@export var carry_anim: StringName = &"carry_walk"
@export var debug_walk_anim: bool = false

var _job: Dictionary = {}
var _state: String = "idle"
var _carry_resource: String = ""
var _carry_amount: float = 0.0
var _path_waypoints: Array[Vector2] = []
var _path_tiles: Array[Vector2i] = []
var _path_from_tile: Vector2i = Vector2i.ZERO
var _waypoint_index: int = 0

var _grid: GridManager
var _anim: AnimatedSprite2D
var _label: Label
var _warned_anims: Dictionary = {}


func _ready() -> void:
	if get_parent() == null or get_tree().current_scene == self:
		position = Vector2(640, 360)

	_anim = get_node_or_null(anim_node_path) as AnimatedSprite2D
	_label = get_node_or_null(^"Label") as Label

	if not _anim:
		push_error("Citizen: AnimatedSprite2D nicht gefunden unter '%s'" % anim_node_path)
		return

	if sprite_frames:
		_anim.sprite_frames = sprite_frames

	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if not _anim.sprite_frames:
		push_warning("Citizen: Keine SpriteFrames! Weise sie am AnimatedSprite2D oder am Citizen-Node zu.")
		return

	_audit_walk_animations()
	_play_idle()


func set_grid_manager(grid: GridManager) -> void:
	_grid = grid


func is_idle() -> bool:
	return _state == "idle"


func assign_job(job: Dictionary) -> void:
	var source_pos := ProductionManager.get_building_world_pos(job["from_anchor"])
	var dest_pos := ProductionManager.get_building_world_pos(job["to_anchor"])
	if source_pos == Vector2.ZERO or dest_pos == Vector2.ZERO:
		push_warning("Citizen: Keine Weltposition für Auftrag %s" % str(job))
		ProductionManager.release_job(job)
		return

	_job = job.duplicate()
	_state = "to_source"
	_carry_resource = ""
	_carry_amount = 0.0
	_build_path_to(source_pos)
	_update_label()


func _process(delta: float) -> void:
	_update_draw_order()
	match _state:
		"idle":
			return
		"to_source":
			if _walk_path(delta):
				_pickup()
		"to_dest":
			if _walk_path(delta):
				_deliver()


func _update_draw_order() -> void:
	# Gleiche Tiefe wie isometrische Tiles: weiter unten auf dem Screen = weiter vorne.
	z_index = int(global_position.y)


func _build_path_to(target_world: Vector2) -> void:
	_path_waypoints.clear()
	_path_tiles.clear()
	_waypoint_index = 0

	if not _grid:
		_path_waypoints.append(target_world)
		return

	var from_tile := _grid.world_to_tile(global_position)
	var to_tile := _grid.world_to_tile(target_world)
	_path_from_tile = from_tile
	_path_tiles = _grid.find_path(from_tile, to_tile)

	if debug_walk_anim:
		print("Citizen Pfad: %s -> %s (%d Schritte)" % [from_tile, to_tile, _path_tiles.size()])

	for tile in _path_tiles:
		_path_waypoints.append(_grid.tile_to_world(tile))

	if _path_waypoints.is_empty():
		_path_waypoints.append(target_world)


func _walk_path(delta: float) -> bool:
	if _path_waypoints.is_empty():
		return true

	if _waypoint_index >= _path_waypoints.size():
		_play_idle()
		return true

	var target: Vector2 = _path_waypoints[_waypoint_index]
	var offset := target - global_position

	if offset.length() <= ARRIVE_DISTANCE:
		global_position = target
		_waypoint_index += 1
		if _waypoint_index >= _path_waypoints.size():
			_play_idle()
			return true
		return false

	global_position += offset.normalized() * walk_speed * delta
	_update_walk_animation(offset, _get_step_anim_suffix())
	return false


func _get_step_anim_suffix() -> StringName:
	if not _grid or _waypoint_index >= _path_tiles.size():
		return &"southeast"
	var to_tile := _path_tiles[_waypoint_index]
	var from_tile: Vector2i
	if _waypoint_index == 0:
		from_tile = _path_from_tile
	else:
		from_tile = _path_tiles[_waypoint_index - 1]
	return _grid.get_walk_anim_suffix(from_tile, to_tile)


func _audit_walk_animations() -> void:
	if not _anim or not _anim.sprite_frames:
		return
	var names: PackedStringArray = _anim.sprite_frames.get_animation_names()
	print("Citizen SpriteFrames: ", names)
	for suffix in ISO_WALK_SUFFIXES:
		var key := StringName("%s_%s" % [walk_anim, suffix])
		if not _has_animation(key):
			push_warning("Citizen: Lauf-Animation fehlt: %s" % key)


func _update_walk_animation(offset: Vector2, iso_suffix: StringName) -> void:
	if not _anim or not _anim.sprite_frames:
		return

	var anim := carry_anim if _carry_amount > 0.0 else walk_anim
	if not _has_animation(anim):
		anim = walk_anim

	var dir_anim := StringName("%s_%s" % [anim, iso_suffix])
	if debug_walk_anim:
		print("Citizen spielt: %s" % dir_anim)
	if _has_animation(dir_anim):
		_anim.play(dir_anim)
		_anim.flip_h = false
		return

	# Fallback: exakter Name ohne Prefix (z. B. nur "walk_northeast")
	if _has_animation(iso_suffix):
		_anim.play(iso_suffix)
		_anim.flip_h = false
		return

	if _has_animation(anim):
		if not _warned_anims.has(dir_anim):
			_warned_anims[dir_anim] = true
			push_warning("Citizen: '%s' fehlt, Fallback auf '%s'" % [dir_anim, anim])
		_anim.play(anim)
		_anim.flip_h = false


func _has_animation(anim_name: StringName) -> bool:
	return _anim.sprite_frames != null and _anim.sprite_frames.has_animation(anim_name)


func _play_idle() -> void:
	if not _anim or not _anim.sprite_frames:
		return

	if _has_animation(idle_anim):
		_anim.play(idle_anim)
		return

	var names: PackedStringArray = _anim.sprite_frames.get_animation_names()
	if names.is_empty():
		push_warning("Citizen: SpriteFrames hat keine Animationen.")
		return

	push_warning(
		"Citizen: Animation '%s' fehlt. Verfügbar: %s — spiele '%s'."
		% [idle_anim, ", ".join(names), names[0]]
	)
	_anim.play(names[0])


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
	_build_path_to(ProductionManager.get_building_world_pos(_job["to_anchor"]))
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
	_path_waypoints.clear()
	_path_tiles.clear()
	_waypoint_index = 0
	_update_label()
	_play_idle()


func _update_label() -> void:
	if not _label:
		return
	if _carry_resource.is_empty():
		_label.text = ""
	else:
		_label.text = "%s%.0f" % [_carry_resource.left(1).to_upper(), _carry_amount]
