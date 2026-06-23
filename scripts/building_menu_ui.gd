extends CanvasLayer
## Dynamisches Bau-Menü + Ressourcen-Anzeige + Produktions-Einstellungen.


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")
@export var build_toggle_button: Button
@export var build_panel: Control
@export var building_list: VBoxContainer
@export var mode_panel: PanelContainer
@export var mode_list: VBoxContainer
@export var money_label: Label
@export var income_label: Label
@export var resources_label: Label

var _placer: Node2D
var _menu_open: bool = false
var _selected_index: int = 0
var _building_buttons: Array[Button] = []
var _mode_checks: Array[CheckBox] = []


func _ready() -> void:
	layer = 10
	_placer = get_node_or_null(building_placer_path) as Node2D
	if not _placer:
		push_error("BuildingMenuUI: BuildingPlacer nicht gefunden: %s" % building_placer_path)

	if build_panel:
		build_panel.visible = false
	if mode_panel:
		mode_panel.visible = false
	if build_toggle_button:
		build_toggle_button.pressed.connect(_on_toggle_menu)

	GameState.money_changed.connect(_refresh_hud)
	GameState.income_changed.connect(_refresh_hud)
	GameState.population_changed.connect(_refresh_hud)
	ProductionManager.resources_changed.connect(_refresh_hud)
	ProductionManager.day_completed.connect(_refresh_hud)

	_build_building_buttons()
	_select_building(0)
	_refresh_hud()

	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(false)


func _build_building_buttons() -> void:
	if not building_list:
		return
	for child in building_list.get_children():
		child.queue_free()
	_building_buttons.clear()

	for i in BuildingCatalog.get_count():
		var building: Dictionary = BuildingCatalog.get_building(i)
		var btn := Button.new()
		btn.text = BuildingCatalog.get_button_label(building)
		btn.custom_minimum_size = Vector2(320, 28)
		btn.pressed.connect(_on_building_pressed.bind(i))
		building_list.add_child(btn)
		_building_buttons.append(btn)


func _on_toggle_menu() -> void:
	if not build_panel:
		return
	_menu_open = not _menu_open
	build_panel.visible = _menu_open
	if build_toggle_button:
		build_toggle_button.text = "Schließen" if _menu_open else "Bauen"
	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(_menu_open)


func _on_building_pressed(index: int) -> void:
	_select_building(index)


func _select_building(index: int) -> void:
	_selected_index = index
	if _placer and _placer.has_method("select_building"):
		_placer.select_building(index)
	_rebuild_mode_panel()
	_refresh_building_buttons()


func _rebuild_mode_panel() -> void:
	if not mode_panel or not mode_list:
		return
	for child in mode_list.get_children():
		child.queue_free()
	_mode_checks.clear()

	var building: Dictionary = BuildingCatalog.get_building(_selected_index)
	if not BuildingCatalog.has_production_modes(building):
		mode_panel.visible = false
		return

	mode_panel.visible = true
	var title := Label.new()
	title.text = "Produktion einstellen (mehrere möglich):"
	mode_list.add_child(title)

	var entries: Array = building.get("modes", building.get("recipes", []))
	var active: Array = ProductionManager.get_default_modes(_selected_index)

	for entry in entries:
		var check := CheckBox.new()
		var mode_id: String = str(entry.get("id", ""))
		check.text = str(entry.get("label", mode_id))
		check.button_pressed = mode_id in active
		check.toggled.connect(_on_mode_toggled.bind(mode_id))
		mode_list.add_child(check)
		_mode_checks.append(check)


func _on_mode_toggled(enabled: bool, mode_id: String) -> void:
	var modes: Array = ProductionManager.get_default_modes(_selected_index)
	if enabled:
		if mode_id not in modes:
			modes.append(mode_id)
	else:
		modes.erase(mode_id)
	ProductionManager.set_default_modes(_selected_index, modes)


func _refresh_hud(_arg = null) -> void:
	if money_label:
		money_label.text = "Geld: %d €" % GameState.money
	if income_label:
		income_label.text = "Wohn-Einkommen: +%d €/s  |  Bevölkerung: %d" % [
			int(GameState.get_income_per_second()),
			GameState.population,
		]
	if resources_label:
		resources_label.text = "\n".join(ProductionManager.get_summary_lines(10))
	_refresh_building_buttons()


func _refresh_building_buttons() -> void:
	for i in _building_buttons.size():
		var building: Dictionary = BuildingCatalog.get_building(i)
		_building_buttons[i].text = BuildingCatalog.get_button_label(building)
		_building_buttons[i].disabled = (i == _selected_index) or not GameState.can_afford(BuildingCatalog.get_cost(building))
