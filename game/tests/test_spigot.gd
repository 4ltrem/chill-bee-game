extends "res://tests/test_lidstill.gd"

# Quinn: 0.2 item 12 (Spigot Flow), written from game/specs/0.2-first-automation.md before the code.
# Every expected number comes from the config. Spigot Flow is a one-tap shop buy: its real-click test is item 1's (t_shop_buy_button_real_click_twice).


func _spigot_level(n: int) -> void:
	_eco().call("reset")
	_eco().call("set_level", "spigot_flow", n)


## Seconds at which each jar of a two-frame load is bottled, at Spigot Flow level n (real advance() steps, no jar_fly shortcuts).
func _spigot_times(n: int) -> Array:
	_spigot_level(n)
	var c: Object = await _mk_cen()
	var t: Object = await _mk_truck()
	if c == null or t == null:
		return []
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
	var dt: float = 0.02
	var spj: float = float(cv("bottling_seconds_per_jar"))
	for i in int((spj * float(jars) + 2.0) / dt):
		clock[0] += dt
		c.call("advance", dt)
	return times


## Spigot Flow cost at levels 0..max is floor(30 x 1.20^level); the config holds the spec's 30, 1.20 and max 5.
# goal T12.1
func t_spigot_cost_floor_levels() -> void:
	var base: float = float(cv("spigot_flow_base_cost"))
	var growth: float = float(cv("spigot_flow_cost_growth"))
	var max_l: int = int(cv("spigot_flow_max_level"))
	eq(base, 30.0, "config: Spigot Flow base cost is the spec's $30")
	ck(absf(growth - 1.20) < 0.00001, "config: Spigot Flow growth is the spec's 1.20 (%s)" % str(growth))
	eq(max_l, 5, "config: Spigot Flow max level is the spec's 5")
	for n in range(0, max_l + 1):
		_spigot_level(n)
		eq(int(_eco().call("cost", "spigot_flow")), int(floor(base * pow(growth, float(n)) + 0.000001)), "Spigot Flow level %d: cost is floor(30 x 1.20^level)" % n)
	_eco().call("reset")
	_fin()


## Bottling one jar takes bottling_seconds_per_jar x (1 - cut x level): 3.0 s at level 0, 1.8 s (+-0.05) at level 5; jars come at k x that.
# goal T12.1
func t_spigot_bottling_time_by_level() -> void:
	var spj: float = float(cv("bottling_seconds_per_jar"))
	var cut: float = float(cv("spigot_flow_cut_per_level"))
	var max_l: int = int(cv("spigot_flow_max_level"))
	near(spj, 3.0, "config: base bottling time is the spec's 3.0 s", 0.0001)
	near(spj * (1.0 - cut * float(max_l)), 1.8, "config: level 5 leaves 1.8 s", 0.05)
	var dt: float = 0.02
	for n in range(0, max_l + 1):
		var per: float = spj * (1.0 - cut * float(n))
		var times: Array = await _spigot_times(n)
		ck(times.size() >= 2, "Spigot Flow %d: at least two jars bottled (%d)" % [n, times.size()])
		for k in times.size():
			near(float(times[k]), float(k + 1) * per, "Spigot Flow %d: jar %d bottled at k x %.2f s" % [n, k + 1, per], dt * 2.0 + 0.01)
		if n == 0 and times.size() > 0:
			near(float(times[0]), 3.0, "level 0: one jar takes 3.0 s", 0.05)
		if n == max_l and times.size() > 0:
			near(float(times[0]), 1.8, "level 5: one jar takes 1.8 s", 0.05)
	_eco().call("reset")
	_fin()


## The jar's flight time stays jar_fly_seconds at every Spigot Flow level: no jar shows at the spigot before it lands, one does right after.
# goal T12.1
func t_spigot_jar_flight_unchanged() -> void:
	var fly: float = float(cv("jar_fly_seconds"))
	eq(fly, 0.5, "config: jar flight time is 0.5 s (unchanged by item 12)")
	for n in range(0, int(cv("spigot_flow_max_level")) + 1):
		_spigot_level(n)
		var c: Object = await _mk_cen()
		if c == null:
			_fin()
			return
		_to_cranking(c, _cpf() * 2)
		_crank_done(c)
		_begin_bottling(c)
		var dt: float = 0.02
		var t: float = 0.0
		var landed_at: float = -1.0
		for i in int((fly + 0.5) / dt):
			c.call("advance", dt)
			t += dt
			if landed_at < 0.0 and float(c.call("spigot_jar_fraction")) >= 0.0:
				landed_at = t
		ck(landed_at >= 0.0, "Spigot Flow %d: the jar lands at the spigot" % n)
		near(landed_at, fly, "Spigot Flow %d: the jar lands after jar_fly_seconds" % n, dt * 2.0 + 0.01)
	_eco().call("reset")
	_fin()
