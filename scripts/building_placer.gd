extends Node2D
## Gebäude platzieren, entfernen, Ghost-Vorschau.
## An einen Node2D in der Szene hängen (z.B. "BuildingPlacer").
##
## VERKNÜPFUNG: Entweder main.gd nutzen (automatisch),
## oder unten im Inspector "Grid Manager Path" auf ../GridManager lassen.


@export_group("Verknüpfungen")
## Pfad zum GridManager-Node (Standard passt wenn er Geschwister-Node heißt "GridManager")
@export var grid_manager_path: NodePath = NodePath("../GridManager")

@export_group("Spiel")
@export var selected_building_index: int = 0

var _grid: GridManager
var _ghost: Sprite2D


func _ready() -> void:
	_grid = get_node_or_null(grid_manager_path) as GridManager
	if not _grid:
		push_error("BuildingPlacer: GridManager nicht gefunden! Pfad prüfen: %s" % grid_manager_path)
	_setup_ghost()


## Wird vom Bau-Menü aufgerufen wenn der Spieler ein Gebäude wählt.
func select_building(index: int) -> void:
	if index >= 0 and index < BuildingCatalog.get_count():
		selected_building_index = index


func _setup_ghost() -> void:
	_ghost = Sprite2D.new()
	_ghost.modulate = Color(1, 1, 1, 0.5)
	_ghost.visible = false
	add_child(_ghost)


func _process(_delta: float) -> void:
	_update_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if not _grid:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_num: int = int(event.keycode) - KEY_1
		if key_num >= 0 and key_num < BuildingCatalog.get_count():
			selected_building_index = key_num

	if event is InputEventMouseButton and event.pressed:
		var tile := _grid.world_to_tile(get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_building(tile)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_building(tile)


func _update_ghost() -> void:
	if not _grid or not _grid.building_layer:
		_ghost.visible = false
		return

	var building := BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		_ghost.visible = false
		return

	var tile := _grid.world_to_tile(get_global_mouse_position())
	var can_place := _grid.can_place(tile, building.get("size", Vector2i.ONE))

	_ghost.global_position = _grid.tile_to_world(tile)
	_ghost.visible = true
	_ghost.modulate = Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

	var tile_data := _grid.building_layer.tile_set.get_source(building["source_id"])
	if tile_data is TileSetAtlasSource:
		var atlas: TileSetAtlasSource = tile_data
		_ghost.texture = atlas.texture
		_ghost.region_enabled = true
		_ghost.region_rect = atlas.get_tile_texture_region(building["atlas_coords"])


func _place_building(origin: Vector2i) -> void:
	var building := BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		return

	var size: Vector2i = building.get("size", Vector2i.ONE)
	if not _grid.can_place(origin, size):
		return

	var layer := _grid.building_layer
	for x in range(size.x):
		for y in range(size.y):
			var cell := origin + Vector2i(x, y)
			layer.set_cell(cell, building["source_id"], building["atlas_coords"])


func _remove_building(tile: Vector2i) -> void:
	if not _grid.building_layer:
		return
	if _grid.building_layer.get_cell_source_id(tile) == -1:
		return
	_grid.building_layer.erase_cell(tile)
