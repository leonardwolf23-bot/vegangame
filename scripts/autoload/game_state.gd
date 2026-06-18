extends Node
## Autoload: Geld und Wohn-Einkommen.


signal money_changed(new_amount: int)
signal income_changed(income_per_second: float)

const STARTING_MONEY: int = 500

var money: int = STARTING_MONEY
var _housing_income: float = 0.0
var _income_accumulator: float = 0.0


func _ready() -> void:
	money = STARTING_MONEY
	money_changed.emit(money)
	income_changed.emit(_housing_income)


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
	income_changed.emit(_housing_income)


func unregister_housing(income: int) -> void:
	if income <= 0:
		return
	_housing_income = maxf(0.0, _housing_income - float(income))
	income_changed.emit(_housing_income)


func get_income_per_second() -> float:
	return _housing_income
