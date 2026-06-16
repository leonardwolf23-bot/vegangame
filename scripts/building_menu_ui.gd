extends CanvasLayer
## Bau-Menü für im Editor gebaute Buttons.
## CanvasLayer-Root → Toggle-Button + Panel mit Gebäude-Buttons.


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")
@export var build_toggle_button: Button
@export var build_panel: Control
@export var button_house: Button
@export var button_fabrik: Button

var _placer: Node2D
var _menu_open: bool = false


func _ready() -> void:
	layer = 10
	_placer = get_node_or_null(building_placer_path) as Node2D
	if not _placer:
		push_error("BuildingMenuUI: BuildingPlacer nicht gefunden: %s" % building_placer_path)

	if build_panel:
		build_panel.visible = false
	if build_toggle_button:
		build_toggle_button.pressed.connect(_on_toggle_menu)
	if button_house:
		button_house.pressed.connect(_on_select.bind(0))
	if button_fabrik:
		button_fabrik.pressed.connect(_on_select.bind(1))

	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(false)


func _on_toggle_menu() -> void:
	if not build_panel:
		return
	_menu_open = not _menu_open
	build_panel.visible = _menu_open
	if build_toggle_button:
		build_toggle_button.text = "Schließen" if _menu_open else "Bauen"
	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(_menu_open)


func _on_select(index: int) -> void:
	if _placer and _placer.has_method("select_building"):
		_placer.select_building(index)
