extends Node2D
## Spieler: tilebasierte Bewegung — ein Grid-Schritt pro Tastendruck.


const ARRIVE_DISTANCE: float = 2.0

@export var walk_speed: float = 120.0
@export var grid_manager_path: NodePath = NodePath("../../GridManager")
@export var anim_node_path: NodePath = ^"AnimatedSprite2D"
@export var idle_anim: StringName = &"idle"
@export var walk_anim: StringName = &"walk"

var _grid: GridManager
var _anim: AnimatedSprite2D
var _current_tile: Vector2i = Vector2i.ZERO
var _is_moving: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _move_from_tile: Vector2i = Vector2i.ZERO
var _move_to_tile: Vector2i = Vector2i.ZERO
var _current_walk_anim: StringName = &""


func _ready() -> void:
	_grid = get_node_or_null(grid_manager_path) as GridManager
	_anim = get_node_or_null(anim_node_path) as AnimatedSprite2D
	if _anim and _anim.sprite_frames:
		_play_idle()
	await get_tree().process_frame
	_snap_to_nearest_tile()


func set_grid_manager(grid: GridManager) -> void:
	_grid = grid
	_snap_to_nearest_tile()


func _unhandled_input(event: InputEvent) -> void:
	if _is_moving or not _grid:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var dir := _key_to_tile_dir(event.physical_keycode)
	if dir == Vector2i.ZERO:
		return

	var next_tile := _current_tile + dir
	if not _grid.can_player_walk_on(next_tile):
		return

	_start_move(next_tile)


func _process(delta: float) -> void:
	_update_draw_order()
	if not _is_moving:
		return

	var offset := _move_target - global_position
	var move_dist := walk_speed * delta

	if offset.length() <= maxf(move_dist, ARRIVE_DISTANCE):
		global_position = _move_target
		_current_tile = _move_to_tile
		_is_moving = false
		_current_walk_anim = &""
		_play_idle()
		return

	global_position += offset.normalized() * move_dist
	_update_walk_animation(offset)


func _start_move(to_tile: Vector2i) -> void:
	_move_from_tile = _current_tile
	_move_to_tile = to_tile
	_move_target = _grid.tile_to_world(to_tile)
	_is_moving = true

	var step_offset := _move_target - global_position
	_update_walk_animation(step_offset)


func _key_to_tile_dir(keycode: Key) -> Vector2i:
	# Isometrisches Grid: W = nordost, S = südwest, A = nordwest, D = südost.
	match keycode:
		KEY_W, KEY_UP:
			return Vector2i(0, -1)
		KEY_S, KEY_DOWN:
			return Vector2i(0, 1)
		KEY_A, KEY_LEFT:
			return Vector2i(-1, 0)
		KEY_D, KEY_RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO


func _snap_to_nearest_tile() -> void:
	if not _grid or not _grid.building_layer:
		return

	var tile := _grid.world_to_tile(global_position)
	if _grid.can_player_walk_on(tile):
		_current_tile = tile
		global_position = _grid.tile_to_world(tile)
		return

	for radius in range(1, 12):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if abs(x) != radius and abs(y) != radius:
					continue
				var candidate := tile + Vector2i(x, y)
				if _grid.can_player_walk_on(candidate):
					_current_tile = candidate
					global_position = _grid.tile_to_world(candidate)
					return


func _update_draw_order() -> void:
	z_index = int(global_position.y)


func _update_walk_animation(move_offset: Vector2) -> void:
	if not _anim or not _anim.sprite_frames:
		return
	if move_offset.length_squared() < 0.01:
		_play_idle()
		return

	var suffix: StringName = &"southeast"
	if _grid:
		suffix = _grid.get_walk_anim_suffix(_move_from_tile, _move_to_tile)

	var anim_name := StringName("%s_%s" % [walk_anim, suffix])
	if _anim.sprite_frames.has_animation(anim_name):
		if _current_walk_anim != anim_name:
			_current_walk_anim = anim_name
			_anim.play(anim_name)
	elif _anim.sprite_frames.has_animation(walk_anim):
		if _current_walk_anim != walk_anim:
			_current_walk_anim = walk_anim
			_anim.play(walk_anim)


func _play_idle() -> void:
	if not _anim or not _anim.sprite_frames:
		return
	if _anim.sprite_frames.has_animation(idle_anim):
		if _anim.animation != idle_anim:
			_anim.play(idle_anim)
