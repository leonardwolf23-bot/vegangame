extends CanvasLayer
## Bau-Menü für im Editor gebaute Buttons.
## CanvasLayer-Root → Panel mit Buttons → Buttons im Inspector zuweisen.


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")
@export var button_house: Button
@export var button_fabrik: Button

var _placer: Node2D


func _ready() -> void:
	layer = 10
	_placer = get_node_or_null(building_placer_path) as Node2D
	if not _placer:
		push_error("BuildingMenuUI: BuildingPlacer nicht gefunden: %s" % building_placer_path)

	if button_house:
		button_house.pressed.connect(_on_select.bind(0))
	if button_fabrik:
		button_fabrik.pressed.connect(_on_select.bind(1))


func _on_select(index: int) -> void:
	if _placer and _placer.has_method("select_building"):
		_placer.select_building(index)
