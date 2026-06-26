extends Node
## Autoload: Vitamin B12, Vitamin D und mentale Gesundheit als Marker (Versorgung vs. Bedarf).


signal health_status_changed

const SUPPLY_PER_FREIZEITPARK: float = 4.0
const SUPPLY_PER_STADTPARK: float = 3.5
const BOOK_MENTAL_WELLNESS: float = 2.5

const MARKERS: Array[Dictionary] = [
	{
		"id": "b12",
		"label": "Vitamin B12",
		"need_per_citizen": 1.5,
		"sources": {
			"vitamin_b12": 2.0,
			"sojamilch": 1.2,
			"hafermilch": 1.0,
			"sojajoghurt": 1.0,
		},
	},
	{
		"id": "vitamin_d",
		"label": "Vitamin D",
		"need_per_citizen": 2.0,
		"sources": {
			"vitamin_d": 2.0,
			"hafermilch": 1.0,
			"sojamilch": 0.8,
		},
		"building_id": "freizeitpark",
		"building_supply": SUPPLY_PER_FREIZEITPARK,
	},
	{
		"id": "mental",
		"label": "Mentale Gesundheit",
		"need_per_citizen": 2.0,
		"sources": {
			"mental_wellness": 1.0,
		},
		"building_id": "stadtpark",
		"building_supply": SUPPLY_PER_STADTPARK,
	},
]

var _deficient: Dictionary = {}
var _grid_manager: GridManager


func _ready() -> void:
	for marker in MARKERS:
		_deficient[marker["id"]] = false
	ProductionManager.day_completed.connect(_check_all)
	ProductionManager.resources_changed.connect(_check_all)
	GameState.population_changed.connect(_check_all)
	call_deferred("_check_all")


func bind_grid_manager(grid: GridManager) -> void:
	_grid_manager = grid
	_check_all()


func is_deficient(marker_id: String) -> bool:
	return bool(_deficient.get(marker_id, false))


func get_supply(marker: Dictionary) -> float:
	var total := 0.0
	for resource_id in marker.get("sources", {}):
		var factor: float = float(marker["sources"][resource_id])
		total += ProductionManager.get_total_amount(resource_id) * factor
	if marker.has("building_id") and _grid_manager:
		var count := _grid_manager.count_buildings_by_id(str(marker["building_id"]))
		total += float(count) * float(marker.get("building_supply", 0.0))
	return total


func get_need(marker: Dictionary) -> float:
	return float(GameState.population) * float(marker.get("need_per_citizen", 0.0))


func get_marker_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for marker in MARKERS:
		lines.append(_format_marker_line(marker))
	return lines


func read_book_at_rathaus() -> void:
	ProductionManager.add_resources({"mental_wellness": BOOK_MENTAL_WELLNESS})
	_check_all()


func _format_marker_line(marker: Dictionary) -> String:
	var marker_id: String = marker["id"]
	var label: String = marker["label"]
	var supply := get_supply(marker)
	var need := get_need(marker)
	if need <= 0.0:
		return "%s: —" % label
	if bool(_deficient.get(marker_id, false)):
		return "⚠ %s: Mangel! (%.0f / %.0f)" % [label, supply, need]
	return "%s: %.0f / %.0f" % [label, supply, need]


func refresh_markers() -> void:
	_check_all()
	health_status_changed.emit()


func _check_all(_arg = null) -> void:
	var status_changed := false
	for marker in MARKERS:
		if _update_marker(marker):
			status_changed = true
	if status_changed:
		health_status_changed.emit()


func _update_marker(marker: Dictionary) -> bool:
	var marker_id: String = marker["id"]
	var need := get_need(marker)
	var deficient := need > 0.0 and get_supply(marker) < need
	var was_deficient: bool = bool(_deficient.get(marker_id, false))
	_deficient[marker_id] = deficient
	return deficient != was_deficient
