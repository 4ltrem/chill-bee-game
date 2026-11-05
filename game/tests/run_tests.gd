# Quinn: milestone 0.1 (Harvest) unit and scene tests, written from game/specs/0.1-harvest.md (approved 2026-11-04)
# BEFORE the code exists, on top of the revision 3 suite (tests whose rule is unchanged are kept).
#   Godot --headless --path game --script res://tests/run_tests.gd
# Exit code 0 only if every test passed AND the final "RAN n of n" line printed with n == the number of tests.
# If that line is missing the run is a FAILURE (a compile error in this file or a hang prints nothing).
#
# Rules this file follows:
#  * Every number comes from the live config (_cfg()), never a literal, so Dev mode or default_config.tres edits
#    cannot break a test. The one exception is t_config_values, which checks the Values table on purpose, against
#    res://scripts/default_config.tres (not user://dev_config.tres).
#  * Nothing outside the spec's Contract table is called directly: it goes through has_method / call / get so a
#    rename fails ONE test with a clear message and the file still parses.
#  * The hive, centrifuge, pile and truck under test are the nodes of an instance of res://scenes/main.tscn (the spec
#    moves the models into scenes, so a bare script .new() has no body to build). Each test makes its own instance and
#    frees it.
#  * Expected jar counts are computed from INTEGER cell counts as one division (cells * frame_jars / cells_per_frame),
#    never by summing floats: the code under test must get 2 jars out of 35 cells of 2/35 each.
#  * Input tests push events into the viewport in window pixels (tests/farm_input.gd), as a real mouse sends them.
#  * Silent-PASS guards: every test must reach its final _fin() line and make at least one check, else it FAILS;
#    a harness self-check proves eq() can fail; the run ends with "RAN n of n".
#  * CB_SCRIPTS=res://tests/broken/ (env var) points _make() at a broken copy of the scripts folder; scene tests need a
#    broken copy of the project instead (main.tscn names its scripts by path), see the report.
# Spec line numbers in the comments are not used: comments name the spec section ("Done when", "The loop step n").
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")

var fi: RefCounted
var _failed: int = 0
var _passed: int = 0
var _cur_ok: bool = true
var _cur_msgs: Array[String] = []
var _checks: int = 0
var _finished: bool = false
var _counter: int = 0
var _to_free: Array = []
var _cfg_saved: Dictionary = {}
var _setting_saved: Variant = null
var _setting_touched: bool = false
var _user_cfg_backup: PackedByteArray = PackedByteArray()
var _user_cfg_existed: bool = false

const USER_CFG := "user://dev_config.tres"
const DEFAULT_CFG := "res://scripts/default_config.tres"
const DEV_SETTING := "chill_bee/dev_mode"


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame   # root has finished setting up its children; add_child is safe from here
	fi = FarmInput.new(self)
	var tests: Array[String] = [
		# economy (unchanged)
		"t_cost_formula", "t_cost_max_level", "t_buy_deducts_and_levels", "t_buy_blocked_unaffordable",
		"t_fill_multiplier", "t_bee_count", "t_fill_multiplier_is_bees_over_base", "t_economy_removed_jars",
		"t_earn_and_jar_value", "t_drawn_count_capped",
		# contract and config (new values, retired values, retired scene)
		"t_node_contract", "t_config_values", "t_config_placeholders_marked", "t_retired_api_gone",
		# hive: fill by frames and slots, risen frame, overflow of one hive, scrape
		"t_fill_time_level0", "t_fill_time_with_levels", "t_hive_rate_is_live", "t_fill_in_order_slot_by_slot",
		"t_risen_frame_never_fills", "t_overflow_one_hive_then_pause", "t_became_full_once_while_filling",
		"t_became_full_count_full_overflow", "t_scrape_value", "t_scrape_rules", "t_next_frame_to_harvest",
		# centrifuge: bucket, lid, turns, floor bottling
		"t_bucket_capacity_and_states", "t_lid_close_and_signal", "t_turns_per_jar", "t_crank_enabled_flag",
		"t_hold_at_cap", "t_hold_ramp_is_visual_only", "t_hold_never_slower", "t_hold_release_stops",
		"t_tap_cap", "t_tap_cap_is_live", "t_crank_ignored_outside_cranking", "t_real_mouse_taps_crank",
		"t_real_touch_taps_crank", "t_button_press_is_not_a_crank",
		"t_bottling_timing", "t_bottling_time_is_live", "t_bottling_floor_and_leftover_carry", "t_leftover_adds_no_turns",
		"t_bottling_35_single_cells_is_2_jars", "t_pile_unit",
		# truck (unchanged) and the wheels
		"t_truck_full_and_can_sell", "t_truck_sell_credits_at_once", "t_truck_crate_while_away",
		"t_truck_return_loads_crate", "t_truck_trip_time_is_live", "t_truck_wheels_roll_with_travel",
		# the zoom, through real input
		"t_zoom_ui_and_camera", "t_zoom_bucket_lid_pile_flow", "t_back_after_one_frame", "t_back_keeps_half_frame",
		"t_fork_rules", "t_fork_shows_while_cranking_and_state_table", "t_no_crank_during_zoom",
		"t_zoom_fill_and_bottling_keep_running",
		"t_scrape_then_back_in_pop_window_bucket", "t_scrape_then_back_in_pop_window_pile", "t_resume_pending_pile_loads_while_zoom_open",
		"t_pop_tween_unchanged", "t_focus_styles",
		# floating icons (unchanged) and icon sizes
		"t_icon_follows_anchor", "t_icon_hidden_behind_camera", "t_icon_touch_area_in_scene",
		# dev mode
		"t_dev_mode_setting", "t_dev_no_panel_when_off",
		"t_dev_panel_when_on", "t_dev_max_tap_rate", "t_dev_bottling_seconds", "t_dev_save_reset_roundtrip",
		"t_dev_user_file_ignored_when_off", "t_dev_backquote_opens", "t_dev_three_finger_opens", "t_dev_actions",
		"t_dev_show_ui_bounds",
	]
	var only: String = OS.get_environment("CB_ONLY")   # a comma list of test names: run just those (the broken-copy runs use it); empty = all
	if only != "":
		var keep: Array[String] = []
		for t in tests:
			if (",%s," % only).contains(",%s," % t):
				keep.append(t)
		tests = keep
		print("CB_ONLY: running ", tests.size(), " test(s): ", tests)
	_selfcheck()
	_backup_user_cfg()
	# the equivalent of the Dev panel's "Reset to defaults": a stale user://dev_config.tres (backed up above, and removed) must not skew the run
	print("Dev config: a user://dev_config.tres was ", "FOUND (backed up, removed for the run, restored at the end)" if _user_cfg_existed else "not present", "; the live config is reset to default_config.tres")
	FarmInput.reset_dev_config()
	var ran: int = 0
	for t in tests:
		_eco_reset()
		_cur_ok = true
		_cur_msgs.clear()
		_checks = 0
		_finished = false
		await call(t)
		if not _finished:
			_cur_ok = false
			_cur_msgs.append("test stopped before its final line (script error or missing method; see the engine error above)")
		if _checks == 0:
			_cur_ok = false
			_cur_msgs.append("test made no checks")
		_cleanup()
		ran += 1
		if _cur_ok:
			_passed += 1
			print("PASS  ", t, "  (", _checks, " checks)")
		else:
			_failed += 1
			print("FAIL  ", t, "  ", " | ".join(_cur_msgs))
	_restore_user_cfg()
	print("---- %d passed, %d failed" % [_passed, _failed])
	print("RAN %d of %d" % [ran, tests.size()])
	quit(1 if (_failed > 0 or ran != tests.size()) else 0)


# ---------------------------------------------------------------- harness

func ck(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_cur_ok = false
		_cur_msgs.append(msg)


func eq(actual: Variant, expected: Variant, what: String) -> void:
	_checks += 1
	if actual != expected:
		_cur_ok = false
		_cur_msgs.append("%s: expected %s got %s" % [what, str(expected), str(actual)])


## near(actual, expected, what, tol) or near(actual, expected, tol, what): both argument orders are accepted.
func near(actual: float, expected: float, a3: Variant, a4: Variant = 0.001) -> void:
	var what: String = str(a3) if a3 is String else str(a4)
	var tol: float = float(a4) if a3 is String else float(a3)
	_checks += 1
	if absf(actual - expected) > tol:
		_cur_ok = false
		_cur_msgs.append("%s: expected %s (+-%s) got %s" % [what, str(expected), str(tol), str(actual)])


func _fin() -> void:
	_finished = true


## The harness must be able to fail: eq(1, 2) has to flip the flag, or every PASS above is meaningless.
func _selfcheck() -> void:
	_cur_ok = true
	_cur_msgs.clear()
	eq(1, 2, "selfcheck")
	near(1.0, 2.0, "selfcheck near")
	ck(false, "selfcheck ck")
	var worked: bool = (not _cur_ok) and _cur_msgs.size() == 3
	_cur_ok = true
	_cur_msgs.clear()
	_checks = 0
	if not worked:
		print("FAIL  harness self-check: eq/near/ck did not register a failure")
		quit(1)


func _cleanup() -> void:
	for n in _to_free:
		if is_instance_valid(n):
			if n is Node and (n as Node).is_inside_tree():
				(n as Node).get_parent().remove_child(n)
			n.free()
	_to_free.clear()
	var cfg: Variant = _cfg()
	for k in _cfg_saved:
		if cfg != null:
			cfg.set(k, _cfg_saved[k])
	_cfg_saved.clear()
	if _setting_touched:
		ProjectSettings.set_setting(DEV_SETTING, _setting_saved)
		_setting_touched = false
	Engine.time_scale = 1.0
	if FileAccess.file_exists(USER_CFG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(USER_CFG))


func _backup_user_cfg() -> void:
	_user_cfg_existed = FileAccess.file_exists(USER_CFG)
	if _user_cfg_existed:
		_user_cfg_backup = FileAccess.get_file_as_bytes(USER_CFG)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(USER_CFG))


func _restore_user_cfg() -> void:
	if FileAccess.file_exists(USER_CFG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(USER_CFG))
	if _user_cfg_existed:
		var f := FileAccess.open(USER_CFG, FileAccess.WRITE)
		f.store_buffer(_user_cfg_backup)
		f.close()


func _eco() -> Node:
	return root.get_node_or_null("Economy")


func _eco_reset() -> void:
	var e: Node = _eco()
	if e == null:
		return
	if e.has_method("reset"):
		e.call("reset")
	else:
		e.set("money", 0)
		e.set("swarm_level", 0)


## The live config. The spec never says where scripts get it; Economy.config is where revision 2 kept it.
func _cfg() -> Variant:
	var e: Node = _eco()
	if e != null and e.get("config") != null:
		return e.get("config")
	return null


## Read one config value; a missing name fails the test with its name instead of aborting.
func cv(name: String) -> Variant:
	var c: Variant = _cfg()
	if c == null:
		ck(false, "no live config found (Economy.config is null)")
		return 0
	var v: Variant = c.get(name)
	if v == null:
		ck(false, "config has no value named '%s' (spec Values table)" % name)
		return 0
	return v


func _set_cfg(name: String, value: Variant) -> void:
	var c: Variant = _cfg()
	if c == null:
		ck(false, "no live config to set '%s'" % name)
		return
	if not _cfg_saved.has(name):
		_cfg_saved[name] = c.get(name)
	c.set(name, value)


func _script_path(file: String) -> String:
	var base: String = OS.get_environment("CB_SCRIPTS")
	if base == "":
		base = "res://scripts/"
	return base + file


## Load and instantiate one of Patricia's scripts, asserting each step (no silent PASS on a compile error).
func _make(file: String) -> Object:
	var path: String = _script_path(file)
	var s: Variant = load(path)
	ck(s != null, "%s failed to load (compile error?)" % path)
	if s == null:
		return null
	ck((s as GDScript).can_instantiate(), "%s cannot instantiate (compile error?)" % path)
	if not (s as GDScript).can_instantiate():
		return null
	var o: Object = (s as GDScript).new()
	ck(o != null, "%s.new() returned null" % path)
	if o != null:
		ck(o.get_script() == s, "%s: instance does not carry the script" % path)
		_to_free.append(o)
	return o


func _give_config(o: Object) -> void:
	var c: Variant = _cfg()
	if c != null and "config" in o:
		o.set("config", c)


## Enum member by name, wherever the enum lives in the script (the spec names the states but not the enum).
func _st(o: Object, state_name: String) -> int:
	var map: Dictionary = (o.get_script() as GDScript).get_script_constant_map()
	for k in map:
		var v: Variant = map[k]
		if v is Dictionary and (v as Dictionary).has(state_name):
			return int((v as Dictionary)[state_name])
	ck(false, "no enum member %s in %s (spec: states EMPTY, LOADING, FULL, CRANKING, DONE, BOTTLING)" % [state_name, o.get_script().resource_path])
	return -999


func _add_root(n: Node) -> void:
	n.set_process(false)
	n.set_physics_process(false)
	root.add_child(n)
	n.set_process(false)
	n.set_physics_process(false)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Poll until cond.call() is true or timeout (s).
func _until(cond: Callable, timeout: float) -> bool:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < timeout * 1000.0:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _bump() -> void:
	_counter += 1


func _to_window() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func _push_mouse(vp_pos: Vector2, pressed: bool) -> void:
	fi.mouse_button(vp_pos, pressed)


## An empty point of the screen: no Control there, so the press reaches _unhandled_input like a real tap.
const EMPTY_SPOT := Vector2(360.0, 640.0)


## Mouse press and release at a spot, through the real viewport input path.
func _real_click(pos: Vector2) -> void:
	_push_mouse(pos, true)
	_push_mouse(pos, false)


# ---------------------------------------------------------------- config-derived numbers (integers first, one division)

func _cpf() -> int:
	return int(cv("grid_cols")) * int(cv("grid_rows"))


func _frames_n() -> int:
	return int(cv("frames_per_hive"))


## cell value in jars: frame_jars / cells_per_frame (2 / 35 at the defaults)
func _cell_value() -> float:
	return float(int(cv("frame_jars"))) / float(_cpf())


## jars in n cells as ONE division from integers
func _jars_of(cells: int) -> float:
	return float(cells * int(cv("frame_jars"))) / float(_cpf())


## hive capacity in jars (5 frames x 2 jars = 10)
func _hive_jars() -> float:
	return float(_frames_n() * int(cv("frame_jars")))


## the bucket's capacity in cells: centrifuge_capacity_frames x cells_per_frame (70)
func _bucket_cells() -> int:
	return int(cv("centrifuge_capacity_frames")) * _cpf()


## crank turns for n cells: ceil(jars x taps_per_jar), done in integers so float noise cannot move it
@warning_ignore("integer_division")
func _turns_for(cells: int) -> int:
	var num: int = cells * int(cv("frame_jars")) * int(cv("taps_per_jar"))
	var den: int = _cpf()
	return (num + den - 1) / den


func _tap_gap() -> float:
	return 1.0 / float(cv("max_tap_rate")) + 0.01


# ---------------------------------------------------------------- scene-backed parts

func _mk_main(quiet: bool = false) -> Node:
	var ps: Variant = load("res://scenes/main.tscn")
	ck(ps != null, "res://scenes/main.tscn failed to load")
	if ps == null:
		return null
	var m: Node = (ps as PackedScene).instantiate()
	ck(m != null, "main.tscn failed to instantiate")
	if m == null:
		return null
	if quiet:
		m.process_mode = Node.PROCESS_MODE_DISABLED   # nothing ticks: the hive does not fill behind the test's back
	root.add_child(m)
	_to_free.append(m)
	await _frames(5)
	return m


func _nn(m: Node, name: String) -> Node:
	var n: Node = m.find_child(name, true, false)
	ck(n != null, "node '%s' missing in the scene (spec: Node paths for Bob)" % name)
	return n


func _shown(n: Node) -> bool:
	return n != null and (n as CanvasItem).is_visible_in_tree()


## Stop a main instance's own ticking so the test drives advance() itself (input handlers keep working).
func _quiet(m: Node) -> void:
	m.set_process(false)
	for nm in ["Hive", "Centrifuge", "Truck", "Pile"]:
		var n: Node = m.find_child(nm, true, false)
		if n != null:
			n.set_process(false)
			n.set_physics_process(false)


func _mk_hive() -> Object:
	var m: Node = await _mk_main(true)
	if m == null:
		return null
	return _nn(m, "Hive")


func _mk_cen() -> Object:
	var m: Node = await _mk_main()
	if m == null:
		return null
	_quiet(m)
	return _nn(m, "Centrifuge")


func _mk_truck() -> Object:
	var m: Node = await _mk_main()
	if m == null:
		return null
	_quiet(m)
	return _nn(m, "Truck")


## Fill a centrifuge's bucket with `cells` cells (default: full), lid on. EMPTY/LOADING -> FULL.
func _load_bucket(c: Object, cells: int = -1) -> void:
	var n: int = _bucket_cells() if cells < 0 else cells
	c.call("add_cells", n, _jars_of(n))
	c.call("close_lid")


## Full bucket, lid on, then FULL -> CRANKING.
func _to_cranking(c: Object, cells: int = -1) -> void:
	_load_bucket(c, cells)
	c.call("begin_crank")


## Tap n times, spaced `spacing` s apart in advance() time; returns how many tap() calls counted.
func _tap_spaced(c: Object, n: int, spacing: float) -> int:
	var counted: int = 0
	for i in n:
		if c.call("tap"):
			counted += 1
		c.call("advance", spacing)
	return counted


## Press (one tap), hold, advance in dt steps until the state leaves CRANKING; returns the elapsed time.
func _hold_to_done(c: Object, dt: float, limit: float) -> float:
	var cranking: int = _st(c, "CRANKING")
	c.call("tap")
	c.call("set_holding", true)
	var t: float = 0.0
	while int(c.get("state")) == cranking and t < limit:
		c.call("advance", dt)
		t += dt
	c.call("set_holding", false)
	return t


## One frame's worth of hive time that fills `jars` jars at multiplier 1
func _secs_for_jars(jars: float) -> float:
	return jars * float(cv("base_seconds_per_jar"))


## Time for one more cell to arrive at multiplier 1
func _cell_secs() -> float:
	return float(cv("base_seconds_per_jar")) * _cell_value()


## Capped cells per frame, read through hive.frame_cells(i)
func _profile(h: Object) -> Array:
	var out: Array = []
	for i in _frames_n():
		out.append(fi.capped(h as Node, i))
	return out


func _hive_filled(h: Object) -> void:
	# exactly the hive's capacity, overflow empty: base time x capacity
	h.call("advance", _secs_for_jars(_hive_jars()) + _cell_secs() * 0.5, 1.0)


# ---------------------------------------------------------------- economy (unchanged)

# L67: cost = 25 x 1.18^level, rounded; max level 10.
func t_cost_formula() -> void:
	var e: Node = _eco()
	var base: float = float(cv("swarm_base_cost"))
	var growth: float = float(cv("swarm_cost_growth"))
	eq(e.call("swarm_cost"), roundi(base), "level 0 cost")
	for lvl in int(cv("swarm_max_level")):
		e.set("swarm_level", lvl)
		eq(e.call("swarm_cost"), roundi(base * pow(growth, lvl)), "cost at level %d" % lvl)
	_fin()


# L67: max level 10; button disabled when maxed.
func t_cost_max_level() -> void:
	var e: Node = _eco()
	var maxl: int = int(cv("swarm_max_level"))
	e.set("money", 100000000)
	for i in maxl:
		ck(e.call("buy_swarm"), "buy %d should succeed" % i)
	eq(e.get("swarm_level"), maxl, "level after max buys")
	ck(not e.call("can_buy_swarm"), "cannot buy at max")
	var m: int = e.get("money")
	ck(not e.call("buy_swarm"), "buy beyond max refused")
	eq(e.get("swarm_level"), maxl, "level stays at max")
	eq(e.get("money"), m, "money unchanged on refused buy")
	_fin()


# L67
func t_buy_deducts_and_levels() -> void:
	var e: Node = _eco()
	var c0: int = int(e.call("swarm_cost"))
	e.set("money", c0 * 4)
	ck(e.call("buy_swarm"), "buy ok")
	eq(e.get("money"), c0 * 4 - c0, "money after first buy")
	eq(e.get("swarm_level"), 1, "level 1")
	var c1: int = int(e.call("swarm_cost"))
	ck(e.call("buy_swarm"), "second buy ok")
	eq(e.get("money"), c0 * 4 - c0 - c1, "money after second buy")
	_fin()


# L67: disabled when unaffordable.
func t_buy_blocked_unaffordable() -> void:
	var e: Node = _eco()
	var c0: int = int(e.call("swarm_cost"))
	e.set("money", c0 - 1)
	ck(not e.call("can_buy_swarm"), "cannot buy with cost-1")
	ck(not e.call("buy_swarm"), "buy refused")
	eq(e.get("swarm_level"), 0, "level 0")
	eq(e.get("money"), c0 - 1, "money unchanged")
	_fin()


# L67: Worker Swarm Count gives +15% fill rate per level (GDD).
func t_fill_multiplier() -> void:
	var e: Node = _eco()
	var bonus: float = float(cv("swarm_fill_bonus_per_level"))
	near(float(e.call("fill_multiplier")), 1.0, "level 0")
	for lvl in int(cv("swarm_max_level")) + 1:
		e.set("swarm_level", lvl)
		near(float(e.call("fill_multiplier")), 1.0 + bonus * lvl, "level %d" % lvl)
	_fin()


# L67, L105: +bees_per_swarm_level bees per level.
func t_bee_count() -> void:
	var e: Node = _eco()
	var per: int = int(cv("bees_per_swarm_level"))
	var b0: int = int(e.call("bee_count"))
	ck(b0 > 0, "level 0 has bees (got %d)" % b0)
	for lvl in int(cv("swarm_max_level")) + 1:
		e.set("swarm_level", lvl)
		eq(e.call("bee_count"), b0 + lvl * per, "bees at level %d" % lvl)
	e.set("swarm_level", 0)
	e.set("money", 100000)
	e.call("buy_swarm")
	eq(e.call("bee_count"), b0 + per, "a purchase adds bees_per_swarm_level bees")
	_fin()


# L67: the extra bees give the fill rate: multiplier = bees / base bees.
func t_fill_multiplier_is_bees_over_base() -> void:
	var e: Node = _eco()
	e.set("swarm_level", 0)
	var b0: float = float(e.call("bee_count"))
	for lvl in int(cv("swarm_max_level")) + 1:
		e.set("swarm_level", lvl)
		near(float(e.call("fill_multiplier")), float(e.call("bee_count")) / b0, "multiplier = bees / base at level %d" % lvl)
	_fin()


# L122, L26, L30: jars, add_jars(), sell_jars(), jars_changed are gone from Economy; earn() exists.
func t_economy_removed_jars() -> void:
	var e: Node = _eco()
	ck(not ("jars" in e), "Economy.jars must be removed (jars live in centrifuge, crate, truck)")
	ck(not e.has_method("add_jars"), "Economy.add_jars() must be removed")
	ck(not e.has_method("sell_jars"), "Economy.sell_jars() must be removed")
	ck(not e.has_signal("jars_changed"), "Economy.jars_changed must be removed")
	ck(e.has_method("earn"), "Economy.earn(amount) must exist")
	ck(e.has_method("jar_value"), "Economy.jar_value() must exist")
	ck(e.has_signal("money_changed"), "Economy.money_changed must exist")
	ck(e.has_signal("swarm_level_changed"), "Economy.swarm_level_changed must exist")
	ck(not ("no_rapid_tap_mode" in e), "Economy.no_rapid_tap_mode must be removed (L26)")
	_fin()


# L122, L66
func t_earn_and_jar_value() -> void:
	var e: Node = _eco()
	eq(e.call("jar_value"), int(cv("sale_value_per_jar")), "jar_value() = sale_value_per_jar")
	var seen: Array = []
	e.connect("money_changed", func(m: Variant) -> void: seen.append(m))
	e.call("earn", 30)
	eq(e.get("money"), 30, "money after earn(30)")
	ck(seen.size() >= 1, "money_changed emitted by earn()")
	e.call("earn", 12)
	eq(e.get("money"), 42, "money accumulates")
	_fin()


# L38, L105: the drawn flock is capped at visual_bee_cap while the counter keeps rising.
func t_drawn_count_capped() -> void:
	var e: Node = _eco()
	var b: Object = _make("bees.gd")
	if b == null:
		_fin()
		return
	var per: int = int(cv("bees_per_swarm_level"))
	var b0: int = int(e.call("bee_count"))
	var cap: int = b0 + per + per / 2   # level 1 is under the cap, level 2 is over it
	_set_cfg("visual_bee_cap", cap)
	root.add_child(b as Node)
	await process_frame
	await process_frame   # _ready builds the MultiMesh and sizes the flock
	ck(b.has_method("drawn_count"), "bees.gd has drawn_count()")
	if not b.has_method("drawn_count"):
		_fin()
		return
	eq(b.call("drawn_count"), b0, "level 0: all bees drawn (under the cap)")
	e.set("swarm_level", 2)
	e.emit_signal("swarm_level_changed", 2)
	eq(e.call("bee_count"), b0 + 2 * per, "counter keeps rising")
	eq(b.call("drawn_count"), cap, "drawn capped at visual_bee_cap")
	eq((b as MultiMeshInstance3D).multimesh.instance_count, cap, "multimesh.instance_count capped")
	e.set("swarm_level", 10)
	e.emit_signal("swarm_level_changed", 10)
	eq(b.call("drawn_count"), cap, "still capped at max level")
	_fin()


# ---------------------------------------------------------------- contract and config

# "Node paths for Bob", "Models as reusable scenes", "Changes": the scene has the named nodes, harvest.tscn is gone.
func t_node_contract() -> void:
	ck(not FileAccess.file_exists("res://scenes/harvest.tscn"), "harvest.tscn must be deleted (spec: retired)")
	for scene in ["truck", "jar", "jar_crate", "flower_patch", "hive", "centrifuge", "honey_cell"]:
		ck(FileAccess.file_exists("res://scenes/props/%s.tscn" % scene), "scenes/props/%s.tscn missing (spec: Models as reusable scenes)" % scene)
	var mats: int = 0
	var d := DirAccess.open("res://materials")
	ck(d != null, "game/materials/ missing (spec: materials as .tres)")
	if d != null:
		for f in d.get_files():
			if f.ends_with(".tres"):
				mats += 1
	ck(mats >= 7, "game/materials/ holds %d .tres, spec lists 7 (capped, uncapped, extracted, jar amber, glass, steel, wood)" % mats)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	for nm in ["Hive", "ForkAnchor", "HiveLidSpot", "FrameSlots", "Honeycomb", "Centrifuge", "CentrifugeAnchor",
			"CentrifugeLidSpot", "BucketMouth", "Pile", "ZoomFraming", "HarvestUIRoot", "HarvestUI", "HintLabel", "BackButton",
			"FarmWorld", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon", "ContinueButton", "UpgradeButton"]:
		_nn(m, nm)
	for i in _frames_n():
		_nn(m, "Slot%d" % (i + 1))
	ck(m.find_child("Harvest", true, false) == null, "no 'Harvest' close-up root any more")
	var hive: Node = m.find_child("Hive", true, false)
	if hive != null:
		ck(hive.is_in_group("bee_home"), "Hive is in the group bee_home")
	var ui: Node = m.find_child("HarvestUI", true, false)
	if ui != null and ui is Control:
		eq((ui as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "HarvestUI ignores the mouse (full rect, never in the way)")
	var back: Node = m.find_child("BackButton", true, false)
	if back != null and back is Control:
		ck((back as Control).size.y >= 120.0, "BackButton at least 120 px high (%s)" % str((back as Control).size.y))
	_fin()


# "Values" table: every new value, checked on the defaults file itself.
func t_config_values() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres failed to load")
	if c == null:
		_fin()
		return
	var table: Dictionary = {
		"frames_per_hive": 5, "frame_jars": 2, "overflow_hives": 1, "centrifuge_capacity_frames": 2, "taps_per_jar": 4,
		"zoom_seconds": 0.6, "lid_drop_seconds": 0.4, "slide_seconds": 0.3, "frame_rise": 1.2, "cell_fly_seconds": 0.5,
		"pile_visual_cap": 40, "bucket_visual_cap": 40, "icon_visual_px": 88, "min_cell_px": 44,
		# unchanged from revision 3
		"sale_value_per_jar": 3, "truck_capacity_jars": 10, "truck_trip_seconds": 30.0,
		"bottling_seconds_per_jar": 3.0, "max_tap_rate": 5.0, "hold_ramp_seconds": 1.5,
		"base_seconds_per_jar": 6.0, "swarm_fill_bonus_per_level": 0.15, "swarm_base_cost": 25.0,
		"swarm_cost_growth": 1.18, "swarm_max_level": 10, "grid_cols": 7, "grid_rows": 5,
		"bees_per_swarm_level": 3, "visual_bee_cap": 60,
	}
	for k in table:
		var v: Variant = c.get(k)
		ck(v != null, "default_config.tres has no value '%s' (Values table)" % k)
		if v != null:
			near(float(v), float(table[k]), "default '%s'" % k)
	var zs: Variant = c.get("zoom_size")
	ck(zs != null, "default_config.tres has no value 'zoom_size' (Values table: Bob sets it)")
	if zs != null:
		ck(float(zs) > 0.0, "zoom_size is a positive ortho size (got %s)" % str(zs))
	for gone in ["taps_per_frame", "overflow_frames", "hold_taps_per_second", "hold_mode", "no_rapid_tap_mode"]:
		ck(c.get(gone) == null, "'%s' must be gone from the config (replaced or removed)" % gone)
	var e: Node = _eco()
	eq(e.call("bee_count"), 20, "base swarm of 20 bees at level 0 (assumes no user dev_config override)")
	# derived numbers the Done-when list quotes, from the config
	eq(int(c.get("frames_per_hive")) * int(c.get("frame_jars")), 10, "a full hive is 10 jars")
	eq(int(c.get("grid_cols")) * int(c.get("grid_rows")), 35, "35 cells per frame")
	_fin()


# "Values": placeholders are marked `# PLACEHOLDER (GDD TBD)` in game_config.gd.
func t_config_placeholders_marked() -> void:
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd unreadable")
	if f == null:
		_fin()
		return
	var lines: PackedStringArray = f.get_as_text().split("\n")
	f.close()
	for name in ["taps_per_jar", "centrifuge_capacity_frames", "truck_capacity_jars", "truck_trip_seconds",
			"bottling_seconds_per_jar", "max_tap_rate", "hold_ramp_seconds"]:
		var found: bool = false
		var marked: bool = false
		for i in lines.size():
			if lines[i].contains("var %s" % name):
				found = true
				if lines[i].contains("PLACEHOLDER (GDD TBD)") or (i > 0 and lines[i - 1].contains("PLACEHOLDER (GDD TBD)")):
					marked = true
		ck(found, "game_config.gd declares no 'var %s'" % name)
		ck(not found or marked, "'%s' is not marked # PLACEHOLDER (GDD TBD) on its line or the line above" % name)
	# every value of the Values table is an @export var (adjustable in Dev mode)
	var text: String = "\n".join(lines)
	for name in ["frames_per_hive", "frame_jars", "overflow_hives", "zoom_seconds", "lid_drop_seconds", "frame_rise",
			"cell_fly_seconds", "pile_visual_cap", "bucket_visual_cap", "icon_visual_px", "min_cell_px", "zoom_size"]:
		ck(text.contains("@export var %s" % name), "game_config.gd has no '@export var %s' (Dev mode lists exported values)" % name)
	_fin()


# "Contract": take_frame() goes; the hive owns the frames.
func t_retired_api_gone() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	ck(not h.has_method("take_frame"), "hive.take_frame() goes (spec: Contract, hive.gd)")
	for meth in ["is_full", "is_paused", "has_capped_cells", "next_frame_to_harvest", "frame_cells", "scrape", "raise_frame",
			"lower_frame", "open_lid", "close_lid", "fill_now", "advance", "cell_value"]:
		ck(h.has_method(meth), "hive.gd has no %s() (spec: Contract)" % meth)
	for sig in ["storage_changed", "became_full", "lid_moved", "frame_raised", "frame_lowered"]:
		ck(h.has_signal(sig), "hive.gd has no signal %s (spec: Contract)" % sig)
	_fin()


# ---------------------------------------------------------------- hive

# Loop step 1: a full hive (5 frames x 2 jars) takes 10 jars x base seconds per jar = 60 s.
func t_fill_time_level0() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var cap: float = _hive_jars()
	var full_t: float = _secs_for_jars(cap)
	near(float(h.get("storage")), 0.0, "new hive starts empty", _cell_value() * 0.5)
	h.call("advance", full_t - 1.0, 1.0)
	ck(not h.call("is_full"), "not full 1 s before the full time")
	h.call("advance", 2.0, 1.0)
	ck(h.call("is_full"), "full 1 s after the full time")
	near(float(h.get("capacity")), cap, "capacity = frames_per_hive x frame_jars")
	near(float(h.get("storage")), cap, "storage at capacity", _cell_value() * 0.01)
	_fin()


# Loop step 1 and Tree A: the fill rate scales with the bee count.
func t_fill_time_with_levels() -> void:
	var e: Node = _eco()
	e.set("swarm_level", 1)
	var m: float = float(e.call("fill_multiplier"))
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var full_t: float = _secs_for_jars(_hive_jars()) / m
	h.call("advance", full_t - 1.0, m)
	ck(not h.call("is_full"), "level 1 not full 1 s early")
	h.call("advance", 2.0, m)
	ck(h.call("is_full"), "level 1 full 1 s late")
	_fin()


# Dev mode: no cached config; edits apply to the next advance.
func t_hive_rate_is_live() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var secs: float = float(cv("base_seconds_per_jar"))
	var tol: float = _cell_value() * 1.05   # storage moves in steps of one cell
	h.call("advance", secs * 2.0, 1.0)
	near(float(h.get("storage")), 2.0, "2 jars after 2 x base seconds", tol)
	_set_cfg("base_seconds_per_jar", secs / 2.0)
	var before: float = float(h.get("storage"))
	h.call("advance", secs, 1.0)   # at the halved time per jar this is 2 more jars
	near(float(h.get("storage")) - before, 2.0, "rate change applies to the next advance", tol * 2.0)
	_fin()


# Done when, fill: "60 s fills all 5 frames (10 jars) in order, slot by slot". Frame k gets no cell before frame k-1 is full.
func t_fill_in_order_slot_by_slot() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var cpf: int = _cpf()
	var nf: int = _frames_n()
	var cs: float = _cell_secs()
	eq(_profile(h), [0, 0, 0, 0, 0].slice(0, nf), "a new hive holds no Capped cell")
	for i in nf:
		var arr: PackedByteArray = h.call("frame_cells", i)
		eq(arr.size(), cpf, "frame %d has cells_per_frame slots" % i)
		var empties: int = 0
		for b in arr:
			if b == 2:
				empties += 1
		eq(empties, cpf, "frame %d starts as empty slots (state 2)" % i)
	h.call("advance", cs * 0.5, 1.0)   # half a cell of margin, so float noise cannot move a cell
	var bad: String = ""
	for j in range(1, nf * cpf + 1):
		h.call("advance", cs, 1.0)
		var want: Array = []
		var left: int = j
		for f in nf:
			var take: int = mini(left, cpf)
			want.append(take)
			left -= take
		var got: Array = _profile(h)
		if got != want and bad == "":
			bad = "after %d cells: Capped per frame %s, expected %s (frames fill in order)" % [j, str(got), str(want)]
		if bad != "":
			break
	ck(bad == "", bad)
	ck(h.call("is_full"), "full after nf x cpf cells")
	near(float(h.get("storage")), _hive_jars(), "storage = 10 jars", _cell_value() * 0.01)
	near(float(h.get("overflow")), 0.0, "overflow still empty at the moment of full", _cell_value() * 1.05)
	_fin()


# Loop step 1: "A frame that is risen (on display) never fills; honey goes to the other frames or the overflow."
# Spec ambiguity noted in the report: raise_frame(i) on a frame with no Capped cell is not described; the test raises an empty frame.
func t_risen_frame_never_fills() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var cpf: int = _cpf()
	var nf: int = _frames_n()
	var risen: int = 2
	var seen: Array = []
	h.connect("frame_raised", func(i: Variant) -> void: seen.append(["raised", int(i)]))
	h.connect("frame_lowered", func(i: Variant) -> void: seen.append(["lowered", int(i)]))
	h.call("raise_frame", risen)
	eq(seen, [["raised", risen]], "raise_frame(i) emits frame_raised(i)")
	h.call("advance", _secs_for_jars(_hive_jars()) + _cell_secs() * 0.5, 1.0)   # 60 s: ten jars arrive
	var want: Array = []
	for f in nf:
		want.append(0 if f == risen else cpf)
	eq(_profile(h), want, "the risen frame took no cell, the other frames filled")
	var ov: float = _hive_jars() - float(cpf * (nf - 1)) * _cell_value()
	near(float(h.get("overflow")), ov, "the honey the risen frame would have taken went to the overflow", _cell_value() * 1.5)
	ck(not h.call("is_full"), "not full while a slot cannot fill (a frame is risen)")
	h.call("lower_frame")
	eq(seen.size(), 2, "lower_frame() emits frame_lowered")
	if seen.size() == 2:
		eq(seen[1], ["lowered", risen], "frame_lowered(i) names the frame")
	h.call("advance", _secs_for_jars(_hive_jars()), 1.0)
	eq(_profile(h), [cpf, cpf, cpf, cpf, cpf].slice(0, nf), "once lowered the frame fills again")
	ck(h.call("is_full"), "full again")
	_fin()


# Done when, fill: "overflow takes the next 10 jars, then the hive pauses". Overflow buffer = overflow_hives x capacity.
func t_overflow_one_hive_then_pause() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var tol: float = _cell_value() * 1.5
	var cap: float = _hive_jars()
	var ocap: float = cap * float(cv("overflow_hives"))
	_hive_filled(h)
	ck(h.call("is_full"), "full after 60 s")
	near(float(h.get("overflow")), 0.0, "overflow starts empty", tol)
	ck(not h.call("is_paused"), "not paused yet")
	h.call("advance", _secs_for_jars(ocap) / 2.0, 1.0)
	near(float(h.get("overflow")), ocap / 2.0, "overflow half full", tol)
	near(float(h.get("storage")), cap, "storage stays at capacity", _cell_value() * 0.01)
	ck(not h.call("is_paused"), "not paused at half overflow")
	h.call("advance", _secs_for_jars(ocap) / 2.0 + 1.0, 1.0)
	near(float(h.get("overflow")), ocap, "overflow full after the next 10 jars", tol)
	ck(h.call("is_paused"), "paused when both are full")
	h.call("advance", 1000.0, 1.0)
	near(float(h.get("overflow")), ocap, "overflow capped", tol)
	near(float(h.get("storage")), cap, "storage capped", _cell_value() * 0.01)
	_fin()


func t_became_full_once_while_filling() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	_counter = 0
	h.connect("became_full", _bump)
	var total: float = _secs_for_jars(_hive_jars()) + 10.0
	var steps: int = int(total / 0.1)
	for i in steps:
		h.call("advance", 0.1, 1.0)
	eq(_counter, 1, "one became_full across the fill")
	_fin()


func t_became_full_count_full_overflow() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	_counter = 0
	h.connect("became_full", _bump)
	_hive_filled(h)
	eq(_counter, 1, "became_full on the first fill")
	h.call("advance", _secs_for_jars(_hive_jars()), 1.0)
	eq(_counter, 1, "no repeat while full or overflowing")
	h.call("advance", 100000.0, 1.0)
	eq(_counter, 1, "no repeat once paused")
	_fin()


# Done when, scrape: "one cell moves 2 / 35 jars from the hive; a full frame scraped moves 2 jars".
func t_scrape_value() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	_hive_filled(h)
	near(float(h.call("cell_value")), _cell_value(), 1e-9, "hive.cell_value() = frame_jars / cells_per_frame")
	var before: float = float(h.get("storage"))
	var got: float = float(h.call("scrape", 0, 0))
	near(got, _jars_of(1), 1e-9, "scrape returns the jar value of one cell (2 / 35)")
	near(before - float(h.get("storage")), _jars_of(1), 1e-9, "one cell moved 2 / 35 jars out of the hive's storage")
	var sum: float = got
	for c in range(1, _cpf()):
		sum += float(h.call("scrape", 0, c))
	near(sum, float(cv("frame_jars")), 1e-6, "a full frame scraped returns frame_jars (2) jars")
	near(before - float(h.get("storage")), float(cv("frame_jars")), 1e-6, "a full frame scraped moved frame_jars jars out of storage")
	eq(fi.capped(h as Node, 0), 0, "no Capped cell left in the scraped frame")
	eq(fi.capped(h as Node, 1), _cpf(), "the next frame is untouched")
	_fin()


# Loop step 3: a scrape is Capped -> Uncapped (state 1); a cell scraped once cannot be scraped again; an empty slot yields nothing.
# Ambiguity in the report: whether state 2 is written by the hive at the scrape or by the flight; this test accepts 1 or 2.
func t_scrape_rules() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	h.call("advance", _cell_secs() * 3.5, 1.0)   # three cells in frame 0
	eq(_profile(h)[0], 3, "three cells arrived")
	var arr0: PackedByteArray = h.call("frame_cells", 0)
	eq(arr0[0], 0, "a filled slot is Capped (0)")
	var s0: float = float(h.get("storage"))
	near(float(h.call("scrape", 0, 1)), _cell_value(), 1e-9, "first scrape of cell 1 returns its value")
	var arr1: PackedByteArray = h.call("frame_cells", 0)
	ck(arr1[1] == 1 or arr1[1] == 2, "a scraped cell is no longer Capped (state %d)" % arr1[1])
	eq(arr1[0], 0, "its neighbours keep their state")
	near(float(h.call("scrape", 0, 1)), 0.0, "scraping the same cell twice returns 0", 1e-9)
	near(float(h.get("storage")), s0 - _cell_value(), 1e-9, "the second scrape moved nothing")
	near(float(h.call("scrape", 3, 0)), 0.0, "scraping an empty slot returns 0", 1e-9)
	var arr3: PackedByteArray = h.call("frame_cells", 3)
	eq(arr3[0], 2, "an empty slot stays Extracted (2)")
	_fin()


# Loop step 3 and Contract: next_frame_to_harvest() is the first frame with Capped cells (-1 if none); has_capped_cells().
func t_next_frame_to_harvest() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	eq(h.call("next_frame_to_harvest"), -1, "empty hive: no frame to harvest")
	ck(not h.call("has_capped_cells"), "empty hive: no Capped cell")
	_hive_filled(h)
	eq(h.call("next_frame_to_harvest"), 0, "full hive: frame 0 first")
	ck(h.call("has_capped_cells"), "full hive has Capped cells")
	for c in _cpf():
		h.call("scrape", 0, c)
	eq(h.call("next_frame_to_harvest"), 1, "frame 0 scraped out: frame 1 next")
	for f in range(1, _frames_n()):
		for c in _cpf():
			h.call("scrape", f, c)
	eq(h.call("next_frame_to_harvest"), -1, "everything scraped: -1")
	ck(not h.call("has_capped_cells"), "no Capped cell left")
	_fin()


# ---------------------------------------------------------------- centrifuge: bucket, lid, turns, floor bottling

# Done when, bucket: "cells go to the bucket until 2 x 35"; states EMPTY -> LOADING; capacity read live.
func t_bucket_capacity_and_states() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var cap: int = _bucket_cells()
	eq(c.get("state"), _st(c, "EMPTY"), "starts EMPTY")
	ck(c.call("has_room"), "EMPTY has room")
	eq(c.call("room_cells"), cap, "room_cells = centrifuge_capacity_frames x cells_per_frame (70)")
	eq(c.get("lid_open"), true, "EMPTY: lid off")
	eq(c.get("cells"), 0, "no cells yet")
	c.call("add_cells", 1, _jars_of(1))
	eq(c.get("state"), _st(c, "LOADING"), "one cell in, room left: LOADING")
	eq(c.call("room_cells"), cap - 1, "room_cells counts down")
	eq(c.get("lid_open"), true, "LOADING: lid still off")
	ck(c.call("has_room"), "LOADING has room")
	c.call("add_cells", cap - 1, _jars_of(cap - 1))
	eq(c.get("cells"), cap, "bucket holds cap cells")
	eq(c.call("room_cells"), 0, "no room left")
	ck(not c.call("has_room"), "full bucket has no room")
	near(float(c.get("jars")), _jars_of(cap), 1e-6, "jars = 4 for 70 cells")
	# the capacity is read live (Dev mode)
	var c2: Object = await _mk_cen()
	_set_cfg("centrifuge_capacity_frames", 1)
	eq(c2.call("room_cells"), _cpf(), "room_cells follows centrifuge_capacity_frames live")
	_fin()


# Done when, lid: close_lid() -> FULL, lid_open false, lid_moved(false); then begin_crank -> CRANKING.
func t_lid_close_and_signal() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var seen: Array = []
	c.connect("lid_moved", func(o: Variant) -> void: seen.append(bool(o)))
	c.call("add_cells", _cpf(), _jars_of(_cpf()))
	c.call("close_lid")
	eq(c.get("lid_open"), false, "lid on after close_lid()")
	eq(c.get("state"), _st(c, "FULL"), "a part-full bucket with its lid on waits as FULL (Spin shows)")
	ck(seen.size() > 0 and seen[seen.size() - 1] == false, "lid_moved(false) emitted (got %s)" % str(seen))
	eq(c.get("cells"), _cpf(), "closing the lid keeps the cells")
	c.call("begin_crank")
	eq(c.get("state"), _st(c, "CRANKING"), "begin_crank -> CRANKING")
	_fin()


# Done when, crank: ceil(jars x taps_per_jar) turns; 16 turns for 4 jars. Uses the integer cell count.
func t_turns_per_jar() -> void:
	var per_jar: int = int(cv("taps_per_jar"))
	var cases: Array = [_bucket_cells(), _cpf(), _cpf() + 1, 1]   # 4 jars, 2 jars, 2.057 jars, 2/35 jar
	for cells in cases:
		var c: Object = await _mk_cen()
		if c == null:
			_fin()
			return
		var want: int = _turns_for(cells)
		var done: Array = [0]
		c.connect("extraction_done", func() -> void: done[0] += 1)
		_to_cranking(c, cells)
		var cranking: int = _st(c, "CRANKING")
		var sent: int = 0
		while int(c.get("state")) == cranking and sent < want + 6:
			if not c.call("tap"):
				ck(false, "%d cells: a spaced tap was not counted" % cells)
			c.call("advance", _tap_gap())
			sent += 1
		eq(sent, want, "%d cells (%s jars): ceil(jars x taps_per_jar) turns" % [cells, str(_jars_of(cells))])
		eq(c.get("state"), _st(c, "DONE"), "%d cells: DONE after the last turn" % cells)
		eq(done[0], 1, "%d cells: extraction_done once" % cells)
	var c4: Object = await _mk_cen()
	_to_cranking(c4)
	var n4: int = 0
	var cranking4: int = _st(c4, "CRANKING")
	while int(c4.get("state")) == cranking4 and n4 < 200:
		c4.call("tap")
		c4.call("advance", _tap_gap())
		n4 += 1
	eq(n4, int(roundf(_jars_of(_bucket_cells()))) * per_jar, "4 jars take 4 x taps_per_jar turns (16 at the defaults)")
	_fin()


# Contract: crank_enabled false (the zoom) stops every turn; true again counts.
func t_crank_enabled_flag() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	ck("crank_enabled" in c, "centrifuge.gd has crank_enabled (spec: Contract)")
	if not ("crank_enabled" in c):
		_fin()
		return
	eq(c.get("crank_enabled"), true, "crank_enabled defaults to true on the farm")
	_to_cranking(c)
	c.set("crank_enabled", false)
	ck(not c.call("tap"), "tap() ignored while crank_enabled is false")
	c.call("advance", 1.0)
	ck(not c.call("tap"), "still ignored a second later")
	c.call("set_holding", true)
	for i in 120:
		c.call("advance", 1.0 / 60.0)
	c.call("set_holding", false)
	eq(c.get("turns_counted"), 0, "no turn counted: not by tap, not by hold, while disabled")
	eq(c.get("state"), _st(c, "CRANKING"), "still CRANKING (cranking just stopped counting)")
	c.set("crank_enabled", true)
	c.call("advance", 1.0)
	ck(c.call("tap"), "tap() counts again once enabled")
	eq(c.get("turns_counted"), 1, "one turn counted")
	_fin()


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
	eq(c.get("state"), _st(c, "DONE"), "hold reached DONE")
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
	eq(tapper.get("state"), _st(tapper, "DONE"), "tapped bucket reached DONE")
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


# Table of states: crank input counts only in CRANKING (and then only unless zoomed). Real input in every state.
func t_crank_ignored_outside_cranking() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var burst: int = n * 3
	for i in burst:   # EMPTY
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("turns_counted"), 0, "EMPTY: input counted nothing")
	eq(c.get("state"), _st(c, "EMPTY"), "EMPTY unchanged by input")
	c.call("add_cells", _cpf(), _jars_of(_cpf()))   # LOADING
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("turns_counted"), 0, "LOADING: input counted nothing")
	eq(c.get("state"), _st(c, "LOADING"), "LOADING unchanged by input")
	c.call("add_cells", _bucket_cells() - _cpf(), _jars_of(_bucket_cells() - _cpf()))
	c.call("close_lid")   # FULL
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("turns_counted"), 0, "FULL: input counted nothing")
	eq(c.get("state"), _st(c, "FULL"), "FULL unchanged by input (begin_crank starts cranking, not a tap)")
	c.call("begin_crank")   # CRANKING: positive control
	var cranking: int = _st(c, "CRANKING")
	for i in n + 5:
		if int(c.get("state")) != cranking:
			break
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "DONE"), "CRANKING: real clicks counted and finished the bucket (positive control)")
	var turns: Variant = c.get("turns_counted")
	for i in burst:   # DONE
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "DONE"), "DONE unchanged by input")
	eq(c.get("turns_counted"), turns, "DONE: no extra turn")
	c.call("open_spigot")   # BOTTLING
	var bottling: int = _st(c, "BOTTLING")
	for i in 3:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), bottling, "BOTTLING unchanged by input")
	eq(c.get("turns_counted"), turns, "BOTTLING: no extra turn")
	_fin()


func t_real_mouse_taps_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < n * 2:
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
		sent += 1
	eq(sent, n, "exactly ceil(jars x taps_per_jar) real clicks finish the bucket")
	eq(c.get("state"), _st(c, "DONE"), "DONE")
	var c2: Object = await _mk_cen()
	_to_cranking(c2)
	for i in 15:
		_real_click(EMPTY_SPOT)
	ck(not c2.call("tap"), "15 real clicks in zero time were already counted once, so a 16th tap is capped")
	_fin()


func t_real_touch_taps_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < n * 2:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = EMPTY_SPOT * _to_window()
		root.push_input(down)
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = down.position
		root.push_input(up)
		c.call("advance", gap)
		sent += 1
	eq(c.get("state"), _st(c, "DONE"), "touch taps finished the bucket (%d sent)" % sent)
	_fin()


func t_button_press_is_not_a_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	var btn := Button.new()
	btn.position = Vector2(100.0, 900.0)
	btn.size = Vector2(300.0, 150.0)
	btn.text = "Upgrade"
	layer.add_child(btn)
	root.add_child(layer)
	_to_free.append(layer)
	await process_frame
	_to_cranking(c)
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var on_button: Vector2 = btn.get_global_rect().get_center()
	for i in n * 2:
		_real_click(on_button)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "CRANKING"), "clicks on a button did not crank")
	eq(c.get("turns_counted"), 0, "no turns from button clicks")
	var cranking: int = _st(c, "CRANKING")
	for i in n * 2:
		if int(c.get("state")) != cranking:
			break
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "DONE"), "clicks off the button finish the bucket (positive control)")
	_fin()


# ---------------------------------------------------------------- bottling

## Crank a loaded bucket to DONE by spaced taps.
func _crank_done(c: Object) -> int:
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < 400:
		c.call("tap")
		c.call("advance", _tap_gap())
		sent += 1
	return sent


## Bottle until EMPTY (advance in steps); returns the jar_bottled count and the bottling_done arguments.
func _bottle_out(c: Object, step: float = 0.05) -> Dictionary:
	var bottled: Array = []
	var done_args: Array = []
	c.connect("jar_bottled", func(n: Variant) -> void: bottled.append(int(n)))
	c.connect("bottling_done", func(j: Variant) -> void: done_args.append(int(j)))
	c.call("open_spigot")
	var limit: float = float(cv("bottling_seconds_per_jar")) * (float(c.get("jars")) + 4.0) + 5.0
	var t: float = 0.0
	var empty: int = _st(c, "EMPTY")
	while int(c.get("state")) != empty and t < limit:
		c.call("advance", step)
		t += step
	return {"bottled": bottled, "done": done_args}


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
	eq(c.get("state"), _st(c, "DONE"), "extracted before bottling")
	var times: Array = []
	var clock: Array = [0.0]
	var counts: Array = []
	var done_args: Array = []
	c.connect("jar_bottled", func(n: Variant) -> void:
		times.append(clock[0])
		counts.append(int(n))
		t.call("receive_jar"))
	c.connect("bottling_done", func(j: Variant) -> void: done_args.append(int(j)))
	c.call("open_spigot")
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
	c.call("open_spigot")
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

# L126, L230: capacity jars make the truck full and sellable.
func t_truck_full_and_can_sell() -> void:
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	eq(t.get("capacity"), cap, "truck.capacity = truck_capacity_jars")
	ck(not t.call("is_full"), "empty truck is not full")
	ck(not t.call("can_sell"), "empty truck cannot sell")
	for i in cap - 1:
		t.call("receive_jar")
	ck(not t.call("is_full"), "one jar short is not full")
	ck(not t.call("can_sell"), "one jar short cannot sell")
	t.call("receive_jar")
	eq(t.get("loaded_jars"), cap, "loaded_jars = capacity")
	ck(t.call("is_full"), "capacity jars make it full")
	ck(t.call("can_sell"), "full and home: can_sell()")
	eq(t.call("load_value"), cap * int(cv("sale_value_per_jar")), "load_value() = jars x $ per jar")
	t.call("receive_jar")
	eq(t.get("loaded_jars"), cap, "a jar beyond capacity does not overload the truck")
	eq(t.get("crate_jars"), 1, "the extra jar goes to the crate")
	_fin()


# L126, L66, L230: sell() credits the money at once, empties the truck, sets away, emits departed.
func t_truck_sell_credits_at_once() -> void:
	var e: Node = _eco()
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var per: int = int(cv("sale_value_per_jar"))
	for i in cap:
		t.call("receive_jar")
	_counter = 0
	t.connect("departed", _bump)
	var seen: Array = []
	t.connect("load_changed", func(l: Variant, c: Variant) -> void: seen.append([int(l), int(c)]))
	var m0: int = int(e.get("money"))
	var got: Variant = t.call("sell")
	eq(got, cap * per, "sell() returns the load value")
	eq(e.get("money"), m0 + cap * per, "money credited at once, with no advance() call")
	ck(t.get("away"), "away after sell()")
	eq(t.get("loaded_jars"), 0, "truck emptied")
	eq(_counter, 1, "departed emitted once")
	ck(seen.size() > 0 and seen[seen.size() - 1] == [0, 0], "load_changed(0, 0) emitted after selling (got %s)" % str(seen))
	ck(not t.call("can_sell"), "cannot sell while away")
	_fin()


# L65: jars bottled while the truck is away go to the crate.
func t_truck_crate_while_away() -> void:
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	for i in cap:
		t.call("receive_jar")
	t.call("sell")
	for i in 4:
		t.call("receive_jar")
	eq(t.get("crate_jars"), 4, "jars bottled while away go to the crate")
	eq(t.get("loaded_jars"), 0, "nothing on the away truck")
	_fin()


# L65, L66, L230: on return the crate loads onto the truck up to its capacity.
func t_truck_return_loads_crate() -> void:
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var trip: float = float(cv("truck_trip_seconds"))
	for i in cap:
		t.call("receive_jar")
	t.call("sell")
	var extra: int = cap + 3
	for i in extra:
		t.call("receive_jar")
	eq(t.get("crate_jars"), extra, "crate holds %d" % extra)
	_counter = 0
	t.connect("returned", _bump)
	t.call("advance", trip - 0.5)
	ck(t.get("away"), "still away 0.5 s before the trip time")
	eq(_counter, 0, "not returned yet")
	t.call("advance", 1.0)
	ck(not t.get("away"), "back after truck_trip_seconds")
	eq(_counter, 1, "returned emitted once")
	eq(t.get("loaded_jars"), cap, "the crate loaded the truck up to capacity")
	eq(t.get("crate_jars"), extra - cap, "the rest stays in the crate")
	ck(t.call("can_sell"), "full truck at home can sell again")
	_fin()


# L97: truck_trip_seconds is read live (the next trip uses the edited value).
func t_truck_trip_time_is_live() -> void:
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var cap: int = int(cv("truck_capacity_jars"))
	var trip: float = float(cv("truck_trip_seconds"))
	for i in cap:
		t.call("receive_jar")
	t.call("sell")
	t.call("advance", trip + 0.5)
	ck(not t.get("away"), "first trip ended at the default time")
	_set_cfg("truck_trip_seconds", trip * 2.0)
	for i in cap:
		t.call("receive_jar")
	t.call("sell")
	t.call("advance", trip + 0.5)
	ck(t.get("away"), "second trip is still away after the OLD trip time")
	t.call("advance", trip)
	ck(not t.get("away"), "second trip ended at the NEW trip time")
	_fin()


# ---------------------------------------------------------------- the zoom (real input on the farm)

const SCENE_NODES := ["Hive", "Centrifuge", "Pile", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon", "ContinueButton",
		"UpgradeButton", "BackButton", "HintLabel", "SummaryModal", "SummaryOkButton", "CentrifugeLabel", "MoneyLabel",
		"FillLabel", "BeeCountLabel", "ShopPanel"]


## The named nodes of a main instance; a missing one fails the test (spec: Node paths for Bob) and returns {}.
func _parts(m: Node) -> Dictionary:
	var d: Dictionary = {}
	var ok: bool = true
	for nm in SCENE_NODES:
		var n: Node = m.find_child(nm, true, false)
		if n == null:
			ck(false, "node '%s' missing in the scene (spec: Node paths for Bob)" % nm)
			ok = false
		d[nm] = n
	return d if ok else {}


## Listen to the hive: the risen frame (-1 when none), every raise and lower, every lid move.
func _track(hive: Node) -> Dictionary:
	var tr: Dictionary = {"risen": -1, "raised": [], "lowered": [], "lid": []}
	hive.connect("frame_raised", func(i: Variant) -> void:
		tr["risen"] = int(i)
		(tr["raised"] as Array).append(int(i)))
	hive.connect("frame_lowered", func(i: Variant) -> void:
		(tr["lowered"] as Array).append(int(i))
		if int(tr["risen"]) == int(i):
			tr["risen"] = -1)
	hive.connect("lid_moved", func(o: Variant) -> void: (tr["lid"] as Array).append(bool(o)))
	return tr


## CHEAT (Dev mode, marked): a full hive (all frames Capped, overflow empty) and the fill frozen, so nothing arrives by itself.
func _full_hive_frozen(hive: Node) -> void:
	hive.call("fill_now")
	_set_cfg("base_seconds_per_jar", 1.0e9)


func _zoom_settle() -> float:
	return float(cv("zoom_seconds")) + _lid_t() + float(cv("slide_seconds")) + 0.5


## Tap the fork where it floats, wait for the zoom (frame_raised), then for the camera, lid and slide to settle.
func _open_zoom(m: Node, p: Dictionary, tr: Dictionary) -> bool:
	var on_anchor: bool = await fi.click_icon(p["ForkIcon"] as Control)
	ck(on_anchor, "the fork icon sits at its anchor's projected position (click went there)")
	var raised: bool = await _until(func() -> bool: return int(tr["risen"]) >= 0, 3.0)
	await _wait(_zoom_settle())
	return raised


## Scrape the risen frame with real drags until it has no Capped cell (or the zoom moved on); returns the frame index worked.
func _scrape_risen(m: Node, hive: Node, tr: Dictionary, passes: int = 5) -> int:
	var f: int = int(tr["risen"])
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	if f < 0 or hc == null or cam == null:
		ck(false, "scrape: no risen frame / Honeycomb / camera (risen=%d)" % f)
		return f
	for pass_i in passes:
		if int(tr["risen"]) != f or fi.capped(hive, f) == 0:
			break
		for r in fi.rows(hc, cam):
			if int(tr["risen"]) != f or fi.capped(hive, f) == 0:
				break
			await fi.drag_row(r)
	return f


## After a frame is finished: wait for it to slide down and the next to slide up (or for the zoom to end), then settle.
func _next_frame(tr: Dictionary, was: int, timeout: float = 4.0) -> bool:
	var moved: bool = await _until(func() -> bool: return int(tr["risen"]) >= 0 and int(tr["risen"]) != was, timeout)
	await _wait(float(cv("slide_seconds")) + 0.45)
	return moved


## Total jars held anywhere before bottling: hive storage + overflow + bucket + pile.
func _jars_everywhere(p: Dictionary) -> float:
	return float((p["Hive"] as Node).get("storage")) + float((p["Hive"] as Node).get("overflow")) \
			+ float((p["Centrifuge"] as Node).get("jars")) + float((p["Pile"] as Node).get("jars"))


# Spec "The loop" step 3 and Look: tapping the fork zooms (camera size to zoom_size), hides the farm UI, opens the hive lid
# and raises the first frame with Capped cells; BackButton sits in a top corner clear of the frame and the bucket.
func t_zoom_ui_and_camera() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	await _frames(4)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	ck(cam != null, "a current Camera3D exists on the farm")
	if cam == null:
		_fin()
		return
	var size0: float = cam.size
	var farm_ui: Array = ["MoneyLabel", "FillLabel", "BeeCountLabel", "UpgradeButton", "ShopPanel"]
	for nm in farm_ui:
		ck(_shown(p[nm]), "%s shows on the farm before the zoom" % nm)
	ck(_shown(p["ForkIcon"]), "fork shows at a full hive")
	ck(not _shown(p["BackButton"]) and not _shown(p["HintLabel"]), "BackButton and hint are hidden on the farm")
	ck((p["ForkIcon"] as Control).size.x >= 120.0 and (p["ForkIcon"] as Control).size.y >= 120.0, "fork icon touch area at least 120 x 120 (%s)" % str((p["ForkIcon"] as Control).size))
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "tapping the fork raised a frame (frame_raised)")
	eq(tr["risen"], 0, "the first frame with Capped cells rises first")
	eq(tr["lid"], [true], "the hive lid opened (lid_moved(true)) once")
	near(cam.size, float(cv("zoom_size")), 0.05, "camera size reaches zoom_size")
	ck(cam.size < size0, "the camera zoomed in (size %s < %s)" % [str(cam.size), str(size0)])
	for nm in farm_ui + ["ForkIcon", "CentrifugeIcon", "SellIcon", "ContinueButton", "CentrifugeLabel"]:
		ck(not _shown(p[nm]), "%s is hidden during the zoom" % nm)
	ck(_shown(p["BackButton"]) and _shown(p["HintLabel"]), "BackButton and the hint show during the zoom")
	var back: Control = p["BackButton"]
	ck(back.size.y >= 120.0, "BackButton at least 120 px high (%s)" % str(back.size.y))
	ck(back.get_global_rect().get_center().y < 320.0, "BackButton sits in a top corner (centre y %s)" % str(back.get_global_rect().get_center().y))
	var rect: Rect2 = back.get_global_rect()
	var hc: Node = m.find_child("Honeycomb", true, false)
	var hit: int = 0
	if hc != null:
		for pt in fi.cells(hc):
			if rect.has_point(cam.unproject_position(pt.global_position)):
				hit += 1
		eq(hit, 0, "no cell of the risen frame lies under BackButton")
	var mouth: Node = m.find_child("BucketMouth", true, false)
	if mouth != null:
		ck(not rect.has_point(cam.unproject_position((mouth as Node3D).global_position)), "BucketMouth is not under BackButton")
	var hl: Label = p["HintLabel"]
	ck(hl.text.strip_edges() != "", "the hint has text")
	await fi.click_ctl(back)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	near(cam.size, size0, 0.05, "the camera returns to its farm size after Back")
	eq(tr["lid"], [true, false], "the hive lid went back on (lid_moved(false))")
	eq(tr["risen"], -1, "the risen frame slid back down")
	for nm in farm_ui:
		ck(_shown(p[nm]), "%s is back after the zoom" % nm)
	ck(_shown(p["ForkIcon"]), "fork shows after Back: Capped cells remain")
	ck(not _shown(p["BackButton"]), "BackButton hidden again on the farm")
	_fin()


# Done when, bucket and pile, lid on, pile auto-load; the whole loop with a 5-frame hive:
#  frame 1 and 2 -> bucket (35, then 70 cells, lid on), frames 3-5 -> pile (105), zoom ends by itself; Spin, crank
#  ceil(jars x 4) real clicks, Continue, bottle 4 jars; the lid lifts, the pile loads 70 (lid on, bucket full);
#  twice more: 35 cells (no zoom open: lid on), then 2 jars. All through real input.
func t_zoom_bucket_lid_pile_flow() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var pile: Node = p["Pile"]
	var truck: Node = p["Truck"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	_set_cfg("max_tap_rate", 20.0)               # CHEAT (Dev): quicker cranking, the cap rules are tested elsewhere
	_set_cfg("bottling_seconds_per_jar", 0.1)    # CHEAT (Dev): quicker bottling
	await _frames(4)
	var cpf: int = _cpf()
	var cap: int = _bucket_cells()
	var total_cells: int = cpf * _frames_n()
	eq(fi.capped_total(hive, _frames_n()), total_cells, "precondition: 5 full frames")
	var jars0: float = _jars_everywhere(p)
	near(jars0, _hive_jars(), 1e-6, "precondition: 10 jars in the hive")
	eq(cen.get("state"), _st(cen, "EMPTY"), "precondition: bucket EMPTY")
	var opened: bool = await _open_zoom(m, p, tr)
	if not opened:
		ck(false, "zoom did not open")
		_fin()
		return
	# frame 1 -> bucket
	var f0: int = await _scrape_risen(m, hive, tr)
	ck(await _next_frame(tr, f0), "frame %d done: the next frame rose" % f0)
	await _wait(float(cv("cell_fly_seconds")) + 0.3)
	eq(cen.get("cells"), cpf, "frame 1: 35 cells in the bucket")
	eq(pile.get("cells"), 0, "frame 1: pile empty")
	eq(cen.get("state"), _st(cen, "LOADING"), "35 cells, room left: LOADING")
	eq(cen.get("lid_open"), true, "lid still off with room left")
	near(float(cen.get("jars")), _jars_of(cpf), 1e-6, "the frame's 2 jars moved from the hive to the bucket")
	near(_jars_everywhere(p), jars0, 1e-6, "no jar lost or made (hive + bucket + pile)")
	# frame 2 -> bucket full -> lid on
	var f1: int = await _scrape_risen(m, hive, tr)
	ck(await _next_frame(tr, f1), "frame %d done: the next frame rose" % f1)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	eq(cen.get("cells"), cap, "frame 2: the bucket holds 2 x 35 cells")
	eq(cen.get("lid_open"), false, "the bucket's lid dropped on when it filled")
	eq(cen.get("state"), _st(cen, "FULL"), "bucket full, lid on: FULL")
	eq(pile.get("cells"), 0, "nothing piled yet")
	# frames 3, 4, 5 -> pile
	var f2: int = await _scrape_risen(m, hive, tr)
	ck(await _next_frame(tr, f2), "frame %d done: the next frame rose" % f2)
	await _wait(float(cv("cell_fly_seconds")) + 0.3)
	eq(cen.get("cells"), cap, "frame 3: the bucket stays at capacity")
	eq(pile.get("cells"), cpf, "frame 3: its 35 cells went to the pile")
	near(float(pile.get("jars")), _jars_of(cpf), 1e-6, "the pile holds the frame's jars")
	var f3: int = await _scrape_risen(m, hive, tr)
	ck(await _next_frame(tr, f3), "frame %d done: the next frame rose" % f3)
	var f4: int = await _scrape_risen(m, hive, tr)
	# the last frame: the zoom ends by itself
	await _wait(float(cv("close_delay_seconds")) + float(cv("zoom_seconds")) + _lid_t() + float(cv("slide_seconds")) + float(cv("cell_fly_seconds")) + 0.8)
	eq(pile.get("cells"), total_cells - cap, "frames 3-5: 105 cells piled")
	eq(fi.capped_total(hive, _frames_n()), 0, "no Capped cell left in the hive")
	eq(tr["raised"], [0, 1, 2, 3, 4], "frames rose in order, one at a time")
	eq(tr["lid"], [true, false], "hive lid off at the start, on at the end of the zoom")
	near(_jars_everywhere(p), jars0, 1e-6, "all 10 jars accounted for: 4 in the bucket, 6 in the pile")
	ck(_shown(p["CentrifugeIcon"]), "the zoom ended on its own: Spin shows")
	ck(_shown(p["MoneyLabel"]), "the farm UI is back")
	ck(not _shown(p["ForkIcon"]), "the hive is empty and no Back was used: the fork is hidden")
	eq(cen.get("state"), _st(cen, "FULL"), "bucket FULL after the zoom")
	# three rounds of spin and bottle: 70 + 70 + 35 cells = 4 + 4 + 2 jars
	var spot: Vector2 = fi.free_spot(m)
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.03
	var want_cells: Array = [cap, cap, total_cells - 2 * cap]   # 70, 70, 35
	var want_pile: Array = [total_cells - 2 * cap, 0, 0]         # 35, 0, 0 left after the load that follows
	var sum_jars: int = 0
	for round_i in 3:
		var cells_now: int = int(cen.get("cells"))
		eq(cells_now, int(want_cells[round_i]), "round %d: the bucket holds %d cells" % [round_i + 1, int(want_cells[round_i])])
		ck(_shown(p["CentrifugeIcon"]), "round %d: Spin shows" % (round_i + 1))
		await fi.click_icon(p["CentrifugeIcon"] as Control)
		await _frames(3)
		eq(cen.get("state"), _st(cen, "CRANKING"), "round %d: tapping Spin starts CRANKING" % (round_i + 1))
		var turns: int = _turns_for(cells_now)
		var sent: int = 0
		var cranking: int = _st(cen, "CRANKING")
		while int(cen.get("state")) == cranking and sent < turns + 6:
			await fi.click_at(spot)
			await _wait(gap)
			sent += 1
		eq(sent, turns, "round %d: ceil(jars x 4) = %d real clicks" % [round_i + 1, turns])
		eq(cen.get("state"), _st(cen, "DONE"), "round %d: DONE" % (round_i + 1))
		await _frames(3)
		ck(_shown(p["ContinueButton"]), "round %d: Continue shows" % (round_i + 1))
		await fi.click_ctl(p["ContinueButton"] as Control)
		var jars_expected: int = int(floorf(_jars_of(cells_now) + 0.000001))
		var summary_shown: bool = await _until(func() -> bool: return _shown(p["SummaryModal"]), 8.0)
		ck(summary_shown, "round %d: the summary shows after the last jar" % (round_i + 1))
		sum_jars += jars_expected
		eq(truck.get("loaded_jars"), sum_jars, "round %d: floor(jars) = %d jars went to the truck" % [round_i + 1, jars_expected])
		await fi.click_ctl(p["SummaryOkButton"] as Control)
		await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.8)
		if round_i < 2:
			eq(pile.get("cells"), int(want_pile[round_i]), "round %d: the pile loaded into the empty bucket by itself (%d cells left)" % [round_i + 1, int(want_pile[round_i])])
			eq(cen.get("lid_open"), false, "round %d: the bucket closed after the load (full, or no zoom open)" % (round_i + 1))
			eq(cen.get("state"), _st(cen, "FULL"), "round %d: FULL again, Spin shows" % (round_i + 1))
		else:
			eq(pile.get("cells"), 0, "round 3: the pile is empty")
			eq(cen.get("state"), _st(cen, "EMPTY"), "round 3: bucket EMPTY")
			eq(cen.get("lid_open"), true, "round 3: the lid lifted off, the bucket is empty and open")
	eq(truck.get("loaded_jars"), int(cv("truck_capacity_jars")), "10 jars on the truck at the end")
	_fin()


# Done when: "lid on at zoom end with a part-full bucket (Back after one frame: 35 cells, 2 jars, lid on, Spin shows)".
func t_back_after_one_frame() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	await _frames(4)
	var cpf: int = _cpf()
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom did not open")
		_fin()
		return
	var f0: int = await _scrape_risen(m, hive, tr)
	ck(await _next_frame(tr, f0), "frame %d done, the next rose" % f0)
	await _wait(float(cv("cell_fly_seconds")) + 0.3)
	eq(cen.get("lid_open"), true, "before Back: lid still off (35 of 70 cells)")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")) + _lid_t())
	eq(cen.get("cells"), cpf, "Back: 35 cells in the bucket")
	near(float(cen.get("jars")), float(cv("frame_jars")), 1e-6, "Back: 2 jars in the bucket")
	eq(cen.get("lid_open"), false, "Back: the lid is on (zoom ended with cells in the bucket)")
	eq(cen.get("state"), _st(cen, "FULL"), "Back: FULL")
	ck(_shown(p["CentrifugeIcon"]), "Back: Spin shows")
	ck(_shown(p["ForkIcon"]), "Back: the fork stays, four frames still hold Capped cells")
	eq(fi.capped_total(hive, _frames_n()), cpf * (_frames_n() - 1), "four full frames remain")
	eq(tr["risen"], -1, "the risen frame went back down")
	_fin()


# Done when: "Back keeps a half-scraped frame's cells; the fork shows while any Capped cell remains".
# One half-scraped frame: it must come up again, same cells, and be finished; then the zoom ends by itself and the fork goes.
func t_back_keeps_half_frame() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	await _frames(4)
	var cpf: int = _cpf()
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom did not open")
		_fin()
		return
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var rws: Array = fi.rows(hc, cam)
	ck(rws.size() >= 2, "the risen frame shows at least two screen rows (%d)" % rws.size())
	if rws.size() < 2:
		_fin()
		return
	eq(tr["risen"], 0, "frame 0 is on display")
	await fi.drag_row(rws[0])
	await fi.drag_row(rws[1])
	await _wait(float(cv("cell_fly_seconds")) + 0.4)
	var left: int = fi.capped(hive, 0)
	ck(left > 0 and left < cpf, "half a frame scraped: %d of %d cells still Capped" % [left, cpf])
	var snapshot: PackedByteArray = hive.call("frame_cells", 0)
	eq(int(cen.get("cells")), cpf - left, "the scraped cells are in the bucket")
	eq(tr["risen"], 0, "the half frame is still up (not done)")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")) + _lid_t())
	eq(hive.call("frame_cells", 0), snapshot, "Back kept the half frame's cells exactly (no reset to Capped)")
	eq(fi.capped(hive, 0), left, "the half frame still has %d Capped cells" % left)
	eq(tr["risen"], -1, "the half frame slid down")
	ck(_shown(p["ForkIcon"]), "the fork shows after Back while Capped cells remain")
	eq(cen.get("lid_open"), false, "Back with cells in the bucket: lid on")
	ck(_shown(p["CentrifugeIcon"]), "Spin shows")
	eq(hive.call("next_frame_to_harvest"), 0, "the half frame is the next to harvest")
	# the way back in: the same frame rises, then the others; at the end the zoom ends by itself and the fork goes
	tr["raised"] = []
	if not await _open_zoom(m, p, tr):
		ck(false, "second zoom did not open")
		_fin()
		return
	eq(tr["risen"], 0, "the half frame rises first on the return")
	for k in _frames_n():
		var f: int = await _scrape_risen(m, hive, tr)
		if k < _frames_n() - 1:
			ck(await _next_frame(tr, f), "frame %d done, the next rose" % f)
	await _wait(float(cv("close_delay_seconds")) + float(cv("zoom_seconds")) + _lid_t() + 1.5)
	eq(fi.capped_total(hive, _frames_n()), 0, "everything scraped")
	ck(not _shown(p["ForkIcon"]), "the zoom ended on its own with no Capped cell: the fork is gone (resume cleared)")
	ck(_shown(p["MoneyLabel"]), "the farm UI is back")
	_fin()


# Done when and step 2: the fork shows whenever the hive is full, at every centrifuge state including CRANKING;
# not at a hive that is not full (no Back yet).
func t_fork_rules() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	cen.set_process(false)
	(p["Truck"] as Node).set_process(false)
	_set_cfg("base_seconds_per_jar", 1.0e9)
	await _frames(4)
	var fork: Node = p["ForkIcon"]
	ck(not _shown(fork), "empty hive, EMPTY centrifuge: no fork")
	hive.call("fill_now")
	await _frames(3)
	ck(hive.call("is_full"), "precondition: hive full")
	ck(_shown(fork), "EMPTY: fork shown at a full hive")
	cen.call("add_cells", _cpf(), _jars_of(_cpf()))
	await _frames(3)
	eq(cen.get("state"), _st(cen, "LOADING"), "precondition: LOADING")
	ck(_shown(fork), "LOADING: fork shown")
	cen.call("add_cells", _bucket_cells() - _cpf(), _jars_of(_bucket_cells() - _cpf()))
	cen.call("close_lid")
	await _frames(3)
	eq(cen.get("state"), _st(cen, "FULL"), "precondition: FULL")
	ck(_shown(fork), "FULL: fork shown (cells will pile up)")
	cen.call("begin_crank")
	await _frames(3)
	eq(cen.get("state"), _st(cen, "CRANKING"), "precondition: CRANKING")
	ck(_shown(fork), "CRANKING: fork shown at a full hive")
	_crank_done(cen)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "DONE"), "precondition: DONE")
	ck(_shown(fork), "DONE: fork shown")
	cen.call("open_spigot")
	await _frames(3)
	eq(cen.get("state"), _st(cen, "BOTTLING"), "precondition: BOTTLING")
	ck(_shown(fork), "BOTTLING: fork shown")
	# not full any more: hidden at every state (a scrape without the zoom, so no Back has set the resume flag)
	hive.call("scrape", 0, 0)
	await _frames(3)
	ck(not hive.call("is_full"), "precondition: the hive is no longer full")
	ck(not _shown(fork), "BOTTLING, hive not full, no Back: fork hidden")
	_fin()


# State table with LOADING and the lid, and the farm icons during the zoom (Spin and Continue are farm-only).
func t_fork_shows_while_cranking_and_state_table() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var truck: Node = p["Truck"]
	var tr: Dictionary = _track(hive)
	cen.set_process(false)
	truck.set_process(false)
	_full_hive_frozen(hive)
	await _frames(4)
	var cicon: Node = p["CentrifugeIcon"]
	var cont: Node = p["ContinueButton"]
	var sell: Node = p["SellIcon"]
	eq(_shown(sell), bool(truck.call("can_sell")), "EMPTY: Sell icon follows the truck")
	ck(not _shown(cicon) and not _shown(cont), "EMPTY: Spin and Continue hidden")
	eq(cen.get("lid_open"), true, "EMPTY: lid off")
	cen.call("add_cells", _cpf(), _jars_of(_cpf()))
	await _frames(3)
	ck(not _shown(cicon) and not _shown(cont), "LOADING: Spin and Continue hidden")
	eq(cen.get("lid_open"), true, "LOADING: lid off")
	cen.call("add_cells", _bucket_cells() - _cpf(), _jars_of(_bucket_cells() - _cpf()))
	cen.call("close_lid")
	await _frames(3)
	ck(_shown(cicon), "FULL: Spin shows (farm)")
	ck(not _shown(cont), "FULL: Continue hidden")
	eq(cen.get("lid_open"), false, "FULL: lid on")
	# zoom open: Spin hidden
	ck(await _open_zoom(m, p, tr), "zoom opened with a FULL bucket")
	ck(not _shown(cicon), "zoom: Spin hidden (farm only)")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	ck(_shown(cicon), "after the zoom: Spin shows again")
	cen.call("begin_crank")
	await _frames(3)
	ck(not _shown(cicon) and not _shown(cont), "CRANKING: Spin and Continue hidden")
	_crank_done(cen)
	await _frames(3)
	ck(_shown(cont), "DONE: Continue shown")
	ck(not _shown(cicon), "DONE: Spin hidden")
	for i in int(cv("truck_capacity_jars")):
		truck.call("receive_jar")
	await _frames(3)
	ck(_shown(sell), "DONE: Sell icon shown once the truck is full and home")
	tr["raised"] = []
	ck(await _open_zoom(m, p, tr), "zoom opened at DONE")
	ck(not _shown(cont), "zoom: Continue hidden (farm only)")
	ck(not _shown(sell), "zoom: Sell icon hidden (farm UI)")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	ck(_shown(cont), "after the zoom: Continue shows again")
	cen.call("open_spigot")
	await _frames(3)
	ck(not _shown(cicon) and not _shown(cont), "BOTTLING: Spin and Continue hidden")
	truck.call("sell")
	await _frames(3)
	ck(not _shown(sell), "truck away: Sell icon hidden")
	_fin()


# Step 3: "crank input never counts (a drag on a frame is never a crank turn), cranking stops counting until the zoom ends".
# Cells scraped while CRANKING go to the pile.
func t_no_crank_during_zoom() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var pile: Node = p["Pile"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	await _frames(4)
	_to_cranking(cen)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "CRANKING"), "precondition: CRANKING")
	ck(_shown(p["ForkIcon"]), "CRANKING at a full hive: the fork shows")
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.03
	var spot: Vector2 = fi.free_spot(m)
	await fi.click_at(spot)
	eq(cen.get("turns_counted"), 1, "positive control: one real click on the farm counts one turn")
	await _wait(gap)
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom did not open while CRANKING")
		_fin()
		return
	eq(cen.get("crank_enabled"), false, "crank_enabled is false during the zoom")
	var zspot: Vector2 = fi.free_spot(m)
	for i in 5:
		await fi.click_at(zspot)
		await _wait(gap)
	_push_mouse(zspot, true)
	await _wait(1.0)
	_push_mouse(zspot, false)
	eq(cen.get("turns_counted"), 1, "clicks and a hold during the zoom counted no turn")
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var rws: Array = fi.rows(hc, cam)
	if rws.size() > 0:
		await fi.drag_row(rws[0])
	await _wait(float(cv("cell_fly_seconds")) + 0.4)
	eq(cen.get("turns_counted"), 1, "a drag across the frame is never a crank turn")
	ck(int(pile.get("cells")) > 0, "cells scraped while CRANKING went to the pile (%s)" % str(pile.get("cells")))
	eq(cen.get("cells"), _bucket_cells(), "the cranking bucket took no cell")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	eq(cen.get("crank_enabled"), true, "crank_enabled is true again after the zoom")
	await fi.click_at(fi.free_spot(m))
	eq(cen.get("turns_counted"), 2, "after the zoom a real click counts again")
	_fin()


# Step 3: "bottling, the truck and the hive fill keep running" during the zoom; the risen frame never fills.
func t_zoom_fill_and_bottling_keep_running() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var truck: Node = p["Truck"]
	var tr: Dictionary = _track(hive)
	hive.call("fill_now")
	_set_cfg("base_seconds_per_jar", 1.5)       # CHEAT (Dev): honey arrives slowly but visibly
	await _frames(4)
	_to_cranking(cen)
	_crank_done(cen)
	cen.call("open_spigot")
	await _frames(3)
	eq(cen.get("state"), _st(cen, "BOTTLING"), "precondition: BOTTLING")
	ck(_shown(p["ForkIcon"]), "BOTTLING at a full hive: the fork shows")
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom did not open while BOTTLING")
		_fin()
		return
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var rws: Array = fi.rows(hc, cam)
	if rws.size() > 0:
		await fi.drag_row(rws[0])
	await _wait(float(cv("cell_fly_seconds")) + 0.4)
	var f: int = int(tr["risen"])
	var risen_capped: int = fi.capped(hive, f)
	var ov0: float = float(hive.get("overflow"))
	var jars0: int = int(truck.get("loaded_jars")) + int(truck.get("crate_jars"))
	var state0: int = int(cen.get("state"))
	await _wait(4.0)
	ck(float(hive.get("overflow")) > ov0 + 0.5, "the hive keeps filling during the zoom: overflow %s -> %s" % [str(ov0), str(hive.get("overflow"))])
	eq(fi.capped(hive, f), risen_capped, "the risen frame took none of that honey (still %d Capped)" % risen_capped)
	var jars1: int = int(truck.get("loaded_jars")) + int(truck.get("crate_jars"))
	ck(jars1 > jars0 or int(cen.get("state")) != state0, "bottling keeps running during the zoom: jars %d -> %d" % [jars0, jars1])
	_fin()


# Done when: "the pop tween's parameters (1.3 -> 1, 0.18 s, back-out) are unchanged". Measured on a real scrape: the scraped
# cell's global scale (relative to before the scrape) follows Tween.interpolate_value(1.3, -0.3, t, 0.18, BACK, OUT).
# The test shows it can fail: three altered pops (peak 1.5, 0.36 s, sine easing) must each miss the tolerance on the same samples.
func t_pop_tween_unchanged() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	await _frames(4)
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom did not open")
		_fin()
		return
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	if not hc.has_signal("cell_scraped"):
		ck(false, "honeycomb.gd has no signal cell_scraped(cell, jar_value, world_position) (spec: Contract)")
		_fin()
		return
	var base: Dictionary = {}
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		base[mi] = (mi as Node3D).global_transform.basis.get_scale().x
	var rec: Dictionary = {"t0": -1, "wp": Vector3.ZERO, "node": null, "samples": [], "n": 0}
	hc.connect("cell_scraped", func(_c: Variant, _v: Variant, wp: Variant) -> void:
		rec["n"] = int(rec["n"]) + 1
		if int(rec["t0"]) < 0:
			rec["t0"] = Time.get_ticks_usec()
			rec["wp"] = wp)
	var cs: Array[Node3D] = fi.cells(hc)
	if cs.size() == 0:
		ck(false, "no cell colliders under Honeycomb")
		_fin()
		return
	var target: Node3D = cs[cs.size() / 2]
	var pt: Vector2 = cam.unproject_position(target.global_position)
	fi.mouse_button(pt, true)
	var t_end: int = Time.get_ticks_usec() + 400000
	while Time.get_ticks_usec() < t_end:
		await process_frame
		if int(rec["t0"]) < 0:
			continue
		if rec["node"] == null:
			var best: float = 1.0e9
			for mi in base:
				if is_instance_valid(mi):
					best = minf(best, ((mi as Node3D).global_position - (rec["wp"] as Vector3)).length())
			var pick: Node3D = null
			var dev: float = -1.0
			for mi in base:
				if is_instance_valid(mi) and ((mi as Node3D).global_position - (rec["wp"] as Vector3)).length() <= best + 0.02:
					var d: float = absf((mi as Node3D).global_transform.basis.get_scale().x / float(base[mi]) - 1.0)
					if d > dev:
						dev = d
						pick = mi as Node3D
			rec["node"] = pick
		var node: Node3D = rec["node"]
		if node != null and is_instance_valid(node):
			var t: float = float(Time.get_ticks_usec() - int(rec["t0"])) / 1.0e6
			(rec["samples"] as Array).append([t, node.global_transform.basis.get_scale().x / float(base[node])])
	fi.mouse_button(pt, false)
	ck(int(rec["n"]) >= 1, "a real press on a cell scraped it (cell_scraped emitted)")
	var samples: Array = []
	for s in (rec["samples"] as Array):
		if float((s as Array)[0]) <= 0.175:
			samples.append(s)
	ck(samples.size() >= 4, "enough samples inside the 0.18 s pop (%d)" % samples.size())
	if samples.size() < 4:
		_fin()
		return
	var skew: float = 0.0
	for i in range(1, samples.size()):
		skew = maxf(skew, float((samples[i] as Array)[0]) - float((samples[i - 1] as Array)[0]))
	skew = minf(maxf(skew, 0.004), 0.03)
	var tol: float = 0.04
	var real_dev: float = _pop_dev(samples, 1.3, 0.18, Tween.TRANS_BACK, skew)
	ck(real_dev <= tol, "the pop follows 1.3 -> 1 over 0.18 s, back-out: worst deviation %.3f (tolerance %.2f, %d samples)" % [real_dev, tol, samples.size()])
	var peak: float = 0.0
	for s in samples:
		peak = maxf(peak, float((s as Array)[1]))
	ck(peak >= 1.2 and peak <= 1.32, "the pop starts near 1.3 (peak %.3f)" % peak)
	# the test can fail: altered pops would not pass on these samples
	ck(_pop_dev(samples, 1.5, 0.18, Tween.TRANS_BACK, skew) > tol, "self-check: a pop of 1.5 would be caught")
	ck(_pop_dev(samples, 1.3, 0.36, Tween.TRANS_BACK, skew) > tol, "self-check: a 0.36 s pop would be caught")
	ck(_pop_dev(samples, 1.3, 0.18, Tween.TRANS_SINE, skew) > tol, "self-check: sine easing instead of back-out would be caught")
	_fin()


## Worst distance between sampled scale and the curve initial=peak -> 1 over dur, allowing +-skew of time (one frame).
func _pop_dev(samples: Array, peak: float, dur: float, trans: int, skew: float) -> float:
	var worst: float = 0.0
	for s in samples:
		var t: float = float((s as Array)[0])
		var best: float = 99.0
		for off in [-skew, 0.0, skew]:
			var tt: float = clampf(t + off, 0.0, dur)
			var expv: float = float(Tween.interpolate_value(peak, 1.0 - peak, tt, dur, trans, Tween.EASE_OUT))
			best = minf(best, absf(float((s as Array)[1]) - expv))
		worst = maxf(worst, best)
	return worst


# Accessibility / play-test item 7: every touch button has StyleBoxEmpty as its focus style and focus_mode None, so a
# focused disabled button cannot look enabled. The pixel half (the disabled colour of a button that was told to grab
# focus) is in play_loop.gd.
func t_focus_styles() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	for nm in ["UpgradeButton", "ContinueButton", "ForkIcon", "CentrifugeIcon", "SellIcon", "SummaryOkButton", "BackButton"]:
		var b: Node = _nn(m, nm)
		if b == null or not (b is Button):
			ck(false, "%s is not a Button" % nm)
			continue
		var btn: Button = b as Button
		eq(btn.focus_mode, Control.FOCUS_NONE, "%s focus_mode = None" % nm)
		ck(btn.get_theme_stylebox("focus") is StyleBoxEmpty, "%s: focus style is StyleBoxEmpty (got %s)" % [nm, str(btn.get_theme_stylebox("focus"))])
		btn.grab_focus()
		ck(not btn.has_focus(), "%s: grab_focus() does not take focus" % nm)
	_fin()


# Accessibility: icons keep a touch area of at least 120 x 120 whatever their visible size; the visible size is smaller.
func t_icon_touch_area_in_scene() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	ck(float(cv("icon_visual_px")) < 120.0, "icon_visual_px (%s) is below the 120 px touch area" % str(cv("icon_visual_px")))
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon"]:
		var c: Node = _nn(m, nm)
		if c != null and c is Control:
			var s: Vector2 = (c as Control).size
			ck(s.x >= 120.0 and s.y >= 120.0, "%s touch area at least 120 x 120 (%s)" % [nm, str(s)])
	_fin()


# Look: "the wheels turn while the truck drives, and their roll matches the direction of travel both ways (no skid)".
# No-skid means the contact point is at rest: v = omega x up (for a wheel of radius 1), so dot(omega x up, v) > 0 on the
# drive-off leg AND on the return leg. omega comes from the wheel's global basis between frames, v from its global position.
func t_truck_wheels_roll_with_travel() -> void:
	var ps: Variant = load("res://scenes/props/truck.tscn")
	ck(ps != null, "res://scenes/props/truck.tscn failed to load (spec: Models as reusable scenes)")
	if ps == null:
		_fin()
		return
	var tk: Node = (ps as PackedScene).instantiate()
	root.add_child(tk)
	_to_free.append(tk)
	_give_config(tk)
	await _frames(3)
	_set_cfg("truck_trip_seconds", 6.0)         # CHEAT (Dev): a short trip, slow enough that a wheel turns < 1 rad per frame
	_set_cfg("truck_slide_distance", 10.0)
	var names: Array = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	var cand: Dictionary = {}                   # wheel name -> Array of nodes (the wheel node and its Node3D descendants)
	for nm in names:
		var w: Node = tk.find_child(nm, true, false)
		ck(w != null, "truck.tscn has no node %s (spec)" % nm)
		if w == null:
			_fin()
			return
		var list: Array = [w]
		for d in w.find_children("*", "Node3D", true, false):
			list.append(d)
		cand[nm] = list
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	var series: Dictionary = {}                 # name -> Array of [pos, [basis per candidate]]
	for nm in names:
		series[nm] = []
	tk.call("sell")
	var t_end: int = Time.get_ticks_msec() + int((float(cv("truck_trip_seconds")) + 1.0) * 1000.0)
	while Time.get_ticks_msec() < t_end:
		await process_frame
		for nm in names:
			var bases: Array = []
			for n in (cand[nm] as Array):
				bases.append((n as Node3D).global_transform.basis)
			(series[nm] as Array).append([((cand[nm] as Array)[0] as Node3D).global_position, bases])
	for nm in names:
		var sr: Array = series[nm]
		ck(sr.size() > 20, "%s: enough frames sampled (%d)" % [nm, sr.size()])
		if sr.size() <= 20:
			continue
		var start: Vector3 = (sr[0] as Array)[0]
		var far_i: int = 0
		var far_d: float = 0.0
		for i in sr.size():
			var d: float = (((sr[i] as Array)[0]) as Vector3).distance_to(start)
			if d > far_d:
				far_d = d
				far_i = i
		ck(far_d > 1.0, "%s: the truck drove away (%.2f units)" % [nm, far_d])
		# the spinning node of this wheel: the candidate that turned the most
		var spin_k: int = 0
		var spin_tot: float = -1.0
		for k in (cand[nm] as Array).size():
			var tot: float = 0.0
			for i in range(1, sr.size()):
				var q: Quaternion = ((((sr[i] as Array)[1] as Array)[k] as Basis) * ((((sr[i - 1] as Array)[1] as Array)[k] as Basis).inverse())).orthonormalized().get_rotation_quaternion()
				tot += 2.0 * acos(clampf(absf(q.w), 0.0, 1.0))
			if tot > spin_tot:
				spin_tot = tot
				spin_k = k
		ck(spin_tot > 1.0, "%s: the wheel turned while the truck drove (total %.2f rad)" % [nm, spin_tot])
		var good: Array = [0, 0]
		var bad: Array = [0, 0]
		for i in range(1, sr.size()):
			var v: Vector3 = (((sr[i] as Array)[0]) as Vector3) - (((sr[i - 1] as Array)[0]) as Vector3)
			if v.length() < 1.0e-4:
				continue
			var b1: Basis = ((sr[i] as Array)[1] as Array)[spin_k]
			var b0: Basis = ((sr[i - 1] as Array)[1] as Array)[spin_k]
			var q: Quaternion = (b1 * b0.inverse()).orthonormalized().get_rotation_quaternion()
			if q.w < 0.0:
				q = -q
			var ang: float = 2.0 * acos(clampf(q.w, 0.0, 1.0))
			if ang < 1.0e-3:
				continue
			var axis: Vector3 = Vector3(q.x, q.y, q.z).normalized()
			var leg: int = 0 if i <= far_i else 1
			if (axis * ang).cross(Vector3.UP).dot(v) > 0.0:
				good[leg] += 1
			else:
				bad[leg] += 1
		ck(int(good[0]) + int(bad[0]) >= 5, "%s: the drive-off leg has measurable samples (%s)" % [nm, str([good[0], bad[0]])])
		ck(int(good[1]) + int(bad[1]) >= 5, "%s: the return leg has measurable samples (%s)" % [nm, str([good[1], bad[1]])])
		eq(bad[0], 0, "%s: drive-off leg: every sample rolls with the travel (no skid); %d good" % [nm, good[0]])
		eq(bad[1], 0, "%s: return leg: every sample rolls with the travel (no skid); %d good" % [nm, good[1]])
	_fin()


# Dev mode, new action: "Show UI bounds" toggle (outlines drawn on a top CanvasLayer). Behaviour only: toggling on adds
# visible drawing, toggling off removes it. The look is in the screenshot.
func t_dev_show_ui_bounds() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var panel: Node = _find_dev_panel(m)
	ck(panel != null, "dev panel exists")
	if panel == null:
		_fin()
		return
	var btn: Button = _button_with(panel, "bounds")
	ck(btn != null, "no Button with 'bounds' in its text (the Show UI bounds action)")
	if btn == null:
		_fin()
		return
	var count_vis: Callable = func() -> int:
		var k: int = 0
		for n in root.find_children("*", "CanvasItem", true, false):
			if (n as CanvasItem).is_visible_in_tree():
				k += 1
		return k
	await _frames(3)
	var before: int = count_vis.call()
	btn.pressed.emit()
	await _frames(4)
	var on: int = count_vis.call()
	ck(on > before, "Show UI bounds on: visible drawing was added (%d -> %d)" % [before, on])
	btn.pressed.emit()
	await _frames(4)
	var off: int = count_vis.call()
	eq(off, before, "Show UI bounds off: the outlines are gone")
	_fin()


# ---------------------------------------------------------------- floating icons (unchanged)

func _mk_icon_rig(anchor_pos: Vector3, ortho: bool) -> Dictionary:
	var cam := Camera3D.new()
	if ortho:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 10.0
	cam.position = Vector3(0.0, 10.0, 0.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(cam)
	cam.current = true
	var marker := Marker3D.new()
	marker.position = anchor_pos
	root.add_child(marker)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var icon: Object = _make("floating_icon.gd")
	if icon != null:
		icon.set("anchor_path", marker.get_path())
		icon.set("screen_offset", Vector2.ZERO)
		(icon as Control).custom_minimum_size = Vector2(120.0, 120.0)
		layer.add_child(icon as Node)
	_to_free.append(cam)
	_to_free.append(marker)
	_to_free.append(layer)
	await _frames(4)
	return {"cam": cam, "marker": marker, "icon": icon}


# L127: the icon places itself at camera.unproject_position(anchor.global_position) + screen_offset.
# Relative checks (the spec does not say whether that point is the icon's corner or its centre).
func t_icon_follows_anchor() -> void:
	var rig: Dictionary = await _mk_icon_rig(Vector3(0.0, 0.0, 0.0), true)
	var icon: Object = rig["icon"]
	var cam: Camera3D = rig["cam"]
	var marker: Marker3D = rig["marker"]
	if icon == null:
		_fin()
		return
	var p0: Vector2 = (icon as Control).global_position
	var s0: Vector2 = cam.unproject_position(marker.global_position)
	marker.position = Vector3(2.0, 0.0, -1.5)
	await _frames(3)
	var s1: Vector2 = cam.unproject_position(marker.global_position)
	var p1: Vector2 = (icon as Control).global_position
	ck(s1.distance_to(s0) > 20.0, "rig: the anchor moved on screen (%s)" % str(s1 - s0))
	near(p1.x - p0.x, s1.x - s0.x, "icon moved with the anchor in x", 1.5)
	near(p1.y - p0.y, s1.y - s0.y, "icon moved with the anchor in y", 1.5)
	icon.set("screen_offset", Vector2(0.0, -80.0))
	await _frames(3)
	var p2: Vector2 = (icon as Control).global_position
	near(p2.x - p1.x, 0.0, "screen_offset x applied", 1.5)
	near(p2.y - p1.y, -80.0, "screen_offset y applied", 1.5)
	_fin()


# L127: hides when the anchor is behind the camera.
func t_icon_hidden_behind_camera() -> void:
	var rig: Dictionary = await _mk_icon_rig(Vector3(0.0, 0.0, 0.0), false)
	var icon: Object = rig["icon"]
	var marker: Marker3D = rig["marker"]
	if icon == null:
		_fin()
		return
	ck((icon as Control).is_visible_in_tree(), "icon visible with the anchor in front of the camera")
	marker.position = Vector3(0.0, 30.0, 0.0)   # the camera sits at y = 10 looking down: this is behind it
	await _frames(3)
	ck(not (icon as Control).is_visible_in_tree(), "icon hidden with the anchor behind the camera")
	marker.position = Vector3(0.0, 0.0, 0.0)
	await _frames(3)
	ck((icon as Control).is_visible_in_tree(), "icon visible again once the anchor is back in front")
	_fin()


# ---------------------------------------------------------------- config and dev mode

func _load_script_static(file: String, method: String) -> Variant:
	var s: Variant = load(_script_path(file))
	ck(s != null, "%s failed to load" % file)
	if s == null:
		return null
	return (s as GDScript).call(method)

# L213: the project setting exists and is true for prototypes.
func t_dev_mode_setting() -> void:
	ck(ProjectSettings.has_setting(DEV_SETTING), "project setting %s does not exist" % DEV_SETTING)
	if ProjectSettings.has_setting(DEV_SETTING):
		eq(ProjectSettings.get_setting(DEV_SETTING), true, "chill_bee/dev_mode is true for prototypes")
	_fin()


func _find_dev_panel(m: Node) -> Node:
	for n in m.find_children("*", "", true, false):
		var s: Variant = n.get_script()
		if s != null and (s as Script).resource_path.ends_with("dev_panel.gd"):
			return n
	for n in root.find_children("*", "", true, false):
		var s2: Variant = n.get_script()
		if s2 != null and (s2 as Script).resource_path.ends_with("dev_panel.gd"):
			return n
	return null


func _set_dev_mode(on: bool) -> void:
	if not _setting_touched:
		_setting_saved = ProjectSettings.get_setting(DEV_SETTING, true)
		_setting_touched = true
	ProjectSettings.set_setting(DEV_SETTING, on)


# L213: with chill_bee/dev_mode false the panel and its input are never created.
func t_dev_no_panel_when_off() -> void:
	_set_dev_mode(false)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	await _frames(5)
	ck(_find_dev_panel(m) == null, "no dev_panel node exists with chill_bee/dev_mode false")
	var k := InputEventKey.new()
	k.keycode = KEY_QUOTELEFT
	k.physical_keycode = KEY_QUOTELEFT
	k.pressed = true
	root.push_input(k)
	await _frames(3)
	ck(_find_dev_panel(m) == null, "the backquote key creates nothing when dev mode is off")
	_fin()


# L214: with dev mode on, main.gd adds the panel at start (positive control for the test above).
func t_dev_panel_when_on() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	ck(_find_dev_panel(m) != null, "a dev_panel.gd node exists with chill_bee/dev_mode true")
	_fin()


## Find the SpinBox of the panel row whose label names `prop` (label text normalised: lower case, letters and digits only).
## The spec does not say how rows are named or nested; this matches the label text against the property name.
func _row_spin(panel: Node, prop: String) -> SpinBox:
	var want: String = prop.to_lower().replace("_", "")
	for l in panel.find_children("*", "Label", true, false):
		var norm: String = ""
		for ch in (l as Label).text.to_lower():
			if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
				norm += ch
		if norm.contains(want):
			var p: Node = l.get_parent()
			while p != null and p != panel.get_parent():
				var spins: Array = p.find_children("*", "SpinBox", true, false)
				if spins.size() == 1:
					return spins[0] as SpinBox
				if spins.size() > 1:
					return null
				p = p.get_parent()
	return null


func _button_with(panel: Node, needle: String) -> Button:
	for b in panel.find_children("*", "Button", true, false):
		if (b as Button).text.to_lower().contains(needle.to_lower()):
			return b as Button
	return null


func _mk_panel() -> Node:
	var p: Object = _make("dev_panel.gd")
	if p == null:
		return null
	_give_config(p)
	root.add_child(p as Node)
	await _frames(3)
	return p as Node


# L215: editing max_tap_rate through the panel changes the next counted tap.
func t_dev_max_tap_rate() -> void:
	_set_dev_mode(true)
	var panel: Node = await _mk_panel()
	var c: Object = await _mk_cen()
	if panel == null or c == null:
		_fin()
		return
	var rate: float = float(cv("max_tap_rate"))
	var spin: SpinBox = _row_spin(panel, "max_tap_rate")
	ck(spin != null, "dev panel has no single SpinBox row labelled max_tap_rate")
	if spin == null:
		_fin()
		return
	_cfg_saved["max_tap_rate"] = rate
	spin.value = rate * 2.0
	eq(float(cv("max_tap_rate")), rate * 2.0, "panel edit reached the live config")
	_to_cranking(c)
	ck(c.call("tap"), "first tap counts")
	c.call("advance", 1.2 / (rate * 2.0))
	ck(c.call("tap"), "next tap after 1.2 / new rate counts (old cap would ignore it)")
	_fin()


# L215: editing bottling_seconds_per_jar through the panel changes the next jar.
func t_dev_bottling_seconds() -> void:
	_set_dev_mode(true)
	var panel: Node = await _mk_panel()
	var c: Object = await _mk_cen()
	if panel == null or c == null:
		_fin()
		return
	var spj: float = float(cv("bottling_seconds_per_jar"))
	var spin: SpinBox = _row_spin(panel, "bottling_seconds_per_jar")
	ck(spin != null, "dev panel has no single SpinBox row labelled bottling_seconds_per_jar")
	if spin == null:
		_fin()
		return
	_cfg_saved["bottling_seconds_per_jar"] = spj
	spin.value = spj * 2.0
	eq(float(cv("bottling_seconds_per_jar")), spj * 2.0, "panel edit reached the live config")
	_to_cranking(c)
	_tap_spaced(c, _turns_for(_bucket_cells()), _tap_gap())
	var times: Array = []
	var clock: Array = [0.0]
	c.connect("jar_bottled", func(_n: Variant) -> void: times.append(clock[0]))
	c.call("open_spigot")
	var dt: float = 0.05
	while times.size() < 1 and clock[0] < spj * 6.0:
		clock[0] += dt
		c.call("advance", dt)
	eq(times.size(), 1, "a jar was bottled")
	if times.size() == 1:
		near(float(times[0]), spj * 2.0, "the next jar takes the edited time", dt * 3.0)
	_fin()


# L212: Save writes user://dev_config.tres, which loads over the defaults at the next config load;
# Reset to defaults deletes it. The spec names no API: buttons are found by their text, "a new config load"
# is GameConfig.load_default().
func t_dev_save_reset_roundtrip() -> void:
	_set_dev_mode(true)
	var panel: Node = await _mk_panel()
	if panel == null:
		_fin()
		return
	var spin: SpinBox = _row_spin(panel, "max_tap_rate")
	var save: Button = _button_with(panel, "save")
	var reset: Button = _button_with(panel, "default")
	ck(spin != null, "dev panel has no single SpinBox row labelled max_tap_rate")
	ck(save != null, "dev panel has no Button with 'Save' in its text")
	ck(reset != null, "dev panel has no Button with 'default' in its text (Reset to defaults)")
	if spin == null or save == null or reset == null:
		_fin()
		return
	var def: Variant = load(DEFAULT_CFG)
	var rate_default: float = float(def.get("max_tap_rate"))
	_cfg_saved["max_tap_rate"] = float(cv("max_tap_rate"))
	var edited: float = rate_default * 3.0
	spin.value = edited
	save.pressed.emit()
	ck(FileAccess.file_exists(USER_CFG), "Save wrote user://dev_config.tres")
	var fresh: Variant = _load_script_static("game_config.gd", "load_default")
	ck(fresh != null, "GameConfig.load_default() returned null")
	if fresh != null:
		near(float(fresh.get("max_tap_rate")), edited, "a new config load carries the saved value over the default")
		near(float(fresh.get("taps_per_jar")), float(def.get("taps_per_jar")), "an unedited value stays at its default")
	reset.pressed.emit()
	ck(not FileAccess.file_exists(USER_CFG), "Reset to defaults deleted user://dev_config.tres")
	var fresh2: Variant = _load_script_static("game_config.gd", "load_default")
	if fresh2 != null:
		near(float(fresh2.get("max_tap_rate")), rate_default, "after Reset a new config load is the default again")
	_fin()


# L213: with dev mode off, user://dev_config.tres is ignored.
func t_dev_user_file_ignored_when_off() -> void:
	var def: Variant = load(DEFAULT_CFG)
	var tweaked: Variant = def.duplicate()
	var rate_default: float = float(def.get("max_tap_rate"))
	tweaked.set("max_tap_rate", rate_default * 3.0)
	var err: int = ResourceSaver.save(tweaked, USER_CFG)
	eq(err, OK, "test wrote a user://dev_config.tres")
	_set_dev_mode(true)
	var on_cfg: Variant = _load_script_static("game_config.gd", "load_default")
	if on_cfg != null:
		near(float(on_cfg.get("max_tap_rate")), rate_default * 3.0, "dev mode on: the user file loads (positive control)")
	_set_dev_mode(false)
	var off_cfg: Variant = _load_script_static("game_config.gd", "load_default")
	ck(off_cfg != null, "load_default() returned a config with dev mode off")
	if off_cfg != null:
		near(float(off_cfg.get("max_tap_rate")), rate_default, "dev mode off: user://dev_config.tres is ignored")
	_fin()


func _panel_open(p: Node) -> bool:
	if p is CanvasLayer:
		return (p as CanvasLayer).visible
	if p is CanvasItem:
		return (p as CanvasItem).is_visible_in_tree()
	return true


# L209: the backquote key opens the panel (desktop).
func t_dev_backquote_opens() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Node = _find_dev_panel(m)
	ck(p != null, "dev panel exists")
	if p == null:
		_fin()
		return
	if _panel_open(p):
		ck(false, "panel is already open at start: cannot tell whether the key opens it (spec does not say if it starts hidden)")
		_fin()
		return
	var k := InputEventKey.new()
	k.keycode = KEY_QUOTELEFT
	k.physical_keycode = KEY_QUOTELEFT
	k.pressed = true
	root.push_input(k)
	var k2 := InputEventKey.new()
	k2.keycode = KEY_QUOTELEFT
	k2.physical_keycode = KEY_QUOTELEFT
	k2.pressed = false
	root.push_input(k2)
	await _frames(3)
	ck(_panel_open(p), "the backquote key opened the dev panel")
	_fin()


# L209: a three-finger tap opens the panel (phone).
func t_dev_three_finger_opens() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Node = _find_dev_panel(m)
	ck(p != null, "dev panel exists")
	if p == null:
		_fin()
		return
	if _panel_open(p):
		ck(false, "panel is already open at start: cannot tell whether the tap opens it")
		_fin()
		return
	for i in 3:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.pressed = true
		t.position = (EMPTY_SPOT + Vector2(80.0 * i, 0.0)) * _to_window()
		root.push_input(t)
	await _frames(2)
	for i in 3:
		var t2 := InputEventScreenTouch.new()
		t2.index = i
		t2.pressed = false
		t2.position = (EMPTY_SPOT + Vector2(80.0 * i, 0.0)) * _to_window()
		root.push_input(t2)
	await _frames(3)
	ck(_panel_open(p), "a three-finger tap opened the dev panel")
	_fin()


# L211: actions: +$100, fill the hive now, game speed (Engine.time_scale). Buttons found by their text.
func t_dev_actions() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Node = _find_dev_panel(m)
	ck(p != null, "dev panel exists")
	if p == null:
		_fin()
		return
	var e: Node = _eco()
	var plus: Button = _button_with(p, "$100")
	var fillb: Button = _button_with(p, "fill")
	var fast: Button = _button_with(p, "5")
	ck(plus != null, "no Button with '$100' (the +$100 action)")
	ck(fillb != null, "no Button with 'fill' (fill the hive now)")
	ck(fast != null, "no Button with '5' (game speed x5)")
	if plus != null:
		var m0: int = int(e.get("money"))
		plus.pressed.emit()
		eq(e.get("money"), m0 + 100, "+$100 action")
	if fillb != null:
		fillb.pressed.emit()
		await _frames(2)
		var hive: Node = _nn(m, "Hive")
		ck(hive != null and hive.call("is_full"), "fill the hive now fills it")
		if hive != null:
			eq(_profile(hive), [_cpf(), _cpf(), _cpf(), _cpf(), _cpf()].slice(0, _frames_n()), "Fill hive now fills all 5 frames")
	if fast != null:
		fast.pressed.emit()
		eq(Engine.time_scale, 5.0, "game speed x5 sets Engine.time_scale")
	_fin()


# Patricia's confirmation (0.1), requested test 1: a scrape inside the 0.18 s pop window, followed by Back before the pop ends.
# The scrape moves its jar value at once (logic never waits for tweens), so Back must not lose, double or strand the cell: its slot
# reads Extracted, its jars are in the bucket (or the pile) exactly once, no flying cell is left over, the lid is on.
# Real input only: a real press on the cell, then a real click on BackButton, inside the pop (Engine.time_scale slows the game to
# 0.1 so "inside 0.18 s of game time" holds even on a slow frame; the test measures the game time between the two events).
func _scrape_back_in_pop(to_pile: bool) -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var pile: Node = p["Pile"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	var cap: int = _bucket_cells()
	if to_pile:
		cen.call("add_cells", cap, _jars_of(cap))   # CHEAT: a full bucket, so the scraped cell goes to the pile
		cen.call("close_lid")
	await _frames(4)
	var jars0: float = _jars_everywhere(p)
	var kids0: Array = root.get_children()
	var cells0: int = int(cen.get("cells"))
	var pile0: int = int(pile.get("cells"))
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom did not open")
		_fin()
		return
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var body: Node3D = null
	for c in hc.find_children("*", "CollisionObject3D", true, false):
		if c.has_meta("cell_index") and int(c.get_meta("cell_index")) == 17:
			body = c as Node3D
	ck(body != null, "cell 17 has a collider with its cell_index")
	if body == null:
		_fin()
		return
	var at: Vector2 = cam.unproject_position(body.global_position)
	Engine.time_scale = 0.1
	var t0: int = Time.get_ticks_msec()
	fi.mouse_button(at, true)
	await process_frame
	fi.mouse_button(at, false)
	await process_frame
	var capped_after: int = fi.capped(hive, 0)
	var state17: int = int(hive.call("frame_cells", 0)[17])
	await fi.click_ctl(p["BackButton"] as Control)
	var game_s: float = float(Time.get_ticks_msec() - t0) / 1000.0 * 0.1
	Engine.time_scale = 1.0
	ck(game_s < 0.18, "Back was clicked %.3f game-seconds after the scrape, inside the 0.18 s pop" % game_s)
	eq(capped_after, _cpf() - 1, "the real press scraped exactly one cell")
	eq(state17, 2, "the slot reads Extracted (2) at once, before the pop ends")
	await _wait(_zoom_settle() + float(cv("zoom_seconds")) + _lid_t() + float(cv("cell_fly_seconds")) + 0.6)
	var f0: PackedByteArray = hive.call("frame_cells", 0)
	eq(int(f0[17]), 2, "after Back: the scraped slot is still Extracted")
	var extracted: int = 0
	var capped: int = 0
	for b in f0:
		if b == 2:
			extracted += 1
		elif b == 0:
			capped += 1
	eq(extracted, 1, "after Back: exactly one slot of the frame is empty")
	eq(capped, _cpf() - 1, "after Back: the other 34 cells are still Capped")
	if to_pile:
		eq(pile.get("cells"), pile0 + 1, "the cell is in the pile once (not lost, not doubled)")
		eq(cen.get("cells"), cells0, "the full bucket took nothing")
		near(float(pile.get("jars")), _jars_of(1), 1e-9, "the pile holds one cell's jars (2 / 35)")
	else:
		eq(cen.get("cells"), cells0 + 1, "the cell is in the bucket once (not lost, not doubled)")
		eq(pile.get("cells"), pile0, "nothing went to the pile")
		near(float(cen.get("jars")), _jars_of(1), 1e-9, "the bucket holds one cell's jars (2 / 35)")
	near(_jars_everywhere(p), jars0, 1e-9, "hive + overflow + bucket + pile: no jar lost or made")
	var strays: Array = []
	for n in root.get_children():
		if not kids0.has(n):
			strays.append(n.name)
	eq(strays, [], "no flying cell or other node was left behind under the root")
	eq(cen.get("lid_open"), false, "the zoom ended with cells in the bucket: lid on")
	eq(cen.get("state"), _st(cen, "FULL"), "FULL, waiting for Spin")
	ck(_shown(p["CentrifugeIcon"]), "Spin shows")
	ck(_shown(p["ForkIcon"]), "the fork stays: 34 + 4 x 35 Capped cells remain")
	eq(tr["risen"], -1, "the frame went back down")
	eq(tr["lid"], [true, false], "the hive lid went on again")
	ck(_shown(p["MoneyLabel"]) and not _shown(p["BackButton"]), "the farm UI is back")
	# the half frame comes up again with its 34 cells when the fork is tapped
	tr["raised"] = []
	ck(await _open_zoom(m, p, tr), "the fork opens the zoom again")
	eq(tr["raised"], [0], "the frame with the empty slot rises first")
	eq(fi.capped(hive, 0), _cpf() - 1, "it shows its 34 Capped cells")
	_fin()


func t_scrape_then_back_in_pop_window_bucket() -> void:
	await _scrape_back_in_pop(false)


func t_scrape_then_back_in_pop_window_pile() -> void:
	await _scrape_back_in_pop(true)


# Patricia's confirmation (0.1), requested test 2: resume_pending (set by Back, so the fork stays) combined with the pile loading in after
# bottling while a zoom is open. Order matters, Continue cannot be clicked in the zoom:
#   zoom 1: frames 1-2 -> bucket (70, lid on), frame 3 -> pile (35); Back with frame 4 risen -> resume_pending, fork shows
#   Spin, crank to DONE, Continue (real clicks) -> BOTTLING; while bottling the fork (kept by resume_pending) opens zoom 2
#   zoom 2: bottling ends inside the zoom -> the pile loads into the empty bucket and the lid STAYS OFF (not full, zoom open)
#   later scrapes go to the bucket (frame 4: 35 -> 70, lid on when it fills), frame 5 -> pile; the zoom ends on its own:
#   resume_pending clears, the fork goes, the lid is on. Jars conserved all the way: 10 = hive + bucket + pile + truck.
func t_resume_pending_pile_loads_while_zoom_open() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var pile: Node = p["Pile"]
	var truck: Node = p["Truck"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	_set_cfg("bottling_seconds_per_jar", 1.5)   # CHEAT (Dev): long enough to open the zoom while bottling, short enough to finish in it
	await _frames(4)
	var cpf: int = _cpf()
	var cap: int = _bucket_cells()
	var jars0: float = _jars_everywhere(p)
	var truck_jars: Callable = func() -> int: return int(truck.get("loaded_jars")) + int(truck.get("crate_jars"))
	eq(m.get("resume_pending"), false, "start: resume_pending is false")
	# ---- zoom 1
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom 1 did not open")
		_fin()
		return
	for k in 3:
		var f: int = await _scrape_risen(m, hive, tr)
		ck(await _next_frame(tr, f), "zoom 1: frame %d done, the next rose" % f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	eq(tr["risen"], 3, "zoom 1: frame 4 (index 3) is risen")
	eq(cen.get("cells"), cap, "zoom 1: the bucket holds 70 cells")
	eq(pile.get("cells"), cpf, "zoom 1: the pile holds 35 cells")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")) + _lid_t())
	eq(m.get("resume_pending"), true, "Back set resume_pending")
	ck(_shown(p["ForkIcon"]), "Back: the fork shows (frames 4 and 5 hold Capped cells)")
	eq(cen.get("state"), _st(cen, "FULL"), "Back: bucket FULL")
	near(_jars_everywhere(p) + float(truck_jars.call()), jars0, 1e-9, "zoom 1: jars conserved")
	# ---- spin and bottle
	await fi.click_icon(p["CentrifugeIcon"] as Control)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "CRANKING"), "Spin: CRANKING")
	var sent: int = await _crank_done(cen)
	eq(cen.get("state"), _st(cen, "DONE"), "cranked to DONE (%d turns)" % sent)
	await _frames(3)
	ck(_shown(p["ForkIcon"]), "DONE: the fork still shows (resume_pending)")
	await fi.click_ctl(p["ContinueButton"] as Control)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "BOTTLING"), "Continue: BOTTLING")
	await _wait(float(cv("bottling_seconds_per_jar")) * 0.5)
	ck(_shown(p["ForkIcon"]), "BOTTLING: the fork shows (resume_pending)")
	# ---- zoom 2, opened while bottling
	tr["raised"] = []
	if not await _open_zoom(m, p, tr):
		ck(false, "zoom 2 did not open while bottling")
		_fin()
		return
	eq(tr["raised"], [3], "zoom 2: frame 4 (index 3) rises first")
	eq(cen.get("state"), _st(cen, "BOTTLING"), "zoom 2: bottling keeps running in the zoom")
	var bottling: int = _st(cen, "BOTTLING")
	var finished: bool = await _until(func() -> bool: return int(cen.get("state")) != bottling, float(cv("bottling_seconds_per_jar")) * 8.0)
	ck(finished, "bottling ended inside the zoom")
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 1.0)
	ck(_shown(p["BackButton"]) and int(tr["risen"]) == 3, "the zoom is still open on frame 4")
	eq(pile.get("cells"), 0, "the pile loaded into the empty bucket")
	eq(cen.get("cells"), cpf, "the bucket holds the 35 pile cells")
	eq(cen.get("lid_open"), true, "the lid stays OFF: the bucket is not full and a zoom is open")
	eq(cen.get("state"), _st(cen, "LOADING"), "LOADING")
	eq(truck_jars.call(), int(floorf(_jars_of(cap) + 0.000001)), "the 70-cell batch gave floor(4) = 4 jars to the truck")
	near(_jars_everywhere(p) + float(truck_jars.call()), jars0, 1e-9, "zoom 2 after bottling: jars conserved")
	# ---- later scrapes go to the bucket until it is full, then to the pile
	var f3: int = await _scrape_risen(m, hive, tr)
	ck(await _next_frame(tr, f3), "frame 4 done, frame 5 rose")
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	eq(cen.get("cells"), cap, "frame 4's cells went to the bucket (35 + 35)")
	eq(pile.get("cells"), 0, "nothing piled while the bucket had room")
	eq(cen.get("lid_open"), false, "the lid dropped on when the bucket filled")
	eq(cen.get("state"), _st(cen, "FULL"), "FULL")
	var f4: int = await _scrape_risen(m, hive, tr)
	await _wait(float(cv("close_delay_seconds")) + float(cv("zoom_seconds")) + _lid_t() + float(cv("slide_seconds")) + float(cv("cell_fly_seconds")) + 0.8)
	eq(pile.get("cells"), cpf, "frame 5's cells went to the pile")
	eq(fi.capped_total(hive, _frames_n()), 0, "no Capped cell left")
	eq(m.get("resume_pending"), false, "the zoom ended on its own: resume_pending cleared")
	ck(not _shown(p["ForkIcon"]), "the fork is gone: hive not full and resume_pending false")
	ck(_shown(p["MoneyLabel"]) and not _shown(p["BackButton"]), "the farm UI is back")
	eq(cen.get("lid_open"), false, "lid on")
	eq(cen.get("state"), _st(cen, "FULL"), "FULL after the zoom")
	ck(_shown(p["CentrifugeIcon"]), "Spin shows")
	eq(tr["lid"], [true, false, true, false], "hive lid: on-off-on-off over the two zooms")
	near(_jars_everywhere(p) + float(truck_jars.call()), jars0, 1e-9, "end: 10 jars = hive + bucket + pile + truck")
	_fin()


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


## Lid time of 0.1.1: the lift then the fall (lid_lift_seconds is absent from a 0.1.0 config: counts as 0 so the old waits still work).
func _lid_t() -> float:
	var c: Variant = _cfg()
	var lift: Variant = c.get("lid_lift_seconds") if c != null else null
	return float(cv("lid_drop_seconds")) + (float(lift) if lift != null else 0.0)


# Spec 0.1 ("Show UI bounds": outlines every visible Control's rect, icons' touch rects dashed, anchor points). Test defect of 0.1.0:
# t_dev_show_ui_bounds only counted visible CanvasItems around the toggle, so it passed while the overlay drew nothing (its _collect skipped
# Node3D subtrees and Main is a Node3D, so it collected no Control). This test asks the overlay what it would draw, in the running main scene.
# The pixels on the rect edges are checked in tests/ui_bounds_pixels.gd (needs a window).
func t_dev_ui_bounds_collects_controls() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	var panel: Node = _find_dev_panel(m)
	ck(panel != null, "dev panel exists")
	if panel == null or p.is_empty():
		_fin()
		return
	_full_hive_frozen(p["Hive"])   # the fork icon floats
	await _frames(4)
	var btn: Button = _button_with(panel, "bounds")
	ck(btn != null, "no Button with 'bounds' in its text")
	if btn == null:
		_fin()
		return
	btn.pressed.emit()
	await _frames(4)
	var ov: Node = root.find_child("UiBoundsOverlay", true, false)
	ck(ov != null, "the overlay node (UiBoundsOverlay) exists after the toggle")
	if ov == null or not ov.has_method("collect_controls"):
		ck(false, "the overlay has no collect_controls()")
		_fin()
		return
	var got: Array = ov.call("collect_controls")
	ck(got.size() > 0, "collect_controls() returned %d controls, must be > 0 with the farm UI showing" % got.size())
	var visible_named: int = 0
	for nm in SCENE_NODES:
		var n: Node = p[nm]
		if n is Control and (n as Control).is_visible_in_tree():
			visible_named += 1
			ck(got.has(n), "collect_controls() includes the visible Control '%s'" % nm)
	ck(visible_named >= 4, "at least 4 named Controls were visible to be collected (%d)" % visible_named)
	for nm in ["ForkIcon", "UpgradeButton", "MoneyLabel"]:
		ck(got.has(p[nm]), "collect_controls() includes %s (fork shows at a full hive; Upgrade and Money are farm UI)" % nm)
	# it must not list a hidden Control
	ck(not got.has(p["BackButton"]), "the hidden BackButton is not collected")
	btn.pressed.emit()
	await _frames(3)
	_fin()
