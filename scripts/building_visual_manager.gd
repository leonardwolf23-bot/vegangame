extends Node
## Spawnt animierte Gebäude-Overlays und triggert working bei Produktion.


const VISUAL_SCENE: PackedScene = preload("res://scenes/buildings/building_visual.tscn")

var _visuals: Dictionary = {}


func _ready() -> void:
	ProductionManager.building_produced.connect(_on_building_produced)


func spawn(anchor: Vector2i, building_index: int, world_pos: Vector2) -> void:
	var building: Dictionary = BuildingCatalog.get_building(building_index)
	if not BuildingCatalog.supports_production_animation(building):
		return

	remove(anchor)

	var visual: Node2D = VISUAL_SCENE.instantiate()
	add_child(visual)
	if visual.has_method("setup"):
		visual.setup(anchor, building, world_pos)
	_visuals[_anchor_key(anchor)] = visual


func remove(anchor: Vector2i) -> void:
	var key := _anchor_key(anchor)
	if not _visuals.has(key):
		return
	var visual: Node = _visuals[key]
	_visuals.erase(key)
	if is_instance_valid(visual):
		visual.queue_free()


func _on_building_produced(anchor: Vector2i) -> void:
	var visual: Node = _visuals.get(_anchor_key(anchor))
	if is_instance_valid(visual) and visual.has_method("play_production"):
		visual.play_production()


func _anchor_key(anchor: Vector2i) -> String:
	return "%d,%d" % [anchor.x, anchor.y]
