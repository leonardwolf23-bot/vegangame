extends Node2D
## Haupt-Szene: verbindet GridManager mit den TileMap-Layern.
## An den Root-Node deiner Szene hängen.
##
## Passe die Node-Pfade unten an, wenn deine Nodes anders heißen.


@export_group("TileMap-Pfade")
@export var ground_layer_path: NodePath = NodePath("World/GroundLayer")
@export var building_layer_path: NodePath = NodePath("World/BuildingLayer")
@export var grid_manager_path: NodePath = NodePath("GridManager")
@export var player_path: NodePath = NodePath("World/Player")
@export var camera_path: NodePath = NodePath("Camera2D")


func _ready() -> void:
	var grid_manager := get_node_or_null(grid_manager_path) as GridManager
	if not grid_manager:
		push_error("Main: GridManager nicht gefunden unter: %s" % grid_manager_path)
		return

	var ground := get_node_or_null(ground_layer_path) as TileMapLayer
	var buildings := get_node_or_null(building_layer_path) as TileMapLayer

	if not ground:
		push_error("Main: Ground-Layer nicht gefunden unter: %s" % ground_layer_path)
	if not buildings:
		push_error("Main: Building-Layer nicht gefunden unter: %s" % building_layer_path)

	grid_manager.ground_layer = ground
	grid_manager.building_layer = buildings

	var player := get_node_or_null(player_path) as Node2D
	if player and player.has_method("set_grid_manager"):
		player.set_grid_manager(grid_manager)

	var camera := get_node_or_null(camera_path) as Camera2D
	if camera and camera.has_method("set_follow_target") and player:
		camera.set_follow_target(player)
