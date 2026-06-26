extends Node2D
## Spieler: Point-and-Click auf dem isometrischen Tile-Grid.


const ARRIVE_DISTANCE: float = 2.0

@export var walk_speed: float = 120.0
@export var grid_manager_path: NodePath = NodePath("../../GridManager")
@export var building_placer_path: NodePath = NodePath("../../BuildingPlacer")
@export var anim_node_path: NodePath = ^"AnimatedSprite2D"
@export var idle_anim: StringName = &"idle"
@export var walk_anim: StringName = &"walk"
## Nur Optik — verschiebt Sprite/Label, nicht die Grid-Logik.
@export var visual_offset: Vector2 = Vector2(-16, -16)
@export var debug_clicks: bool = false

var _grid: GridManager
var _placer: Node2D
var _anim: AnimatedSprite2D
var _current_tile: Vector2i = Vector2i.ZERO
var _path_waypoints: Array[Vector2] = []
var _path_tiles: Array[Vector2i] = []
var _path_from_tile: Vector2i = Vector2i.ZERO
var _waypoint_index: int = 0
var _current_walk_anim: StringName = &""


func _ready() -> void:
	_placer = get_node_or_null(building_placer_path) as Node2D
	_anim = get_node_or_null(anim_node_path) as AnimatedSprite2D
	_apply_visual_offset()
	if _anim and _anim.sprite_frames:
		_play_idle()
	if not _grid:
		_grid = get_node_or_null(grid_manager_path) as GridManager
	await _wait_for_grid()
	_snap_to_nearest_tile()


func set_grid_manager(grid: GridManager) -> void:
	_grid = grid
	call_deferred("_snap_to_nearest_tile")


func _wait_for_grid(max_frames: int = 30) -> void:
	for _i in max_frames:
		if _grid and _grid_is_ready():
			return
		if not _grid:
			_grid = get_node_or_null(grid_manager_path) as GridManager
		await get_tree().process_frame


func _grid_is_ready() -> bool:
	if not _grid:
		return false
	return _grid.ground_layer != null or _grid.building_layer != null


func _unhandled_input(event: InputEvent) -> void:
	if not _grid or not _grid_is_ready():
		return
	if _is_build_mode_active():
		return
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	_move_to_tile(_grid.world_to_tile_from_mouse())
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_update_draw_order()
	if _path_waypoints.is_empty():
		return
	_walk_path(delta)


func _is_build_mode_active() -> bool:
	return _placer != null and _placer.has_method("is_build_mode_active") and _placer.is_build_mode_active()


func _move_to_tile(to_tile: Vector2i) -> void:
	if not _grid:
		return
	if to_tile == _current_tile and _path_waypoints.is_empty():
		return

	if debug_clicks:
		print("Player Klick → Tile %s, Welt %s" % [to_tile, _tile_to_walk_pos(to_tile)])

	_path_waypoints.clear()
	_path_tiles.clear()
	_waypoint_index = 0
	_current_walk_anim = &""
	_path_from_tile = _current_tile

	_path_tiles = _grid.find_player_path_to_near(_current_tile, to_tile)
	for tile in _path_tiles:
		_path_waypoints.append(_tile_to_walk_pos(tile))

	if _path_waypoints.is_empty():
		_play_idle()


func _walk_path(delta: float) -> void:
	if _waypoint_index >= _path_waypoints.size():
		_finish_path()
		return

	var target: Vector2 = _path_waypoints[_waypoint_index]
	var offset := target - global_position
	var move_dist := walk_speed * delta

	if offset.length() <= maxf(move_dist, ARRIVE_DISTANCE):
		global_position = target
		_current_tile = _path_tiles[_waypoint_index]
		_waypoint_index += 1
		if _waypoint_index >= _path_waypoints.size():
			_finish_path()
			return
		var next_offset := _path_waypoints[_waypoint_index] - global_position
		_update_walk_animation(next_offset, _get_step_anim_suffix())
		return

	global_position += offset.normalized() * move_dist
	_update_walk_animation(offset, _get_step_anim_suffix())


func _finish_path() -> void:
	_path_waypoints.clear()
	_path_tiles.clear()
	_waypoint_index = 0
	_current_walk_anim = &""
	_play_idle()


func _get_step_anim_suffix() -> StringName:
	if not _grid:
		return &"southeast"
	if _waypoint_index < _path_tiles.size():
		var to_tile := _path_tiles[_waypoint_index]
		var from_tile: Vector2i
		if _waypoint_index == 0:
			from_tile = _path_from_tile
		else:
			from_tile = _path_tiles[_waypoint_index - 1]
		return _grid.get_walk_anim_suffix(from_tile, to_tile)
	if _waypoint_index < _path_waypoints.size():
		var move_offset := _path_waypoints[_waypoint_index] - global_position
		if move_offset.length_squared() > 0.01:
			return _grid.offset_to_walk_suffix(move_offset)
	return &"southeast"


func _snap_to_nearest_tile() -> void:
	if not _grid or not _grid_is_ready():
		return

	var tile := _grid.world_to_tile(global_position)
	if _grid.can_player_walk_on(tile):
		_current_tile = tile
		global_position = _tile_to_walk_pos(tile)
		return

	for radius in range(1, 12):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if abs(x) != radius and abs(y) != radius:
					continue
				var candidate := tile + Vector2i(x, y)
				if _grid.can_player_walk_on(candidate):
					_current_tile = candidate
					global_position = _tile_to_walk_pos(candidate)
					return


func _tile_to_walk_pos(tile: Vector2i) -> Vector2:
	if not _grid:
		return global_position
	if _grid.has_method("tile_to_walk_world"):
		return _grid.tile_to_walk_world(tile)
	if _grid.has_method("tile_to_world"):
		return _grid.tile_to_world(tile)
	return global_position


func _update_draw_order() -> void:
	z_index = int(global_position.y)


func _update_walk_animation(move_offset: Vector2, iso_suffix: StringName) -> void:
	if not _anim or not _anim.sprite_frames:
		return
	if move_offset.length_squared() < 0.01:
		_play_idle()
		return

	var anim_name := StringName("%s_%s" % [walk_anim, iso_suffix])
	if _anim.sprite_frames.has_animation(anim_name):
		if _current_walk_anim != anim_name:
			_current_walk_anim = anim_name
			_anim.play(anim_name)
	elif _anim.sprite_frames.has_animation(walk_anim):
		if _current_walk_anim != walk_anim:
			_current_walk_anim = walk_anim
			_anim.play(walk_anim)


func _apply_visual_offset() -> void:
	for child in get_children():
		if child is CanvasItem and child != self:
			child.position = visual_offset


func _play_idle() -> void:
	if not _anim or not _anim.sprite_frames:
		return
	if _anim.sprite_frames.has_animation(idle_anim):
		if _anim.animation != idle_anim:
			_anim.play(idle_anim)
