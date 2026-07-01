extends Node
## Autoload: Lager, Tages-Tick, Gebäude-Produktion, lokale Lager + Transport.


signal resources_changed
signal day_completed(day_number: int)

const CARRY_AMOUNT: float = 3.0
const LOCAL_STOCK_CAP: float = 30.0
const INN_STOCK_CAP: float = 60.0
const INN_TARGET_PER_FOOD: float = 6.0
const WAREHOUSE_STOCK_CAP: float = 150.0
const WAREHOUSE_TARGET_PER_RESOURCE: float = 12.0
const FOOD_PER_CITIZEN_PER_DAY: float = 1.5

var stock: Dictionary = {}
var day_timer: float = 0.0
var day_count: int = 0

# anchor (String) -> {building_index, modes, world_pos}
var _buildings: Dictionary = {}
# building_index -> Array[String] default modes for new placements
var _default_modes: Dictionary = {}
# anchor (String) -> {resource_id: amount}
var _local_stock: Dictionary = {}
# job_key -> reserved amount (avoid duplicate assignments)
var _reserved: Dictionary = {}

var _grid_manager: GridManager


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


func register_building(anchor: Vector2i, building_index: int, world_pos: Vector2 = Vector2.ZERO) -> void:
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	var key := _anchor_key(anchor)
	var modes: Array = get_default_modes(building_index)
	if modes.is_empty() and building.has("default_modes"):
		modes = building["default_modes"].duplicate()

	_buildings[key] = {
		"building_index": building_index,
		"modes": modes,
		"world_pos": world_pos,
	}
	if not _local_stock.has(key):
		_local_stock[key] = {}

	_bootstrap_production(anchor, building, modes)


func unregister_building(anchor: Vector2i) -> void:
	var key := _anchor_key(anchor)
	_buildings.erase(key)
	_local_stock.erase(key)
	_clear_reservations_for_anchor(anchor)


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


func has_building_at(anchor: Vector2i) -> bool:
	return _buildings.has(_anchor_key(anchor))


func register_placed_building_if_needed(anchor: Vector2i, building_index: int) -> void:
	if has_building_at(anchor):
		return
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if building.is_empty() or not BuildingCatalog.needs_production_manager(building):
		return
	var world_pos := Vector2.ZERO
	if _grid_manager:
		var center_tile: Vector2i = BuildingCatalog.get_block_center(anchor, building)
		world_pos = _grid_manager.tile_to_world(center_tile)
	register_building(anchor, building_index, world_pos)


func bind_grid_manager(grid: GridManager) -> void:
	_grid_manager = grid
	refresh_all_world_positions()


func refresh_all_world_positions() -> void:
	if not _grid_manager:
		return
	for key in _buildings:
		var anchor := _key_to_anchor(key)
		var building_index: int = int(_buildings[key]["building_index"])
		var building: Dictionary = BuildingCatalog.get_building(building_index)
		if building.is_empty():
			continue
		var center_tile: Vector2i = BuildingCatalog.get_block_center(anchor, building)
		_buildings[key]["world_pos"] = _grid_manager.tile_to_world(center_tile)


func get_building_world_pos(anchor: Vector2i) -> Vector2:
	var key := _anchor_key(anchor)
	if not _buildings.has(key):
		return Vector2.ZERO
	var pos: Vector2 = _buildings[key].get("world_pos", Vector2.ZERO)
	if pos != Vector2.ZERO:
		return pos
	if _grid_manager:
		var building_index: int = int(_buildings[key]["building_index"])
		var building: Dictionary = BuildingCatalog.get_building(building_index)
		if not building.is_empty():
			var center_tile: Vector2i = BuildingCatalog.get_block_center(anchor, building)
			pos = _grid_manager.tile_to_world(center_tile)
			_buildings[key]["world_pos"] = pos
			return pos
	return Vector2.ZERO


func get_amount(resource_id: String) -> float:
	return float(stock.get(resource_id, 0.0))


func get_local_amount(anchor: Vector2i, resource_id: String) -> float:
	var key := _anchor_key(anchor)
	if not _local_stock.has(key):
		return 0.0
	return float(_local_stock[key].get(resource_id, 0.0))


func get_total_amount(resource_id: String) -> float:
	var total := get_amount(resource_id)
	for key in _local_stock:
		total += float(_local_stock[key].get(resource_id, 0.0))
	return total


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


func take_from_local(anchor: Vector2i, resource_id: String, amount: float) -> float:
	var key := _anchor_key(anchor)
	if not _local_stock.has(key):
		return 0.0
	var available := float(_local_stock[key].get(resource_id, 0.0))
	var reserved := _get_reserved(anchor, resource_id)
	available = maxf(available - reserved, 0.0)
	var taken := minf(amount, available)
	if taken <= 0.0:
		return 0.0
	_local_stock[key][resource_id] = float(_local_stock[key].get(resource_id, 0.0)) - taken
	if _local_stock[key][resource_id] <= 0.0:
		_local_stock[key].erase(resource_id)
	_unreserve(anchor, resource_id, taken)
	resources_changed.emit()
	return taken


func add_to_local(anchor: Vector2i, resource_id: String, amount: float) -> void:
	if amount <= 0.0 or not is_transportable(resource_id):
		return
	var key := _anchor_key(anchor)
	if not _local_stock.has(key):
		_local_stock[key] = {}
	var current := float(_local_stock[key].get(resource_id, 0.0))
	var cap := _get_local_cap(anchor)
	_local_stock[key][resource_id] = minf(current + amount, cap)
	resources_changed.emit()


func _get_local_cap(anchor: Vector2i) -> float:
	var key := _anchor_key(anchor)
	if not _buildings.has(key):
		return LOCAL_STOCK_CAP
	var building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
	if BuildingCatalog.is_inn(building):
		return INN_STOCK_CAP
	if BuildingCatalog.is_warehouse(building):
		return WAREHOUSE_STOCK_CAP
	return LOCAL_STOCK_CAP


func get_inn_food_supply() -> float:
	var total := 0.0
	for key in _buildings:
		var building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
		if not BuildingCatalog.is_inn(building):
			continue
		var anchor := _key_to_anchor(key)
		for resource_id in ResourceCatalog.get_edible_resource_ids():
			var amount := get_local_amount(anchor, resource_id)
			if amount > 0.0:
				total += amount * ResourceCatalog.get_food_value(resource_id)
	return total


func has_inn() -> bool:
	for key in _buildings:
		var building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
		if BuildingCatalog.is_inn(building):
			return true
	return false


func has_warehouse() -> bool:
	for key in _buildings:
		var building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
		if BuildingCatalog.is_warehouse(building):
			return true
	return false


func get_local_stock_lines(anchor: Vector2i, max_lines: int = 8) -> PackedStringArray:
	var lines: PackedStringArray = []
	var key := _anchor_key(anchor)
	if not _local_stock.has(key):
		lines.append("Lager leer")
		return lines
	var totals: Dictionary = _local_stock[key].duplicate()
	var keys: Array = totals.keys()
	keys.sort()
	var shown := 0
	for resource_id in keys:
		var amount: float = float(totals[resource_id])
		if amount <= 0.0:
			continue
		lines.append("%s: %.0f" % [ResourceCatalog.get_resource_name(resource_id), amount])
		shown += 1
		if shown >= max_lines:
			lines.append("...")
			break
	if shown == 0:
		lines.append("Lager leer")
	return lines


func is_transportable(resource_id: String) -> bool:
	return resource_id not in ["strom", "essen", "wasser", "seitanpulver"]


func release_job(job: Dictionary) -> void:
	if job.is_empty():
		return
	_unreserve(job["from_anchor"], job["resource"], float(job["amount"]))


func create_transport_jobs() -> Array:
	var jobs: Array = []
	jobs.append_array(_create_warehouse_delivery_jobs())
	jobs.append_array(_create_processor_jobs())
	jobs.append_array(_create_inn_delivery_jobs())
	return jobs


func _create_processor_jobs() -> Array:
	var jobs: Array = []
	var seen: Dictionary = {}

	for dest_key in _buildings:
		var dest_data: Dictionary = _buildings[dest_key]
		var dest_anchor := _key_to_anchor(dest_key)
		var building: Dictionary = BuildingCatalog.get_building(dest_data["building_index"])
		if building.is_empty():
			continue
		var kind: String = building.get("kind", "")
		if kind not in ["processor", "multi_recipe"]:
			continue

		for mode_id in dest_data["modes"]:
			var recipe: Dictionary = BuildingCatalog.get_recipe(building, str(mode_id))
			if recipe.is_empty():
				continue
			for resource_id in recipe.get("inputs", {}):
				if not is_transportable(resource_id):
					continue
				var needed: float = float(recipe["inputs"][resource_id])
				var have := get_local_amount(dest_anchor, resource_id)
				if have >= needed:
					continue

				var source_anchor := _find_best_source(dest_anchor, resource_id)
				if source_anchor == Vector2i(-999999, -999999):
					continue

				var pair_key := "%s>%s:%s" % [_anchor_key(source_anchor), dest_key, resource_id]
				if seen.has(pair_key):
					continue
				seen[pair_key] = true

				var source_available := _get_available_at(source_anchor, resource_id)
				var carry := minf(CARRY_AMOUNT, needed - have)
				carry = minf(carry, source_available)
				if carry <= 0.0:
					continue

				_reserve(source_anchor, resource_id, carry)
				jobs.append({
					"from_anchor": source_anchor,
					"to_anchor": dest_anchor,
					"resource": resource_id,
					"amount": carry,
				})

	return jobs


func _create_inn_delivery_jobs() -> Array:
	var jobs: Array = []
	var seen: Dictionary = {}

	for dest_key in _buildings:
		var dest_data: Dictionary = _buildings[dest_key]
		var dest_anchor := _key_to_anchor(dest_key)
		var building: Dictionary = BuildingCatalog.get_building(dest_data["building_index"])
		if not BuildingCatalog.is_inn(building):
			continue

		for resource_id in ResourceCatalog.get_edible_resource_ids():
			if not is_transportable(resource_id):
				continue
			var have := get_local_amount(dest_anchor, resource_id)
			if have >= INN_TARGET_PER_FOOD:
				continue

			var source_anchor := _find_best_source(dest_anchor, resource_id)
			if source_anchor == Vector2i(-999999, -999999):
				continue

			var pair_key := "inn:%s>%s:%s" % [_anchor_key(source_anchor), dest_key, resource_id]
			if seen.has(pair_key):
				continue
			seen[pair_key] = true

			var source_available := _get_available_at(source_anchor, resource_id)
			var carry := minf(CARRY_AMOUNT, INN_TARGET_PER_FOOD - have)
			carry = minf(carry, source_available)
			if carry <= 0.0:
				continue

			_reserve(source_anchor, resource_id, carry)
			jobs.append({
				"from_anchor": source_anchor,
				"to_anchor": dest_anchor,
				"resource": resource_id,
				"amount": carry,
			})

	return jobs


func _create_warehouse_delivery_jobs() -> Array:
	var jobs: Array = []
	var seen: Dictionary = {}

	for dest_key in _buildings:
		var dest_data: Dictionary = _buildings[dest_key]
		var dest_anchor := _key_to_anchor(dest_key)
		var building: Dictionary = BuildingCatalog.get_building(dest_data["building_index"])
		if not BuildingCatalog.is_warehouse(building):
			continue

		for resource_id in _collect_transportable_at_producers():
			var have := get_local_amount(dest_anchor, resource_id)
			if have >= WAREHOUSE_TARGET_PER_RESOURCE:
				continue

			var source_anchor := _find_warehouse_source(dest_anchor, resource_id)
			if source_anchor == Vector2i(-999999, -999999):
				continue

			var pair_key := "lager:%s>%s:%s" % [_anchor_key(source_anchor), dest_key, resource_id]
			if seen.has(pair_key):
				continue
			seen[pair_key] = true

			var source_available := _get_available_at(source_anchor, resource_id)
			var carry := minf(CARRY_AMOUNT, WAREHOUSE_TARGET_PER_RESOURCE - have)
			carry = minf(carry, source_available)
			if carry <= 0.0:
				continue

			_reserve(source_anchor, resource_id, carry)
			jobs.append({
				"from_anchor": source_anchor,
				"to_anchor": dest_anchor,
				"resource": resource_id,
				"amount": carry,
			})

	return jobs


func _collect_transportable_at_producers() -> Array:
	var found: Dictionary = {}
	for key in _buildings:
		var source_anchor := _key_to_anchor(key)
		var building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
		if BuildingCatalog.is_warehouse(building) or BuildingCatalog.is_inn(building):
			continue
		for resource_id in _local_stock.get(key, {}):
			if is_transportable(resource_id) and _get_available_at(source_anchor, resource_id) > 0.0:
				found[resource_id] = true
	var ids: Array = found.keys()
	ids.sort()
	return ids


func _find_warehouse_source(dest_anchor: Vector2i, resource_id: String) -> Vector2i:
	var best_anchor := Vector2i(-999999, -999999)
	var best_amount := 0.0
	for key in _buildings:
		var source_anchor := _key_to_anchor(key)
		if source_anchor == dest_anchor:
			continue
		var source_building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
		if BuildingCatalog.is_warehouse(source_building) or BuildingCatalog.is_inn(source_building):
			continue
		var available := _get_available_at(source_anchor, resource_id)
		if available > best_amount:
			best_amount = available
			best_anchor = source_anchor
	return best_anchor


func get_summary_lines(max_lines: int = 8) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("Tag %d  (%.0fs/Tag)" % [day_count, ResourceCatalog.SECONDS_PER_DAY])
	lines.append("(Ware in Gebäuden + Lager)")

	var totals: Dictionary = stock.duplicate()
	for key in _local_stock:
		for resource_id in _local_stock[key]:
			totals[resource_id] = float(totals.get(resource_id, 0.0)) + float(_local_stock[key][resource_id])

	var keys: Array = totals.keys()
	keys.sort()
	var shown := 0
	for resource_id in keys:
		var amount: float = float(totals[resource_id])
		if amount <= 0.0:
			continue
		lines.append("%s: %.0f" % [ResourceCatalog.get_resource_name(resource_id), amount])
		shown += 1
		if shown >= max_lines:
			lines.append("...")
			break
	if _buildings.is_empty():
		lines.append("Keine Produktionsgebäude")
	elif shown == 0:
		lines.append("Noch keine Ware — Bauernhof o.ä. bauen")
	return lines


func _run_day() -> void:
	day_count += 1
	for key in _buildings:
		var data: Dictionary = _buildings[key]
		var anchor := _key_to_anchor(key)
		var building: Dictionary = BuildingCatalog.get_building(data["building_index"])
		if building.is_empty():
			continue
		var kind: String = building.get("kind", "")
		if BuildingCatalog.is_housing(building):
			continue
		if BuildingCatalog.is_warehouse(building):
			_pay_upkeep(building)
			continue
		var upkeep_ok := _pay_upkeep(building)
		var scale := 1.0 if upkeep_ok else 0.5
		if BuildingCatalog.is_inn(building):
			_run_inn_consumption(anchor)
		else:
			_run_building_production(anchor, building, data["modes"], scale)
	day_completed.emit(day_count)
	resources_changed.emit()


func _pay_upkeep(building: Dictionary) -> bool:
	var upkeep := BuildingCatalog.get_daily_upkeep(building)
	if upkeep.is_empty():
		return true
	if not spend_resources(upkeep):
		return false
	return true


func _run_inn_consumption(anchor: Vector2i) -> void:
	var need := float(GameState.population) * FOOD_PER_CITIZEN_PER_DAY
	if need <= 0.0:
		return

	var edible_ids: Array = ResourceCatalog.get_edible_resource_ids()
	edible_ids.sort_custom(func(a, b): return ResourceCatalog.get_food_value(a) > ResourceCatalog.get_food_value(b))

	var remaining := need
	for resource_id in edible_ids:
		if remaining <= 0.0:
			break
		var available := get_local_amount(anchor, resource_id)
		if available <= 0.0:
			continue
		var food_value := ResourceCatalog.get_food_value(resource_id)
		if food_value <= 0.0:
			continue
		var units_needed := remaining / food_value
		var taken := minf(available, units_needed)
		var key := _anchor_key(anchor)
		_local_stock[key][resource_id] = available - taken
		if _local_stock[key][resource_id] <= 0.0:
			_local_stock[key].erase(resource_id)
		remaining -= taken * food_value

	resources_changed.emit()


func _run_building_production(anchor: Vector2i, building: Dictionary, modes: Array, scale: float = 1.0) -> void:
	var kind: String = building.get("kind", "passive")
	match kind:
		"extractor":
			_add_local_outputs_scaled(anchor, building.get("outputs_per_day", {}), scale)
		"multi_extractor":
			for mode_id in modes:
				var mode: Dictionary = BuildingCatalog.get_mode(building, str(mode_id))
				if not mode.is_empty():
					_add_local_outputs_scaled(anchor, mode.get("outputs_per_day", {}), scale)
		"processor", "multi_recipe":
			if scale < 1.0:
				return
			for mode_id in modes:
				var recipe: Dictionary = BuildingCatalog.get_recipe(building, str(mode_id))
				if recipe.is_empty():
					continue
				if _can_process_recipe(anchor, recipe):
					_spend_recipe_inputs(anchor, recipe.get("inputs", {}))
					_add_local_outputs(anchor, recipe.get("outputs", {}))


func _add_local_outputs_scaled(anchor: Vector2i, outputs: Dictionary, scale: float) -> void:
	for resource_id in outputs:
		add_to_local(anchor, resource_id, float(outputs[resource_id]) * scale)


func _add_local_outputs(anchor: Vector2i, outputs: Dictionary) -> void:
	for resource_id in outputs:
		add_to_local(anchor, resource_id, float(outputs[resource_id]))


func _bootstrap_production(anchor: Vector2i, building: Dictionary, modes: Array) -> void:
	# Sofort erste Ware ins lokale Lager, damit Bürger nicht 30s warten müssen.
	var kind: String = building.get("kind", "")
	match kind:
		"extractor":
			_add_local_outputs(anchor, building.get("outputs_per_day", {}))
		"multi_extractor":
			for mode_id in modes:
				var mode: Dictionary = BuildingCatalog.get_mode(building, str(mode_id))
				if not mode.is_empty():
					_add_local_outputs(anchor, mode.get("outputs_per_day", {}))


func _can_process_recipe(anchor: Vector2i, recipe: Dictionary) -> bool:
	for resource_id in recipe.get("inputs", {}):
		var needed := float(recipe["inputs"][resource_id])
		if is_transportable(resource_id):
			if get_local_amount(anchor, resource_id) < needed:
				return false
		elif get_amount(resource_id) < needed:
			return false
	return true


func _spend_recipe_inputs(anchor: Vector2i, inputs: Dictionary) -> void:
	for resource_id in inputs:
		var needed := float(inputs[resource_id])
		if is_transportable(resource_id):
			var key := _anchor_key(anchor)
			_local_stock[key][resource_id] = get_local_amount(anchor, resource_id) - needed
			if _local_stock[key][resource_id] <= 0.0:
				_local_stock[key].erase(resource_id)
		else:
			stock[resource_id] = get_amount(resource_id) - needed


func _find_best_source(dest_anchor: Vector2i, resource_id: String) -> Vector2i:
	var best_anchor := Vector2i(-999999, -999999)
	var best_amount := 0.0
	for key in _buildings:
		var source_anchor := _key_to_anchor(key)
		if source_anchor == dest_anchor:
			continue
		var source_building: Dictionary = BuildingCatalog.get_building(int(_buildings[key]["building_index"]))
		if BuildingCatalog.is_inn(source_building):
			continue
		var available := _get_available_at(source_anchor, resource_id)
		if available > best_amount:
			best_amount = available
			best_anchor = source_anchor
	return best_anchor


func _get_available_at(anchor: Vector2i, resource_id: String) -> float:
	return maxf(get_local_amount(anchor, resource_id) - _get_reserved(anchor, resource_id), 0.0)


func _reserve(anchor: Vector2i, resource_id: String, amount: float) -> void:
	var key := "%s:%s" % [_anchor_key(anchor), resource_id]
	_reserved[key] = float(_reserved.get(key, 0.0)) + amount


func _unreserve(anchor: Vector2i, resource_id: String, amount: float) -> void:
	var key := "%s:%s" % [_anchor_key(anchor), resource_id]
	if not _reserved.has(key):
		return
	_reserved[key] = float(_reserved[key]) - amount
	if _reserved[key] <= 0.0:
		_reserved.erase(key)


func _get_reserved(anchor: Vector2i, resource_id: String) -> float:
	var key := "%s:%s" % [_anchor_key(anchor), resource_id]
	return float(_reserved.get(key, 0.0))


func _clear_reservations_for_anchor(anchor: Vector2i) -> void:
	var prefix := _anchor_key(anchor) + ":"
	var to_erase: Array = []
	for key in _reserved:
		if str(key).begins_with(prefix):
			to_erase.append(key)
	for key in to_erase:
		_reserved.erase(key)


func _anchor_key(anchor: Vector2i) -> String:
	return "%d,%d" % [anchor.x, anchor.y]


func _key_to_anchor(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
