extends "res://tests/test_centrifuge.gd"

# Quinn: bottling tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

# Step 5: a hold counts one turn on press, then max_tap_rate/s: (turns - 1) / max_tap_rate seconds, +- one frame.
func t_hold_at_cap() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var dt: float = 1.0 / 60.0
	var expected: float = (float(_turns_for(_bucket_cells())) - 1.0) / float(cv("max_tap_rate"))
	var t: float = _hold_to_done(c, dt, expected * 3.0 + 5.0)
	_ext(c, "hold reached DONE")
	near(t, expected, "hold finish time (turns - 1) / max_tap_rate", dt + 0.002)
	_fin()


func t_hold_ramp_is_visual_only() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_set_cfg("hold_ramp_seconds", float(cv("hold_ramp_seconds")) * 4.0 + 5.0)
	_to_cranking(c)
	var dt: float = 1.0 / 60.0
	var expected: float = (float(_turns_for(_bucket_cells())) - 1.0) / float(cv("max_tap_rate"))
	var t: float = _hold_to_done(c, dt, expected * 3.0 + 5.0)
	near(t, expected, "hold finish time with a long ramp", dt + 0.002)
	_fin()


# Holding is never slower than tapping at exactly max_tap_rate.
func t_hold_never_slower() -> void:
	var rate: float = float(cv("max_tap_rate"))
	var dt: float = 1.0 / 60.0
	var tapper: Object = await _mk_cen()
	var holder: Object = await _mk_cen()
	if tapper == null or holder == null:
		_fin()
		return
	_to_cranking(tapper)
	var cranking: int = _st(tapper, "CRANKING")
	var t_tap: float = 0.0
	var step: float = 1.0 / rate
	while int(tapper.get("state")) == cranking and t_tap < 1000.0:
		tapper.call("tap")
		tapper.call("advance", step)
		t_tap += step
	var tap_finish: float = t_tap - step
	_ext(tapper, "tapped bucket reached DONE")
	_to_cranking(holder)
	var t_hold: float = _hold_to_done(holder, dt, 1000.0)
	ck(t_hold <= tap_finish + dt + 0.002, "held (%.3f s) finishes no later than tapped at max_tap_rate (%.3f s)" % [t_hold, tap_finish])
	_fin()


func t_hold_release_stops() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	c.call("tap")
	c.call("set_holding", true)
	for i in 60:
		c.call("advance", 1.0 / 60.0)
	c.call("set_holding", false)
	var before: Variant = c.get("turns_counted")
	ck(before != null and int(before) > 1, "the hold counted turns before release (turns_counted = %s)" % str(before))
	for i in 600:
		c.call("advance", 1.0 / 60.0)
	eq(c.get("turns_counted"), before, "no turn after release (10 s idle)")
	eq(c.get("state"), _st(c, "CRANKING"), "still CRANKING after release")
	_fin()


# Step 5: taps closer than 1 / max_tap_rate to the last counted turn are ignored.
func t_tap_cap() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var rate: float = float(cv("max_tap_rate"))
	var per_interval: int = 6
	var n: int = int(roundf(rate * per_interval))
	_to_cranking(c)
	var counted: int = _tap_spaced(c, n, 1.0 / (rate * per_interval))
	eq(counted, int(roundf(rate)), "%d taps over 1 s count as max_tap_rate (%s/s)" % [n, str(rate)])
	var c2: Object = await _mk_cen()
	_to_cranking(c2)
	var burst: int = 0
	for i in 20:
		if c2.call("tap"):
			burst += 1
	eq(burst, 1, "20 taps in zero time count 1")
	_fin()


func t_tap_cap_is_live() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var rate: float = float(cv("max_tap_rate"))
	_set_cfg("max_tap_rate", rate * 2.0)
	_to_cranking(c)
	ck(c.call("tap"), "first tap counts")
	c.call("advance", 1.2 / (rate * 2.0))
	ck(c.call("tap"), "a tap after 1.2 / new rate counts (the old cap would have ignored it)")
	_fin()


# Step 6: one jar every bottling_seconds_per_jar; the jars are floor(jars) of the bucket; the lid lifts off afterwards.
func t_bottling_timing() -> void:
	var c: Object = await _mk_cen()
	var t: Object = await _mk_truck()
	if c == null or t == null:
		_fin()
		return
	var cells: int = _bucket_cells()
	var jars: int = int(floorf(_jars_of(cells) + 0.000001))
	var spj: float = float(cv("bottling_seconds_per_jar"))
	_to_cranking(c, cells)
	_crank_done(c)
	_ext(c, "extracted before bottling")
	var times: Array = []
	var clock: Array = [0.0]
	var counts: Array = []
	var done_args: Array = []
	c.connect("jar_bottled", func(n: Variant) -> void:
		times.append(clock[0])
		counts.append(int(n))
		t.call("receive_jar"))
	c.connect("bottling_done", func(j: Variant) -> void: done_args.append(int(j)))
	_begin_bottling(c)
	var dt: float = 0.05
	var steps: int = int((spj * jars + 2.0) / dt)
	for i in steps:
		clock[0] += dt
		c.call("advance", dt)
	eq(times.size(), jars, "one jar_bottled per whole jar")
	for k in times.size():
		near(float(times[k]), (k + 1) * spj, "jar %d bottled at (k x bottling_seconds_per_jar)" % (k + 1), dt * 2.0 + 0.01)
	eq(counts, range(1, jars + 1), "jar_bottled(count) counts 1..n")
	eq(done_args, [jars], "bottling_done(jars) emitted once with floor(jars)")
	eq(c.get("state"), _st(c, "EMPTY"), "centrifuge EMPTY again")
	eq(c.get("lid_open"), true, "the lid lifts off after bottling: the bucket is empty and open")
	eq(c.get("cells"), 0, "no cells left")
	eq(t.get("loaded_jars"), jars, "every jar went to the truck")
	_fin()


func t_bottling_time_is_live() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var spj: float = float(cv("bottling_seconds_per_jar"))
	_to_cranking(c)
	_crank_done(c)
	var times: Array = []
	var clock: Array = [0.0]
	c.connect("jar_bottled", func(_n: Variant) -> void: times.append(clock[0]))
	_begin_bottling(c)
	var dt: float = 0.05
	while times.size() < 1 and clock[0] < spj * 3.0:
		clock[0] += dt
		c.call("advance", dt)
	eq(times.size(), 1, "first jar bottled")
	_set_cfg("bottling_seconds_per_jar", spj * 2.0)
	var t1: float = clock[0]
	while times.size() < 2 and clock[0] < t1 + spj * 6.0:
		clock[0] += dt
		c.call("advance", dt)
	eq(times.size(), 2, "second jar bottled")
	if times.size() == 2:
		near(float(times[1]) - float(times[0]), spj * 2.0, "the next jar takes the edited time", dt * 3.0)
	_fin()


# Done when: "bottling a fractional bucket gives floor(jars) jars and carries the rest" (never lost).
# 36 cells = 2 jars + 2/35. Batch 2 of 34 cells (1.943 jars) plus the carried 2/35 is exactly 2 jars.
func t_bottling_floor_and_leftover_carry() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var n1: int = _cpf() + 1
	_to_cranking(c, n1)
	_crank_done(c)
	var r1: Dictionary = _bottle_out(c)
	eq(r1["done"], [2], "36 cells (2.057 jars) bottle floor = 2 jars")
	eq((r1["bottled"] as Array).size(), 2, "two jar_bottled signals")
	var left: Variant = c.get("leftover_jars")
	ck(left != null, "centrifuge.gd has leftover_jars (spec: Contract)")
	if left != null:
		near(float(left), _jars_of(n1) - 2.0, 1e-6, "the leftover fraction (2/35) is kept in leftover_jars")
	eq(c.get("state"), _st(c, "EMPTY"), "EMPTY after batch 1")
	var n2: int = _cpf() - 1
	_to_cranking(c, n2)
	_crank_done(c)
	var r2: Dictionary = _bottle_out(c)
	eq(r2["done"], [2], "34 cells (1.943 jars) plus the carried 2/35 bottle 2 jars: the leftover was never lost")
	var left2: Variant = c.get("leftover_jars")
	if left2 != null:
		near(float(left2), 0.0, "nothing left after the second batch", 1e-6)
	_fin()


# Float guard (found by reasoning, not by the spec text): 35 cells fed one at a time, each worth 2/35, are exactly 2 jars.
# Summing 2/35 thirty-five times in float can land on 1.9999999999999998; floor() of that would lose a jar and ceil(x * 4)
# could add a turn. The spec says a full frame is 2 jars and turns are ceil(jars x taps_per_jar) = 8.
func t_bottling_35_single_cells_is_2_jars() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	for i in _cpf():
		c.call("add_cells", 1, _cell_value())
	c.call("close_lid")
	c.call("begin_crank")
	var sent: int = _crank_done(c)
	eq(sent, _turns_for(_cpf()), "35 single cells need ceil(2 x taps_per_jar) = 8 turns (float noise must not add one)")
	var r: Dictionary = _bottle_out(c)
	eq(r["done"], [int(cv("frame_jars"))], "35 cells fed one by one bottle frame_jars (2) jars, not 1")
	_fin()


# Contract pile.gd: cells, jars, add(n, jars), take(n) -> jars of those cells.
func t_pile_unit() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Node = _nn(m, "Pile")
	if p == null:
		_fin()
		return
	eq(p.get("cells"), 0, "a new pile is empty")
	near(float(p.get("jars")), 0.0, "no jars", 1e-9)
	p.call("add", 30, _jars_of(30))
	eq(p.get("cells"), 30, "30 cells piled")
	near(float(p.get("jars")), _jars_of(30), 1e-6, "30 cells' jars")
	var got: float = float(p.call("take", 10))
	near(got, _jars_of(10), 1e-6, "take(10) returns 10 cells' jars")
	eq(p.get("cells"), 20, "20 cells left")
	near(float(p.get("jars")), _jars_of(20), 1e-6, "20 cells' jars left")
	var got2: float = float(p.call("take", 20))
	near(got2, _jars_of(20), 1e-6, "take(20) returns the rest")
	eq(p.get("cells"), 0, "pile emptied")
	near(float(p.get("jars")), 0.0, "no jars left", 1e-6)
	_fin()


# ---------------------------------------------------------------- truck (unchanged rules)

# Clarification (designer, 2026-11-04): leftover honey needs no cranking. Turns = ceil(jars of the CELLS in the bucket x taps_per_jar); the carried
# leftover_jars add no turns, but count in the next batch's bottled floor(jars).
func t_leftover_adds_no_turns() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var n1: int = _cpf() + _cpf() / 2   # 52 cells: 2.97 jars, a carry of 0.97 jars (4 turns' worth if it wrongly counted)
	_to_cranking(c, n1)
	_crank_done(c)
	_bottle_out(c)
	var left: float = float(c.get("leftover_jars"))
	ck(left > 0.01, "batch 1 left a fractional carry (%.4f jars)" % left)
	var n2: int = _cpf() - 5   # 30 cells: 1.71 jars, 7 turns by themselves, 11 if the carry counted
	_load_bucket(c, n2)
	c.call("begin_crank")
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < 400:
		c.call("tap")
		c.call("advance", _tap_gap())
		sent += 1
	eq(sent, _turns_for(n2), "batch 2 (30 cells, carry %.3f): ceil(jars of its cells x taps_per_jar) = %d turns, the carry added none" % [left, _turns_for(n2)])
	eq(c.get("turns_counted"), _turns_for(n2), "turns_counted agrees")
	var r2: Dictionary = _bottle_out(c)
	eq(r2["done"], [2], "the carry still counts in the bottled floor(jars): 30 cells + carry = 2.69 jars, floor 2")
	_fin()


## A fake centrifuge stuck in DONE: the "started by itself" predicate must say no.
func t_start_helper_can_fail() -> void:
	var gs := GDScript.new()
	gs.source_code = "extends Node\nvar state: int = 4\n"
	gs.reload()
	var stuck := Node.new()
	stuck.set_script(gs)
	root.add_child(stuck)
	_to_free.append(stuck)
	var started: bool = await _until(func() -> bool: return int(stuck.get("state")) == 5, 0.3)
	ck(not started, "a centrifuge that stays in DONE is not 'started by itself' (the predicate can fail)")
	stuck.set("state", 5)
	ck(await _until(func() -> bool: return int(stuck.get("state")) == 5, 0.3), "and it says yes once the state moves on")
	_fin()


func t_continue_finder_can_fail() -> void:
	var holder := Node.new()
	var b1 := Button.new()
	b1.name = "ContinueButton"
	var b2 := Button.new()
	b2.text = "Continue"
	var b3 := Button.new()
	b3.text = "Sell"
	holder.add_child(b1)
	holder.add_child(b2)
	holder.add_child(b3)
	_to_free.append(holder)
	eq(_continue_nodes(holder).size(), 2, "the finder sees a node named ContinueButton and a button saying Continue, not a Sell button")
	_fin()


# ---------------------------------------------------------------- the zoom, option A (spec change 1)

# Spec 6: after the last crank turn the spin winds down and bottling starts with NO input. The jars are bottled and reach the truck.
func t_bottling_starts_by_itself() -> void:
	_set_cfg("bottling_seconds_per_jar", 0.5)
	_set_cfg("jar_fly_seconds", 0.2)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var tk: Node = _nn(m, "Truck")
	if c == null or tk == null:
		_fin()
		return
	await _frames(3)
	var done_n: Array = [0]
	var bottled: Array = []
	c.connect("extraction_done", func() -> void: done_n[0] += 1)
	c.connect("jar_bottled", func(n: Variant) -> void: bottled.append(int(n)))
	var jars_n: int = int(floorf(_jars_of(_cpf()) + 0.000001))
	_crank_unaided(c)
	eq(done_n[0], 1, "extraction_done was emitted once")
	# from here on: no input of any kind
	var bottling: int = _st(c, "BOTTLING")
	var started: bool = await _until(func() -> bool: return int(c.get("state")) == bottling, 3.0)
	ck(started, "bottling started by itself within 3 s of the last turn (state %d)" % int(c.get("state")))
	var empty: int = _st(c, "EMPTY")
	var finished: bool = await _until(func() -> bool: return int(c.get("state")) == empty, float(cv("bottling_seconds_per_jar")) * float(jars_n + 2) + 4.0)
	ck(finished, "bottling ran to the end with no input")
	eq(bottled.size(), jars_n, "%d jars were bottled one by one" % jars_n)
	eq(int(tk.get("loaded_jars")), jars_n, "the jars reached the truck")
	ck(int(c.get("state")) != _st(c, "DONE"), "the centrifuge is not left waiting in DONE")
	_fin()


# Spec 6: ContinueButton and the DONE wait are removed: no node, no scene entry, no script mentions it, no button says Continue.
func t_no_continue_button() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	eq(_continue_nodes(m).size(), 0, "no ContinueButton node and no button saying Continue in the running scene")
	var sc := FileAccess.open("res://scenes/main.tscn", FileAccess.READ)
	ck(sc != null, "main.tscn readable")
	if sc != null:
		ck(not sc.get_as_text().contains("ContinueButton"), "main.tscn has no ContinueButton entry")
		sc.close()
	for fn in ["main.gd", "farm_ui.gd"]:
		var f := FileAccess.open(_script_path(fn), FileAccess.READ)
		ck(f != null, "%s readable" % fn)
		if f != null:
			var text: String = f.get_as_text()
			f.close()
			ck(not text.contains("ContinueButton"), "%s no longer mentions ContinueButton" % fn)
	_fin()


# ---------------------------------------------------------------- the summary after Sell (spec change 7)
