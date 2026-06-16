extends Node
## Autoload: Zentrale Liste aller platzierbaren Gebäude.
## BuildingPlacer liest diese Daten automatisch.

# Jedes Gebäude:
#   name              → Anzeigename
#   source_id         → TileSet-Source-ID im Building-Layer
#   atlas_coords      → Position im Atlas
#   size              → Wie viele TileMap-Zellen gesetzt werden (meist 1x1)
#   footprint         → Wie viele Kacheln das Gebäude blockiert (z.B. 3x3)
#   footprint_offset  → Verschiebung des Fußabdrucks relativ zur Anker-Kachel
#                       Beispiel 3x3 mit Fuß in der Mitte unten: Vector2i(-1, -2)
const BUILDINGS: Array[Dictionary] = [
	{
		"name": "House",
		"source_id": 0,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
	},
	{
		"name": "Ersatzmilchfabrik",
		"source_id": 1,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
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


func get_footprint_offset(building: Dictionary) -> Vector2i:
	return building.get("footprint_offset", Vector2i.ZERO)


func get_footprint_origin(anchor: Vector2i, building: Dictionary) -> Vector2i:
	return anchor + get_footprint_offset(building)
