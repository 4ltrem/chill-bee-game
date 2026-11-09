# Implements GDD 3 (Progression Trees, Tree A: Worker Swarm Count) and 1 (Primary Game Loop: sell).
# Autoload "Economy": money, Worker Swarm Count level, cost formula. Logic only, no scene needed.
# Jars live in the centrifuge, crate and truck (truck.gd); the truck credits money through earn().
extends Node

signal money_changed(money: int)
signal swarm_level_changed(level: int)

var config: GameConfig = GameConfig.live()
var money: int = 0
var swarm_level: int = 0


## Bees in the swarm: base + per-level * level (Worker Swarm Count adds bees, GDD Tree A).
func bee_count() -> int:
	return config.base_bee_count + config.bees_per_swarm_level * swarm_level


## Multiplier on the hive fill rate: bee_count / base_bee_count (= 1 + 15% per level with the placeholders).
func fill_multiplier() -> float:
	return float(bee_count()) / float(config.base_bee_count)


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


## Credits money (the truck's sale, Dev mode's +$100).
func earn(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)


func reset() -> void:
	money = 0
	swarm_level = 0
	money_changed.emit(money)
	swarm_level_changed.emit(swarm_level)
