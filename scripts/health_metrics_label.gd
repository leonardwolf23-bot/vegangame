extends Label
## An ein Label in der Main-Szene hängen — zeigt B12, Vitamin D, mentale Gesundheit.


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PopulationHealth.health_status_changed.connect(_refresh)
	GameState.population_changed.connect(_refresh)
	ProductionManager.resources_changed.connect(_refresh)
	ProductionManager.day_completed.connect(_refresh)
	call_deferred("_refresh")


func _refresh(_arg = null) -> void:
	text = "--- Gesundheit ---\n" + "\n".join(PopulationHealth.get_marker_lines())
