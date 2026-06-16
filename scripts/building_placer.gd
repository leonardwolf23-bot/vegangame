extends Node2D
## Gebäude platzieren, entfernen, Ghost-Vorschau.
## An einen Node2D in der Szene hängen (z.B. "BuildingPlacer").


@export_group("Verknüpfungen")
@export var grid_manager_path: NodePath = NodePath("../GridManager")

@export_group("Spiel")
@export var selected_building_index: int = 0

@export_group("Ghost-Vorschau")
## Verschiebt die Vorschau in Kachel-Einheiten (Bruchteile möglich, z.B. 0.5)
@export var ghost_offset_tiles: Vector2 = Vector2(0, 0.5)

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
	if not _grid or not _build_mode_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_num: int = int(event.keycode) - KEY_1
		if key_num >= 0 and key_num < BuildingCatalog.get_count():
			selected_building_index = key_num

	if event is InputEventMouseButton and event.pressed:
		var tile := _get_placement_tile()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_building(tile)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_building(tile)


func _get_placement_tile() -> Vector2i:
	return _grid.world_to_tile(get_global_mouse_position())


func _can_place_building(tile: Vector2i, building: Dictionary) -> bool:
	if not _grid.can_place_building(tile, building):
		return false
	return GameState.can_afford(BuildingCatalog.get_cost(building))


func _update_ghost() -> void:
	if not _grid or not _grid.building_layer:
		_ghost.visible = false
		return

	var building: Dictionary = BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		_ghost.visible = false
		return

	var tile := _get_placement_tile()
	var can_place: bool = _can_place_building(tile, building)

	_ghost.global_position = _grid.tile_to_world(tile) + _get_ghost_offset()
	_ghost.visible = true
	_ghost.modulate = Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

	var tile_data = _grid.building_layer.tile_set.get_source(building["source_id"])
	if tile_data is TileSetAtlasSource:
		var atlas: TileSetAtlasSource = tile_data
		_ghost.texture = atlas.texture
		_ghost.region_enabled = true
		_ghost.region_rect = atlas.get_tile_texture_region(building["atlas_coords"])


func _place_building(origin: Vector2i) -> void:
	var building: Dictionary = BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		return

	if not _can_place_building(origin, building):
		return

	var cost: int = BuildingCatalog.get_cost(building)
	if not GameState.spend(cost):
		return

	var layer: TileMapLayer = _grid.building_layer
	var size: Vector2i = building.get("size", Vector2i.ONE)

	if size == Vector2i.ONE:
		layer.set_cell(origin, building["source_id"], building["atlas_coords"])
	else:
		for x in range(size.x):
			for y in range(size.y):
				var cell := origin + Vector2i(x, y)
				layer.set_cell(cell, building["source_id"], building["atlas_coords"])

	_grid.register_building(origin, building)
	GameState.add_building_income(BuildingCatalog.get_income(building))


func _remove_building(tile: Vector2i) -> void:
	var income: int = _grid.remove_building_at(tile)
	if income > 0:
		GameState.remove_building_income(income)


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
