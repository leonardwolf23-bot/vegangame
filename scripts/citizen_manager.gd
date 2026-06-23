extends Node
## Spawnt Bürger passend zur Bevölkerung und weist Transport-Aufträge zu.


@export var grid_manager_path: NodePath = NodePath("../../GridManager")
@export var citizens_parent_path: NodePath = NodePath("..")
@export var citizen_scene: PackedScene = preload("res://scenes/citizen.tscn")
@export var job_scan_interval: float = 1.0

var _citizens: Array[Node2D] = []
var _scan_timer: float = 0.0
var _grid: GridManager
var _citizens_parent: Node2D
var _next_spawn_index: int = 0


func _ready() -> void:
	_grid = get_node_or_null(grid_manager_path) as GridManager
	_citizens_parent = get_node_or_null(citizens_parent_path) as Node2D
	if not _citizens_parent:
		push_warning("CitizenManager: World-Parent nicht gefunden: %s" % citizens_parent_path)
	if not _grid:
		push_warning(
			"CitizenManager: GridManager nicht gefunden unter '%s'. Pfad muss ../../GridManager sein."
			% grid_manager_path
		)
	_startup()


func _startup() -> void:
	# Main.gd verdrahtet TileMap-Layer in _ready — erst danach spawnen.
	await get_tree().process_frame
	if not await _wait_for_grid_layers():
		push_warning("CitizenManager: Grid-Layer nicht bereit, Bürger evtl. falsch platziert.")
	if _grid:
		ProductionManager.bind_grid_manager(_grid)
	if not GameState.population_changed.is_connected(_sync_citizen_count):
		GameState.population_changed.connect(_sync_citizen_count)
	_sync_citizen_count(GameState.population)


func _wait_for_grid_layers(max_frames: int = 30) -> bool:
	if not _grid:
		return false
	for _i in max_frames:
		if _grid.building_layer and _grid.ground_layer:
			return true
		await get_tree().process_frame
	return _grid.building_layer != null


func _process(delta: float) -> void:
	_scan_timer += delta
	if _scan_timer >= job_scan_interval:
		_scan_timer = 0.0
		_assign_jobs()


func _sync_citizen_count(target_count: int) -> void:
	while _citizens.size() < target_count:
		_spawn_one_citizen()
	while _citizens.size() > target_count:
		_remove_one_citizen()
	_assign_jobs()


func _spawn_one_citizen() -> void:
	if not _citizens_parent:
		return
	var citizen: Node2D = citizen_scene.instantiate()
	citizen.name = "Citizen_%d" % _next_spawn_index
	_next_spawn_index += 1
	_citizens_parent.add_child(citizen)
	if citizen.has_method("set_grid_manager") and _grid:
		citizen.set_grid_manager(_grid)
	if _grid and _grid.building_layer:
		var spawn_tile := _pick_spawn_tile(_citizens.size())
		citizen.global_position = _grid.tile_to_walk_world(spawn_tile)
	else:
		citizen.global_position = Vector2(100 + _citizens.size() * 20, 100)
	_citizens.append(citizen)


func _remove_one_citizen() -> void:
	if _citizens.is_empty():
		return
	var victim: Node2D = _citizens[0]
	for citizen in _citizens:
		if citizen.has_method("is_idle") and citizen.is_idle():
			victim = citizen
			break
	if victim.has_method("cancel_active_job"):
		victim.cancel_active_job()
	_citizens.erase(victim)
	victim.queue_free()


func _pick_spawn_tile(index: int) -> Vector2i:
	var candidates: Array[Vector2i] = [
		Vector2i(index * 2, index),
		Vector2i(index, index * 2),
		Vector2i(-index * 2, index),
		Vector2i(index, -index * 2),
		Vector2i.ZERO,
	]
	for tile in candidates:
		if _grid.can_walk_on(tile):
			return tile
	return Vector2i(index * 2, index)


func _assign_jobs() -> void:
	if _grid:
		ProductionManager.refresh_all_world_positions()
	var jobs: Array = ProductionManager.create_transport_jobs()
	if jobs.is_empty():
		return
	var job_index := 0
	for citizen in _citizens:
		if not citizen.has_method("is_idle") or not citizen.is_idle():
			continue
		if job_index >= jobs.size():
			break
		if citizen.has_method("assign_job"):
			citizen.assign_job(jobs[job_index])
			job_index += 1
