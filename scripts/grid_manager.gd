class_name GridManager
extends Node


@export var ground_layer: TileMapLayer
@export var building_layer: TileMapLayer
## Feinjustierung in Pixeln (map_to_local ist bereits Tile-Mitte).
@export var walk_pixel_offset: Vector2 = Vector2.ZERO

var _placed: Dictionary = {}
var _cell_owner: Dictionary = {}
var _pending_ground_backup: Dictionary = {}

const _CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


func _coord_layer() -> TileMapLayer:
	if ground_layer:
		return ground_layer
	return building_layer


func world_to_tile_from_mouse() -> Vector2i:
	var layer := _coord_layer()
	if not layer:
		return Vector2i(-9999, -9999)
	return _local_pos_to_tile(layer, layer.get_local_mouse_position())


func world_to_tile(world_pos: Vector2) -> Vector2i:
	var layer := _coord_layer()
	if not layer:
		return Vector2i(-9999, -9999)
	return _local_pos_to_tile(layer, layer.to_local(world_pos))


func tile_to_world(tile: Vector2i) -> Vector2:
	var layer := _coord_layer()
	if not layer:
		return Vector2.ZERO
	var local_pos := layer.map_to_local(tile)
	return layer.to_global(local_pos)


func tile_to_walk_world(tile: Vector2i) -> Vector2:
	return tile_to_world(tile) + walk_pixel_offset


func _local_pos_to_tile(layer: TileMapLayer, local_pos: Vector2) -> Vector2i:
	var rough := layer.local_to_map(local_pos)
	if _local_pos_in_tile(layer, rough, local_pos):
		return rough

	var best := rough
	var best_dist := INF
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var candidate := rough + Vector2i(dx, dy)
			if not _local_pos_in_tile(layer, candidate, local_pos):
				continue
			var dist := local_pos.distance_squared_to(layer.map_to_local(candidate))
			if dist < best_dist:
				best_dist = dist
				best = candidate
	if best_dist < INF:
		return best

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var candidate := rough + Vector2i(dx, dy)
			var dist := local_pos.distance_squared_to(layer.map_to_local(candidate))
			if dist < best_dist:
				best_dist = dist
				best = candidate
	return best


func _local_pos_in_tile(layer: TileMapLayer, tile: Vector2i, local_pos: Vector2) -> bool:
	var center := layer.map_to_local(tile)
	var rel := local_pos - center
	var tile_size := _get_tile_size(layer)
	var hw := float(tile_size.x) * 0.5
	var hh := float(tile_size.y) * 0.5
	if hw <= 0.0 or hh <= 0.0:
		return false
	return abs(rel.x) / hw + abs(rel.y) / hh <= 1.0


func _get_tile_size(layer: TileMapLayer) -> Vector2i:
	if layer.tile_set:
		return layer.tile_set.tile_size
	return Vector2i(64, 32)


func can_walk_on(tile: Vector2i) -> bool:
	return has_ground(tile)


func can_player_walk_on(tile: Vector2i) -> bool:
	if _blocks_player_walk(tile):
		return false
	if has_ground(tile):
		return true
	# Ohne Boden-Tile: freie Fläche begehbar (Prototyp / leere Karte).
	if building_layer and building_layer.get_cell_source_id(tile) != -1:
		return false
	return true


func _blocks_player_walk(tile: Vector2i) -> bool:
	if not _cell_owner.has(tile):
		return false
	var anchor: Vector2i = _cell_owner[tile]
	var data: Dictionary = _placed.get(anchor, {})
	return data.get("kind", "building") != "road"


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return _find_path(from, to, Callable(self, "can_walk_on"))


func find_player_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return _find_path(from, to, Callable(self, "can_player_walk_on"))


func _find_path(from: Vector2i, to: Vector2i, walkable: Callable) -> Array[Vector2i]:
	if from == to:
		return []
	if not walkable.call(from):
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
			if not walkable.call(next):
				continue
			if came_from.has(next):
				continue
			came_from[next] = current
			queue.append(next)

	if not came_from.has(to):
		return []

	return _reconstruct_path(from, to, came_from)


func find_path_to_near(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return _find_path_to_near(from, to, Callable(self, "can_walk_on"))


func find_player_path_to_near(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return _find_path_to_near(from, to, Callable(self, "can_player_walk_on"))


func _find_path_to_near(from: Vector2i, to: Vector2i, walkable: Callable) -> Array[Vector2i]:
	var path := _find_path(from, to, walkable)
	if not path.is_empty():
		return path

	var best_path: Array[Vector2i] = []
	for dir in _CARDINAL_DIRS:
		var alt := to + dir
		if not walkable.call(alt):
			continue
		path = _find_path(from, alt, walkable)
		if path.is_empty():
			continue
		if best_path.is_empty() or path.size() < best_path.size():
			best_path = path
	return best_path


func offset_to_walk_suffix(offset: Vector2) -> StringName:
	return _world_offset_to_anim_suffix(offset)


func _reconstruct_path(from: Vector2i, to: Vector2i, came_from: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var step := to
	while step != from:
		path.push_front(step)
		step = came_from[step]
	return path


func get_walk_anim_suffix(from_tile: Vector2i, to_tile: Vector2i) -> StringName:
	var delta := to_tile - from_tile
	# Isometrisches 64x32 Grid: jeder Tile-Schritt ist eine Schräg-Richtung.
	match delta:
		Vector2i(1, 0):
			return &"southeast"
		Vector2i(-1, 0):
			return &"northwest"
		Vector2i(0, 1):
			return &"southwest"
		Vector2i(0, -1):
			return &"northeast"
		_:
			return _world_offset_to_anim_suffix(tile_to_world(to_tile) - tile_to_world(from_tile))


func _world_offset_to_anim_suffix(offset: Vector2) -> StringName:
	if offset.length_squared() < 0.01:
		return &"southeast"

	var origin := tile_to_world(Vector2i.ZERO)
	var step_x := (tile_to_world(Vector2i(1, 0)) - origin).normalized()
	var step_y := (tile_to_world(Vector2i(0, 1)) - origin).normalized()
	var dir := offset.normalized()
	var dot_x := dir.dot(step_x)
	var dot_y := dir.dot(step_y)

	if absf(dot_x) >= absf(dot_y):
		return &"southeast" if dot_x >= 0.0 else &"northwest"
	return &"southwest" if dot_y >= 0.0 else &"northeast"


func get_place_layer(building: Dictionary) -> TileMapLayer:
	if building.get("place_layer", "building") == "ground":
		return ground_layer
	return building_layer


func has_ground(tile: Vector2i) -> bool:
	if not ground_layer:
		return true
	return ground_layer.get_cell_source_id(tile) != -1


func is_building_slot_free(tile: Vector2i) -> bool:
	return not is_cell_blocked(tile)


func is_cell_blocked(tile: Vector2i) -> bool:
	return _cell_owner.has(tile)


func is_building_layer_free(tile: Vector2i) -> bool:
	if is_cell_blocked(tile):
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
			if not is_building_layer_free(cell):
				return false
	return true


func can_place_building(anchor: Vector2i, building: Dictionary) -> bool:
	var block_origin := BuildingCatalog.get_block_origin(anchor)
	return can_place(block_origin, BuildingCatalog.get_footprint(building))


func get_placed_building_at(tile: Vector2i) -> Dictionary:
	if not _cell_owner.has(tile):
		return {}
	var anchor: Vector2i = _cell_owner[tile]
	return _placed.get(anchor, {})


func get_building_index_at(tile: Vector2i) -> int:
	var data: Dictionary = get_placed_building_at(tile)
	return int(data.get("building_index", -1))


func count_buildings_by_id(building_id: String) -> int:
	var target_index: int = BuildingCatalog.get_index_by_id(building_id)
	if target_index < 0:
		return 0
	var count: int = 0
	for anchor in _placed:
		if int(_placed[anchor].get("building_index", -1)) == target_index:
			count += 1
	return count


## Liest Gebäude-Tiles aus dem BuildingLayer und registriert sie fürs Spiel.
func import_buildings_from_tilemap() -> Array:
	var imported: Array = []
	if not building_layer:
		return imported

	var seen_anchors: Dictionary = {}
	for cell in building_layer.get_used_cells():
		var source_id: int = building_layer.get_cell_source_id(cell)
		if source_id == -1:
			continue
		var atlas_coords: Vector2i = building_layer.get_cell_atlas_coords(cell)
		var building_index: int = BuildingCatalog.get_index_by_tile(source_id, atlas_coords)
		if building_index < 0:
			continue

		var building: Dictionary = BuildingCatalog.get_building(building_index)
		if building.is_empty() or BuildingCatalog.is_road(building):
			continue

		var anchor: Vector2i = cell - BuildingCatalog.get_sprite_cell(building)
		var anchor_key := "%d,%d" % [anchor.x, anchor.y]
		if seen_anchors.has(anchor_key) or _placed.has(anchor):
			continue

		if BuildingCatalog.get_sprite_tile(anchor, building) != cell:
			continue

		register_building(anchor, building_index, building)
		seen_anchors[anchor_key] = true
		imported.append({
			"anchor": anchor,
			"building_index": building_index,
		})

	return imported


func register_building(anchor: Vector2i, building_index: int, building: Dictionary) -> void:
	var footprint: Vector2i = BuildingCatalog.get_footprint(building)
	var block_origin: Vector2i = BuildingCatalog.get_block_origin(anchor)
	var backup: Dictionary = {}
	if BuildingCatalog.is_road(building):
		backup = _pending_ground_backup
	_pending_ground_backup = {}

	_placed[anchor] = {
		"anchor": anchor,
		"footprint": footprint,
		"foot_origin": block_origin,
		"building_index": building_index,
		"cost": BuildingCatalog.get_cost(building),
		"income": BuildingCatalog.get_income(building),
		"kind": building.get("kind", "building"),
		"place_layer": building.get("place_layer", "building"),
		"sprite_tile": BuildingCatalog.get_sprite_tile(anchor, building),
		"ground_backup": backup,
	}

	for x in range(footprint.x):
		for y in range(footprint.y):
			_cell_owner[block_origin + Vector2i(x, y)] = anchor


func remove_building_at(tile: Vector2i) -> Dictionary:
	var anchor: Vector2i = _cell_owner.get(tile, Vector2i(-999999, -999999))
	if anchor == Vector2i(-999999, -999999):
		if not building_layer or building_layer.get_cell_source_id(tile) == -1:
			return {}
		building_layer.erase_cell(tile)
		return {}

	var data: Dictionary = _placed[anchor].duplicate()
	var footprint: Vector2i = data["footprint"] as Vector2i
	var foot_origin: Vector2i = data["foot_origin"] as Vector2i

	for x in range(footprint.x):
		for y in range(footprint.y):
			_cell_owner.erase(foot_origin + Vector2i(x, y))
	_placed.erase(anchor)

	var ground_backup: Dictionary = data.get("ground_backup", {})
	if not ground_backup.is_empty():
		restore_ground_tiles(ground_backup)
		return data

	var layer := building_layer
	if data.get("place_layer", "building") == "ground":
		layer = ground_layer
	var sprite_tile: Vector2i = data.get("sprite_tile", anchor) as Vector2i
	if layer:
		layer.erase_cell(sprite_tile)
	return data


func place_ground_overlay(
	place_origin: Vector2i,
	size: Vector2i,
	source_id: int,
	atlas_coords: Vector2i,
) -> Dictionary:
	_pending_ground_backup = {}
	if not ground_layer:
		return {}

	for x in range(size.x):
		for y in range(size.y):
			var cell := place_origin + Vector2i(x, y)
			_pending_ground_backup[cell] = _snapshot_ground_cell(cell)
			ground_layer.set_cell(cell, source_id, atlas_coords)
	return _pending_ground_backup


func restore_ground_tiles(backup: Dictionary) -> void:
	if not ground_layer:
		return
	for cell_variant in backup.keys():
		var cell: Vector2i = cell_variant
		_restore_ground_cell(cell, backup[cell_variant])


func _snapshot_ground_cell(cell: Vector2i) -> Dictionary:
	if not ground_layer:
		return {}
	var source_id := ground_layer.get_cell_source_id(cell)
	if source_id == -1:
		return {}
	return {
		"source_id": source_id,
		"atlas_coords": ground_layer.get_cell_atlas_coords(cell),
		"alternative_tile": ground_layer.get_cell_alternative_tile(cell),
	}


func _restore_ground_cell(cell: Vector2i, data: Dictionary) -> void:
	if not ground_layer:
		return
	if data.is_empty() or int(data.get("source_id", -1)) == -1:
		ground_layer.erase_cell(cell)
		return
	ground_layer.set_cell(
		cell,
		int(data["source_id"]),
		data["atlas_coords"],
		int(data.get("alternative_tile", 0)),
	)
