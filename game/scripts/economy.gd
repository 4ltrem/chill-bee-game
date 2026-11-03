# Implements GDD 3 (Progression Trees, Tree A: Worker Swarm Count) and 1 (Primary Game Loop: sell).
# Autoload "Economy": money, jars, Worker Swarm Count level, cost formula. Logic only, no scene needed.
extends Node

signal money_changed(money: int)
signal jars_changed(jars: int)
signal swarm_level_changed(level: int)

var config: GameConfig = GameConfig.load_default()
var money: int = 0
var jars: int = 0
var swarm_level: int = 0
## Accessibility (GDD 8): hold the Crank button instead of rapid tapping. Session only (saving is out of scope).
var no_rapid_tap_mode: bool = false


## Multiplier on the hive fill rate: 1 + 15% per level (additive).
func fill_multiplier() -> float:
	return 1.0 + config.swarm_fill_bonus_per_level * float(swarm_level)


## Cost of the next level: base * growth^level, rounded to whole dollars.
## At max level it still returns the formula value; check is_swarm_maxed().
func swarm_cost() -> int:
	return roundi(config.swarm_base_cost * pow(config.swarm_cost_growth, float(swarm_level)))


func is_swarm_maxed() -> bool:
	return swarm_level >= config.swarm_max_level


func can_buy_swarm() -> bool:
	return not is_swarm_maxed() and money >= swarm_cost()


func buy_swarm() -> bool:
	if not can_buy_swarm():
		return false
	money -= swarm_cost()
	swarm_level += 1
	money_changed.emit(money)
	swarm_level_changed.emit(swarm_level)
	return true


func jar_value() -> int:
	return config.sale_value_per_jar


func add_jars(count: int) -> void:
	if count <= 0:
		return
	jars += count
	jars_changed.emit(jars)


## Converts every jar to money. Returns the money earned.
func sell_jars() -> int:
	if jars <= 0:
		return 0
	var earned: int = jars * config.sale_value_per_jar
	jars = 0
	money += earned
	jars_changed.emit(jars)
	money_changed.emit(money)
	return earned


func reset() -> void:
	money = 0
	jars = 0
	swarm_level = 0
	money_changed.emit(money)
	jars_changed.emit(jars)
	swarm_level_changed.emit(swarm_level)
