class_name GridManager
extends Node
## Hilfsklasse für isometrische Koordinaten-Umrechnung.
## An die Main-Szene hängen und Ground-/Building-Layer im Inspector zuweisen.


@export var ground_layer: TileMapLayer
@export var building_layer: TileMapLayer

# origin → footprint; jede belegte Zelle → origin des Gebäudes
var _placed: Dictionary = {}
var _cell_owner: Dictionary = {}


# Wandelt eine globale Maus-/Weltposition in Tile-Koordinaten um.
func world_to_tile(world_pos: Vector2) -> Vector2i:
	if not building_layer:
		return Vector2i(-9999, -9999)
	var local_pos := building_layer.to_local(world_pos)
	return building_layer.local_to_map(local_pos)


# Wandelt Tile-Koordinaten zurück in Weltposition (Tile-Mitte).
func tile_to_world(tile: Vector2i) -> Vector2:
	if not building_layer:
		return Vector2.ZERO
	var local_pos := building_layer.map_to_local(tile)
	return building_layer.to_global(local_pos)


# Prüft ob auf dem Boden-Layer an dieser Stelle ein Tile liegt.
func has_ground(tile: Vector2i) -> bool:
	if not ground_layer:
		return true  # Kein Ground-Layer → überall bauen erlauben
	return ground_layer.get_cell_source_id(tile) != -1


# Prüft ob der Building-Layer an dieser Stelle leer ist.
func is_building_slot_free(tile: Vector2i) -> bool:
	if _cell_owner.has(tile):
		return false
	if not building_layer:
		return false
	return building_layer.get_cell_source_id(tile) == -1


# Markiert alle Kacheln im Fußabdruck als belegt.
func register_building(origin: Vector2i, footprint: Vector2i) -> void:
	_placed[origin] = footprint
	for x in range(footprint.x):
		for y in range(footprint.y):
			_cell_owner[origin + Vector2i(x, y)] = origin


# Entfernt Gebäude an dieser Kachel (findet automatisch den Ursprung).
func remove_building_at(tile: Vector2i) -> bool:
	var origin: Vector2i = _cell_owner.get(tile, Vector2i(-999999, -999999))
	if origin == Vector2i(-999999, -999999):
		if not building_layer or building_layer.get_cell_source_id(tile) == -1:
			return false
		building_layer.erase_cell(tile)
		return true

	var footprint: Vector2i = _placed[origin]
	for x in range(footprint.x):
		for y in range(footprint.y):
			_cell_owner.erase(origin + Vector2i(x, y))
	_placed.erase(origin)
	building_layer.erase_cell(origin)
	return true


# Prüft ob ein Gebäude mit gegebener Größe platziert werden kann.
func can_place(origin: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var cell := origin + Vector2i(x, y)
			if not has_ground(cell):
				return false
			if not is_building_slot_free(cell):
				return false
	return true
