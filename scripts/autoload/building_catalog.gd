extends Node
## Autoload: Zentrale Liste aller platzierbaren Gebäude.
## Hier neue Gebäudetypen hinzufügen – BuildingPlacer liest diese Daten automatisch.

# Jedes Gebäude braucht:
#   name        → Anzeigename (Debug / später UI)
#   source_id   → TileSet-Source-ID im Building-Layer
#   atlas_coords → Position im Atlas (Vector2i)
#   size        → Fußabdruck in Tiles (Vector2i), Standard 1x1
const BUILDINGS: Array[Dictionary] = [
	{
		"name": "Haus",
		"source_id": 0,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
	},
	{
		"name": "Fabrik",
		"source_id": 0,
		"atlas_coords": Vector2i(1, 0),
		"size": Vector2i(2, 2),
	},
	{
		"name": "Park",
		"source_id": 0,
		"atlas_coords": Vector2i(2, 0),
		"size": Vector2i(1, 1),
	},
]


func get_building(index: int) -> Dictionary:
	if index < 0 or index >= BUILDINGS.size():
		return {}
	return BUILDINGS[index]


func get_count() -> int:
	return BUILDINGS.size()
