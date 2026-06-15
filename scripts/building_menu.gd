extends CanvasLayer
## Minimales Bau-Menü – zeigt Buttons für alle Gebäude aus BuildingCatalog.
## Als CanvasLayer in die Main-Szene einfügen (z.B. unter "UI").


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")

var _placer: Node2D
var _buttons: Array[Button] = []


func _ready() -> void:
	_placer = get_node_or_null(building_placer_path) as Node2D
	if not _placer:
		push_error("BuildingMenu: BuildingPlacer nicht gefunden unter: %s" % building_placer_path)
	_build_menu()
	_select_button(0)


func _build_menu() -> void:
	# Panel unten links
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Bauen"
	box.add_child(title)

	# Ein Button pro Gebäude aus dem Catalog
	for i in BuildingCatalog.get_count():
		var building: Dictionary = BuildingCatalog.get_building(i)
		var btn := Button.new()
		btn.text = building.get("name", "Gebäude %d" % i)
		btn.custom_minimum_size = Vector2(160, 32)
		btn.pressed.connect(_on_building_pressed.bind(i))
		box.add_child(btn)
		_buttons.append(btn)


func _on_building_pressed(index: int) -> void:
	if _placer and _placer.has_method("select_building"):
		_placer.select_building(index)
	_select_button(index)


func _select_button(index: int) -> void:
	for i in _buttons.size():
		_buttons[i].disabled = (i == index)
