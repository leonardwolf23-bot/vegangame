extends Node
## Autoload: Alle Gebäude, Rezepte und Produktionsmodi.


const BUILD_RESOURCE_COSTS: Dictionary = {"holz": 5, "stein": 5}

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
		"id": "inn",
		"name": "Gasthaus",
		"kind": "inn",
		"description": "Zentrale Essensversorgung — Bürger liefern fertiges Essen aus Bäckerei, Seitanfabrik usw.",
		"source_id": 17,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 280,
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
			{"id": "sonnenblumen", "label": "Sonnenblumen", "outputs_per_day": {"sonnenblumen": 10.0}},
			{"id": "erdnuesse", "label": "Erdnüsse", "outputs_per_day": {"erdnuesse": 8.0}},
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
		"id": "oelmuehle",
		"name": "Ölmühle",
		"kind": "processor",
		"source_id": 18,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 270,
		"recipes": [
			{
				"id": "sonnenblumenoel",
				"label": "Sonnenblumenöl",
				"inputs": {"sonnenblumen": 5.0},
				"outputs": {"sonnenblumenoel": 4.0},
			},
			{
				"id": "erdnussoel",
				"label": "Erdnussöl",
				"inputs": {"erdnuesse": 5.0},
				"outputs": {"erdnussoel": 4.0},
			},
		],
		"default_modes": ["erdnussoel"],
	},
	{
		"id": "ketchupfabrik",
		"name": "Ketchupfabrik",
		"kind": "processor",
		"source_id": 19,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 290,
		"recipes": [
			{"id": "ketchup", "label": "Ketchup", "inputs": {"tomaten": 5.0}, "outputs": {"ketchup": 5.0}},
		],
		"default_modes": ["ketchup"],
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
				"inputs": {"seitanpulver": 3.0},
				"outputs": {"seitanwuerste": 4.0},
			},
			{
				"id": "seitansteaks",
				"label": "Seitansteaks",
				"inputs": {"seitanpulver": 3.0, "kichererbsenmehl": 1.0},
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
			{
				"id": "pommes",
				"label": "Pommes",
				"inputs": {"kartoffeln": 4.0, "erdnussoel": 1.0},
				"outputs": {"pommes": 6.0},
			},
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
	{
		"id": "seitanwerk",
		"name": "Seitanwerk",
		"kind": "processor",
		"source_id": 12,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 300,
		"recipes": [
			{
				"id": "seitanpulver",
				"label": "Seitanpulver",
				"inputs": {"weizen": 4.0, "kichererbsen": 4.0},
				"outputs": {"seitanpulver": 5.0},
			},
		],
		"default_modes": ["seitanpulver"],
	},
	{
		"id": "tofuhaus",
		"name": "Tofuhaus",
		"kind": "processor",
		"source_id": 13,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 280,
		"recipes": [
			{"id": "tofu", "label": "Tofu", "inputs": {"sojabohnen": 6.0}, "outputs": {"tofu": 5.0}},
			{
				"id": "raeuchertofu",
				"label": "Räuchertofu",
				"inputs": {"sojabohnen": 8.0, "hafer": 2.0},
				"outputs": {"raeuchertofu": 4.0},
			},
		],
		"default_modes": ["tofu"],
	},
	{
		"id": "salatbar",
		"name": "Salatbar",
		"kind": "processor",
		"source_id": 14,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 240,
		"recipes": [
			{
				"id": "salat",
				"label": "Großer Salat",
				"inputs": {"eisbergsalat": 3.0, "tomaten": 2.0},
				"outputs": {"salat": 6.0},
			},
			{
				"id": "salat_mit_avocado",
				"label": "Salat mit Avocado",
				"inputs": {"eisbergsalat": 2.0, "avocados": 2.0, "tomaten": 1.0},
				"outputs": {"salat": 5.0},
			},
		],
		"default_modes": ["salat"],
	},
	{
		"id": "cafe",
		"name": "Café",
		"kind": "processor",
		"source_id": 15,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 260,
		"recipes": [
			{
				"id": "fruehstueck",
				"label": "Frühstück",
				"inputs": {"hafermilch": 3.0, "broetchen": 2.0},
				"outputs": {"fruehstueck": 4.0},
			},
			{
				"id": "soja_cappuccino",
				"label": "Soja-Cappuccino",
				"inputs": {"sojamilch": 4.0, "hafer": 1.0},
				"outputs": {"fruehstueck": 3.0},
			},
		],
		"default_modes": ["fruehstueck"],
	},
	{
		"id": "streetfood",
		"name": "Streetfood-Stand",
		"kind": "processor",
		"source_id": 16,
		"atlas_coords": Vector2i(0, 0),
		"size": Vector2i(1, 1),
		"footprint": Vector2i(3, 3),
		"footprint_offset": Vector2i(-1, -2),
		"cost": 320,
		"recipes": [
			{
				"id": "tofu_burger",
				"label": "Tofu-Burger",
				"inputs": {"tofu": 2.0, "broetchen": 1.0, "eisbergsalat": 1.0},
				"outputs": {"streetfood": 4.0},
			},
			{
				"id": "seitan_wrap",
				"label": "Seitan-Wrap",
				"inputs": {"seitanwuerste": 2.0, "tomaten": 1.0, "eisbergsalat": 1.0},
				"outputs": {"streetfood": 3.0},
			},
		],
		"default_modes": ["tofu_burger"],
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


func get_resource_costs(building: Dictionary) -> Dictionary:
	if building.has("resource_costs"):
		return building["resource_costs"].duplicate()
	return BUILD_RESOURCE_COSTS.duplicate()


func can_afford(building: Dictionary) -> bool:
	if not GameState.can_afford(get_cost(building)):
		return false
	return ProductionManager.has_resources(get_resource_costs(building))


func spend_build_cost(building: Dictionary) -> bool:
	if not can_afford(building):
		return false
	var money_cost := get_cost(building)
	if not GameState.spend(money_cost):
		return false
	if not ProductionManager.spend_resources(get_resource_costs(building)):
		GameState.add_money(money_cost)
		return false
	return true


func get_income(building: Dictionary) -> int:
	return int(building.get("income", 0))


func get_description(building: Dictionary) -> String:
	return str(building.get("description", ""))


func is_housing(building: Dictionary) -> bool:
	return building.get("kind", "") == "housing"


func is_inn(building: Dictionary) -> bool:
	return building.get("kind", "") == "inn"


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
	var extras: PackedStringArray = []
	var money := get_cost(building)
	if money > 0:
		extras.append("%d€" % money)
	var resources := get_resource_costs(building)
	if float(resources.get("holz", 0.0)) > 0.0:
		extras.append("%d Holz" % int(resources["holz"]))
	if float(resources.get("stein", 0.0)) > 0.0:
		extras.append("%d Stein" % int(resources["stein"]))
	if extras.is_empty():
		return str(building.get("name", "Gebäude"))
	return "%s  |  %s" % [building.get("name", "Gebäude"), " · ".join(extras)]
