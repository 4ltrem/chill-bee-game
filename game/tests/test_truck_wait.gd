extends "res://tests/test_spigot.gd"

# Quinn: 0.2 item 13 (no jar flies after a leaving truck), written from game/specs/0.2-first-automation.md before the code.
# Every expected number comes from the config. Flights take jar_fly_seconds (raised here so the test can act inside one).


## Hook `departed` to note the game time and how many jars the bed shows at that moment (every jar must have landed by then).
func _watch_departure(t: Object) -> Dictionary:
	var rec: Dictionary = {"at": -1, "shown": -1, "count": 0}
	t.connect("departed", func() -> void:
		rec["at"] = _gms()
		rec["shown"] = _bed_count(t as Node)
		rec["count"] = int(rec["count"]) + 1)
	return rec


## Sell press with a jar in flight to the bed: the truck stays home until that jar lands, then departs.
# goal T13.1
func t_truck_sell_waits_for_jar_in_flight() -> void:
	_set_cfg("jar_fly_seconds", 1.5)
	_eco().call("reset")
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var fly: float = float(cv("jar_fly_seconds"))
	var rec: Dictionary = _watch_departure(t)
	_bed_last_jar_in_flight(t, cap)
	ck(t.call("can_sell"), "full bed counted with the last jar still in the air: Sell is available")
	var t_sell: int = _gms()
	t.call("sell")
	t.call("advance", 0.05)
	ck(not t.get("away"), "Sell pressed with a jar in flight: the truck is still home")
	eq(int(rec["count"]), 0, "Sell pressed with a jar in flight: departed not emitted yet")
	await _wait(fly * 0.4)
	t.call("advance", 0.05)
	ck(not t.get("away"), "40 % into the flight: the truck is still home")
	ck(await _advance_until(t, func() -> bool: return t.get("away"), fly + 3.0), "the truck departs after the jar landed")
	eq(int(rec["count"]), 1, "departed emitted once")
	ck(float(int(rec["at"]) - t_sell) / 1000.0 >= fly * 0.8, "the departure is not before the jar's flight ends (%.2f s after Sell, flight %.2f s)" % [float(int(rec["at"]) - t_sell) / 1000.0, fly])
	eq(int(rec["shown"]), cap, "at departure the bed showed every jar landed in its slot")
	_eco().call("reset")
	_fin()


## Auto-Sell owned, a full bed whose last jar is still flying: it leaves only once that jar has landed.
# goal T13.1
func t_truck_autosell_waits_for_jar_in_flight() -> void:
	_set_cfg("jar_fly_seconds", 1.5)
	_eco().call("reset")
	_eco().call("set_level", "faster_delivery", int(cv("auto_sell_unlock_delivery_level")))
	_eco().call("set_level", "auto_sell", 1)
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var fly: float = float(cv("jar_fly_seconds"))
	var rec: Dictionary = _watch_departure(t)
	_bed_last_jar_in_flight(t, cap)
	var t0: int = _gms()
	t.call("advance", 0.05)
	ck(not t.get("away"), "Auto-Sell, full bed, last jar in the air: the truck is still home")
	await _wait(fly * 0.4)
	t.call("advance", 0.05)
	ck(not t.get("away"), "Auto-Sell, 40 % into the flight: the truck is still home")
	ck(await _advance_until(t, func() -> bool: return t.get("away"), fly + 3.0), "Auto-Sell: the truck departs after the jar landed")
	eq(int(rec["count"]), 1, "Auto-Sell: departed emitted once")
	ck(float(int(rec["at"]) - t0) / 1000.0 >= fly * 0.8, "Auto-Sell: the departure is not before the jar's flight ends")
	eq(int(rec["shown"]), cap, "Auto-Sell: at departure the bed showed every jar landed")
	_eco().call("reset")
	_fin()


## A jar bottled after the truck has left flies to the crate: no jar's flight ends at a bed slot after `departed`.
# goal T13.1
func t_truck_jar_after_departure_goes_to_crate() -> void:
	_set_cfg("jar_fly_seconds", 1.0)
	_set_cfg("truck_trip_seconds", 120.0)
	_eco().call("reset")
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var fly: float = float(cv("jar_fly_seconds"))
	for i in cap:
		t.call("receive_jar")
	t.call("sell")
	t.call("advance", 0.05)
	ck(t.get("away"), "no jar in flight: Sell sends the truck off at once")
	t.call("receive_jar", (t as Node3D).global_position + Vector3(0.0, 2.0, 0.0), 0.0, null)
	eq(int(t.get("crate_jars")), 1, "a jar bottled after departure is counted in the crate")
	eq(int(t.get("loaded_jars")), 0, "a jar bottled after departure is not counted on the truck")
	await _wait(fly + 0.6)
	t.call("advance", 0.05)
	eq(_bed_count(t as Node), 0, "no jar's flight ended at a bed slot after departed")
	eq(int(t.get("crate_jars")), 1, "the jar stayed in the crate after landing")
	ck(t.get("away"), "the truck is still away")
	_eco().call("reset")
	_fin()


## Twice, start to finish: bed filled with a jar in flight, Sell, wait, depart, trip, home; the second run matches the first.
# goal T13.1
func t_truck_sell_with_jar_in_flight_twice_matches() -> void:
	_set_cfg("jar_fly_seconds", 1.2)
	_eco().call("reset")
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var fly: float = float(cv("jar_fly_seconds"))
	var per: int = int(_eco().call("jar_value"))
	var waits: Array = []
	var gains: Array = []
	for run in 2:
		ck(await _advance_until(t, func() -> bool: return not t.get("away"), float(t.call("trip_seconds")) * 2.0 + 2.0), "run %d: the truck is home" % (run + 1))
		var rec: Dictionary = _watch_departure(t)
		var m0: int = int(_eco().get("money"))
		_bed_last_jar_in_flight(t, cap)
		var t_sell: int = _gms()
		t.call("sell")
		ck(not t.get("away"), "run %d: Sell with a jar in flight leaves the truck home" % (run + 1))
		ck(await _advance_until(t, func() -> bool: return t.get("away"), fly + 3.0), "run %d: the truck departs" % (run + 1))
		eq(int(rec["count"]), 1, "run %d: departed emitted once" % (run + 1))
		eq(int(rec["shown"]), cap, "run %d: every jar had landed at departure" % (run + 1))
		waits.append(float(int(rec["at"]) - t_sell) / 1000.0)
		gains.append(int(_eco().get("money")) - m0)
		eq(gains[run], cap * per, "run %d: money rose by jars x jar_value" % (run + 1))
		eq(int(t.get("loaded_jars")), 0, "run %d: the bed is empty after leaving" % (run + 1))
	near(float(waits[1]), float(waits[0]), "the second run waited as long as the first", 0.4)
	eq(gains[1], gains[0], "the second run paid the same as the first")
	_eco().call("reset")
	_fin()
