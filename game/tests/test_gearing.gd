extends "res://tests/test_fork.gd"

# Quinn: 0.2 item 4 (Centrifuge Gearing), written from game/specs/0.2-first-automation.md before the code.
# Every expected number comes from the config. Gears are found by the names Gear1..Gear6 (node handoff).


func _gearing_level(n: int) -> void:
	_eco().call("reset")
	_eco().call("set_level", "gearing", n)


func _gear(c: Node, i: int) -> Node3D:
	return c.find_child("Gear%d" % i, true, false) as Node3D


## base crank turns for `cells` cells, as a float (the spec multiplies the base, then rounds up)
func _base_turns(cells: int) -> float:
	return float(cells * int(cv("frame_jars")) * int(cv("taps_per_jar"))) / float(_cpf())


func _expect_turns(cells: int, level: int) -> int:
	var mult: float = 1.0 - float(cv("gearing_cut_per_level")) * float(level)
	return maxi(int(ceil(_base_turns(cells) * mult - 0.000001)), 1)


## signed turn about the parent's Y between two bases
func _turn_y(a: Basis, b: Basis) -> float:
	return (b * a.inverse()).get_euler().y


## Gear1..Gear6 visibility at Gearing N (0 to max): exactly Gear1..Gear(N + 1) show; Gear1 at 0.
# goal T4.1
func t_gearing_gears_visible_by_level() -> void:
	var max_l: int = int(cv("gearing_max_level"))
	eq(max_l, 5, "the spec's Gearing max level (config gearing_max_level)")
	for n in range(0, max_l + 1):
		_gearing_level(n)
		var c: Object = await _mk_cen()
		if c == null:
			_fin()
			return
		c.call("_process", 1.0 / 60.0)
		for i in range(1, 7):
			var g: Node3D = _gear(c as Node, i)
			ck(g != null, "Gearing %d: node Gear%d exists" % [n, i])
			if g == null:
				continue
			eq(g.is_visible_in_tree(), i <= n + 1, "Gearing %d: Gear%d is %s" % [n, i, "visible" if i <= n + 1 else "hidden"])
		if n == 0:
			var g1: Node3D = _gear(c as Node, 1)
			ck(g1 != null and g1.is_visible_in_tree(), "Gearing 0: Gear1 is visible (it sits under the crank at every level)")
	_eco().call("reset")
	_fin()


## One crank run at Gearing 5 through the real tap path: every visible gear's rotation changes, neighbours turn opposite ways. Returns
## the signed turn of each visible gear (Gear1..Gear6).
func _gear_run(level: int, clock_late: float = 0.0) -> Array:
	_gearing_level(level)
	var c: Object = await _mk_cen()
	if c == null:
		return []
	_to_cranking(c)
	if clock_late > 0.0:
		c.call("advance", clock_late)   # the clock has passed the first minutes before this crank starts
	var before: Array = []
	for i in range(1, level + 2):
		before.append((_gear(c as Node, i) as Node3D).transform.basis)
	ck(c.call("tap"), "step start: a tap counts a turn at the start of the crank")
	for k in 6:
		c.call("_process", 1.0 / 60.0)
	var turns: Array = []
	for i in range(1, level + 2):
		turns.append(_turn_y(before[i - 1], (_gear(c as Node, i) as Node3D).transform.basis))
	return turns


## While cranking at Gearing max, every visible gear turns and each turns the opposite way to its neighbour; done twice (the second matches).
# goal T4.1
func t_gearing_gears_turn_opposite_twice() -> void:
	var max_l: int = int(cv("gearing_max_level"))
	var first: Array = await _gear_run(max_l)
	# spec 0.3.2 item 4: "A test cranks a second harvest after the clock has passed the first minutes and checks the gears turn"
	var second: Array = await _gear_run(max_l, 600.0)
	eq(first.size(), max_l + 1, "run 1: every visible gear was measured")
	eq(second.size(), max_l + 1, "run 2: every visible gear was measured")
	for run in [first, second]:
		var tag: String = "run %d" % (1 if run == first else 2)
		for i in run.size():
			ck(absf(float(run[i])) > 0.0001, "%s: Gear%d's rotation changes while cranking (%.5f rad)" % [tag, i + 1, float(run[i])])
			if i > 0:
				ck(float(run[i]) * float(run[i - 1]) < 0.0, "%s: Gear%d turns opposite to Gear%d (%.5f vs %.5f)" % [tag, i + 1, i, float(run[i]), float(run[i - 1])])
	for i in mini(first.size(), second.size()):
		ck(float(first[i]) * float(second[i]) > 0.0, "run 2 turns Gear%d the same way as run 1" % (i + 1))
	_eco().call("reset")
	_fin()


## Gearing 0..max: the turns needed are ceil(base x (1 - cut x level)), at least 1; level 2 is ceil(base x 0.70); real taps need exactly that many.
# goal T4.2
func t_gearing_turns_by_level() -> void:
	var cut: float = float(cv("gearing_cut_per_level"))
	ck(absf((1.0 - cut * 2.0) - 0.70) < 0.0001, "config: Gearing 2 leaves 0.70 of the base turns (cut %s per level)" % str(cut))
	var cells: int = _bucket_cells()
	for n in range(0, int(cv("gearing_max_level")) + 1):
		_gearing_level(n)
		var c: Object = await _mk_cen()
		if c == null:
			_fin()
			return
		_load_bucket(c)
		_land_lid(c)   # spec 0.3.2 item 11
		c.call("begin_crank")
		var want: int = _expect_turns(cells, n)
		if n == 2:
			eq(want, maxi(int(ceil(_base_turns(cells) * 0.70 - 0.000001)), 1), "Gearing 2: ceil(base x 0.70)")
		eq(c.call("turns_needed"), want, "Gearing %d: turns needed" % n)
		var counted: Array = [0]
		c.connect("turn_counted", func(_t: Variant) -> void: counted[0] += 1)
		_crank_done(c)
		eq(counted[0], want, "Gearing %d: real taps needed to finish the extraction" % n)
	_eco().call("reset")
	_fin()


## Bottling time is unchanged at every Gearing level: jar k is bottled at k x bottling_seconds_per_jar.
# goal T4.2
func t_gearing_bottling_time_unchanged() -> void:
	var spj: float = float(cv("bottling_seconds_per_jar"))
	for n in range(0, int(cv("gearing_max_level")) + 1):
		_gearing_level(n)
		var c: Object = await _mk_cen()
		var t: Object = await _mk_truck()
		if c == null or t == null:
			_fin()
			return
		var cells: int = _cpf() * 2
		var jars: int = int(floorf(_jars_of(cells) + 0.000001))
		_to_cranking(c, cells)
		_crank_done(c)
		var times: Array = []
		var clock: Array = [0.0]
		c.connect("jar_bottled", func(_k: Variant) -> void:
			times.append(clock[0])
			t.call("receive_jar"))
		_begin_bottling(c)
		var dt: float = 0.05
		for i in int((spj * float(jars) + 2.0) / dt):
			clock[0] += dt
			c.call("advance", dt)
		eq(times.size(), jars, "Gearing %d: one jar_bottled per whole jar" % n)
		for k in times.size():
			near(float(times[k]), float(k + 1) * spj, "Gearing %d: jar %d bottled at k x bottling_seconds_per_jar" % [n, k + 1], dt * 2.0 + 0.01)
	_eco().call("reset")
	_fin()


## With "own motor" on, the hold ramp is cut a further gearing_post_auto_time_cut_per_level per level; with it off there is no such cut.
# goal T4.2
func t_gearing_own_motor_cut() -> void:
	var post: float = float(cv("gearing_post_auto_time_cut_per_level"))
	eq(post, 0.08, "config: the after-automation cut is 8% per level")
	var base: float = float(cv("hold_ramp_seconds"))
	for n in range(1, int(cv("gearing_max_level")) + 1):
		_gearing_level(n)
		var c: Object = await _mk_cen()
		if c == null:
			_fin()
			return
		_set_cfg("dev_own_motor", false)
		var off: float = float(c.call("ramp_seconds"))
		_set_cfg("dev_own_motor", true)
		var on: float = float(c.call("ramp_seconds"))
		ck(off > 0.0 and off < base, "Gearing %d, motor off: the ramp is shorter than the base %s (%.4f)" % [n, str(base), off])
		near(on / off, 1.0 - post * float(n), "Gearing %d: own motor on cuts the ramp a further 8%% x level" % n, 0.0001)
		_load_bucket(c)
		_land_lid(c)   # spec 0.3.2 item 11
		c.call("begin_crank")
		_set_cfg("dev_own_motor", true)
		eq(c.call("turns_needed"), _expect_turns(_bucket_cells(), n), "Gearing %d: the motor cut leaves the turns needed alone (a time cut)" % n)
		_set_cfg("dev_own_motor", false)
	_eco().call("reset")
	_fin()
