# Implements GDD 3 (Progression Trees, Tree A: Worker Swarm Count) and 1 (Primary Game Loop: sell).
# Autoload "Economy": money, Worker Swarm Count level, cost formula. Logic only, no scene needed.
# Jars live in the centrifuge, crate and truck (truck.gd); the truck credits money through earn().
extends Node

signal money_changed(money: int)
signal swarm_level_changed(level: int)
signal flight_level_changed(level: int)

var config: GameConfig = GameConfig.live()
var money: int = 0
var swarm_level: int = 0
var flight_level: int = 0
signal phase_changed(phase: int)
var phase: int = 1   # GDD 1; 0.2 item 7: Auto-Sell sets 2 (no gameplay effect in 0.2)


## Bees in the swarm: base + per-level * level (Worker Swarm Count adds bees, GDD Tree A).
func bee_count() -> int:
	return config.base_bee_count + config.bees_per_swarm_level * swarm_level


## Flight Endurance (0.2 item 2): 1 + flight_speed_bonus_per_level * level. Bee speed and, on top of Swarm, the hive fill.
func flight_multiplier() -> float:
	return 1.0 + config.flight_speed_bonus_per_level * float(flight_level)


func is_flight_maxed() -> bool:
	return flight_level >= config.flight_max_level


## Sets the Flight Endurance level (clamped to 0..flight_max_level); the shop's purchase (item 1) calls it after taking the cost.
func set_flight_level(lv: int) -> void:
	set_level("flight", lv)


## Multiplier on the hive fill rate: bee_count / base_bee_count (= 1 + 15% per level with the placeholders), times Flight Endurance.
func fill_multiplier() -> float:
	return float(bee_count()) / float(config.base_bee_count) * flight_multiplier()


## Cost of the next level: base * growth^level, rounded to whole dollars.
## At max level it still returns the formula value; check is_swarm_maxed().
func swarm_cost() -> int:
	return cost("swarm")


func is_swarm_maxed() -> bool:
	return is_maxed("swarm")


func can_buy_swarm() -> bool:
	return can_buy("swarm")


func buy_swarm() -> bool:
	return buy("swarm")


# --- 0.2 item 1: one table of upgrades (id, name, config keys, gate); shop_ui.gd builds one row per entry, in this order ---
const UPGRADE_IDS: Array[String] = ["swarm", "flight", "heated_fork", "gearing", "faster_delivery", "auto_sell"]

signal upgrade_changed(id: String, level: int)

var _levels: Dictionary = {}   # id -> level, for the ids without their own variable (swarm_level and flight_level keep theirs)


## Row title.
func upgrade_name(id: String) -> String:
	match id:
		"swarm": return "Worker Swarm Count"
		"flight": return "Flight Endurance"
		"heated_fork": return "Heated Uncapping Fork"
		"gearing": return "Centrifuge Gearing"
		"faster_delivery": return "Faster Delivery"
		"auto_sell": return "Auto-Sell"
	return id


func level(id: String) -> int:
	match id:
		"swarm": return swarm_level
		"flight": return flight_level
	return int(_levels.get(id, 0))


func max_level(id: String) -> int:
	match id:
		"swarm": return config.swarm_max_level
		"flight": return config.flight_max_level
		"heated_fork": return config.heated_fork_max_level
		"gearing": return config.gearing_max_level
		"faster_delivery": return config.faster_delivery_max_level
		"auto_sell": return 1
	return 0


## True for one-time buys (the row shows "Owned" instead of "Lv x / y").
func is_one_time(id: String) -> bool:
	return max_level(id) == 1


func is_maxed(id: String) -> bool:
	return level(id) >= max_level(id)


## Next cost: base * growth^level. Swarm keeps its rounding (no change in behaviour); the others round down.
func cost(id: String) -> int:
	var lv: float = float(level(id))
	match id:
		"swarm": return floori(config.swarm_base_cost * pow(config.swarm_cost_growth, lv))
		"flight": return floori(config.flight_base_cost * pow(config.flight_cost_growth, lv))
		"heated_fork": return floori(config.heated_fork_base_cost * pow(config.heated_fork_cost_growth, lv))
		"gearing": return floori(config.gearing_base_cost * pow(config.gearing_cost_growth, lv))
		"faster_delivery": return floori(config.faster_delivery_base_cost * pow(config.faster_delivery_cost_growth, lv))
		"auto_sell": return floori(config.auto_sell_cost)
	return 0


## Gate text while locked ("Needs Faster Delivery 1"), else "".
func gate_text(id: String) -> String:
	if id == "auto_sell" and level("faster_delivery") < config.auto_sell_unlock_delivery_level:
		return "Needs Faster Delivery %d" % config.auto_sell_unlock_delivery_level
	return ""


func is_locked(id: String) -> bool:
	return gate_text(id) != ""


func can_buy(id: String) -> bool:
	return not is_maxed(id) and not is_locked(id) and money >= cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	money -= cost(id)
	set_level(id, level(id) + 1)
	money_changed.emit(money)
	return true


## Sets a level directly (clamped to 0..max) and emits the signals; buy() and Dev mode use it.
func set_level(id: String, lv: int) -> void:
	lv = clampi(lv, 0, max_level(id))
	match id:
		"swarm":
			swarm_level = lv
			swarm_level_changed.emit(lv)
		"flight":
			flight_level = lv
			flight_level_changed.emit(lv)
		_:
			_levels[id] = lv
	upgrade_changed.emit(id, lv)
	if id == "auto_sell" and lv >= 1 and phase < 2:
		phase = 2
		phase_changed.emit(phase)


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
	flight_level = 0
	_levels.clear()
	if phase != 1:
		phase = 1
		phase_changed.emit(phase)
	for id in UPGRADE_IDS:
		upgrade_changed.emit(id, 0)
	money_changed.emit(money)
	swarm_level_changed.emit(swarm_level)
	flight_level_changed.emit(flight_level)
