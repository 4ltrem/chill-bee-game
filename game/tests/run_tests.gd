# Quinn: Prototype 0 unit tests. Run:
#   Godot --headless --path game --script res://tests/run_tests.gd
# Exit code 0 = all pass, 1 = any failure. One line per test.
extends SceneTree

var _failed: int = 0
var _passed: int = 0
var _cur_ok: bool = true
var _cur_msgs: Array[String] = []
var _counter: int = 0


func _initialize() -> void:
	var eco: Node = root.get_node("Economy")
	var tests: Array[String] = [
		"t_cost_formula", "t_cost_max_level", "t_buy_deducts_and_levels", "t_buy_blocked_unaffordable",
		"t_fill_multiplier", "t_bee_count", "t_fill_multiplier_is_bees_over_base", "t_drawn_count_capped", "t_fill_time_level0", "t_fill_time_with_levels",
		"t_overflow_and_pause", "t_take_frame_not_full", "t_take_frame_with_overflow",
		"t_became_full_count_full_overflow", "t_became_full_once_while_filling",
		"t_cell_transitions", "t_cell_reset_on_next_harvest", "t_uncap_only_from_capped", "t_all_uncapped_signal",
		"t_taps_per_frame", "t_hold_mode", "t_hold_mode_ignores_taps", "t_tap_mode_ignores_hold",
		"t_sell", "t_sell_empty", "t_config_values",
	]
	for t in tests:
		eco.reset()
		eco.no_rapid_tap_mode = false
		_cur_ok = true
		_cur_msgs.clear()
		await call(t, eco)
		if _cur_ok:
			_passed += 1
			print("PASS  ", t)
		else:
			_failed += 1
			print("FAIL  ", t, "  ", "; ".join(_cur_msgs))
	print("---- %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func ck(cond: bool, msg: String) -> void:
	if not cond:
		_cur_ok = false
		_cur_msgs.append(msg)


func eq(actual: Variant, expected: Variant, what: String) -> void:
	if actual != expected:
		_cur_ok = false
		_cur_msgs.append("%s: expected %s got %s" % [what, str(expected), str(actual)])


func near(actual: float, expected: float, what: String, tol: float = 0.001) -> void:
	if absf(actual - expected) > tol:
		_cur_ok = false
		_cur_msgs.append("%s: expected %s got %s" % [what, str(expected), str(actual)])


func _hive() -> Hive:
	var h := Hive.new()
	h.config = GameConfig.load_default()
	return h


func _honeycomb() -> Honeycomb:
	return Honeycomb.new()   # not in tree: logic only (_init allocates cells)


func _centri(jars: int) -> Centrifuge:
	var c := Centrifuge.new()
	c.start(jars)
	return c


func _bump() -> void:
	_counter += 1


# --- economy ---

func t_cost_formula(eco: Node) -> void:
	eq(eco.swarm_cost(), 25, "level 0 cost")
	for lvl in 10:
		eco.swarm_level = lvl
		eq(eco.swarm_cost(), roundi(25.0 * pow(1.18, lvl)), "cost at level %d" % lvl)
	eco.swarm_level = 1
	eq(eco.swarm_cost(), 30, "level 1 cost (29.5 rounds to 30)")


func t_cost_max_level(eco: Node) -> void:
	eco.money = 1000000
	for i in 10:
		ck(eco.buy_swarm(), "buy %d should succeed" % i)
	eq(eco.swarm_level, 10, "level after 10 buys")
	ck(eco.is_swarm_maxed(), "maxed")
	ck(not eco.can_buy_swarm(), "cannot buy at max")
	var m: int = eco.money
	ck(not eco.buy_swarm(), "11th buy refused")
	eq(eco.swarm_level, 10, "level stays 10")
	eq(eco.money, m, "money unchanged on refused buy")


func t_buy_deducts_and_levels(eco: Node) -> void:
	eco.money = 100
	ck(eco.buy_swarm(), "buy ok")
	eq(eco.money, 75, "money after first buy")
	eq(eco.swarm_level, 1, "level 1")
	ck(eco.buy_swarm(), "second buy ok")
	eq(eco.money, 45, "money after second buy ($30)")


func t_buy_blocked_unaffordable(eco: Node) -> void:
	eco.money = 24
	ck(not eco.can_buy_swarm(), "cannot buy with $24")
	ck(not eco.buy_swarm(), "buy refused")
	eq(eco.swarm_level, 0, "level 0")
	eq(eco.money, 24, "money unchanged")


func t_fill_multiplier(eco: Node) -> void:
	near(eco.fill_multiplier(), 1.0, "level 0")
	for lvl in 11:
		eco.swarm_level = lvl
		near(eco.fill_multiplier(), 1.0 + 0.15 * lvl, "level %d" % lvl)
	near(eco.fill_multiplier(), 2.5, "level 10 = 2.5x")


func t_sell(eco: Node) -> void:
	eco.add_jars(10)
	eq(eco.jars, 10, "jars")
	eq(eco.sell_jars(), 30, "earned 10 x $3")
	eq(eco.money, 30, "money")
	eq(eco.jars, 0, "jars cleared")
	eco.add_jars(4)
	eco.sell_jars()
	eq(eco.money, 42, "money accumulates")


func t_sell_empty(eco: Node) -> void:
	eq(eco.sell_jars(), 0, "nothing earned")
	eq(eco.money, 0, "money 0")


func t_config_values(_eco: Node) -> void:
	var c: GameConfig = GameConfig.load_default()
	eq(c.frame_jars, 10, "frame_jars")
	eq(c.overflow_frames, 1, "overflow_frames")
	near(c.swarm_fill_bonus_per_level, 0.15, "bonus")
	near(c.swarm_base_cost, 25.0, "base cost")
	near(c.swarm_cost_growth, 1.18, "growth")
	eq(c.swarm_max_level, 10, "max level")
	near(c.base_seconds_per_jar, 6.0, "sec per jar")
	eq(c.sale_value_per_jar, 3, "sale value")
	eq(c.taps_per_frame, 20, "taps per frame")
	near(c.hold_taps_per_second, 4.0, "hold rate")
	eq(c.grid_cols * c.grid_rows, 35, "7x5 cells")


# --- hive ---

func t_bee_count(eco: Node) -> void:
	eq(eco.bee_count(), 20, "level 0 = 20 bees")
	eco.swarm_level = 1
	eq(eco.bee_count(), 23, "level 1 = 23 bees")
	eco.swarm_level = 10
	eq(eco.bee_count(), 50, "level 10 = 50 bees")
	eco.swarm_level = 0
	eco.money = 100
	eco.buy_swarm()
	eq(eco.bee_count(), 23, "a purchase adds 3 bees")


func t_fill_multiplier_is_bees_over_base(eco: Node) -> void:
	for lvl in 11:
		eco.swarm_level = lvl
		near(eco.fill_multiplier(), float(eco.bee_count()) / 20.0, "multiplier = bees / 20 at level %d" % lvl)
	eco.swarm_level = 1
	near(eco.fill_multiplier(), 1.15, "level 1 = 1.15")


## A lowered visual_bee_cap caps the drawn flock while the counter keeps rising.
func t_drawn_count_capped(eco: Node) -> void:
	var saved: GameConfig = eco.config
	var cfg: GameConfig = GameConfig.load_default().duplicate() as GameConfig
	cfg.visual_bee_cap = 25
	eco.config = cfg
	# Loaded at run time: bees.gd names the Economy autoload, which does not compile before the autoloads exist.
	var b: MultiMeshInstance3D = (load("res://scripts/bees.gd") as GDScript).new()
	ck(b != null, "Bees script instantiates")
	if b == null:
		eco.config = saved
		return
	root.add_child.call_deferred(b)   # root is still setting up its children inside _initialize
	await process_frame
	await process_frame   # _ready builds the MultiMesh and sizes the flock
	eq(b.drawn_count(), 20, "level 0: 20 drawn (under the cap of 25)")
	eq(b.multimesh.instance_count, 20, "level 0: instance_count 20")
	eco.swarm_level = 3   # 29 bees > cap 25
	eco.swarm_level_changed.emit(3)
	eq(eco.bee_count(), 29, "counter keeps rising: 29")
	eq(b.drawn_count(), 25, "drawn capped at 25")
	eq(b.multimesh.instance_count, 25, "instance_count capped at 25")
	eco.swarm_level = 10
	eco.swarm_level_changed.emit(10)
	eq(eco.bee_count(), 50, "counter 50")
	eq(b.drawn_count(), 25, "still 25 drawn at 50 bees")
	root.remove_child(b)
	b.free()
	eco.config = saved


func t_fill_time_level0(_eco: Node) -> void:
	var h := _hive()
	for i in 590:
		h.advance(0.1, 1.0)
	ck(not h.is_full(), "not full at 59 s (storage %s)" % h.storage)
	near(h.storage, 9.833, "storage at 59 s", 0.01)
	for i in 10:
		h.advance(0.1, 1.0)
	ck(h.is_full(), "full at 60 s (storage %s)" % h.storage)
	eq(h.capacity, 10, "capacity")
	h.free()


func t_fill_time_with_levels(_eco: Node) -> void:
	var h := _hive()
	for i in 500:
		h.advance(0.1, 1.15)   # 50 s at level 1; full needs 60/1.15 = 52.2 s
	ck(not h.is_full(), "level 1 not full at 50 s")
	for i in 30:
		h.advance(0.1, 1.15)
	ck(h.is_full(), "level 1 full by 53 s")
	h.free()


func t_overflow_and_pause(_eco: Node) -> void:
	var h := _hive()
	h.advance(60.0, 1.0)
	ck(h.is_full(), "full after 60 s")
	near(h.overflow, 0.0, "overflow starts empty")
	ck(not h.is_paused(), "not paused yet")
	h.advance(30.0, 1.0)
	near(h.overflow, 5.0, "overflow 5 after 30 s more")
	near(h.storage, 10.0, "storage stays 10")
	ck(not h.is_paused(), "not paused at half overflow")
	h.advance(30.0, 1.0)
	near(h.overflow, 10.0, "overflow 10")
	ck(h.is_paused(), "paused when both full")
	h.advance(100.0, 1.0)
	near(h.overflow, 10.0, "overflow capped at 10")
	near(h.storage, 10.0, "storage capped at 10")
	h.free()


func t_take_frame_not_full(_eco: Node) -> void:
	var h := _hive()
	h.advance(30.0, 1.0)
	eq(h.take_frame(), 0, "take_frame when not full")
	near(h.storage, 5.0, "storage untouched")
	h.free()


func t_take_frame_with_overflow(_eco: Node) -> void:
	var h := _hive()
	h.advance(90.0, 1.0)   # full + 5 overflow
	eq(h.take_frame(), 10, "take_frame returns 10")
	near(h.storage, 5.0, "overflow moved into storage")
	near(h.overflow, 0.0, "overflow emptied")
	ck(not h.is_full(), "not full")
	h.advance(60.0, 1.0)
	ck(h.is_full(), "refills")
	h.free()
	var h2 := _hive()
	h2.advance(1000.0, 1.0)
	eq(h2.take_frame(), 10, "take from paused hive")
	near(h2.storage, 10.0, "full overflow refills storage fully")
	near(h2.overflow, 0.0, "overflow 0")
	ck(not h2.is_paused(), "unpaused after take_frame")
	h2.free()


func t_became_full_count_full_overflow(_eco: Node) -> void:
	var h := _hive()
	_counter = 0
	h.became_full.connect(_bump)
	h.advance(60.0, 1.0)
	eq(_counter, 1, "became_full on first fill")
	h.advance(60.0, 1.0)
	eq(_counter, 1, "no repeat while full/overflowing")
	h.take_frame()
	eq(_counter, 2, "became_full emitted exactly once by take_frame with full overflow")
	h.advance(5.0, 1.0)
	eq(_counter, 2, "no extra emit afterwards")
	h.free()


func t_became_full_once_while_filling(_eco: Node) -> void:
	var h := _hive()
	_counter = 0
	h.became_full.connect(_bump)
	for i in 700:
		h.advance(0.1, 1.0)
	eq(_counter, 1, "one emit across fill")
	h.free()


# --- honeycomb ---

func t_cell_transitions(_eco: Node) -> void:
	var hc := _honeycomb()
	eq(hc.cell_count(), 35, "35 cells")
	eq(Honeycomb.CAPPED, 0, "CAPPED = 0")
	eq(Honeycomb.UNCAPPED, 1, "UNCAPPED = 1")
	eq(Honeycomb.EXTRACTED, 2, "EXTRACTED = 2")
	for i in 35:
		eq(hc.get_state(i), 0, "initial state %d" % i)
	ck(not hc.all_uncapped(), "not all uncapped at start")
	ck(hc.uncap_at(3), "uncap 3 returns true")
	eq(hc.get_state(3), 1, "cell 3 uncapped")
	for i in 35:
		hc.uncap_at(i)
	ck(hc.all_uncapped(), "all uncapped")
	for i in 35:
		eq(hc.get_state(i), 1, "state %d" % i)
	hc.extract_all()
	for i in 35:
		eq(hc.get_state(i), 2, "extracted %d" % i)
	hc.free()


func t_cell_reset_on_next_harvest(_eco: Node) -> void:
	var hc := _honeycomb()
	for i in 35:
		hc.uncap_at(i)
	hc.extract_all()
	hc.reset()
	for i in 35:
		eq(hc.get_state(i), 0, "capped after reset %d" % i)
	ck(not hc.all_uncapped(), "not all uncapped after reset")
	for i in 35:
		hc.uncap_at(i)
	ck(hc.all_uncapped(), "second round uncaps")
	hc.free()


func t_uncap_only_from_capped(_eco: Node) -> void:
	var hc := _honeycomb()
	ck(hc.uncap_at(0), "first uncap")
	ck(not hc.uncap_at(0), "second uncap of same cell is no-op")
	ck(not hc.uncap_at(-1), "negative index")
	ck(not hc.uncap_at(35), "out of range")
	hc.extract_all()
	ck(not hc.uncap_at(0), "extracted cell cannot uncap")
	eq(hc.get_state(0), 2, "still extracted")
	hc.free()


func t_all_uncapped_signal(_eco: Node) -> void:
	var hc := _honeycomb()
	_counter = 0
	hc.all_cells_uncapped.connect(_bump)
	for i in 34:
		hc.uncap_at(i)
	eq(_counter, 0, "not emitted at 34")
	hc.uncap_at(34)
	eq(_counter, 1, "emitted once at 35")
	hc.free()


# --- centrifuge ---

func t_taps_per_frame(_eco: Node) -> void:
	var c := _centri(10)
	var done: Array = [0]
	c.batch_done.connect(func(j: int) -> void: done[0] = j)
	for i in 19:
		c.crank()
	eq(c.jars_filled, 9, "9 jars after 19 taps")
	eq(done[0], 0, "not done after 19")
	ck(c.running, "still running")
	c.crank()
	eq(c.jars_filled, 10, "10 jars after 20 taps")
	eq(done[0], 10, "batch_done(10)")
	ck(not c.running, "stopped")
	c.crank()
	eq(c.jars_filled, 10, "extra tap ignored")
	c.free()
	var c2 := _centri(10)
	c2.crank()
	eq(c2.jars_filled, 0, "1 tap = 0 jars")
	c2.crank()
	eq(c2.jars_filled, 1, "2 taps = 1 jar")
	c2.free()


func t_hold_mode(_eco: Node) -> void:
	var c := _centri(10)
	c.hold_mode = true
	var done: Array = [0]
	c.batch_done.connect(func(j: int) -> void: done[0] = j)
	c.set_holding(true)
	var t: float = 0.0
	while c.running and t < 20.0:
		c.advance(1.0 / 60.0)
		t += 1.0 / 60.0
	ck(t > 4.8 and t < 5.2, "hold takes about 5 s, took %.2f s" % t)
	eq(done[0], 10, "batch_done(10)")
	c.free()
	var c2 := _centri(10)
	c2.hold_mode = true
	c2.set_holding(true)
	for i in 60:
		c2.advance(1.0 / 60.0)
	var before: float = c2.taps_done
	c2.set_holding(false)
	for i in 60:
		c2.advance(1.0 / 60.0)
	near(c2.taps_done, before, "no progress while released")
	near(before, 4.0, "1 s of hold = 4 taps", 0.05)
	c2.free()


func t_hold_mode_ignores_taps(_eco: Node) -> void:
	var c := _centri(10)
	c.hold_mode = true
	for i in 30:
		c.crank()
	eq(c.jars_filled, 0, "taps ignored in hold mode")
	c.free()


func t_tap_mode_ignores_hold(_eco: Node) -> void:
	var c := _centri(10)
	c.set_holding(true)
	for i in 120:
		c.advance(1.0 / 60.0)
	eq(c.jars_filled, 0, "holding does nothing in tap mode")
	c.free()
