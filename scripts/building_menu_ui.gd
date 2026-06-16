extends CanvasLayer
## Bau-Menü + Geld- und Milch-Anzeige.


@export var building_placer_path: NodePath = NodePath("../BuildingPlacer")
@export var build_toggle_button: Button
@export var build_panel: Control
@export var button_house: Button
@export var button_fabrik: Button
@export var money_label: Label
@export var income_label: Label
@export var milk_label: Label

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

	GameState.money_changed.connect(_on_money_changed)
	GameState.income_changed.connect(_on_income_changed)
	GameState.milk_changed.connect(_on_milk_changed)
	_refresh_money_ui()
	_refresh_building_buttons()

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


func _on_money_changed(_new_amount: int) -> void:
	_refresh_money_ui()
	_refresh_building_buttons()


func _on_income_changed(_income: float) -> void:
	_refresh_money_ui()


func _on_milk_changed(_amount: float) -> void:
	_refresh_money_ui()


func _refresh_money_ui() -> void:
	if money_label:
		money_label.text = "Geld: %d €" % GameState.money
	if income_label:
		income_label.text = "Einkommen: +%d €/s" % int(GameState.get_income_per_second())
	if milk_label:
		var net_milk: float = GameState.get_milk_production() - GameState.get_milk_consumption()
		milk_label.text = "Milch: %d  |  +%.0f / -%.0f /s" % [
			int(GameState.milk),
			GameState.get_milk_production(),
			GameState.get_milk_consumption(),
		]
		if net_milk < 0.0 and GameState.milk <= 0.0:
			milk_label.text += "  (Häuser ohne Milch!)"


func _refresh_building_buttons() -> void:
	var buttons: Array[Button] = [button_house, button_fabrik]
	for i in buttons.size():
		var btn: Button = buttons[i]
		if not btn:
			continue
		var building: Dictionary = BuildingCatalog.get_building(i)
		if building.is_empty():
			continue
		btn.text = BuildingCatalog.get_button_label(building)
		btn.disabled = not GameState.can_afford(BuildingCatalog.get_cost(building))
