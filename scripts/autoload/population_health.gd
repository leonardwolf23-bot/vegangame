extends Node
class_name PopulationHealthService
## Autoload: Bevölkerungsgesundheit — Vitamin-D-Mangel erkennen + Warnsound.


signal vitamin_d_deficiency_changed(is_deficient: bool)

const VITAMIN_D_PER_CITIZEN: float = 2.0
const WARNING_COOLDOWN: float = 45.0

@export_file("*.ogg", "*.wav", "*.mp3") var warning_audio_path: String = "res://audio/vitamin_d_mangel.ogg"

const VITAMIN_D_SOURCES: Dictionary = {
	"hafermilch": 1.0,
	"sojamilch": 1.0,
	"sojajoghurt": 0.5,
	"fruehstueck": 2.0,
}

var _deficient: bool = false
var _cooldown: float = 0.0
var _audio: AudioStreamPlayer


func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	add_child(_audio)
	_load_warning_audio()
	ProductionManager.day_completed.connect(_on_day_completed)
	ProductionManager.resources_changed.connect(_on_resources_changed)
	GameState.population_changed.connect(_on_population_changed)
	call_deferred("_check_vitamin_d")


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)


func is_vitamin_d_deficient() -> bool:
	return _deficient


func get_vitamin_d_supply() -> float:
	var total := 0.0
	for resource_id in VITAMIN_D_SOURCES:
		var factor: float = float(VITAMIN_D_SOURCES[resource_id])
		total += ProductionManager.get_total_amount(resource_id) * factor
	return total


func get_vitamin_d_need() -> float:
	return float(GameState.population) * VITAMIN_D_PER_CITIZEN


func get_status_line() -> String:
	var supply := get_vitamin_d_supply()
	var need := get_vitamin_d_need()
	if need <= 0.0:
		return "Vitamin D: —"
	if _deficient:
		return "⚠ Vitamin-D-Mangel! (%.0f / %.0f)" % [supply, need]
	return "Vitamin D: %.0f / %.0f" % [supply, need]


func _load_warning_audio() -> void:
	if warning_audio_path.is_empty() or not ResourceLoader.exists(warning_audio_path):
		push_warning(
			"PopulationHealth: Audiodatei fehlt — lege '%s' ab (OGG/WAV/MP3)."
			% warning_audio_path
		)
		return
	var stream: AudioStream = load(warning_audio_path)
	if stream:
		_audio.stream = stream


func _on_day_completed(_day: int) -> void:
	_check_vitamin_d(true)


func _on_resources_changed() -> void:
	_check_vitamin_d(false)


func _on_population_changed(_population: int) -> void:
	_check_vitamin_d(false)


func _check_vitamin_d(force_audio: bool = false) -> void:
	var need := get_vitamin_d_need()
	var deficient := need > 0.0 and get_vitamin_d_supply() < need

	if deficient and (not _deficient or force_audio or _cooldown <= 0.0):
		_play_warning()

	if deficient != _deficient:
		_deficient = deficient
		vitamin_d_deficiency_changed.emit(_deficient)

	if not deficient:
		_cooldown = 0.0


func _play_warning() -> void:
	if not _audio or not _audio.stream:
		return
	if _audio.playing:
		return
	_audio.play()
	_cooldown = WARNING_COOLDOWN
