extends Node
## Autoload: Geld, Einkommen, Kosten.
## Project Settings → Autoload → GameState

signal money_changed(new_amount: int)
signal income_changed(income_per_second: float)

const STARTING_MONEY: int = 500

var money: int = STARTING_MONEY
var _income_per_second: float = 0.0
var _income_accumulator: float = 0.0


func _ready() -> void:
	money = STARTING_MONEY
	money_changed.emit(money)
	income_changed.emit(_income_per_second)


func _process(delta: float) -> void:
	if _income_per_second <= 0.0:
		return
	_income_accumulator += _income_per_second * delta
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


func add_building_income(income: int) -> void:
	if income <= 0:
		return
	_income_per_second += float(income)
	income_changed.emit(_income_per_second)


func remove_building_income(income: int) -> void:
	if income <= 0:
		return
	_income_per_second = maxf(0.0, _income_per_second - float(income))
	income_changed.emit(_income_per_second)


func get_income_per_second() -> float:
	return _income_per_second
