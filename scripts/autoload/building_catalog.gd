extends Node
## Autoload: Zentrale Liste aller platzierbaren Gebäude.
## Hier neue Gebäudetypen hinzufügen – BuildingPlacer liest diese Daten automatisch.

# Jedes Gebäude braucht:
#   name        → Anzeigename (Debug / später UI)
#   source_id   → TileSet-Source-ID im Building-Layer
#   atlas_coords → Position im Atlas (Vector2i)
#   size        → Wie viele Tiles beim Platzieren gesetzt werden (meist 1x1)
#   footprint   → Blockierter Bereich auf dem Grid (z.B. 3x3 bei großen Sprites)
const BUILDINGS: Array[Dictionary] = [
	{
		"name": "House",
		"source_id": 0,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
	},
	{
		"name": "Ersatzmilchfabrik",
		"source_id": 1,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
	},
]


func get_building(index: int) -> Dictionary:
	if index < 0 or index >= BUILDINGS.size():
		return {}
	return BUILDINGS[index]


func get_count() -> int:
	return BUILDINGS.size()


func get_footprint(building: Dictionary) -> Vector2i:
	if building.has("footprint"):
		return building["footprint"]
	return building.get("size", Vector2i.ONE)
