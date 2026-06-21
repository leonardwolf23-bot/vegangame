extends Node
## Autoload: Alle Gebäude, Rezepte und Produktionsmodi.


const BUILDINGS: Array[Dictionary] = [
	{
		"id": "house",
		"name": "Haus",
		"kind": "housing",
		"source_id": 0,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 100,
		"income": 5,
	},
	{
		"id": "holzfaeller",
		"name": "Holzfäller",
		"kind": "extractor",
		"source_id": 1,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 120,
		"outputs_per_day": {"holz": 15.0},
		"anim_idle": "idle",
		"anim_working": "working",
		"anim_work_duration": 3.0,
	},
	{
		"id": "steinmetz",
		"name": "Steinmetz",
		"kind": "extractor",
		"source_id": 2,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 120,
		"outputs_per_day": {"stein": 12.0},
	},
	{
		"id": "wasserwerk",
		"name": "Wasserwerk",
		"kind": "extractor",
		"source_id": 3,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 200,
		"skip_water_upkeep": true,
		"outputs_per_day": {"wasser": 500.0},
	},
	{
		"id": "bauernhof",
		"name": "Bauernhof",
		"kind": "multi_extractor",
		"source_id": 4,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 250,
		"modes": [
			{"id": "weizen", "label": "Weizen", "outputs_per_day": {"weizen": 10.0}},
			{"id": "sojabohnen", "label": "Sojabohnen", "outputs_per_day": {"sojabohnen": 10.0}},
			{"id": "kichererbsen", "label": "Kichererbsen", "outputs_per_day": {"kichererbsen": 10.0}},
			{"id": "hafer", "label": "Hafer", "outputs_per_day": {"hafer": 10.0}},
			{"id": "kartoffeln", "label": "Kartoffeln", "outputs_per_day": {"kartoffeln": 10.0}},
		],
		"default_modes": ["weizen"],
	},
	{
		"id": "gewaechshaus",
		"name": "Indoor-Gewächshaus",
		"kind": "multi_extractor",
		"source_id": 5,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 300,
		"modes": [
			{"id": "cashewkerne", "label": "Cashewkerne", "outputs_per_day": {"cashewkerne": 6.0}},
			{"id": "avocados", "label": "Avocados", "outputs_per_day": {"avocados": 6.0}},
			{"id": "tomaten", "label": "Tomaten", "outputs_per_day": {"tomaten": 6.0}},
			{"id": "eisbergsalat", "label": "Eisbergsalat", "outputs_per_day": {"eisbergsalat": 6.0}},
		],
		"default_modes": ["tomaten"],
	},
	{
		"id": "all_pro",
		"name": "All Pro",
		"kind": "processor",
		"source_id": 6,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 350,
		"recipes": [
			{"id": "sojamilch", "label": "Sojamilch", "inputs": {"sojabohnen": 5.0}, "outputs": {"sojamilch": 5.0}},
			{"id": "hafermilch", "label": "Hafermilch", "inputs": {"hafer": 5.0}, "outputs": {"hafermilch": 5.0}},
			{"id": "sojajoghurt", "label": "Sojajoghurt", "inputs": {"sojabohnen": 6.0}, "outputs": {"sojajoghurt": 4.0}},
		],
		"default_modes": ["sojamilch"],
	},
	{
		"id": "muehle",
		"name": "Mühle",
		"kind": "processor",
		"source_id": 7,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 280,
		"recipes": [
			{"id": "weizenmehl", "label": "Weizenmehl", "inputs": {"weizen": 5.0}, "outputs": {"weizenmehl": 5.0}},
			{"id": "kichererbsenmehl", "label": "Kichererbsenmehl", "inputs": {"kichererbsen": 5.0}, "outputs": {"kichererbsenmehl": 5.0}},
		],
		"default_modes": ["weizenmehl"],
	},
	{
		"id": "baeckerei",
		"name": "Bäckerei",
		"kind": "processor",
		"source_id": 8,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 260,
		"recipes": [
			{"id": "broetchen", "label": "Brötchen", "inputs": {"weizenmehl": 3.0}, "outputs": {"broetchen": 5.0}},
			{"id": "bretzeln", "label": "Bretzeln", "inputs": {"weizenmehl": 3.0}, "outputs": {"bretzeln": 4.0}},
		],
		"default_modes": ["broetchen"],
	},
	{
		"id": "seitanmanufaktur",
		"name": "Seitanmanufaktur",
		"kind": "processor",
		"source_id": 9,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 320,
		"recipes": [
			{
				"id": "seitanwuerste",
				"label": "Seitanwürste",
				"inputs": {"seitanpulver": 2.0, "kichererbsenmehl": 2.0},
				"outputs": {"seitanwuerste": 4.0},
			},
			{
				"id": "seitansteaks",
				"label": "Seitansteaks",
				"inputs": {"seitanpulver": 2.0, "kichererbsenmehl": 2.0},
				"outputs": {"seitansteaks": 3.0},
			},
		],
		"default_modes": ["seitanwuerste"],
	},
	{
		"id": "pommesbude",
		"name": "Pommesbude",
		"kind": "processor",
		"source_id": 10,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 300,
		"recipes": [
			{"id": "pommes", "label": "Pommes", "inputs": {"kartoffeln": 4.0}, "outputs": {"pommes": 6.0}},
			{"id": "hummus", "label": "Hummus", "inputs": {"kichererbsen": 3.0, "tomaten": 1.0}, "outputs": {"hummus": 4.0}},
			{"id": "guacamole", "label": "Guacamole", "inputs": {"avocados": 3.0, "tomaten": 1.0}, "outputs": {"guacamole": 4.0}},
		],
		"default_modes": ["pommes"],
	},
	{
		"id": "vaesefabrik",
		"name": "Väsefabrik",
		"kind": "processor",
		"source_id": 11,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 340,
		"recipes": [
			{"id": "kaese", "label": "Väse (Käse)", "inputs": {"cashewkerne": 4.0}, "outputs": {"kaese": 3.0}},
		],
		"default_modes": ["kaese"],
	},
]


func get_building(index: int) -> Dictionary:
	if index < 0 or index >= BUILDINGS.size():
		return {}
	return BUILDINGS[index]


func get_count() -> int:
	return BUILDINGS.size()


func get_cost(building: Dictionary) -> int:
	return int(building.get("cost", 0))


func get_income(building: Dictionary) -> int:
	return int(building.get("income", 0))


func is_housing(building: Dictionary) -> bool:
	return building.get("kind", "") == "housing"


func has_production_modes(building: Dictionary) -> bool:
	var kind: String = building.get("kind", "")
	return kind in ["multi_extractor", "processor"]


func get_daily_upkeep(building: Dictionary) -> Dictionary:
	if bool(building.get("skip_water_upkeep", false)):
		return {
			"strom": ResourceCatalog.UPKEEP_STROM,
			"essen": ResourceCatalog.UPKEEP_ESSEN,
		}
	return {
		"strom": ResourceCatalog.UPKEEP_STROM,
		"essen": ResourceCatalog.UPKEEP_ESSEN,
		"wasser": ResourceCatalog.UPKEEP_WASSER,
	}


func get_mode(building: Dictionary, mode_id: String) -> Dictionary:
	for mode in building.get("modes", []):
		if str(mode.get("id", "")) == mode_id:
			return mode
	return {}


func get_recipe(building: Dictionary, recipe_id: String) -> Dictionary:
	for recipe in building.get("recipes", []):
		if str(recipe.get("id", "")) == recipe_id:
			return recipe
	return {}


func get_footprint(building: Dictionary) -> Vector2i:
	if building.has("footprint"):
		return building["footprint"]
	return building.get("size", Vector2i.ONE)


func get_footprint_offset(building: Dictionary) -> Vector2i:
	return building.get("footprint_offset", Vector2i.ZERO)


func get_footprint_origin(anchor: Vector2i, building: Dictionary) -> Vector2i:
	return anchor + get_footprint_offset(building)


func get_button_label(building: Dictionary) -> String:
	return "%s  |  %d€" % [building.get("name", "Gebäude"), get_cost(building)]


func supports_production_animation(building: Dictionary) -> bool:
	var kind: String = building.get("kind", "")
	return kind in ["extractor", "multi_extractor", "processor"]


func get_sprite_frames(building: Dictionary) -> SpriteFrames:
	return building.get("sprite_frames", null) as SpriteFrames


func get_anim_idle(building: Dictionary) -> StringName:
	return StringName(building.get("anim_idle", "idle"))


func get_anim_working(building: Dictionary) -> StringName:
	return StringName(building.get("anim_working", "working"))


func get_anim_work_duration(building: Dictionary) -> float:
	return float(building.get("anim_work_duration", 3.0))
