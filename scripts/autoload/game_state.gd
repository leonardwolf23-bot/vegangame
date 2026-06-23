extends Node
## Autoload: Geld, Bevölkerung und Wohn-Einkommen.


signal money_changed(new_amount: int)
signal income_changed(income_per_second: float)
signal population_changed(population: int)

const STARTING_MONEY: int = 500
const PEOPLE_PER_HOUSE: int = 5
const STARTING_POPULATION: int = 0

var money: int = STARTING_MONEY
var population: int = STARTING_POPULATION
var _housing_income: float = 0.0
var _income_accumulator: float = 0.0


func _ready() -> void:
	money = STARTING_MONEY
	population = STARTING_POPULATION
	money_changed.emit(money)
	income_changed.emit(_housing_income)
	population_changed.emit(population)


func _process(delta: float) -> void:
	if _housing_income <= 0.0:
		return
	_income_accumulator += _housing_income * delta
	if _income_accumulator >= 1.0:
		var gain: int = int(_income_accumulator)
		_income_accumulator -= float(gain)
		add_money(gain)


func can_afford(cost: int) -> bool:
	return money >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	money_changed.emit(money)
	return true


func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)


func register_housing(income: int) -> void:
	if income <= 0:
		return
	_housing_income += float(income)
	population += PEOPLE_PER_HOUSE
	income_changed.emit(_housing_income)
	population_changed.emit(population)


func unregister_housing(income: int) -> void:
	if income <= 0:
		return
	_housing_income = maxf(0.0, _housing_income - float(income))
	population = maxi(0, population - PEOPLE_PER_HOUSE)
	income_changed.emit(_housing_income)
	population_changed.emit(population)


func get_income_per_second() -> float:
	return _housing_income
