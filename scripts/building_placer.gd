extends Node2D
## Gebäude platzieren, verkaufen, Ghost-Vorschau.


@export_group("Verknüpfungen")
@export var grid_manager_path: NodePath = NodePath("../GridManager")

@export_group("Spiel")
@export var selected_building_index: int = 0
@export_range(0.0, 1.0, 0.05) var sell_refund_factor: float = 0.5

@export_group("Ghost-Vorschau")
@export var ghost_offset_tiles: Vector2 = Vector2.ZERO

var _grid: GridManager
var _ghost: Sprite2D
var _build_mode_active: bool = false


func _ready() -> void:
	_grid = get_node_or_null(grid_manager_path) as GridManager
	if not _grid:
		push_error("BuildingPlacer: GridManager nicht gefunden! Pfad: %s" % grid_manager_path)
		return
	_setup_ghost()


func select_building(index: int) -> void:
	if index >= 0 and index < BuildingCatalog.get_count():
		selected_building_index = index


func set_build_mode(active: bool) -> void:
	_build_mode_active = active
	if not _build_mode_active and _ghost:
		_ghost.visible = false


func is_build_mode_active() -> bool:
	return _build_mode_active


func _setup_ghost() -> void:
	_ghost = Sprite2D.new()
	_ghost.modulate = Color(1, 1, 1, 0.5)
	_ghost.visible = false
	_ghost.z_index = 100
	_ghost.y_sort_enabled = false
	add_child(_ghost)


func _process(_delta: float) -> void:
	if not _build_mode_active:
		if _ghost:
			_ghost.visible = false
		return
	_update_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if not _grid:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_sell_building(_get_placement_tile())
		return

	if not _build_mode_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_num: int = int(event.keycode) - KEY_1
		if key_num >= 0 and key_num < BuildingCatalog.get_count():
			selected_building_index = key_num

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_place_building(_get_placement_tile())


func _get_placement_tile() -> Vector2i:
	return _grid.world_to_tile_from_mouse()


func _can_place_building(tile: Vector2i, building: Dictionary) -> bool:
	if not _grid.can_place_building(tile, building):
		return false
	return BuildingCatalog.can_afford(building)


func _update_ghost() -> void:
	if not _grid or not _grid.building_layer:
		_ghost.visible = false
		return

	var building: Dictionary = BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		_ghost.visible = false
		return

	var tile: Vector2i = _get_placement_tile()
	var can_place: bool = _can_place_building(tile, building)

	_ghost.global_position = _grid.tile_to_walk_world(tile) + _get_ghost_offset()
	_ghost.visible = true
	_ghost.modulate = Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

	var tile_data = _grid.building_layer.tile_set.get_source(building["source_id"])
	if tile_data is TileSetAtlasSource:
		var atlas: TileSetAtlasSource = tile_data
		_ghost.texture = atlas.texture
		_ghost.region_enabled = true
		_ghost.region_rect = atlas.get_tile_texture_region(building["atlas_coords"])


func _place_building(origin: Vector2i) -> void:
	var building_index: int = selected_building_index
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if building.is_empty():
		return

	if not _can_place_building(origin, building):
		return

	if not BuildingCatalog.spend_build_cost(building):
		return

	var layer: TileMapLayer = _grid.building_layer
	var size: Vector2i = building.get("size", Vector2i.ONE)

	if size == Vector2i.ONE:
		layer.set_cell(origin, building["source_id"], building["atlas_coords"])
	else:
		for x in range(size.x):
			for y in range(size.y):
				var cell: Vector2i = origin + Vector2i(x, y)
				layer.set_cell(cell, building["source_id"], building["atlas_coords"])

	_grid.register_building(origin, building_index, building)
	if not BuildingCatalog.is_housing(building):
		var foot_origin := BuildingCatalog.get_footprint_origin(origin, building)
		var footprint := BuildingCatalog.get_footprint(building)
		var center_tile := foot_origin + Vector2i(footprint.x / 2, footprint.y / 2)
		var world_pos := _grid.tile_to_world(center_tile)
		ProductionManager.register_building(origin, building_index, world_pos)

	if BuildingCatalog.is_housing(building):
		GameState.register_housing(BuildingCatalog.get_income(building))


func _sell_building(tile: Vector2i) -> void:
	var data: Dictionary = _grid.remove_building_at(tile)
	if data.is_empty():
		return

	var anchor: Vector2i = data.get("anchor", Vector2i.ZERO)
	ProductionManager.unregister_building(anchor)

	var building_index: int = int(data.get("building_index", -1))
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if BuildingCatalog.is_housing(building):
		GameState.unregister_housing(BuildingCatalog.get_income(building))

	var cost: int = int(data.get("cost", 0))
	var refund: int = int(cost * sell_refund_factor)
	if refund > 0:
		GameState.add_money(refund)

	var resource_costs: Dictionary = data.get("resource_costs", {})
	for resource_id in resource_costs:
		var resource_refund := int(float(resource_costs[resource_id]) * sell_refund_factor)
		if resource_refund > 0:
			ProductionManager.add_resources({resource_id: float(resource_refund)})


func _get_ghost_offset() -> Vector2:
	if not _grid or not _grid.building_layer:
		return Vector2.ZERO
	var layer := _grid.building_layer

	var full := Vector2i(
		int(floor(ghost_offset_tiles.x)),
		int(floor(ghost_offset_tiles.y))
	)
	var frac := ghost_offset_tiles - Vector2(full)

	var offset := layer.map_to_local(full) - layer.map_to_local(Vector2i.ZERO)

	if frac != Vector2.ZERO:
		var step_x := layer.map_to_local(Vector2i(1, 0)) - layer.map_to_local(Vector2i.ZERO)
		var step_y := layer.map_to_local(Vector2i(0, 1)) - layer.map_to_local(Vector2i.ZERO)
		offset += step_x * frac.x + step_y * frac.y

	return offset
