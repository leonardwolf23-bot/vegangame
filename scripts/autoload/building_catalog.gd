extends Node
## Autoload: Zentrale Liste aller platzierbaren Gebäude.

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
		"produce_milk": 0.0,
		"consume_milk": 2.0,
		"income_needs_milk": true,
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
		"produce_milk": 5.0,
		"consume_milk": 0.0,
		"income_needs_milk": false,
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


func get_produce_milk(building: Dictionary) -> float:
	return float(building.get("produce_milk", 0.0))


func get_consume_milk(building: Dictionary) -> float:
	return float(building.get("consume_milk", 0.0))


func income_needs_milk(building: Dictionary) -> bool:
	return bool(building.get("income_needs_milk", false))


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
	var label := "%s  |  %d€  |  +%d/s" % [name_text, cost, income]
	var produce: float = get_produce_milk(building)
	var consume: float = get_consume_milk(building)
	if produce > 0.0:
		label += "  |  +%.0f Milch/s" % produce
	if consume > 0.0:
		label += "  |  -%.0f Milch/s" % consume
	return label
