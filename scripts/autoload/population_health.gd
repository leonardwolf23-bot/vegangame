extends Node
class_name PopulationHealthService
## Autoload: Bevölkerungsgesundheit — Mangel erkennen + Warnsounds.


signal health_status_changed

const WARNING_INTERVAL_DAYS: int = 3

@export_file("*.ogg", "*.wav", "*.mp3") var vitamin_d_audio_path: String = "res://audio/vitamin_d_mangel.ogg"
@export_file("*.ogg", "*.wav", "*.mp3") var b12_audio_path: String = "res://audio/b12_mangel.ogg"
@export_file("*.ogg", "*.wav", "*.mp3") var protein_audio_path: String = "res://audio/protein_mangel.ogg"
@export_file("*.ogg", "*.wav", "*.mp3") var food_audio_path: String = "res://audio/essen_mangel.ogg"

const ALERTS: Array[Dictionary] = [
	{
		"id": "vitamin_d",
		"label": "Vitamin D",
		"need_per_citizen": 2.0,
		"sources": {
			"hafermilch": 1.0,
			"sojamilch": 1.0,
			"sojajoghurt": 0.5,
			"fruehstueck": 2.0,
		},
	},
	{
		"id": "b12",
		"label": "Vitamin B12",
		"need_per_citizen": 1.5,
		"sources": {
			"sojamilch": 1.2,
			"hafermilch": 1.0,
			"sojajoghurt": 1.0,
			"fruehstueck": 0.8,
			"tofu": 0.4,
			"raeuchertofu": 0.5,
		},
	},
	{
		"id": "protein",
		"label": "Protein",
		"need_per_citizen": 4.0,
		"sources": {
			"tofu": 1.5,
			"raeuchertofu": 1.8,
			"seitanwuerste": 1.5,
			"seitansteaks": 2.0,
			"hummus": 1.2,
			"kichererbsen": 0.8,
			"sojabohnen": 0.8,
			"broetchen": 0.6,
			"bretzeln": 0.6,
			"streetfood": 1.5,
			"fruehstueck": 1.0,
			"kaese": 1.0,
			"pommes": 0.4,
		},
	},
	{
		"id": "food",
		"label": "Essen",
		"need_per_citizen": 3.0,
		"global_resource": "essen",
		"sources": {
			"broetchen": 1.0,
			"bretzeln": 1.0,
			"pommes": 0.8,
			"hummus": 1.0,
			"guacamole": 1.0,
			"salat": 1.2,
			"fruehstueck": 1.5,
			"streetfood": 1.5,
			"seitanwuerste": 1.0,
			"seitansteaks": 1.2,
			"tofu": 0.8,
			"kaese": 0.8,
		},
	},
]

var _deficient: Dictionary = {}
var _last_warning_day: Dictionary = {}
var _audio_players: Dictionary = {}
var _audio_queue: Array[String] = []
var _active_audio_id: String = ""


func _ready() -> void:
	for alert in ALERTS:
		var alert_id: String = alert["id"]
		_deficient[alert_id] = false
		_last_warning_day[alert_id] = -WARNING_INTERVAL_DAYS
		_setup_audio_player(alert_id)
	ProductionManager.day_completed.connect(_on_day_completed)
	ProductionManager.resources_changed.connect(_on_resources_changed)
	GameState.population_changed.connect(_on_population_changed)
	call_deferred("_check_all")


func is_deficient(alert_id: String) -> bool:
	return bool(_deficient.get(alert_id, false))


func is_vitamin_d_deficient() -> bool:
	return is_deficient("vitamin_d")


func get_supply(alert: Dictionary) -> float:
	var total := 0.0
	if alert.has("global_resource"):
		total += ProductionManager.get_amount(str(alert["global_resource"]))
	for resource_id in alert.get("sources", {}):
		var factor: float = float(alert["sources"][resource_id])
		total += ProductionManager.get_total_amount(resource_id) * factor
	return total


func get_need(alert: Dictionary) -> float:
	return float(GameState.population) * float(alert.get("need_per_citizen", 0.0))


func get_status_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for alert in ALERTS:
		lines.append(_format_status_line(alert))
	return lines


func get_status_line() -> String:
	var lines := get_status_lines()
	if lines.is_empty():
		return ""
	return lines[0]


func _format_status_line(alert: Dictionary) -> String:
	var alert_id: String = alert["id"]
	var label: String = alert["label"]
	var supply := get_supply(alert)
	var need := get_need(alert)
	if need <= 0.0:
		return "%s: —" % label
	if bool(_deficient.get(alert_id, false)):
		return "⚠ %s-Mangel! (%.0f / %.0f)" % [label, supply, need]
	return "%s: %.0f / %.0f" % [label, supply, need]


func _setup_audio_player(alert_id: String) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "AlertAudio_%s" % alert_id
	player.finished.connect(_on_audio_finished)
	add_child(player)
	_audio_players[alert_id] = player
	_load_audio_for(alert_id)


func _audio_path_for(alert_id: String) -> String:
	match alert_id:
		"vitamin_d":
			return vitamin_d_audio_path
		"b12":
			return b12_audio_path
		"protein":
			return protein_audio_path
		"food":
			return food_audio_path
	return ""


func _load_audio_for(alert_id: String) -> void:
	var path := _audio_path_for(alert_id)
	var player: AudioStreamPlayer = _audio_players.get(alert_id)
	if not player:
		return
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("PopulationHealth: Audiodatei fehlt für '%s' — '%s'" % [alert_id, path])
		return
	var stream: AudioStream = load(path)
	if stream:
		player.stream = stream


func _on_day_completed(day: int) -> void:
	_check_all(day)


func _on_resources_changed() -> void:
	_check_all()


func _on_population_changed(_population: int) -> void:
	_check_all()


func _check_all(play_audio_on_day: int = -1) -> void:
	var status_changed := false
	for alert in ALERTS:
		if _update_alert(alert):
			status_changed = true
	if status_changed:
		health_status_changed.emit()
	if play_audio_on_day >= 0:
		_queue_due_audio(play_audio_on_day)


func _update_alert(alert: Dictionary) -> bool:
	var alert_id: String = alert["id"]
	var need := get_need(alert)
	var deficient := need > 0.0 and get_supply(alert) < need
	var was_deficient: bool = bool(_deficient.get(alert_id, false))
	_deficient[alert_id] = deficient
	return deficient != was_deficient


func _queue_due_audio(day: int) -> void:
	if day < 0:
		return
	for alert in ALERTS:
		var alert_id: String = alert["id"]
		if not bool(_deficient.get(alert_id, false)):
			continue
		var last_day: int = int(_last_warning_day.get(alert_id, -WARNING_INTERVAL_DAYS))
		if day - last_day < WARNING_INTERVAL_DAYS:
			continue
		if alert_id in _audio_queue:
			continue
		_audio_queue.append(alert_id)
	_try_play_next_audio(day)


func _try_play_next_audio(day: int) -> void:
	if not _active_audio_id.is_empty():
		return
	if _audio_queue.is_empty():
		return
	var alert_id: String = _audio_queue.pop_front()
	var player: AudioStreamPlayer = _audio_players.get(alert_id)
	if not player or not player.stream:
		_try_play_next_audio(day)
		return
	player.play()
	_active_audio_id = alert_id
	_last_warning_day[alert_id] = day


func _on_audio_finished() -> void:
	_active_audio_id = ""
	if not _audio_queue.is_empty():
		_try_play_next_audio(ProductionManager.day_count)
