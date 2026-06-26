extends Node2D
## Gebäude platzieren, verkaufen, Ghost-Vorschau.


@export_group("Verknüpfungen")
@export var grid_manager_path: NodePath = NodePath("../GridManager")

@export_group("Spiel")
@export var selected_building_index: int = 0
@export_range(0.0, 1.0, 0.05) var sell_refund_factor: float = 0.5

@export_group("Ghost-Vorschau")
@export var ghost_offset_tiles: Vector2 = Vector2(0, 0.5)

var _grid: GridManager
var _ghost_root: Node2D
var _ghost_cells: Array[Sprite2D] = []
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
	if not _build_mode_active:
		_hide_ghost()


func is_build_mode_active() -> bool:
	return _build_mode_active


func _setup_ghost() -> void:
	_ghost_root = Node2D.new()
	_ghost_root.z_index = 100
	add_child(_ghost_root)


func _hide_ghost() -> void:
	for cell in _ghost_cells:
		cell.visible = false


func _ensure_ghost_cells(count: int) -> void:
	while _ghost_cells.size() < count:
		var sprite := Sprite2D.new()
		sprite.modulate = Color(1, 1, 1, 0.5)
		sprite.y_sort_enabled = false
		_ghost_root.add_child(sprite)
		_ghost_cells.append(sprite)
	for i in _ghost_cells.size():
		_ghost_cells[i].visible = i < count


func _process(_delta: float) -> void:
	if not _build_mode_active:
		_hide_ghost()
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
	var tile := _grid.world_to_tile(get_global_mouse_position())
	var building: Dictionary = BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		return tile
	return BuildingCatalog.snap_placement_anchor(tile, building)


func _can_place_building(tile: Vector2i, building: Dictionary) -> bool:
	if not _grid.can_place_building(tile, building):
		return false
	return GameState.can_afford(BuildingCatalog.get_cost(building))


func _update_ghost() -> void:
	var building: Dictionary = BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		_hide_ghost()
		return

	var layer: TileMapLayer = _grid.get_place_layer(building)
	if not layer or not layer.tile_set:
		_hide_ghost()
		return

	var anchor: Vector2i = _get_placement_tile()
	var can_place: bool = _can_place_building(anchor, building)
	var place_origin := BuildingCatalog.get_visual_origin(anchor, building)
	var size: Vector2i = BuildingCatalog.get_visual_size(building)
	var tint := Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

	var tile_data = layer.tile_set.get_source(building["source_id"])
	if not tile_data is TileSetAtlasSource:
		_hide_ghost()
		return

	var atlas: TileSetAtlasSource = tile_data
	var region := atlas.get_tile_texture_region(building["atlas_coords"])
	var ghost_offset := _get_ghost_offset()

	_ensure_ghost_cells(size.x * size.y)
	var index := 0
	for x in range(size.x):
		for y in range(size.y):
			var cell: Vector2i = place_origin + Vector2i(x, y)
			var sprite := _ghost_cells[index]
			sprite.global_position = _grid.tile_to_world(cell) + ghost_offset
			sprite.texture = atlas.texture
			sprite.region_enabled = true
			sprite.region_rect = region
			sprite.modulate = tint
			index += 1


func _place_building(origin: Vector2i) -> void:
	var building_index: int = selected_building_index
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if building.is_empty():
		return

	if not _can_place_building(origin, building):
		return

	var cost: int = BuildingCatalog.get_cost(building)
	if not GameState.spend(cost):
		return

	var place_origin := BuildingCatalog.get_visual_origin(origin, building)
	var size: Vector2i = BuildingCatalog.get_visual_size(building)

	if BuildingCatalog.is_road(building):
		_grid.place_ground_overlay(
			place_origin,
			size,
			building["source_id"],
			building["atlas_coords"],
		)
	else:
		var layer: TileMapLayer = _grid.get_place_layer(building)
		if not layer:
			return
		for x in range(size.x):
			for y in range(size.y):
				var cell: Vector2i = place_origin + Vector2i(x, y)
				layer.set_cell(cell, building["source_id"], building["atlas_coords"])

	_grid.register_building(origin, building_index, building)
	if BuildingCatalog.is_road(building):
		return
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
	var building_index: int = int(data.get("building_index", -1))
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if not BuildingCatalog.is_road(building):
		ProductionManager.unregister_building(anchor)
	if BuildingCatalog.is_housing(building):
		GameState.unregister_housing(BuildingCatalog.get_income(building))

	var cost: int = int(data.get("cost", 0))
	var refund: int = int(cost * sell_refund_factor)
	if refund > 0:
		GameState.add_money(refund)


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
