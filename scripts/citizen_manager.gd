extends Node2D
## Spawnt Bürger und weist Transport-Aufträge zu.


@export var grid_manager_path: NodePath = NodePath("../../GridManager")
@export var citizen_scene: PackedScene = preload("res://scenes/citizen.tscn")
@export var citizen_count: int = 6
@export var job_scan_interval: float = 1.0

var _citizens: Array[Node2D] = []
var _scan_timer: float = 0.0
var _grid: GridManager


func _ready() -> void:
	_grid = get_node_or_null(grid_manager_path) as GridManager
	if not _grid:
		push_warning(
			"CitizenManager: GridManager nicht gefunden unter '%s'. Pfad muss ../../GridManager sein."
			% grid_manager_path
		)
	_spawn_citizens()


func _process(delta: float) -> void:
	_scan_timer += delta
	if _scan_timer >= job_scan_interval:
		_scan_timer = 0.0
		_assign_jobs()


func _spawn_citizens() -> void:
	for i in citizen_count:
		var citizen: Node2D = citizen_scene.instantiate()
		citizen.name = "Citizen_%d" % i
		if _grid:
			citizen.global_position = _grid.tile_to_world(Vector2i(i * 2, 0))
		else:
			citizen.position = Vector2(100 + i * 20, 100)
		add_child(citizen)
		_citizens.append(citizen)


func _assign_jobs() -> void:
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
