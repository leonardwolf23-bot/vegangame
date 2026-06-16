extends CanvasLayer
## Minimales Bau-Menü – per Button ein-/ausblendbar.
## Als CanvasLayer in die Main-Szene einfügen (z.B. unter "UI").


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")

var _placer: Node2D
var _buttons: Array[Button] = []
var _panel: PanelContainer
var _toggle_btn: Button
var _menu_open: bool = false


func _ready() -> void:
	layer = 10
	_placer = get_node_or_null(building_placer_path) as Node2D
	if not _placer:
		push_error("BuildingMenu: BuildingPlacer nicht gefunden unter: %s" % building_placer_path)
	_build_menu()
	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(false)


func _build_menu() -> void:
	_toggle_btn = Button.new()
	_toggle_btn.text = "Bauen"
	_toggle_btn.custom_minimum_size = Vector2(120, 36)
	_toggle_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_toggle_btn.offset_left = 16
	_toggle_btn.offset_top = 16
	_toggle_btn.offset_right = 136
	_toggle_btn.offset_bottom = 52
	_toggle_btn.pressed.connect(_on_toggle_menu)
	add_child(_toggle_btn)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 16
	_panel.offset_top = 60
	_panel.offset_right = 196
	_panel.offset_bottom = 180
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Gebäude wählen"
	box.add_child(title)

	for i in BuildingCatalog.get_count():
		var building: Dictionary = BuildingCatalog.get_building(i)
		var btn := Button.new()
		btn.text = building.get("name", "Gebäude %d" % i)
		btn.custom_minimum_size = Vector2(160, 32)
		btn.pressed.connect(_on_building_pressed.bind(i))
		box.add_child(btn)
		_buttons.append(btn)


func _on_toggle_menu() -> void:
	_menu_open = not _menu_open
	_panel.visible = _menu_open
	_toggle_btn.text = "Schließen" if _menu_open else "Bauen"
	if _placer and _placer.has_method("set_build_mode"):
		_placer.set_build_mode(_menu_open)
	if _menu_open:
		_select_button(_placer.selected_building_index if _placer else 0)


func _on_building_pressed(index: int) -> void:
	if _placer and _placer.has_method("select_building"):
		_placer.select_building(index)
	_select_button(index)


func _select_button(index: int) -> void:
	for i in _buttons.size():
		_buttons[i].disabled = (i == index)
