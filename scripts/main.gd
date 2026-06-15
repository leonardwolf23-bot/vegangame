extends Node2D
## Haupt-Szene: Verknüpft alle Systeme miteinander.
## Szene-Struktur (in Godot anlegen):
##
##   Main (dieses Skript)
##   ├── Camera2D          → camera_controller.gd
##   ├── GridManager       → grid_manager.gd
##   ├── BuildingPlacer    → building_placer.gd
##   └── World (Node2D)
##       ├── GroundLayer   → TileMapLayer (Boden)
##       └── BuildingLayer → TileMapLayer (Gebäude)


@onready var grid_manager: GridManager = $GridManager
@onready var building_placer: Node2D = $BuildingPlacer


func _ready() -> void:
	# Referenzen zwischen den Systemen verdrahten
	var ground := $World/GroundLayer as TileMapLayer
	var buildings := $World/BuildingLayer as TileMapLayer

	grid_manager.ground_layer = ground
	grid_manager.building_layer = buildings
	building_placer.grid_manager = grid_manager
