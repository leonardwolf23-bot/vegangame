extends Node2D
## Spieler-Charakter: WASD-Bewegung auf dem isometrischen Grid.


@export var walk_speed: float = 120.0
@export var grid_manager_path: NodePath = NodePath("../../GridManager")
@export var anim_node_path: NodePath = ^"AnimatedSprite2D"
@export var idle_anim: StringName = &"idle"
@export var walk_anim: StringName = &"walk"

var _grid: GridManager
var _anim: AnimatedSprite2D
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


func _physics_process(delta: float) -> void:
	var input_dir := _read_move_input()
	if input_dir == Vector2.ZERO:
		_current_walk_anim = &""
		_play_idle()
		_update_draw_order()
		return

	var move := input_dir.normalized() * walk_speed * delta
	var new_pos := global_position + move
	new_pos = _resolve_collision(global_position, new_pos)
	global_position = new_pos
	_update_walk_animation(move)
	_update_draw_order()


func _read_move_input() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction


func _resolve_collision(from: Vector2, to: Vector2) -> Vector2:
	if not _grid:
		return to
	if _can_stand_at(to):
		return to

	var slide_x := Vector2(to.x, from.y)
	if _can_stand_at(slide_x):
		return slide_x

	var slide_y := Vector2(from.x, to.y)
	if _can_stand_at(slide_y):
		return slide_y

	return from


func _can_stand_at(world_pos: Vector2) -> bool:
	if not _grid:
		return true
	return _grid.can_player_walk_on(_grid.world_to_tile(world_pos))


func _snap_to_nearest_tile() -> void:
	if not _grid or not _grid.building_layer:
		return
	var tile := _grid.world_to_tile(global_position)
	if _grid.can_player_walk_on(tile):
		global_position = _grid.tile_to_world(tile)
		return
	for radius in range(1, 12):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if abs(x) != radius and abs(y) != radius:
					continue
				var candidate := Vector2i(x, y)
				if _grid.can_player_walk_on(candidate):
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
		suffix = _grid.offset_to_walk_suffix(move_offset)

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
