extends Node
## Autoload: Zentrale Liste aller platzierbaren Gebäude.

# Jedes Gebäude:
#   name, source_id, atlas_coords, size, footprint, footprint_offset
#   cost    → Baukosten in Euro
#   income  → Einkommen pro Sekunde
const BUILDINGS: Array[Dictionary] = [
	{
		"name": "House",
		"source_id": 0,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 100,
		"income": 5,
	},
	{
		"name": "Ersatzmilchfabrik",
		"source_id": 1,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 300,
		"income": 15,
	},
]


func get_building(index: int) -> Dictionary:
	if index < 0 or index >= BUILDINGS.size():
		return {}
	return BUILDINGS[index]


func get_count() -> int:
	return BUILDINGS.size()


func get_cost(building: Dictionary) -> int:
	return int(building.get("cost", 0))


func get_income(building: Dictionary) -> int:
	return int(building.get("income", 0))


func get_footprint(building: Dictionary) -> Vector2i:
	if building.has("footprint"):
		return building["footprint"]
	return building.get("size", Vector2i.ONE)


func get_footprint_offset(building: Dictionary) -> Vector2i:
	return building.get("footprint_offset", Vector2i.ZERO)


func get_footprint_origin(anchor: Vector2i, building: Dictionary) -> Vector2i:
	return anchor + get_footprint_offset(building)


func get_button_label(building: Dictionary) -> String:
	var name_text: String = building.get("name", "Gebäude")
	var cost: int = get_cost(building)
	var income: int = get_income(building)
	return "%s  |  %d€  |  +%d/s" % [name_text, cost, income]
