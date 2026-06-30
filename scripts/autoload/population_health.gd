extends Node
## Autoload: Vitamin B12, Vitamin D, mentale Gesundheit — Marker + Warnsounds.


signal health_status_changed

const WARNING_INTERVAL_DAYS: int = 3

const SUPPLY_PER_FREIZEITPARK: float = 4.0
const SUPPLY_PER_STADTPARK: float = 3.5
const BOOK_MENTAL_WELLNESS: float = 2.5

@export_file("*.ogg", "*.wav", "*.mp3") var b12_audio_path: String = "res://audio/b12_mangel.ogg"
@export_file("*.ogg", "*.wav", "*.mp3") var vitamin_d_audio_path: String = "res://audio/vitamin_d_mangel.ogg"
@export_file("*.ogg", "*.wav", "*.mp3") var mental_audio_path: String = "res://audio/mental_mangel.ogg"

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
var _last_warning_day: Dictionary = {}
var _audio_players: Dictionary = {}
var _audio_queue: Array[String] = []
var _active_audio_id: String = ""
var _grid_manager: GridManager


func _ready() -> void:
	for marker in MARKERS:
		var marker_id: String = marker["id"]
		_deficient[marker_id] = false
		_last_warning_day[marker_id] = -WARNING_INTERVAL_DAYS
		_setup_audio_player(marker_id)

	ProductionManager.day_completed.connect(_on_day_completed)
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
		var count: int = _grid_manager.count_buildings_by_id(str(marker["building_id"]))
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


func _on_day_completed(day: int) -> void:
	_check_all(day)


func _check_all(play_audio_on_day: int = -1) -> void:
	var status_changed := false
	for marker in MARKERS:
		if _update_marker(marker):
			status_changed = true
	if status_changed:
		health_status_changed.emit()
	if play_audio_on_day >= 0:
		_queue_due_audio(play_audio_on_day)


func _update_marker(marker: Dictionary) -> bool:
	var marker_id: String = marker["id"]
	var need := get_need(marker)
	var deficient := need > 0.0 and get_supply(marker) < need
	var was_deficient: bool = bool(_deficient.get(marker_id, false))
	_deficient[marker_id] = deficient
	return deficient != was_deficient


func _setup_audio_player(marker_id: String) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "AlertAudio_%s" % marker_id
	player.finished.connect(_on_audio_finished)
	add_child(player)
	_audio_players[marker_id] = player
	_load_audio_for(marker_id)


func _audio_path_for(marker_id: String) -> String:
	match marker_id:
		"b12":
			return b12_audio_path
		"vitamin_d":
			return vitamin_d_audio_path
		"mental":
			return mental_audio_path
	return ""


func _load_audio_for(marker_id: String) -> void:
	var path := _audio_path_for(marker_id)
	var player: AudioStreamPlayer = _audio_players.get(marker_id)
	if not player:
		return
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("PopulationHealth: Audiodatei fehlt für '%s' — '%s'" % [marker_id, path])
		return
	var stream: AudioStream = load(path)
	if stream:
		player.stream = stream


func _queue_due_audio(day: int) -> void:
	if day < 0:
		return
	for marker in MARKERS:
		var marker_id: String = marker["id"]
		if not bool(_deficient.get(marker_id, false)):
			continue
		var last_day: int = int(_last_warning_day.get(marker_id, -WARNING_INTERVAL_DAYS))
		if day - last_day < WARNING_INTERVAL_DAYS:
			continue
		if marker_id in _audio_queue:
			continue
		_audio_queue.append(marker_id)
	_try_play_next_audio(day)


func _try_play_next_audio(day: int) -> void:
	if not _active_audio_id.is_empty():
		return
	if _audio_queue.is_empty():
		return
	var marker_id: String = _audio_queue.pop_front()
	var player: AudioStreamPlayer = _audio_players.get(marker_id)
	if not player or not player.stream:
		_try_play_next_audio(day)
		return
	player.play()
	_active_audio_id = marker_id
	_last_warning_day[marker_id] = day


func _on_audio_finished() -> void:
	_active_audio_id = ""
	if not _audio_queue.is_empty():
		_try_play_next_audio(ProductionManager.day_count)
