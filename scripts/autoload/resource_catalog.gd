extends Node
## Autoload: Ressourcen-Namen und Tages-Konstanten.

const SECONDS_PER_DAY: float = 30.0

const UPKEEP_STROM: float = 1.0
const UPKEEP_ESSEN: float = 0.5
const UPKEEP_WASSER: float = 3.0

const BUILDING_MATERIALS: Array[String] = ["holz", "stein"]

const DISPLAY_NAMES: Dictionary = {
	"strom": "Strom (kWh)",
	"essen": "Essen (kg)",
	"wasser": "Wasser (L)",
	"holz": "Holz",
	"stein": "Stein",
	"weizen": "Weizen",
	"sojabohnen": "Sojabohnen",
	"kichererbsen": "Kichererbsen",
	"hafer": "Hafer",
	"kartoffeln": "Kartoffeln",
	"sonnenblumen": "Sonnenblumen",
	"erdnuesse": "Erdnüsse",
	"cashewkerne": "Cashewkerne",
	"avocados": "Avocados",
	"tomaten": "Tomaten",
	"ketchup": "Ketchup",
	"eisbergsalat": "Eisbergsalat",
	"sojamilch": "Sojamilch",
	"hafermilch": "Hafermilch",
	"sojajoghurt": "Sojajoghurt",
	"weizenmehl": "Weizenmehl",
	"kichererbsenmehl": "Kichererbsenmehl",
	"seitanpulver": "Seitanpulver",
	"seitanwuerste": "Seitanwürste",
	"seitansteaks": "Seitansteaks",
	"broetchen": "Brötchen",
	"bretzeln": "Bretzeln",
	"pommes": "Pommes",
	"hummus": "Hummus",
	"guacamole": "Guacamole",
	"kaese": "Väse (Käse)",
	"tofu": "Tofu",
	"raeuchertofu": "Räuchertofu",
	"salat": "Salat",
	"fruehstueck": "Frühstück",
	"streetfood": "Streetfood",
	"sonnenblumenoel": "Sonnenblumenöl",
	"erdnussoel": "Erdnussöl",
}

## Fertige Speisen — werden ans Gasthaus geliefert (Wert = Essens-Einheiten).
const EDIBLE_FOODS: Dictionary = {
	"broetchen": 1.0,
	"bretzeln": 1.0,
	"pommes": 0.8,
	"hummus": 1.0,
	"guacamole": 1.0,
	"salat": 1.2,
	"fruehstueck": 1.5,
	"streetfood": 1.5,
	"seitanwuerste": 1.0,
	"seitansteaks": 1.2,
	"tofu": 0.8,
	"raeuchertofu": 0.9,
	"kaese": 0.8,
	"sojamilch": 0.6,
	"hafermilch": 0.6,
	"sojajoghurt": 0.7,
}


func is_edible(resource_id: String) -> bool:
	return EDIBLE_FOODS.has(resource_id)


func is_building_material(resource_id: String) -> bool:
	return resource_id in BUILDING_MATERIALS


func get_food_value(resource_id: String) -> float:
	return float(EDIBLE_FOODS.get(resource_id, 0.0))


func get_edible_resource_ids() -> Array:
	return EDIBLE_FOODS.keys()


func get_resource_name(resource_id: String) -> String:
	return DISPLAY_NAMES.get(resource_id, resource_id)


func get_start_stock() -> Dictionary:
	return {
		"strom": 200.0,
		"essen": 80.0,
		"wasser": 400.0,
		"holz": 40.0,
		"stein": 40.0,
	}
