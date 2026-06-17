class_name GridManager
extends Node


@export var ground_layer: TileMapLayer
@export var building_layer: TileMapLayer

var _placed: Dictionary = {}
var _cell_owner: Dictionary = {}

const _CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


func world_to_tile(world_pos: Vector2) -> Vector2i:
	if not building_layer:
		return Vector2i(-9999, -9999)
	var local_pos := building_layer.to_local(world_pos)
	return building_layer.local_to_map(local_pos)


func tile_to_world(tile: Vector2i) -> Vector2:
	if not building_layer:
		return Vector2.ZERO
	var local_pos := building_layer.map_to_local(tile)
	return building_layer.to_global(local_pos)


func can_walk_on(tile: Vector2i) -> bool:
	return has_ground(tile)


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if from == to:
		return []
	if not can_walk_on(to):
		return []

	var queue: Array[Vector2i] = [from]
	var came_from: Dictionary = {from: from}
	var head := 0

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		if current == to:
			break
		for dir in _CARDINAL_DIRS:
			var next := current + dir
			if not can_walk_on(next):
				continue
			if came_from.has(next):
				continue
			came_from[next] = current
			queue.append(next)

	if not came_from.has(to):
		return []

	var path: Array[Vector2i] = []
	var step := to
	while step != from:
		path.push_front(step)
		step = came_from[step]
	return path


func get_walk_anim_suffix(from_tile: Vector2i, to_tile: Vector2i) -> StringName:
	var delta := to_tile - from_tile
	# Isometrisches Grid: exakt ein Tile pro Schritt, keine Diagonalen.
	match delta:
		Vector2i(1, 0):
			return &"east"   # bildschirm: unten-rechts
		Vector2i(-1, 0):
			return &"west"   # bildschirm: oben-links
		Vector2i(0, 1):
			return &"south"  # bildschirm: unten-links
		Vector2i(0, -1):
			return &"north"  # bildschirm: oben-rechts
		_:
			return _world_offset_to_anim_suffix(tile_to_world(to_tile) - tile_to_world(from_tile))


func _world_offset_to_anim_suffix(offset: Vector2) -> StringName:
	if offset.length_squared() < 0.01:
		return &"south"

	var origin := tile_to_world(Vector2i.ZERO)
	var step_x := (tile_to_world(Vector2i(1, 0)) - origin).normalized()
	var step_y := (tile_to_world(Vector2i(0, 1)) - origin).normalized()
	var dir := offset.normalized()
	var dot_x := dir.dot(step_x)
	var dot_y := dir.dot(step_y)

	if absf(dot_x) >= absf(dot_y):
		return &"east" if dot_x >= 0.0 else &"west"
	return &"south" if dot_y >= 0.0 else &"north"


func has_ground(tile: Vector2i) -> bool:
	if not ground_layer:
		return true
	return ground_layer.get_cell_source_id(tile) != -1


func is_building_slot_free(tile: Vector2i) -> bool:
	if _cell_owner.has(tile):
		return false
	if not building_layer:
		return false
	return building_layer.get_cell_source_id(tile) == -1


func can_place(origin: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var cell := origin + Vector2i(x, y)
			if not has_ground(cell):
				return false
			if not is_building_slot_free(cell):
				return false
	return true


func can_place_building(anchor: Vector2i, building: Dictionary) -> bool:
	var foot_origin := BuildingCatalog.get_footprint_origin(anchor, building)
	return can_place(foot_origin, BuildingCatalog.get_footprint(building))


func register_building(anchor: Vector2i, building_index: int, building: Dictionary) -> void:
	var footprint: Vector2i = BuildingCatalog.get_footprint(building)
	var foot_origin: Vector2i = BuildingCatalog.get_footprint_origin(anchor, building)

	_placed[anchor] = {
		"anchor": anchor,
		"footprint": footprint,
		"foot_origin": foot_origin,
		"building_index": building_index,
		"cost": BuildingCatalog.get_cost(building),
		"income": BuildingCatalog.get_income(building),
	}

	for x in range(footprint.x):
		for y in range(footprint.y):
			_cell_owner[foot_origin + Vector2i(x, y)] = anchor


func remove_building_at(tile: Vector2i) -> Dictionary:
	var anchor: Vector2i = _cell_owner.get(tile, Vector2i(-999999, -999999))
	if anchor == Vector2i(-999999, -999999):
		if not building_layer or building_layer.get_cell_source_id(tile) == -1:
			return {}
		building_layer.erase_cell(tile)
		return {}

	var data: Dictionary = _placed[anchor].duplicate()
	var footprint: Vector2i = data["footprint"]
	var foot_origin: Vector2i = data["foot_origin"]

	for x in range(footprint.x):
		for y in range(footprint.y):
			_cell_owner.erase(foot_origin + Vector2i(x, y))
	_placed.erase(anchor)
	building_layer.erase_cell(anchor)
	return data
