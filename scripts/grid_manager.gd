class_name GridManager
extends Node


@export var ground_layer: TileMapLayer
@export var building_layer: TileMapLayer

var _placed: Dictionary = {}
var _cell_owner: Dictionary = {}


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
