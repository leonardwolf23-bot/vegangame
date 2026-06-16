extends Node
## Autoload: Geld, Einkommen, Ersatzmilch-Produktion.


signal money_changed(new_amount: int)
signal income_changed(income_per_second: float)
signal milk_changed(amount: float)

const STARTING_MONEY: int = 500

var money: int = STARTING_MONEY
var milk: float = 0.0

var _income_free: float = 0.0
var _income_needs_milk: float = 0.0
var _milk_production: float = 0.0
var _milk_consumption: float = 0.0
var _income_accumulator: float = 0.0


func _ready() -> void:
	money = STARTING_MONEY
	money_changed.emit(money)
	income_changed.emit(get_effective_income())
	milk_changed.emit(milk)


func _process(delta: float) -> void:
	_update_milk(delta)
	_update_income(delta)


func _update_milk(delta: float) -> void:
	if _milk_production <= 0.0 and _milk_consumption <= 0.0:
		return
	var old_milk: float = milk
	milk = maxf(0.0, milk + (_milk_production - _milk_consumption) * delta)
	if not is_equal_approx(old_milk, milk):
		milk_changed.emit(milk)
		income_changed.emit(get_effective_income())


func _update_income(delta: float) -> void:
	var active_income: float = get_effective_income()
	if active_income <= 0.0:
		return
	_income_accumulator += active_income * delta
	if _income_accumulator >= 1.0:
		var gain: int = int(_income_accumulator)
		_income_accumulator -= float(gain)
		add_money(gain)


func get_effective_income() -> float:
	if _houses_have_milk():
		return _income_free + _income_needs_milk
	return _income_free


func _houses_have_milk() -> bool:
	if _income_needs_milk <= 0.0:
		return true
	if _milk_consumption <= 0.0:
		return true
	return milk > 0.0 or _milk_production >= _milk_consumption


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


func register_building_effects(building: Dictionary) -> void:
	var income: int = BuildingCatalog.get_income(building)
	if income > 0:
		if BuildingCatalog.income_needs_milk(building):
			_income_needs_milk += float(income)
		else:
			_income_free += float(income)
		income_changed.emit(get_effective_income())

	var produce: float = BuildingCatalog.get_produce_milk(building)
	var consume: float = BuildingCatalog.get_consume_milk(building)
	if produce > 0.0:
		_milk_production += produce
	if consume > 0.0:
		_milk_consumption += consume
	if produce > 0.0 or consume > 0.0:
		milk_changed.emit(milk)
		income_changed.emit(get_effective_income())


func unregister_building_effects(data: Dictionary) -> void:
	var income: int = int(data.get("income", 0))
	var needs_milk: bool = bool(data.get("income_needs_milk", false))
	if income > 0:
		if needs_milk:
			_income_needs_milk = maxf(0.0, _income_needs_milk - float(income))
		else:
			_income_free = maxf(0.0, _income_free - float(income))
		income_changed.emit(get_effective_income())

	var produce: float = float(data.get("produce_milk", 0.0))
	var consume: float = float(data.get("consume_milk", 0.0))
	if produce > 0.0:
		_milk_production = maxf(0.0, _milk_production - produce)
	if consume > 0.0:
		_milk_consumption = maxf(0.0, _milk_consumption - consume)
	if produce > 0.0 or consume > 0.0:
		milk_changed.emit(milk)
		income_changed.emit(get_effective_income())


func get_income_per_second() -> float:
	return get_effective_income()


func get_milk_production() -> float:
	return _milk_production


func get_milk_consumption() -> float:
	return _milk_consumption
