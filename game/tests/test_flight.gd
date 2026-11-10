extends "res://tests/test_shop.gd"

# Quinn: 0.2 item 2 (Flight Endurance), written from game/specs/0.2-first-automation.md (item 2).
# The expected factor is 1 + flight_speed_bonus_per_level x level, read from the config; the hive is timed to full.


## Seconds of game time one fresh hive takes to be full, advanced with the multiplier the economy gives right now.
func _flight_secs_to_full(flight: int) -> float:
	var e: Node = _eco()
	e.call("set_level", "swarm", 0)
	e.call("set_level", "flight", flight)
	var h: Object = await _mk_hive()
	if h == null:
		return -1.0
	var m: float = float(e.call("fill_multiplier"))
	var dt: float = 0.05
	var t: float = 0.0
	var limit: float = _secs_for_jars(_hive_jars()) * 3.0
	while not bool(h.call("is_full")) and t < limit:
		h.call("advance", dt, m)
		t += dt
	return t


## At Flight level 3 and Swarm level 0 the hive fills (1 + bonus x 3) times as fast (+-2%) as at level 0.
# goal T2.1
func t_flight_fill_rate_level3() -> void:
	var lvl: int = 3
	var expect: float = 1.0 + float(cv("flight_speed_bonus_per_level")) * float(lvl)
	ck(lvl <= int(cv("flight_max_level")), "level 3 is within flight_max_level")
	var t0: float = await _flight_secs_to_full(0)
	var t3: float = await _flight_secs_to_full(lvl)
	ck(t0 > 0.0 and t3 > 0.0, "both hives were made and filled (t0 %s, t3 %s)" % [str(t0), str(t3)])
	if t0 > 0.0 and t3 > 0.0:
		var ratio: float = t0 / t3
		near(ratio, expect, "fill is %s x as fast at Flight 3 (t0 %s s, t3 %s s)" % [str(expect), str(t0), str(t3)], expect * 0.02)
	_fin()
