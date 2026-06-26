extends CanvasLayer
## Autoload: Interaktion mit Rathaus, Supermarkt und Parks.


var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _action_box: VBoxContainer
var _active_building_index: int = -1


func _ready() -> void:
	layer = 20
	_build_ui()
	hide_panel()


func hide_panel() -> void:
	if _panel:
		_panel.visible = false
	_active_building_index = -1


func open_building(building_index: int) -> void:
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if building.is_empty() or not BuildingCatalog.is_interactive(building):
		return

	_active_building_index = building_index
	_panel.visible = true
	_title_label.text = str(building.get("name", "Gebäude"))
	_body_label.text = str(building.get("description", ""))
	_rebuild_actions(building)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -220
	_panel.offset_top = -180
	_panel.offset_right = 220
	_panel.offset_bottom = 180
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_title_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body_label)

	_action_box = VBoxContainer.new()
	box.add_child(_action_box)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.pressed.connect(hide_panel)
	box.add_child(close_btn)


func _rebuild_actions(building: Dictionary) -> void:
	for child in _action_box.get_children():
		child.queue_free()

	var kind: String = building.get("kind", "")
	match kind:
		"service":
			_add_shop_actions(building)
		"civic":
			_add_rathaus_actions()
		"wellness":
			_add_wellness_actions(building)


func _add_shop_actions(building: Dictionary) -> void:
	for item in BuildingCatalog.get_shop_items(building):
		var item_id: String = str(item.get("id", ""))
		var label: String = str(item.get("label", item_id))
		var cost: int = int(item.get("cost", 0))
		var btn := Button.new()
		btn.text = "%s — %d €" % [label, cost]
		btn.pressed.connect(_on_buy_item.bind(item))
		_action_box.add_child(btn)


func _add_rathaus_actions() -> void:
	var btn := Button.new()
	btn.text = "Buch lesen (+ mentale Auszeit)"
	btn.pressed.connect(_on_read_book)
	_action_box.add_child(btn)


func _add_wellness_actions(building: Dictionary) -> void:
	var info := Label.new()
	var wellness_type: String = str(building.get("wellness_type", ""))
	if wellness_type == "vitamin_d":
		info.text = "Bürger tanken hier Sonne auf — +%.0f Vitamin D pro Park." % PopulationHealth.SUPPLY_PER_FREIZEITPARK
	elif wellness_type == "mental":
		info.text = "Bürger entspannen hier — +%.0f mentale Gesundheit pro Park." % PopulationHealth.SUPPLY_PER_STADTPARK
	else:
		info.text = "Dieser Park stärkt das Wohlbefinden der Stadt."
	_action_box.add_child(info)


func _on_buy_item(item: Dictionary) -> void:
	var cost: int = int(item.get("cost", 0))
	var resource_id: String = str(item.get("id", ""))
	var amount: float = float(item.get("amount", 0.0))
	if resource_id.is_empty() or amount <= 0.0:
		return
	if not GameState.spend(cost):
		return
	ProductionManager.add_resources({resource_id: amount})


func _on_read_book() -> void:
	PopulationHealth.read_book_at_rathaus()
