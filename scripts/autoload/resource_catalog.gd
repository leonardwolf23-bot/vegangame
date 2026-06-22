extends Node
## Autoload: Ressourcen-Namen und Tages-Konstanten.

const SECONDS_PER_DAY: float = 30.0

const UPKEEP_STROM: float = 1.0
const UPKEEP_ESSEN: float = 0.5
const UPKEEP_WASSER: float = 3.0

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
	"cashewkerne": "Cashewkerne",
	"avocados": "Avocados",
	"tomaten": "Tomaten",
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
}


func get_resource_name(resource_id: String) -> String:
	return DISPLAY_NAMES.get(resource_id, resource_id)


func get_start_stock() -> Dictionary:
	return {
		"strom": 200.0,
		"essen": 80.0,
		"wasser": 400.0,
		"holz": 30.0,
		"stein": 30.0,
	}
