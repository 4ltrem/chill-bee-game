extends "res://tests/test_delivery.gd"

# Quinn: 0.2 item 6 (Auto-Sell), written from game/specs/0.2-first-automation.md before the code.
# Every expected number comes from the config. Ownership is set through the Economy level of "auto_sell" (the player-facing state).


func _autosell_level(n: int) -> void:
	_eco().call("reset")
	_eco().call("set_level", "faster_delivery", int(cv("auto_sell_unlock_delivery_level")))
	_eco().call("set_level", "auto_sell", n)


func _fill_bed(t: Object, jars: int) -> void:
	for i in jars:
		t.call("receive_jar")


## Run advance() for `seconds` of game time in 0.1 s steps (no Sell press anywhere).
func _idle(t: Object, seconds: float) -> void:
	var left: float = seconds
	while left > 0.0:
		t.call("advance", 0.1)
		left -= 0.1


## Owned: a full bed leaves with no Sell press and the money rises by jars x jar_value.
# goal T6.1
func t_autosell_full_bed_leaves_by_itself() -> void:
	_autosell_level(1)
	var e: Node = _eco()
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var per: int = int(e.call("jar_value"))
	eq(per, int(cv("sale_value_per_jar")), "Economy.jar_value() = config sale_value_per_jar")
	var m0: int = int(e.get("money"))
	_fill_bed(t, cap - 1)
	t.call("advance", 0.1)
	ck(not t.get("away"), "owned, one jar short: the truck waits")
	eq(e.get("money"), m0, "owned, one jar short: no money yet")
	_fill_bed(t, 1)
	t.call("advance", 0.1)
	ck(t.get("away"), "owned, full bed: the truck leaves with no Sell press")
	eq(e.get("money"), m0 + cap * per, "owned, full bed: money rises by jars x jar_value")
	eq(t.get("loaded_jars"), 0, "owned, full bed: the bed is empty after leaving")
	_eco().call("reset")
	_fin()


## Not owned (also: Faster Delivery 1 alone): a full bed waits, however long.
# goal T6.1
func t_autosell_not_owned_full_bed_waits() -> void:
	_autosell_level(0)
	var e: Node = _eco()
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var m0: int = int(e.get("money"))
	_fill_bed(t, cap)
	_idle(t, 5.0)
	ck(not t.get("away"), "not owned: a full bed does not leave by itself")
	eq(t.get("loaded_jars"), cap, "not owned: the full bed keeps its jars")
	eq(e.get("money"), m0, "not owned: no money without a Sell press")
	ck(t.call("can_sell"), "not owned: Sell is available for the full bed")
	_eco().call("reset")
	_fin()


## Owned: a part load does not leave by itself, and Sell still sells it at jars x jar_value (spec: "Sell stays pressable for a part load").
# goal T6.1
func t_autosell_part_load_sells_by_sell() -> void:
	_autosell_level(1)
	var e: Node = _eco()
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var per: int = int(e.call("jar_value"))
	var part: int = maxi(cap - 1, 1)
	var m0: int = int(e.get("money"))
	_fill_bed(t, part)
	_idle(t, 5.0)
	ck(not t.get("away"), "owned, part load: does not leave by itself")
	eq(e.get("money"), m0, "owned, part load: no money without a Sell press")
	ck(t.call("can_sell"), "owned, part load: Sell is pressable")
	var got: Variant = t.call("sell")
	eq(got, part * per, "owned, part load: Sell returns jars x jar_value")
	eq(e.get("money"), m0 + part * per, "owned, part load: money rises by jars x jar_value")
	ck(t.get("away"), "owned, part load: the truck leaves after the Sell press")
	_eco().call("reset")
	_fin()


## Twice: a full bed sells, the truck returns, a second full bed sells the same way (second run matches the first).
# goal T6.1
func t_autosell_twice_matches() -> void:
	_autosell_level(1)
	var e: Node = _eco()
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var per: int = int(e.call("jar_value"))
	var gains: Array = []
	for run in 2:
		var m0: int = int(e.get("money"))
		_idle(t, float(cv("truck_trip_seconds")) * 2.0 + 1.0)   # let any trip finish: the truck is home
		ck(not t.get("away"), "run %d: the truck is home before the bed fills" % (run + 1))
		_fill_bed(t, cap)
		t.call("advance", 0.1)
		ck(t.get("away"), "run %d: the full bed left with no Sell press" % (run + 1))
		gains.append(int(e.get("money")) - m0)
		eq(gains[run], cap * per, "run %d: money rose by jars x jar_value" % (run + 1))
	eq(gains[1], gains[0], "the second run matches the first")
	_eco().call("reset")
	_fin()
