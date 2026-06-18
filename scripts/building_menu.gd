extends CanvasLayer
## Code-generiertes Bau-Menü mit dynamischer Gebäudeliste.


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")

var _placer: Node2D
var _panel: PanelContainer
var _toggle_btn: Button
var _building_box: VBoxContainer
var _mode_box: VBoxContainer
var _money_label: Label
var _resources_label: Label
var _menu_open: bool = false
var _selected_index: int = 0


func _ready() -> void:
	layer = 10
	_placer = get_node_or_null(building_placer_path) as Node2D
	_build_menu()
	GameState.money_changed.connect(_refresh_hud)
	ProductionManager.resources_changed.connect(_refresh_hud)
	_select_building(0)
	_refresh_hud()
	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(false)


func _build_menu() -> void:
	_money_label = Label.new()
	_money_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_money_label.offset_left = -340
	_money_label.offset_top = 16
	_money_label.offset_right = -16
	_money_label.offset_bottom = 40
	add_child(_money_label)

	_resources_label = Label.new()
	_resources_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_resources_label.offset_left = -340
	_resources_label.offset_top = 44
	_resources_label.offset_right = -16
	_resources_label.offset_bottom = 200
	add_child(_resources_label)

	_toggle_btn = Button.new()
	_toggle_btn.text = "Bauen"
	_toggle_btn.offset_left = 16
	_toggle_btn.offset_top = 16
	_toggle_btn.offset_right = 136
	_toggle_btn.offset_bottom = 52
	_toggle_btn.pressed.connect(_on_toggle_menu)
	add_child(_toggle_btn)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.offset_left = 16
	_panel.offset_top = 60
	_panel.offset_right = 380
	_panel.offset_bottom = 520
	add_child(_panel)

	var margin := MarginContainer.new()
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)

	_building_box = VBoxContainer.new()
	box.add_child(_building_box)

	_mode_box = VBoxContainer.new()
	box.add_child(_mode_box)

	for i in BuildingCatalog.get_count():
		var building: Dictionary = BuildingCatalog.get_building(i)
		var btn := Button.new()
		btn.text = BuildingCatalog.get_button_label(building)
		btn.pressed.connect(_on_building_pressed.bind(i))
		_building_box.add_child(btn)


func _on_toggle_menu() -> void:
	_menu_open = not _menu_open
	_panel.visible = _menu_open
	_toggle_btn.text = "Schließen" if _menu_open else "Bauen"
	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(_menu_open)


func _on_building_pressed(index: int) -> void:
	_select_building(index)


func _select_building(index: int) -> void:
	_selected_index = index
	if _placer and _placer.has_method("select_building"):
		_placer.select_building(index)
	_rebuild_modes()
	_refresh_hud()


func _rebuild_modes() -> void:
	for c in _mode_box.get_children():
		c.queue_free()
	var building: Dictionary = BuildingCatalog.get_building(_selected_index)
	if not BuildingCatalog.has_production_modes(building):
		return
	var entries: Array = building.get("modes", building.get("recipes", []))
	var active: Array = ProductionManager.get_default_modes(_selected_index)
	for entry in entries:
		var check := CheckBox.new()
		var mode_id: String = str(entry.get("id", ""))
		check.text = str(entry.get("label", mode_id))
		check.button_pressed = mode_id in active
		check.toggled.connect(func(on): _toggle_mode(mode_id, on))
		_mode_box.add_child(check)


func _toggle_mode(mode_id: String, enabled: bool) -> void:
	var modes: Array = ProductionManager.get_default_modes(_selected_index)
	if enabled:
		if mode_id not in modes:
			modes.append(mode_id)
	else:
		modes.erase(mode_id)
	ProductionManager.set_default_modes(_selected_index, modes)


func _refresh_hud(_a = null) -> void:
	if _money_label:
		_money_label.text = "Geld: %d €" % GameState.money
	if _resources_label:
		_resources_label.text = "\n".join(ProductionManager.get_summary_lines(12))
