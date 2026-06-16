extends Node
## Autoload: Lager, Tages-Tick, Gebäude-Produktion.


signal resources_changed
signal day_completed(day_number: int)

var stock: Dictionary = {}
var day_timer: float = 0.0
var day_count: int = 0

# anchor (String) -> {building_index, modes, skip_water_upkeep}
var _buildings: Dictionary = {}
# building_index -> Array[String] default modes for new placements
var _default_modes: Dictionary = {}


func _ready() -> void:
	_reset_stock()


func _process(delta: float) -> void:
	day_timer += delta
	if day_timer >= ResourceCatalog.SECONDS_PER_DAY:
		day_timer -= ResourceCatalog.SECONDS_PER_DAY
		_run_day()


func _reset_stock() -> void:
	stock = ResourceCatalog.get_start_stock().duplicate()
	resources_changed.emit()


func set_default_modes(building_index: int, modes: Array) -> void:
	_default_modes[building_index] = modes.duplicate()


func get_default_modes(building_index: int) -> Array:
	return _default_modes.get(building_index, []).duplicate()


func register_building(anchor: Vector2i, building_index: int) -> void:
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	var key := _anchor_key(anchor)
	var modes: Array = get_default_modes(building_index)
	if modes.is_empty() and building.has("default_modes"):
		modes = building["default_modes"].duplicate()

	_buildings[key] = {
		"building_index": building_index,
		"modes": modes,
	}


func unregister_building(anchor: Vector2i) -> void:
	_buildings.erase(_anchor_key(anchor))


func set_building_modes(anchor: Vector2i, modes: Array) -> void:
	var key := _anchor_key(anchor)
	if not _buildings.has(key):
		return
	_buildings[key]["modes"] = modes.duplicate()


func get_building_modes(anchor: Vector2i) -> Array:
	var key := _anchor_key(anchor)
	if not _buildings.has(key):
		return []
	return _buildings[key]["modes"].duplicate()


func get_amount(resource_id: String) -> float:
	return float(stock.get(resource_id, 0.0))


func has_resources(costs: Dictionary) -> bool:
	for resource_id in costs:
		if get_amount(resource_id) < float(costs[resource_id]):
			return false
	return true


func add_resources(amounts: Dictionary) -> void:
	for resource_id in amounts:
		stock[resource_id] = get_amount(resource_id) + float(amounts[resource_id])
	resources_changed.emit()


func spend_resources(costs: Dictionary) -> bool:
	if not has_resources(costs):
		return false
	for resource_id in costs:
		stock[resource_id] = get_amount(resource_id) - float(costs[resource_id])
	resources_changed.emit()
	return true


func _run_day() -> void:
	day_count += 1
	for key in _buildings:
		var data: Dictionary = _buildings[key]
		var building: Dictionary = BuildingCatalog.get_building(data["building_index"])
		if building.is_empty():
			continue
		if not _pay_upkeep(building):
			continue
		_run_building_production(building, data["modes"])
	day_completed.emit(day_count)
	resources_changed.emit()


func _pay_upkeep(building: Dictionary) -> bool:
	var upkeep := BuildingCatalog.get_daily_upkeep(building)
	if upkeep.is_empty():
		return true
	if not spend_resources(upkeep):
		return false
	return true


func _run_building_production(building: Dictionary, modes: Array) -> void:
	var kind: String = building.get("kind", "passive")
	match kind:
		"extractor":
			add_resources(building.get("outputs_per_day", {}))
		"multi_extractor":
			for mode_id in modes:
				var mode: Dictionary = BuildingCatalog.get_mode(building, str(mode_id))
				if not mode.is_empty():
					add_resources(mode.get("outputs_per_day", {}))
		"processor":
			for mode_id in modes:
				var recipe: Dictionary = BuildingCatalog.get_recipe(building, str(mode_id))
				if recipe.is_empty():
					continue
				if has_resources(recipe.get("inputs", {})):
					spend_resources(recipe.get("inputs", {}))
					add_resources(recipe.get("outputs", {}))
		"multi_recipe":
			for mode_id in modes:
				var recipe: Dictionary = BuildingCatalog.get_recipe(building, str(mode_id))
				if recipe.is_empty():
					continue
				if has_resources(recipe.get("inputs", {})):
					spend_resources(recipe.get("inputs", {}))
					add_resources(recipe.get("outputs", {}))


func get_summary_lines(max_lines: int = 8) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("Tag %d  (%.0fs/Tag)" % [day_count, ResourceCatalog.SECONDS_PER_DAY])
	var keys: Array = stock.keys()
	keys.sort()
	var shown := 0
	for resource_id in keys:
		var amount: float = get_amount(resource_id)
		if amount <= 0.0:
			continue
		lines.append("%s: %.0f" % [ResourceCatalog.get_resource_name(resource_id), amount])
		shown += 1
		if shown >= max_lines:
			lines.append("...")
			break
	if _buildings.is_empty():
		lines.append("Keine Produktionsgebäude")
	return lines


func _anchor_key(anchor: Vector2i) -> String:
	return "%d,%d" % [anchor.x, anchor.y]
