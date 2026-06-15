extends Node2D
## Kern-Logik: Gebäude platzieren, entfernen und Vorschau anzeigen.
## An einen Node in der Main-Szene hängen (z.B. "BuildingPlacer").


@export var grid_manager: GridManager
@export var selected_building_index: int = 0

# Ghost-Vorschau: halbtransparentes Sprite das der Maus folgt
var _ghost: Sprite2D


func _ready() -> void:
	_setup_ghost()


func _setup_ghost() -> void:
	_ghost = Sprite2D.new()
	_ghost.modulate = Color(1, 1, 1, 0.5)
	_ghost.visible = false
	add_child(_ghost)


func _process(_delta: float) -> void:
	_update_ghost()


func _unhandled_input(event: InputEvent) -> void:
	if not grid_manager:
		return

	# Zifferntasten 1–9 → Gebäudetyp wählen
	if event is InputEventKey and event.pressed and not event.echo:
		var key_num := event.keycode - KEY_1
		if key_num >= 0 and key_num < BuildingCatalog.get_count():
			selected_building_index = key_num

	# Linksklick → Gebäude platzieren
	if event is InputEventMouseButton and event.pressed:
		var tile := grid_manager.world_to_tile(get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_building(tile)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_building(tile)


func _update_ghost() -> void:
	if not grid_manager or not grid_manager.building_layer:
		_ghost.visible = false
		return

	var building := BuildingCatalog.get_building(selected_building_index)
	if building.is_empty():
		_ghost.visible = false
		return

	var tile := grid_manager.world_to_tile(get_global_mouse_position())
	var can_place := grid_manager.can_place(tile, building.get("size", Vector2i.ONE))

	_ghost.global_position = grid_manager.tile_to_world(tile)
	_ghost.visible = true

	# Grün = platzierbar, Rot = blockiert
	_ghost.modulate = Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

	# Tile-Textur aus dem Building-Layer als Vorschau holen
	var tile_data := grid_manager.building_layer.tile_set.get_source(building["source_id"])
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
	if not grid_manager.can_place(origin, size):
		return

	var layer := grid_manager.building_layer
	for x in range(size.x):
		for y in range(size.y):
			var cell := origin + Vector2i(x, y)
			layer.set_cell(cell, building["source_id"], building["atlas_coords"])


func _remove_building(tile: Vector2i) -> void:
	if not grid_manager.building_layer:
		return
	if grid_manager.building_layer.get_cell_source_id(tile) == -1:
		return
	grid_manager.building_layer.erase_cell(tile)
