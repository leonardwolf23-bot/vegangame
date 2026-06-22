# VeganGame – Isometrischer City Builder

Schlanke Godot-4-Skripte für einen einfachen isometrischen City Builder mit **64×32 Tile-Größe**.

## Projekt-Struktur

```
scripts/
  autoload/
    building_catalog.gd   # Gebäude-Definitionen (Autoload)
  camera_controller.gd    # Kamera: Pan + Zoom
  grid_manager.gd         # Isometrische Koordinaten + Platzierungs-Checks
  building_placer.gd      # Platzieren, Entfernen, Ghost-Vorschau
  building_menu.gd        # Minimales Bau-Menü (UI)
  main.gd                 # Verdrahtet alles in der Main-Szene (optional)
scenes/
  build_menu.tscn         # UI-Szene zum Einfügen
  main.tscn               # Beispiel-Szene (anpassen an dein Projekt)
```

## Einrichtung in deinem bestehenden Godot-Projekt

Falls du schon ein eigenes Projekt hast, kopiere nur den `scripts/`-Ordner und trage den Autoload ein:

1. **Project → Project Settings → Autoload**
2. Pfad: `res://scripts/autoload/building_catalog.gd`
3. Name: `BuildingCatalog`

### Szene-Struktur

```
Main (main.gd)
├── Camera2D          → camera_controller.gd
├── GridManager       → grid_manager.gd
├── BuildingPlacer    → building_placer.gd
└── World (Node2D)
    ├── GroundLayer   → TileMapLayer (Boden)
    └── BuildingLayer → TileMapLayer (Gebäude)
```

Die Node-Namen `World/GroundLayer/BuildingLayer` müssen stimmen, oder du passt die Pfade in `main.gd` an.

### TileSet-Einstellungen

- **Tile Shape:** Isometric
- **Tile Size:** 64 × 32
- Beide TileMapLayer-Nodes brauchen jeweils ein TileSet zugewiesen

### Gebäude anpassen

In `scripts/autoload/building_catalog.gd` die `BUILDINGS`-Liste bearbeiten:

| Feld           | Bedeutung                              |
|----------------|----------------------------------------|
| `name`         | Anzeigename                            |
| `source_id`    | Source-ID im TileSet des Building-Layers |
| `atlas_coords` | Position im Atlas (Vector2i)           |
| `size`         | Fußabdruck in Tiles (z.B. 2×2)         |

## Bau-Menü (UI)

1. In der Main-Szene: **Rechtsklick → Instantiate Child Scene**
2. `scenes/build_menu.tscn` wählen
3. Der UI-Node heißt `UI` und findet den BuildingPlacer automatisch (`../BuildingPlacer`)

Das Menü liest die Gebäude aus `BuildingCatalog` und zeigt Buttons für **House** und **Ersatzmilchfabrik**.

## Steuerung

| Aktion              | Taste / Input        |
|---------------------|----------------------|
| Spieler bewegen     | Linksklick (tilebasiert, außerhalb des Bau-Menüs) |
| Kamera              | Folgt dem Spieler (Mittlere Maustaste = leicht versetzen) |
| Zoom                | Mausrad              |
| Gebäude wählen      | Zifferntasten 1–9    |
| Gebäude platzieren  | Linksklick           |
| Gebäude entfernen   | Rechtsklick          |

## Anpassbare Werte (Inspector)

- **camera_controller.gd:** `pan_speed`, `zoom_min`, `zoom_max`
- **building_placer.gd:** `selected_building_index` (Start-Gebäude)
- **grid_manager.gd:** `ground_layer`, `building_layer` (werden von main.gd gesetzt)
