extends CanvasLayer
## Autoload: Gesundheits-Marker — unabhängig vom Bau-Menü / Main-Szene-UI.


@export var show_panel: bool = true
@export var anchor_top: float = 44.0

var _label: Label


func _ready() -> void:
	layer = 11
	if not show_panel:
		return
	_build_label()
	PopulationHealth.health_status_changed.connect(_refresh)
	GameState.population_changed.connect(_refresh)
	ProductionManager.resources_changed.connect(_refresh)
	ProductionManager.day_completed.connect(_refresh)
	call_deferred("_refresh")


func _build_label() -> void:
	_label = Label.new()
	_label.name = "HealthMetrics"
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -360
	_label.offset_top = anchor_top
	_label.offset_right = -16
	_label.offset_bottom = anchor_top + 116
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)


func _refresh(_arg = null) -> void:
	if not _label:
		return
	_label.text = "--- Gesundheit ---\n" + "\n".join(PopulationHealth.get_marker_lines())
