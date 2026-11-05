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
		# 0.1.1 play-test fixes
		"t_dev_ui_bounds_collects_controls", "t_overlap_helper_can_fail", "t_rim_measure_can_fail", "t_config_011", "t_dev_panel_has_lid_values",
		"t_node_contract_011", "t_hive_footprint_and_frames", "t_hive_lid_open_path", "t_hive_lid_close_path", "t_hive_lid_leaning_pose",
		"t_centrifuge_lid_paths", "t_heap_shows_every_cell", "t_pile_shows_every_cell", "t_jar_fills_then_lid",
		"t_truck_and_crate_jars_full_with_lids", "t_wheel_rims", "t_cell_width_at_zoom",
			# 0.1.2 bottling and sale (written from game/specs/0.1.2-bottling-and-sale.md before the code)
			"t_zoom_view_option_a", "t_hive_size_vs_truck", "t_centrifuge_lid_rests_clear", "t_flight_judge_can_fail", "t_start_helper_can_fail",
			"t_continue_finder_can_fail", "t_node_contract_012", "t_config_012", "t_crate_shows_empties", "t_jar_flights_to_spigot_and_truck",
			"t_jar_lands_in_crate_when_truck_away", "t_crate_fulls_fly_to_truck_on_return", "t_bottling_starts_by_itself", "t_no_continue_button",
			"t_summary_after_sell",
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


## 0.1.2 (spec change 6): no Continue. Once the extraction is over the state is DONE for at most a frame, then BOTTLING (or EMPTY when
## everything is bottled). The signal extraction_done is the exact moment; this checks the state is one of those three.
func _ext(c: Object, msg: String) -> void:
	var st: int = int(c.get("state"))
	ck(st == _st(c, "DONE") or st == _st(c, "BOTTLING") or st == _st(c, "EMPTY"), "%s (state %d: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself)" % [msg, st])


## Start bottling the way the game does: by itself. Tests that call advance() on a quiet scene start it by hand only if the scene did not.
func _begin_bottling(c: Object) -> void:
	if int(c.get("state")) == _st(c, "DONE"):
		c.call("open_spigot")


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
			"FarmWorld", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon", "UpgradeButton"]:
		_nn(m, nm)
	ck(m.find_child("ContinueButton", true, false) == null, "ContinueButton is removed (0.1.2 change 6)")
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
		"zoom_seconds": 0.6, "lid_drop_seconds": 0.4, "slide_seconds": 0.3, "cell_fly_seconds": 0.5,
		"icon_visual_px": 88, "min_cell_px": 44,
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
	for gone in ["taps_per_frame", "overflow_frames", "hold_taps_per_second", "hold_mode", "no_rapid_tap_mode", "bucket_visual_cap", "pile_visual_cap"]:
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
			"cell_fly_seconds", "icon_visual_px", "min_cell_px", "zoom_size"]:
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
		_ext(c, "%d cells: DONE after the last turn" % cells)
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
	_ext(c, "CRANKING: real clicks counted and finished the bucket (positive control)")
	var turns: Variant = c.get("turns_counted")
	for i in burst:   # DONE
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	_ext(c, "DONE unchanged by input")
	eq(c.get("turns_counted"), turns, "DONE: no extra turn")
	_begin_bottling(c)   # BOTTLING
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
	_ext(c, "DONE")
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
	_ext(c, "touch taps finished the bucket (%d sent)" % sent)
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
	_ext(c, "clicks off the button finish the bucket (positive control)")
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
	_begin_bottling(c)
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

const SCENE_NODES := ["Hive", "Centrifuge", "Pile", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon",
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
	for nm in farm_ui + ["ForkIcon", "CentrifugeIcon", "SellIcon", "CentrifugeLabel"]:
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
		_ext(cen, "round %d: DONE" % (round_i + 1))
		await _frames(3)
		ck(p.get("ContinueButton") == null, "round %d: there is no Continue to press (0.1.2)" % (round_i + 1))
		var jars_expected: int = int(floorf(_jars_of(cells_now) + 0.000001))
		var bottling_s: int = _st(cen, "BOTTLING")
		var by_itself: bool = await _until(func() -> bool: return int(cen.get("state")) == bottling_s or int(cen.get("state")) == _st(cen, "EMPTY"), 5.0)
		ck(by_itself, "round %d: bottling started by itself, no input after the last turn" % (round_i + 1))
		var finished_b: bool = await _until(func() -> bool: return int(cen.get("state")) != bottling_s, 40.0)
		ck(finished_b, "round %d: bottling ended" % (round_i + 1))
		ck(not _shown(p["SummaryModal"]), "round %d: no summary after bottling (it comes after Sell)" % (round_i + 1))
		sum_jars += jars_expected
		eq(truck.get("loaded_jars"), sum_jars, "round %d: floor(jars) = %d jars went to the truck" % [round_i + 1, jars_expected])
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
	# Sell: the summary shows only now, with the jars sold, the price per jar and the total
	var per_jar: int = int(cv("sale_value_per_jar"))
	ck(_shown(p["SellIcon"]), "the Sell icon shows over the full truck")
	await fi.click_icon(p["SellIcon"] as Control)
	var sum_up: bool = await _until(func() -> bool: return _shown(p["SummaryModal"]), 3.0)
	ck(sum_up, "the summary shows after Sell")
	await fi.click_ctl(p["SummaryOkButton"] as Control)
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
	_ext(cen, "precondition: DONE")
	ck(_shown(fork), "DONE: fork shown")
	_begin_bottling(cen)
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
	var sell: Node = p["SellIcon"]
	eq(_shown(sell), bool(truck.call("can_sell")), "EMPTY: Sell icon follows the truck")
	ck(not _shown(cicon), "EMPTY: Spin hidden")
	eq(cen.get("lid_open"), true, "EMPTY: lid off")
	cen.call("add_cells", _cpf(), _jars_of(_cpf()))
	await _frames(3)
	ck(not _shown(cicon), "LOADING: Spin hidden")
	eq(cen.get("lid_open"), true, "LOADING: lid off")
	cen.call("add_cells", _bucket_cells() - _cpf(), _jars_of(_bucket_cells() - _cpf()))
	cen.call("close_lid")
	await _frames(3)
	ck(_shown(cicon), "FULL: Spin shows (farm)")
	eq(cen.get("lid_open"), false, "FULL: lid on")
	# zoom open: Spin hidden
	ck(await _open_zoom(m, p, tr), "zoom opened with a FULL bucket")
	ck(not _shown(cicon), "zoom: Spin hidden (farm only)")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	ck(_shown(cicon), "after the zoom: Spin shows again")
	cen.call("begin_crank")
	await _frames(3)
	ck(not _shown(cicon), "CRANKING: Spin hidden")
	_crank_done(cen)
	await _frames(3)
	ck(not _shown(cicon), "after the extraction: Spin hidden (bottling starts by itself, no Continue)")
	for i in int(cv("truck_capacity_jars")):
		truck.call("receive_jar")
	await _frames(3)
	ck(_shown(sell), "DONE: Sell icon shown once the truck is full and home")
	tr["raised"] = []
	ck(await _open_zoom(m, p, tr), "zoom opened at DONE")
	ck(not _shown(sell), "zoom: Sell icon hidden (farm UI)")
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	_begin_bottling(cen)
	await _frames(3)
	ck(not _shown(cicon), "BOTTLING: Spin hidden")
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
	_begin_bottling(cen)
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
	for nm in ["UpgradeButton", "ForkIcon", "CentrifugeIcon", "SellIcon", "SummaryOkButton", "BackButton"]:
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
	_begin_bottling(c)
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
# bottling while a zoom is open. Order matters (0.1.2: bottling starts by itself, no Continue):
#   zoom 1: frames 1-2 -> bucket (70, lid on), frame 3 -> pile (35); Back with frame 4 risen -> resume_pending, fork shows
#   Spin, crank to the end (real clicks) -> BOTTLING by itself; while bottling the fork (kept by resume_pending) opens zoom 2
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
	_ext(cen, "cranked to DONE (%d turns)" % sent)
	await _frames(3)
	ck(_shown(p["ForkIcon"]), "DONE: the fork still shows (resume_pending)")
	await _frames(3)
	eq(cen.get("state"), _st(cen, "BOTTLING"), "no Continue: BOTTLING started by itself")
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


# ================================================================ 0.1.1 play-test fixes (game/specs/0.1.1-playtest-fixes.md)
# Written from the spec before the code. Node names not in the 0.1.1 contract are the 0.1.0 names ("everything not named stays"):
# HiveLid, HiveBody, FrameBars/FrameBar<n>, Honeycomb under Hive; Lid, Bucket, HeapRoot, SpigotJar under Centrifuge; BedJars on the
# truck, CrateJars on the crate. A renamed node fails ONE test with its name in the message (listed in the report as an ambiguity).

## Two boxes lying in contact (resting lid, leaning lid) are not an overlap: the penetration must exceed this many units.
const CONTACT_EPS: float = 0.03


## Oriented boxes of every visible MeshInstance3D under `n` (inclusive), skipping the subtrees in `skip`: [centre, [3 half axes], mesh].
func _obbs(n: Node, skip: Array = []) -> Array:
	var out: Array = []
	var meshes: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		meshes.append(n)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var skipped: bool = false
		for s in skip:
			if s != null and (s == mi or (s as Node).is_ancestor_of(mi)):
				skipped = true
		if skipped:
			continue
		var a: AABB = mi.mesh.get_aabb()
		var gt: Transform3D = mi.global_transform
		out.append([gt * (a.position + a.size * 0.5), [gt.basis.x * (a.size.x * 0.5), gt.basis.y * (a.size.y * 0.5), gt.basis.z * (a.size.z * 0.5)], mi])
	return out


## Separating-axis penetration depth of two oriented boxes (15 axes): <= 0 when separated, else the smallest overlap along any axis.
func _obb_pen(a: Array, b: Array) -> float:
	var aa: Array = a[1]
	var ab: Array = b[1]
	var axes: Array = []
	for v in aa:
		axes.append(v)
	for v in ab:
		axes.append(v)
	for i in 3:
		for j in 3:
			axes.append((aa[i] as Vector3).cross(ab[j] as Vector3))
	var d: Vector3 = (b[0] as Vector3) - (a[0] as Vector3)
	var best: float = 1.0e9
	for ax in axes:
		var l: float = (ax as Vector3).length()
		if l < 1.0e-4:
			continue
		var u: Vector3 = (ax as Vector3) / l
		var ra: float = 0.0
		for v in aa:
			ra += absf((v as Vector3).dot(u))
		var rb: float = 0.0
		for v in ab:
			rb += absf((v as Vector3).dot(u))
		var pen: float = ra + rb - absf(d.dot(u))
		if pen <= 0.0:
			return pen
		best = minf(best, pen)
	return best


## Largest penetration of any box of `lid` into any box of `body` (<= CONTACT_EPS means touching or clear).
func _max_pen(lid: Array, body: Array) -> float:
	var worst: float = -1.0e9
	for l in lid:
		for b in body:
			worst = maxf(worst, _obb_pen(l as Array, b as Array))
	return worst


func _box_corners_y(boxes: Array) -> Vector2:   # (min y, max y) of the corners
	var lo: float = 1.0e9
	var hi: float = -1.0e9
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		var ext: float = absf((ax[0] as Vector3).y) + absf((ax[1] as Vector3).y) + absf((ax[2] as Vector3).y)
		lo = minf(lo, c.y - ext)
		hi = maxf(hi, c.y + ext)
	return Vector2(lo, hi)


func _mk_box(size: Vector3, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	root.add_child(mi)
	mi.global_transform = xf
	_to_free.append(mi)
	return mi


func _angle_between(a: Basis, b: Basis) -> float:
	return (a.orthonormalized().inverse() * b.orthonormalized()).get_rotation_quaternion().get_angle()


## The overlap helper has to be able to fail, or every lid pass below means nothing: a box through a box, a box beside it,
## and a 45-degree box that only overlaps in a world AABB.
func t_overlap_helper_can_fail() -> void:
	var a: MeshInstance3D = _mk_box(Vector3.ONE, Transform3D(Basis.IDENTITY, Vector3.ZERO))
	var b: MeshInstance3D = _mk_box(Vector3.ONE, Transform3D(Basis.IDENTITY, Vector3(0.5, 0.0, 0.0)))
	var c: MeshInstance3D = _mk_box(Vector3.ONE, Transform3D(Basis.IDENTITY, Vector3(1.0, 0.0, 0.0)))
	var d: MeshInstance3D = _mk_box(Vector3.ONE, Transform3D(Basis(Vector3.UP, deg_to_rad(45.0)), Vector3(1.3, 0.0, 0.0)))
	var e: MeshInstance3D = _mk_box(Vector3.ONE, Transform3D(Basis(Vector3.UP, deg_to_rad(45.0)), Vector3(1.1, 0.0, 0.0)))
	var ba: Array = _obbs(a)
	ck(_max_pen(_obbs(b), ba) > CONTACT_EPS, "a box half inside another overlaps (%.3f)" % _max_pen(_obbs(b), ba))
	ck(_max_pen(_obbs(c), ba) <= CONTACT_EPS, "boxes in face contact do not overlap (%.3f)" % _max_pen(_obbs(c), ba))
	ck(_max_pen(_obbs(d), ba) <= 0.0, "a 45 degree box 1.3 away is separated although its world AABB is not (%.3f)" % _max_pen(_obbs(d), ba))
	ck(_max_pen(_obbs(e), ba) > CONTACT_EPS, "the same box at 1.1 overlaps (%.3f)" % _max_pen(_obbs(e), ba))
	_fin()


## Sample a lid's global transform and its worst penetration into the body, once per frame, for `game_secs` of game time.
## Engine.time_scale slows the game so a tween of 0.65 s gives well over 30 frames.
func _sample_lid(lid: Node3D, body_fn: Callable, game_secs: float, scale: float = 0.25) -> Array:
	var out: Array = []
	Engine.time_scale = scale
	var t_end: int = Time.get_ticks_msec() + int(game_secs / scale * 1000.0)
	while Time.get_ticks_msec() < t_end:
		await process_frame
		out.append({"xf": lid.global_transform, "pen": _max_pen(_obbs(lid), body_fn.call() as Array)})
	Engine.time_scale = 1.0
	return out


## Checks every path must satisfy: >= 30 samples, really moving (a teleport passes an overlap test trivially), no overlap, ends at `end_xf`.
func _judge_path(tag: String, s: Array, end_xf: Transform3D, lift: float, check_lift: bool, rot_locked_in_lift: bool) -> void:
	ck(s.size() >= 30, "%s: at least 30 samples (%d)" % [tag, s.size()])
	if s.size() < 2:
		return
	var moving: int = 0
	var worst: float = -1.0e9
	var worst_i: int = 0
	var y0: float = ((s[0] as Dictionary)["xf"] as Transform3D).origin.y
	var o0: Vector3 = ((s[0] as Dictionary)["xf"] as Transform3D).origin
	var peak: float = 0.0
	for i in s.size():
		var xf: Transform3D = (s[i] as Dictionary)["xf"]
		if i > 0 and not xf.origin.is_equal_approx(((s[i - 1] as Dictionary)["xf"] as Transform3D).origin):
			moving += 1
		var pen: float = float((s[i] as Dictionary)["pen"])
		if pen > worst:
			worst = pen
			worst_i = i
		peak = maxf(peak, xf.origin.y - y0)
	ck(moving >= 20, "%s: the lid really moves over the samples (%d of %d samples differ from the previous one)" % [tag, moving, s.size()])
	ck(worst <= CONTACT_EPS, "%s: the lid box never overlaps the body or a frame: worst penetration %.3f at sample %d of %d (contact allowed up to %.2f)" % [tag, worst, worst_i, s.size(), CONTACT_EPS])
	var last: Transform3D = (s[s.size() - 1] as Dictionary)["xf"]
	ck(last.origin.distance_to(end_xf.origin) <= 0.02, "%s: ends at the target position (off by %.3f)" % [tag, last.origin.distance_to(end_xf.origin)])
	ck(_angle_between(last.basis, end_xf.basis) <= 0.03, "%s: ends at the target rotation (off by %.1f deg)" % [tag, rad_to_deg(_angle_between(last.basis, end_xf.basis))])
	if check_lift:
		ck(peak >= lift * 0.95, "%s: the lid rises by lid_lift_height first (peak rise %.3f, lift %.3f)" % [tag, peak, lift])
		var reached: int = -1
		for i in s.size():
			if ((s[i] as Dictionary)["xf"] as Transform3D).origin.y - y0 >= lift * 0.98:
				reached = i
				break
		ck(reached >= 0, "%s: a sample reaches the lift height" % tag)
		if reached >= 0:
			var sideways: float = 0.0
			var turned: float = 0.0
			for i in reached + 1:
				var xf2: Transform3D = (s[i] as Dictionary)["xf"]
				sideways = maxf(sideways, Vector2(xf2.origin.x - o0.x, xf2.origin.z - o0.z).length())
				turned = maxf(turned, _angle_between(((s[0] as Dictionary)["xf"] as Transform3D).basis, xf2.basis))
			ck(sideways <= 0.03, "%s: the lift is straight up (sideways drift %.3f before the top)" % [tag, sideways])
			if rot_locked_in_lift:
				ck(turned <= 0.05, "%s: no tipping before the top of the lift (%.1f deg)" % [tag, rad_to_deg(turned)])


func _hive_body(hive: Node) -> Callable:
	var lid: Node = hive.find_child("HiveLid", true, false)
	var hc: Node = hive.find_child("Honeycomb", true, false)
	return func() -> Array: return _obbs(hive, [lid, hc])


func _hive_setup() -> Dictionary:
	var m: Node = await _mk_main()
	if m == null:
		return {}
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var hive: Node = _nn(m, "Hive")
	if hive == null:
		return {}
	var lid: Node = hive.find_child("HiveLid", true, false)
	var spot: Node = hive.find_child("HiveLidSpot", true, false)
	ck(lid != null, "the hive has a lid node named HiveLid (0.1.0 name; the spec names only HiveLidSpot)")
	ck(spot != null, "HiveLidSpot exists")
	if lid == null or spot == null:
		return {}
	await _frames(3)
	return {"m": m, "hive": hive, "lid": lid, "spot": spot}


# Spec 2: open path (lift, then tip and fall to the leaning pose), no overlap at any sampled point, ends at HiveLidSpot's full transform.
func t_hive_lid_open_path() -> void:
	var h: Dictionary = await _hive_setup()
	if h.is_empty():
		_fin()
		return
	var hive: Node = h["hive"]
	var lid: Node3D = h["lid"]
	var closed: Transform3D = lid.global_transform
	var lift: float = float(cv("lid_lift_height"))
	var secs: float = float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.35
	hive.call("open_lid")
	var s: Array = await _sample_lid(lid, _hive_body(hive), secs)
	var target: Transform3D = (h["spot"] as Node3D).global_transform
	_judge_path("hive lid, opening", s, target, lift, true, true)
	ck(not target.origin.is_equal_approx(closed.origin), "the open pose differs from the closed one")
	_fin()


# Spec 2: closing plays the same path backwards: lifts to lid_lift_height, then comes down onto the hive, ends at the closed transform.
func t_hive_lid_close_path() -> void:
	var h: Dictionary = await _hive_setup()
	if h.is_empty():
		_fin()
		return
	var hive: Node = h["hive"]
	var lid: Node3D = h["lid"]
	var closed: Transform3D = lid.global_transform
	var lift: float = float(cv("lid_lift_height"))
	var secs: float = float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.35
	hive.call("open_lid")
	await _sample_lid(lid, _hive_body(hive), secs)
	hive.call("close_lid")
	var s: Array = await _sample_lid(lid, _hive_body(hive), secs)
	_judge_path("hive lid, closing", s, closed, lift, false, false)
	var peak: float = 0.0
	for e in s:
		peak = maxf(peak, ((e as Dictionary)["xf"] as Transform3D).origin.y - closed.origin.y)
	ck(peak >= lift * 0.95, "closing passes through the lifted pose (peak %.3f above closed, lift %.3f)" % [peak, lift])
	_fin()


func _screen_of(boxes: Array, cam: Camera3D) -> Rect2:
	var have: bool = false
	var r := Rect2()
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var p: Vector2 = cam.unproject_position(c + (ax[0] as Vector3) * sx + (ax[1] as Vector3) * sy + (ax[2] as Vector3) * sz)
					if not have:
						r = Rect2(p, Vector2.ZERO)
						have = true
					else:
						r = r.expand(p)
	return r


# Spec 2: the open pose: leaning about 60-70 degrees from flat, lower edge on the ground, on the side away from the centrifuge, never
# between the camera and the risen frame.
func t_hive_lid_leaning_pose() -> void:
	var h: Dictionary = await _hive_setup()
	if h.is_empty():
		_fin()
		return
	var m: Node = h["m"]
	var hive: Node = h["hive"]
	var lid: Node3D = h["lid"]
	var body_boxes: Array = (_hive_body(hive).call() as Array)
	ck(body_boxes.size() > 0, "the hive has body boxes")
	var ground: float = _box_corners_y(body_boxes).x
	var top: float = _box_corners_y(_obbs(hive.find_child("HiveBody", true, false) if hive.find_child("HiveBody", true, false) != null else hive, [lid, hive.find_child("Honeycomb", true, false), hive.find_child("FrameBars", true, false)])).y
	hive.call("fill_now")
	hive.call("open_lid")
	await _wait(float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.4)
	var lb: Array = _obbs(lid)
	ck(lb.size() > 0, "the open lid has boxes")
	if lb.is_empty():
		_fin()
		return
	var ax: Array = (lb[0] as Array)[1]
	var thin: int = 0
	for i in 3:
		if (ax[i] as Vector3).length() < (ax[thin] as Vector3).length():
			thin = i
	var n: Vector3 = (ax[thin] as Vector3).normalized()
	var tilt: float = rad_to_deg(acos(clampf(absf(n.y), 0.0, 1.0)))
	ck(tilt >= 55.0 and tilt <= 75.0, "the open lid leans about 60-70 degrees from flat (measured %.1f, accepted 55 to 75)" % tilt)
	var low: float = _box_corners_y(lb).x
	ck(absf(low - ground) <= 0.1, "the lid's lower edge is on the ground (lowest corner %.3f, ground %.3f)" % [low, ground])
	ck(_box_corners_y(lb).y > ground + 0.5, "the lid stands up (highest corner %.3f)" % _box_corners_y(lb).y)
	var hc: Vector3 = Vector3.ZERO
	for b in body_boxes:
		hc += (b as Array)[0] as Vector3
	hc /= float(body_boxes.size())
	var lc: Vector3 = Vector3.ZERO
	for b in lb:
		lc += (b as Array)[0] as Vector3
	lc /= float(lb.size())
	var cen: Node3D = _nn(m, "Centrifuge") as Node3D
	var away: Vector3 = ((cen.global_position - hive.global_position) * Vector3(1.0, 0.0, 1.0)).normalized()
	ck((lc - hc).dot(away) < 0.0, "the lid rests on the side away from the centrifuge (offset along the centrifuge direction %.2f)" % (lc - hc).dot(away))
	hive.call("raise_frame", 0)
	await _wait(float(cv("slide_seconds")) + 0.4)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var fb: Node = hive.find_child("FrameBar1", true, false)
	var frame_boxes: Array = _obbs(hive.find_child("Honeycomb", true, false))
	if fb != null:
		frame_boxes.append_array(_obbs(fb))
	ck(frame_boxes.size() > 0, "the risen frame has boxes (FrameBar1 and Honeycomb cells)")
	var blocked: bool = false
	var fwd: Vector3 = -cam.global_transform.basis.z
	var f_rect: Rect2 = _screen_of(frame_boxes, cam)
	var f_depth: float = 0.0
	for b in frame_boxes:
		f_depth += ((b as Array)[0] as Vector3 - cam.global_position).dot(fwd)
	f_depth /= float(maxi(frame_boxes.size(), 1))
	for b in lb:
		var r: Rect2 = _screen_of([b], cam)
		var depth: float = ((b as Array)[0] as Vector3 - cam.global_position).dot(fwd)
		if r.intersects(f_rect) and r.intersection(f_rect).get_area() > 100.0 and depth < f_depth:
			blocked = true
	ck(not blocked, "the open lid is not between the camera and the risen frame")
	ck(_box_corners_y(frame_boxes).x >= top + 0.05, "the risen frame clears the body with a visible gap (lowest frame point %.3f, body top %.3f; frame_rise %s)" % [_box_corners_y(frame_boxes).x, top, str(cv("frame_rise"))])
	_fin()


func _glass_of(c: Node) -> Array:   # the largest glass.tres box of the centrifuge that is not the jar's
	var best: Array = []
	var vol: float = -1.0
	for mi in c.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if m.mesh == null:
			continue
		var mat: Material = _mesh_mat(m)
		if mat == null or not mat.resource_path.ends_with("glass.tres"):
			continue
		var in_jar: bool = false
		var p: Node = m.get_parent()
		while p != null and p != c:
			if p.name == "SpigotJar":
				in_jar = true
			p = p.get_parent()
		if in_jar:
			continue
		var bx: Array = _obbs(m)
		if bx.is_empty():
			continue
		var ax: Array = (bx[0] as Array)[1]
		var v: float = (ax[0] as Vector3).length() * (ax[1] as Vector3).length() * (ax[2] as Vector3).length()
		if v > vol:
			vol = v
			best = bx[0]
	return best


# Spec 2: the centrifuge lid gets the same lift, so it no longer passes through the bucket; lands flat on the ground beside it.
func t_centrifuge_lid_paths() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	_set_cfg("bottling_seconds_per_jar", 0.5)
	var c: Node = _nn(m, "Centrifuge")
	var lid: Node3D = c.find_child("Lid", true, false) as Node3D
	var spot: Node3D = c.find_child("CentrifugeLidSpot", true, false) as Node3D
	ck(lid != null, "the centrifuge has a lid node named Lid (0.1.0 name)")
	if lid == null or spot == null:
		_fin()
		return
	await _frames(3)
	var body_fn: Callable = func() -> Array: return _obbs(c, [lid, c.find_child("HeapRoot", true, false), c.find_child("SpigotJar", true, false)])
	var body0: Array = body_fn.call()
	ck(body0.size() > 0, "the centrifuge body has boxes")
	var ground: float = _box_corners_y(body0).x
	var open_xf: Transform3D = spot.global_transform
	ck(lid.global_position.distance_to(open_xf.origin) <= 0.02 and _angle_between(lid.global_basis, open_xf.basis) <= 0.03, "an EMPTY centrifuge's lid sits at CentrifugeLidSpot (full transform)")
	var lb0: Array = _obbs(lid)
	ck(absf((lid.global_basis.y.normalized()).y) >= cos(deg_to_rad(3.0)), "the open centrifuge lid is flat (up axis tilt)")
	ck(absf(_box_corners_y(lb0).x - ground) <= 0.1, "the open centrifuge lid is on the ground (%.3f vs %.3f)" % [_box_corners_y(lb0).x, ground])
	var cells: int = 20
	c.call("add_cells", cells, _jars_of(cells))
	c.call("close_lid")
	var secs: float = float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + float(cv("close_delay_seconds")) + 0.4
	var s1: Array = await _sample_lid(lid, body_fn, secs)
	var glass: Array = _glass_of(c)
	ck(glass.size() > 0, "a glass.tres bucket mesh exists on the centrifuge")
	var closed_xf: Transform3D = lid.global_transform
	if glass.size() > 0:
		var gc: Vector3 = glass[0]
		ck(Vector2(closed_xf.origin.x - gc.x, closed_xf.origin.z - gc.z).length() <= 0.15, "the closed lid sits over the bucket's axis")
	_judge_path("centrifuge lid, closing", s1, closed_xf, 0.0, false, false)
	c.call("begin_crank")
	_crank_done(c)
	_begin_bottling(c)
	var empty: int = _st(c, "EMPTY")
	var jars: int = maxi(int(floorf(_jars_of(cells))), 1)
	var secs2: float = float(cv("bottling_seconds_per_jar")) * float(jars) + float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 1.0
	var s2: Array = await _sample_lid(lid, body_fn, secs2, 0.5)
	ck(int(c.get("state")) == empty, "bottling ended (EMPTY)")
	_judge_path("centrifuge lid, opening", s2, open_xf, float(cv("lid_lift_height")), true, false)
	ck(absf((lid.global_basis.y.normalized()).y) >= cos(deg_to_rad(3.0)), "the opened centrifuge lid lands flat")
	_fin()


func _span_xz(boxes: Array) -> Array:   # [min x, min z, max x, max z]
	var lo := Vector2(1.0e9, 1.0e9)
	var hi := Vector2(-1.0e9, -1.0e9)
	for bx in boxes:
		var cc: Vector3 = (bx as Array)[0]
		var axs: Array = (bx as Array)[1]
		var ex: float = absf((axs[0] as Vector3).x) + absf((axs[1] as Vector3).x) + absf((axs[2] as Vector3).x)
		var ez: float = absf((axs[0] as Vector3).z) + absf((axs[1] as Vector3).z) + absf((axs[2] as Vector3).z)
		lo = Vector2(minf(lo.x, cc.x - ex), minf(lo.y, cc.z - ez))
		hi = Vector2(maxf(hi.x, cc.x + ex), maxf(hi.y, cc.z + ez))
	return [lo.x, lo.y, hi.x, hi.y]


# 0.1.1 spec 3 as changed by 0.1.2 change 2: the hive is square to the grid, footprint <= 1.7 (no longer the bucket's), frames face +X,
# in a row along Z, all 5 fit inside the footprint.
func t_hive_footprint_and_frames() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	var c: Node = _nn(m, "Centrifuge")
	if hive == null or c == null:
		_fin()
		return
	var hb: Node = hive.find_child("HiveBody", true, false)
	ck(hb != null, "HiveBody exists (0.1.0 name)")
	var floor_boxes: Array = _obbs(hb if hb != null else hive, [hive.find_child("HiveLid", true, false), hive.find_child("Honeycomb", true, false), hive.find_child("FrameBars", true, false)])
	ck(floor_boxes.size() > 0, "HiveBody has boxes")
	for bx in floor_boxes:
		for a3 in ((bx as Array)[1] as Array):
			var hv := Vector2((a3 as Vector3).x, (a3 as Vector3).z)
			if hv.length() > 1.0e-3:
				var ang: float = rad_to_deg(atan2(hv.y, hv.x))
				var off: float = absf(fposmod(ang + 45.0, 90.0) - 45.0)
				ck(off <= 2.0, "a hive body box is square to the ground grid (axis %.1f deg off)" % off)
	var sp: Array = _span_xz(floor_boxes)
	var lo := Vector2(float(sp[0]), float(sp[1]))
	var hi := Vector2(float(sp[2]), float(sp[3]))
	var w: float = hi.x - lo.x
	var dpt: float = hi.y - lo.y
	var glass: Array = _glass_of(c)
	ck(glass.size() > 0, "bucket glass found")
	var bucket_d: float = 2.0
	if glass.size() > 0:
		var gs: Array = _span_xz([glass])
		bucket_d = minf(float(gs[2]) - float(gs[0]), float(gs[3]) - float(gs[1]))
	ck(w <= 1.7 and dpt <= 1.7, "the hive footprint is 1.7 x 1.7 or less (about 1.6 x 1.6; measured %.2f x %.2f)" % [w, dpt])
	ck(w >= 0.8 and dpt >= 0.8, "the hive footprint is not degenerate (measured %.2f x %.2f)" % [w, dpt])
	print("MEASURE hive footprint %.2f x %.2f, bucket outer diameter %.2f (0.1.1's 'footprint = the bucket's' is retired)" % [w, dpt, bucket_d])
	var zs: Array = []
	var xs: Array = []
	for i in _frames_n():
		var slot: Node3D = hive.find_child("Slot%d" % (i + 1), true, false) as Node3D
		ck(slot != null, "Slot%d exists" % (i + 1))
		if slot == null:
			continue
		var nrm: Vector3 = slot.global_basis.y.normalized()
		ck(nrm.dot(Vector3.RIGHT) >= cos(deg_to_rad(3.0)), "Slot%d's face normal points along world +X (%s)" % [i + 1, str(nrm)])
		var wdt: float = slot.global_basis.get_scale().x * float(cv("grid_cols"))
		ck(wdt <= minf(w, dpt) + 0.05, "a frame of %d cells at slot scale %.3f is %.2f wide: fits inside the footprint (%.2f)" % [int(cv("grid_cols")), slot.global_basis.get_scale().x, wdt, minf(w, dpt)])
		ck(slot.global_position.x >= lo.x and slot.global_position.x <= hi.x and slot.global_position.z >= lo.y and slot.global_position.z <= hi.y, "Slot%d stands inside the footprint" % (i + 1))
		zs.append(slot.global_position.z)
		xs.append(slot.global_position.x)
	zs.sort()
	for i in range(1, zs.size()):
		ck(float(zs[i]) - float(zs[i - 1]) > 0.05, "the frames stand in a row along Z, one behind the other (gap %.3f)" % (float(zs[i]) - float(zs[i - 1])))
	if xs.size() > 0:
		ck(float(xs.max()) - float(xs.min()) <= 0.05, "all frames share one X: a row along Z (spread %.3f)" % (float(xs.max()) - float(xs.min())))
	_fin()


# ---------------------------------------------------------------- heap and pile show every cell (spec 4)

## Drawn cells under a node: visible MultiMesh instances, or visible direct Node3D children that are not labels or markers.
func _drawn_positions(n: Node) -> Array:
	var out: Array = []
	if n == null:
		return out
	for mm in n.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi: MultiMeshInstance3D = mm as MultiMeshInstance3D
		if mmi.multimesh == null or not mmi.is_visible_in_tree():
			continue
		var k: int = mmi.multimesh.visible_instance_count if mmi.multimesh.visible_instance_count >= 0 else mmi.multimesh.instance_count
		for i in k:
			out.append(mmi.global_transform * mmi.multimesh.get_instance_transform(i).origin)
	for ch in n.get_children():
		if ch is Node3D and not (ch is Label3D) and not (ch is Marker3D) and not (ch is MultiMeshInstance3D) and (ch as Node3D).is_visible_in_tree():
			out.append((ch as Node3D).global_position)
	return out


# Spec 4: with centrifuge_capacity_frames = 5 the heap shows exactly the cells the bucket holds after each frame (35, 70 ... 175), all
# inside the glass. bucket_visual_cap is gone.
func t_heap_shows_every_cell() -> void:
	_set_cfg("centrifuge_capacity_frames", 5)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var hr: Node = c.find_child("HeapRoot", true, false) if c != null else null
	ck(hr != null, "HeapRoot exists on the centrifuge (0.1.0 name)")
	var glass: Array = _glass_of(c) if c != null else []
	ck(glass.size() > 0, "a glass.tres bucket mesh exists")
	if hr == null or glass.is_empty():
		_fin()
		return
	eq(_bucket_cells(), 5 * _cpf(), "capacity 5 frames = %d cells" % (5 * _cpf()))
	var gs: Array = _span_xz([glass])
	var gc := Vector2((float(gs[0]) + float(gs[2])) * 0.5, (float(gs[1]) + float(gs[3])) * 0.5)
	var radius: float = minf(float(gs[2]) - float(gs[0]), float(gs[3]) - float(gs[1])) * 0.5
	var yr: Vector2 = _box_corners_y([glass])
	for k in range(1, 6):
		var n: int = _cpf()
		c.call("add_cells", n, _jars_of(n))
		c.call("land_cells", n)
		await _frames(4)
		var pos: Array = _drawn_positions(hr)
		eq(pos.size(), k * _cpf(), "after frame %d the heap shows every one of the bucket's %d cells" % [k, k * _cpf()])
		var outside: int = 0
		for p in pos:
			var v: Vector3 = p
			if Vector2(v.x - gc.x, v.z - gc.y).length() > radius or v.y < yr.x or v.y > yr.y:
				outside += 1
		eq(outside, 0, "after frame %d every heap cell lies inside the glass (radius %.2f, y %.2f to %.2f)" % [k, radius, yr.x, yr.y])
	eq(int(c.get("cells")), 5 * _cpf(), "the bucket counts 175 cells")
	_fin()


# Spec 4: the pile shows every piled cell (pile_visual_cap gone); the count label stays.
func t_pile_shows_every_cell() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var p: Node = _nn(m, "Pile")
	if p == null:
		_fin()
		return
	for n in [10, 100, 400]:
		var have: int = int(p.get("cells"))
		p.call("add", n, _jars_of(n))
		p.call("land", n)
		await _frames(4)
		var want: int = have + n
		eq((_drawn_positions(p) as Array).size(), want, "the pile shows all %d cells it holds" % want)
	var label: Label3D = null
	for ch in p.get_children():
		if ch is Label3D:
			label = ch as Label3D
	ck(label != null, "the pile keeps its count label (a Label3D child)")
	if label != null:
		ck(label.is_visible_in_tree() and label.text.contains(str(int(p.get("cells")))), "the count label shows the pile's %d cells (text '%s')" % [int(p.get("cells")), label.text])
	_fin()


# ---------------------------------------------------------------- the jar (spec 5)

func _mat_path(mi: MeshInstance3D) -> String:
	var mat: Material = _mesh_mat(mi)
	return mat.resource_path if mat != null else ""


## The material a mesh instance draws with: override, surface override, the primitive mesh's own, then surface 0
## (the dummy renderer of a headless run cannot count surfaces of a primitive mesh).
func _mesh_mat(mi: MeshInstance3D) -> Material:
	var mat: Material = mi.material_override
	if mat == null:
		mat = mi.get_surface_override_material(0)
	if mat == null and mi.mesh is PrimitiveMesh:
		mat = (mi.mesh as PrimitiveMesh).material
	if mat == null and mi.mesh != null and not (mi.mesh is PrimitiveMesh) and mi.mesh.get_surface_count() > 0:
		mat = mi.mesh.surface_get_material(0)
	return mat


func t_node_contract_011() -> void:
	var ps: Variant = load("res://scenes/props/jar.tscn")
	ck(ps != null, "jar.tscn loads")
	if ps != null:
		var j: Node = (ps as PackedScene).instantiate()
		_to_free.append(j)
		ck(j is Node3D and not (j is MeshInstance3D), "the jar's root is a plain Node3D (was a MeshInstance3D in 0.1.0): %s" % j.get_class())
		eq(String(j.name), "Jar", "the jar's root is named Jar")
		for nm in ["JarGlass", "JarHoney", "JarHoneyBottom", "JarHoneyTop", "JarLid"]:
			ck(j.find_child(nm, true, false) != null, "jar.tscn has %s" % nm)
		for nm in ["JarHoneyBottom", "JarHoneyTop"]:
			ck(j.find_child(nm, true, false) is Marker3D, "%s is a Marker3D" % nm)
		var g: Node = j.find_child("JarGlass", true, false)
		var hn: Node = j.find_child("JarHoney", true, false)
		var ld: Node = j.find_child("JarLid", true, false)
		if g is MeshInstance3D:
			ck(_mat_path(g as MeshInstance3D).ends_with("glass.tres"), "JarGlass uses glass.tres (%s)" % _mat_path(g as MeshInstance3D))
		if hn is MeshInstance3D:
			ck(_mat_path(hn as MeshInstance3D).ends_with("honey_level.tres"), "JarHoney uses honey_level.tres (%s)" % _mat_path(hn as MeshInstance3D))
		if ld != null:
			var lm: MeshInstance3D = ld as MeshInstance3D
			if lm == null:
				var lms: Array = ld.find_children("*", "MeshInstance3D", true, false)
				lm = lms[0] as MeshInstance3D if lms.size() > 0 else null
			ck(lm != null and _mat_path(lm).ends_with("steel.tres"), "JarLid is steel (steel.tres)")
		if j.find_child("JarHoneyBottom", true, false) != null and j.find_child("JarHoneyTop", true, false) != null:
			ck((j.find_child("JarHoneyTop", true, false) as Node3D).position.y > (j.find_child("JarHoneyBottom", true, false) as Node3D).position.y, "JarHoneyTop is above JarHoneyBottom")
	var m: Node = await _mk_main()
	if m != null:
		var c: Node = _nn(m, "Centrifuge")
		var sj: Node = c.find_child("SpigotJar", true, false) if c != null else null
		ck(sj != null and sj.scene_file_path.ends_with("jar.tscn"), "SpigotJar is a jar.tscn instance")
		var zf: Node = _nn(m, "ZoomFraming")
		if zf != null:
			ck(zf.has_meta("zoom_size"), "ZoomFraming carries the zoom_size metadata")
			var d: Variant = load(DEFAULT_CFG)
			if zf.has_meta("zoom_size") and d != null:
				near(float(zf.get_meta("zoom_size")), float(d.get("zoom_size")), "the config default zoom_size equals ZoomFraming's metadata (Bob's value)", 0.01)
	_fin()


## Honey height of a jar as a fraction between its two markers: the top of JarHoney's box. 0 when JarHoney is hidden.
func _jar_frac(jar: Node) -> float:
	var hn: Node3D = jar.find_child("JarHoney", true, false) as Node3D
	var b: Node3D = jar.find_child("JarHoneyBottom", true, false) as Node3D
	var t: Node3D = jar.find_child("JarHoneyTop", true, false) as Node3D
	if hn == null or b == null or t == null:
		return -1.0
	if not hn.is_visible_in_tree():
		return 0.0
	var bx: Array = _obbs(hn)
	if bx.is_empty():
		return 0.0
	var top: float = _box_corners_y(bx).y
	return (top - b.global_position.y) / (t.global_position.y - b.global_position.y)


func _jar_lid_shown(jar: Node) -> bool:
	var ld: Node3D = jar.find_child("JarLid", true, false) as Node3D
	return ld != null and ld.is_visible_in_tree()


# Spec 5: at the spigot the empty jar has no lid, the honey rises over bottling_seconds_per_jar, then the lid goes on.
func t_jar_fills_then_lid() -> void:
	_set_cfg("bottling_seconds_per_jar", 1.5)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var jar: Node = c.find_child("SpigotJar", true, false)
	ck(jar != null, "SpigotJar exists")
	if jar == null:
		_fin()
		return
	var spj: float = float(cv("bottling_seconds_per_jar"))
	var cells: int = _cpf()   # one frame: 2 jars
	c.call("add_cells", cells, _jars_of(cells))
	c.call("close_lid")
	c.call("begin_crank")
	_crank_done(c)
	_ext(c, "extracted before bottling")
	_begin_bottling(c)
	var samples: Array = []   # [t, jar visible, frac, lid shown]
	var t0: int = Time.get_ticks_msec()
	var empty: int = _st(c, "EMPTY")
	while Time.get_ticks_msec() - t0 < int((spj * 2.0 + 2.0) * 1000.0) and int(c.get("state")) != empty:
		await process_frame
		samples.append([float(Time.get_ticks_msec() - t0) / 1000.0, jar.is_visible_in_tree(), _jar_frac(jar), _jar_lid_shown(jar), (jar as Node3D).global_position])
	ck(samples.size() >= 30, "enough samples while bottling (%d)" % samples.size())
	var seen_full_lid: bool = false
	var seen_mid: bool = false
	var bad_lid: int = 0
	var shrink: int = 0
	var first_vis: float = -1.0
	var first_frac: float = -2.0
	var first_lid: bool = true
	var t_full: float = -1.0
	var prev: float = -1.0
	for s in samples:
		var vis: bool = s[1]
		var f: float = s[2]
		var lid: bool = s[3]
		if not vis:
			prev = -1.0
			continue
		if first_vis < 0.0:
			first_vis = s[0]
			first_frac = f
			first_lid = lid
		if lid and f < 0.98:
			bad_lid += 1
		if f >= 0.98 and lid:
			seen_full_lid = true
			if t_full < 0.0:
				t_full = s[0]
		if f > 0.3 and f < 0.7:
			seen_mid = true
		if prev >= 0.0 and f < prev - 0.02 and not (f <= 0.15):
			shrink += 1
		prev = f
	ck(first_vis >= 0.0, "the jar appeared at the spigot")
	ck(first_frac >= -0.5 and first_frac <= 0.15, "the jar appears empty (honey fraction %.2f)" % first_frac)
	ck(not first_lid, "the jar appears without its lid")
	eq(bad_lid, 0, "the lid is shown only when the jar is full (samples with lid and honey below full)")
	eq(shrink, 0, "the honey only rises within one jar")
	ck(seen_mid, "the honey passes through the middle of the jar (rises gradually)")
	ck(seen_full_lid, "the lid shows once the jar is full")
	if first_vis >= 0.0 and t_full >= 0.0:
		var rise: float = t_full - first_vis
		# 0.1.2: the jar first flies in from the crate (jar_fly_seconds); the fill time counts from its arrival at the spigot,
		# the place where the full jar (lid on) was first seen
		var end_pos: Vector3 = Vector3.ZERO
		for s2 in samples:
			if bool(s2[1]) and bool(s2[3]) and float(s2[2]) >= 0.98:
				end_pos = s2[4]
				break
		var arrive: float = first_vis
		for s2 in samples:
			if bool(s2[1]) and (s2[4] as Vector3).distance_to(end_pos) <= 0.3:
				arrive = float(s2[0])
				break
		rise = t_full - arrive
		ck(rise >= spj * 0.7 and rise <= spj * 1.15 + 0.1, "the honey rises over one bottling interval from the jar's arrival at the spigot: %.2f s for bottling_seconds_per_jar %.2f" % [rise, spj])
	_fin()


# Spec 5: jars on the truck and in the crate are full, with lids.
func t_truck_and_crate_jars_full_with_lids() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var tk: Node = _nn(m, "Truck")
	if tk == null:
		_fin()
		return
	for i in 3:
		tk.call("receive_jar")
	await _frames(3)
	var bed: Node = tk.find_child("BedJars", true, false)
	ck(bed != null, "BedJars exists on the truck (0.1.0 name)")
	var seen: int = 0
	if bed != null:
		for j in bed.get_children():
			if (j as Node3D).is_visible_in_tree() and not (j is Label3D):
				seen += 1
				ck(_jar_frac(j) >= 0.98, "a jar on the truck is full (fraction %.2f)" % _jar_frac(j))
				ck(_jar_lid_shown(j), "a jar on the truck has its lid")
	eq(seen, 3, "three jars show on the truck bed")
	for i in int(cv("truck_capacity_jars")) - 3:
		tk.call("receive_jar")
	tk.call("sell")
	tk.call("receive_jar")
	tk.call("receive_jar")
	await _frames(3)
	# 0.1.2: the crate also shows empty jars, on the CrateEmpties side; the full ones (with lids) are the ones on the CrateFulls side
	var geo: Dictionary = _geo_crate(m)
	var seen2: int = 0
	if not geo.is_empty():
		for j in _vis_jars(m):
			var jp: Vector3 = (j as Node3D).global_position
			if _in_crate(geo, jp) and not _empties_side(geo, jp):
				seen2 += 1
				ck(_jar_frac(j) >= 0.98, "a jar in the crate's full group is full (fraction %.2f)" % _jar_frac(j))
				ck(_jar_lid_shown(j), "a jar in the crate's full group has its lid")
	eq(seen2, 2, "two full jars show in the crate")
	_fin()


# ---------------------------------------------------------------- wheel rims (spec 6)

## Total angle (rad) the offset between two nodes turned over the samples. Both nodes' positions move with the truck; their difference does not.
func _offset_turn(offsets: Array) -> float:
	var tot: float = 0.0
	for i in range(1, offsets.size()):
		var a: Vector3 = offsets[i - 1]
		var b: Vector3 = offsets[i]
		if a.length() > 1.0e-6 and b.length() > 1.0e-6:
			tot += a.angle_to(b)
	return tot


## The rotation measure has to fail on a mark that does not turn: a spinning wheel with the mark as a child, and with the mark beside it.
func t_rim_measure_can_fail() -> void:
	var wheel := Node3D.new()
	var rim := Node3D.new()
	var mark_child := Node3D.new()
	var mark_loose := Node3D.new()
	root.add_child(wheel)
	root.add_child(mark_loose)
	wheel.add_child(rim)
	wheel.add_child(mark_child)
	mark_child.position = Vector3(0.0, 0.3, 0.0)
	mark_loose.position = Vector3(0.0, 0.3, 0.0)
	_to_free.append(wheel)
	_to_free.append(mark_loose)
	var turning: Array = []
	var loose: Array = []
	for i in 20:
		wheel.rotate_x(0.1)
		turning.append(mark_child.global_position - rim.global_position)
		loose.append(mark_loose.global_position - rim.global_position)
	ck(_offset_turn(turning) > 1.5, "a mark on the wheel turns (%.2f rad)" % _offset_turn(turning))
	ck(_offset_turn(loose) < 0.001 or _offset_turn(loose) < 0.5 * _offset_turn(turning), "a mark beside the wheel is measured as not turning (%.2f rad)" % _offset_turn(loose))
	_fin()


# Spec 6: each wheel has a light-grey Rim and an off-centre contrasting RimMark as children; they turn with the wheel.
func t_wheel_rims() -> void:
	var ps: Variant = load("res://scenes/props/truck.tscn")
	ck(ps != null, "truck.tscn loads")
	if ps == null:
		_fin()
		return
	var tk: Node = (ps as PackedScene).instantiate()
	root.add_child(tk)
	_to_free.append(tk)
	_give_config(tk)
	await _frames(3)
	_set_cfg("truck_trip_seconds", 6.0)
	_set_cfg("truck_slide_distance", 10.0)
	var names: Array = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	var offs: Dictionary = {}
	var wheels: Dictionary = {}
	for nm in names:
		var w: Node3D = tk.find_child(nm, true, false) as Node3D
		ck(w != null, "%s exists" % nm)
		if w == null:
			_fin()
			return
		var rim: Node3D = w.get_node_or_null("Rim") as Node3D
		var mark: Node3D = w.get_node_or_null("RimMark") as Node3D
		ck(rim != null, "%s has a child named Rim" % nm)
		ck(mark != null, "%s has a child named RimMark" % nm)
		if rim == null or mark == null:
			_fin()
			return
		wheels[nm] = [w, rim, mark]
		offs[nm] = []
		ck((mark.global_position - rim.global_position).length() > 0.02, "%s: RimMark is off-centre from the rim (%.3f)" % [nm, (mark.global_position - rim.global_position).length()])
		var rm: Array = rim.find_children("*", "MeshInstance3D", true, false)
		if rim is MeshInstance3D:
			rm.append(rim)
		var mm: Array = mark.find_children("*", "MeshInstance3D", true, false)
		if mark is MeshInstance3D:
			mm.append(mark)
		ck(rm.size() > 0 and mm.size() > 0, "%s: Rim and RimMark are drawn (have meshes)" % nm)
		if rm.size() > 0 and mm.size() > 0:
			var rc: Color = _albedo_of(rm[0] as MeshInstance3D)
			var mc: Color = _albedo_of(mm[0] as MeshInstance3D)
			ck(rc.get_luminance() >= 0.55 and (maxf(rc.r, maxf(rc.g, rc.b)) - minf(rc.r, minf(rc.g, rc.b))) <= 0.2, "%s: the rim is light grey (albedo %s)" % [nm, str(rc)])
			ck(absf(rc.get_luminance() - mc.get_luminance()) >= 0.25 or (Vector3(rc.r, rc.g, rc.b) - Vector3(mc.r, mc.g, mc.b)).length() >= 0.4, "%s: the mark contrasts with the rim (%s on %s)" % [nm, str(mc), str(rc)])
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	tk.call("sell")
	var t_end: int = Time.get_ticks_msec() + int((float(cv("truck_trip_seconds")) + 1.0) * 1000.0)
	var wspin: Dictionary = {}
	for nm in names:
		wspin[nm] = []
	while Time.get_ticks_msec() < t_end:
		await process_frame
		for nm in names:
			var tr: Array = wheels[nm]
			(offs[nm] as Array).append((tr[2] as Node3D).global_position - (tr[1] as Node3D).global_position)
			(wspin[nm] as Array).append((tr[0] as Node3D).global_basis)
	for nm in names:
		var turn: float = _offset_turn(offs[nm])
		var wturn: float = 0.0
		var bs: Array = wspin[nm]
		for i in range(1, bs.size()):
			wturn += _angle_between(bs[i - 1], bs[i])
		ck(wturn > 1.0, "%s: the wheel turned while driving (%.2f rad)" % [nm, wturn])
		ck(turn > 1.0, "%s: RimMark turned around the rim (%.2f rad) so the roll is visible" % [nm, turn])
		ck(absf(turn - wturn) <= 0.25 * wturn + 0.3, "%s: RimMark turns with the wheel (mark %.2f rad, wheel %.2f rad)" % [nm, turn, wturn])
	_fin()


func _albedo_of(mi: MeshInstance3D) -> Color:
	var mat: Material = _mesh_mat(mi)
	if mat is BaseMaterial3D:
		return (mat as BaseMaterial3D).albedo_color
	return Color(0.0, 0.0, 0.0)


# ---------------------------------------------------------------- the zoom at the new angle (spec 3)

## Screen width (px) of one cell's hexagonal face: its two flat sides through the cell centre along the mesh's local X (the frame's width axis).
func _cell_face_w(mi: MeshInstance3D, cam: Camera3D) -> float:
	var aabb: AABB = mi.mesh.get_aabb()
	var c: Vector3 = aabb.position + aabb.size * 0.5
	c.y = aabb.end.y
	var hx := Vector3(aabb.size.x * 0.5, 0.0, 0.0)
	var gt: Transform3D = mi.global_transform
	return cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx)))


func _zoom_open_main() -> Dictionary:
	var m: Node = await _mk_main()
	if m == null:
		return {}
	var p: Dictionary = _parts(m)
	if p.is_empty():
		return {}
	var tr: Dictionary = _track(p["Hive"])
	_full_hive_frozen(p["Hive"])
	await _frames(4)
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "the zoom opened with a risen frame")
	return {"m": m, "p": p, "tr": tr}


# Spec 3: every cell is at least min_cell_px wide AS SEEN at the new angle; all 35 are measured (a vacuous pass is impossible).
func t_cell_width_at_zoom() -> void:
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var hc: Node = m.find_child("Honeycomb", true, false)
	ck(hc != null, "Honeycomb exists")
	var n: int = 0
	var lo: float = 1.0e9
	if hc != null:
		for mi in hc.find_children("*", "MeshInstance3D", true, false):
			var mm: MeshInstance3D = mi as MeshInstance3D
			if mm.mesh == null or not mm.is_visible_in_tree():
				continue
			var w: float = _cell_face_w(mm, cam)
			if w > 0.0:
				lo = minf(lo, w)
				n += 1
	eq(n, _cpf(), "all %d cells of the risen frame were measured" % _cpf())
	ck(n > 0 and lo >= float(cv("min_cell_px")), "the smallest cell is at least min_cell_px wide on screen: %.1f px >= %s (camera size %.2f, zoom_size %s)" % [lo, str(cv("min_cell_px")), cam.size, str(cv("zoom_size"))])
	_fin()


# ---------------------------------------------------------------- config and Dev mode of 0.1.1

# Config table of 0.1.1: new values, the retired caps are absent from the defaults file and from game_config.gd.
func t_config_011() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres loads")
	if c == null:
		_fin()
		return
	near(float(c.get("lid_lift_height")), 0.6, "default lid_lift_height")
	near(float(c.get("lid_lift_seconds")), 0.25, "default lid_lift_seconds")
	near(float(c.get("lid_drop_seconds")), 0.4, "default lid_drop_seconds (now the fall after the lift)")
	ck(c.get("zoom_size") != null and float(c.get("zoom_size")) > 0.0, "zoom_size is Bob's positive value")
	ck(c.get("frame_rise") != null and float(c.get("frame_rise")) > 0.0, "frame_rise is Bob's positive value")
	for gone in ["bucket_visual_cap", "pile_visual_cap"]:
		ck(c.get(gone) == null, "'%s' is removed from the config (every cell shows)" % gone)
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd readable")
	if f != null:
		var text: String = f.get_as_text()
		f.close()
		for gone in ["bucket_visual_cap", "pile_visual_cap"]:
			ck(not text.contains("var %s" % gone), "game_config.gd no longer declares %s" % gone)
		for nm in ["lid_lift_height", "lid_lift_seconds"]:
			ck(text.contains("@export var %s" % nm), "game_config.gd has @export var %s (Dev mode lists exported values)" % nm)
	# no script reads a removed value
	var d := DirAccess.open("res://scripts")
	if d != null:
		for fn in d.get_files():
			if fn.ends_with(".gd"):
				var sf := FileAccess.open("res://scripts/" + fn, FileAccess.READ)
				var src: String = sf.get_as_text()
				sf.close()
				ck(not src.contains("bucket_visual_cap") and not src.contains("pile_visual_cap"), "%s does not mention a removed cap" % fn)
	_fin()


# Dev mode picks up the new values (rows for lid_lift_height and lid_lift_seconds) and not the removed ones.
func t_dev_panel_has_lid_values() -> void:
	_set_dev_mode(true)
	var panel: Node = await _mk_panel()
	if panel == null:
		_fin()
		return
	for nm in ["lid_lift_height", "lid_lift_seconds", "lid_drop_seconds", "zoom_size", "frame_rise"]:
		ck(_row_spin(panel, nm) != null, "the Dev panel has a row for %s" % nm)
	for gone in ["bucket_visual_cap", "pile_visual_cap"]:
		ck(_row_spin(panel, gone) == null, "the Dev panel has no row for the removed %s" % gone)
	_fin()



# ================================================================ 0.1.2 bottling and sale
# Written from game/specs/0.1.2-bottling-and-sale.md BEFORE the code (Patricia's and Bob's changes were not read). Names used beyond the
# spec: the 0.1.0/0.1.1 names, plus CrateEmpties / CrateFulls (spec: Contract, Bob), SummaryJarsLabel / SummaryValueLabel / SummaryTotalLabel /
# SummaryOkButton, and the jar scene's JarGlass / JarHoney / JarLid. Jars are found by their JarGlass child wherever they hang in the tree
# (the spec does not say which node owns the empties, the fulls or a jar in flight), and classified by what they LOOK like and where they are:
# empty = no honey, no lid; full = honey up, lid on.

const FLIGHT_MIN_AIR: int = 4


## Every visible jar of the scene: the parent of each JarGlass.
func _vis_jars(m: Node) -> Array:
	var out: Array = []
	for g in m.find_children("JarGlass", "", true, false):
		var j: Node = g.get_parent()
		if j is Node3D and (j as Node3D).is_visible_in_tree() and not out.has(j):
			out.append(j)
	return out


func _crate_root(m: Node) -> Node:
	var n: Node = m.find_child("CrateEmpties", true, false)
	while n != null and n != m:
		if n.scene_file_path.ends_with("jar_crate.tscn"):
			return n
		n = n.get_parent()
	var cj: Node = m.find_child("CrateJars", true, false)
	return cj.get_parent() if cj != null else null


## The crate's place: its two group markers and a disc (x, z) around its own boxes (jars not counted) that "in the crate" means.
func _geo_crate(m: Node) -> Dictionary:
	var crate: Node = _crate_root(m)
	var em: Node3D = _nn(m, "CrateEmpties") as Node3D
	var fu: Node3D = _nn(m, "CrateFulls") as Node3D
	ck(crate != null, "the crate (a jar_crate.tscn instance holding CrateEmpties) was found")
	if crate == null or em == null or fu == null:
		return {}
	var jars: Array = []
	for g in crate.find_children("JarGlass", "", true, false):
		jars.append(g.get_parent())
	var boxes: Array = _obbs(crate, jars)
	ck(boxes.size() > 0, "the crate has boxes of its own")
	if boxes.is_empty():
		return {}
	var sp: Array = _span_xz(boxes)
	var ys: Vector2 = _box_corners_y(boxes)
	var cen := Vector2((float(sp[0]) + float(sp[2])) * 0.5, (float(sp[1]) + float(sp[3])) * 0.5)
	var rad: float = Vector2(float(sp[2]) - float(sp[0]), float(sp[3]) - float(sp[1])).length() * 0.5 + 0.3
	return {"cen": cen, "rad": rad, "ylo": ys.x - 0.3, "yhi": ys.y + 1.5, "em": em.global_position, "fu": fu.global_position}


func _in_crate(geo: Dictionary, p: Vector3) -> bool:
	var cen: Vector2 = geo["cen"]
	return Vector2(p.x - cen.x, p.z - cen.y).length() <= float(geo["rad"]) and p.y >= float(geo["ylo"]) and p.y <= float(geo["yhi"])


func _empties_side(geo: Dictionary, p: Vector3) -> bool:
	return p.distance_to(geo["em"] as Vector3) <= p.distance_to(geo["fu"] as Vector3)


func _jar_empty(j: Node) -> bool:
	return _jar_frac(j) <= 0.15 and not _jar_lid_shown(j)


func _jar_full(j: Node) -> bool:
	return _jar_frac(j) >= 0.98 and _jar_lid_shown(j)


## Offsets (lo, size) of the truck's boxes (jars on the bed not counted) from its origin, so its region can follow it while it drives.
func _truck_box_off(tk: Node) -> Array:
	var bed: Node = tk.find_child("BedJars", true, false)
	var boxes: Array = _obbs(tk, [bed])
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		var e := Vector3(absf((ax[0] as Vector3).x) + absf((ax[1] as Vector3).x) + absf((ax[2] as Vector3).x), absf((ax[0] as Vector3).y) + absf((ax[1] as Vector3).y) + absf((ax[2] as Vector3).y), absf((ax[0] as Vector3).z) + absf((ax[1] as Vector3).z) + absf((ax[2] as Vector3).z))
		lo = Vector3(minf(lo.x, c.x - e.x), minf(lo.y, c.y - e.y), minf(lo.z, c.z - e.z))
		hi = Vector3(maxf(hi.x, c.x + e.x), maxf(hi.y, c.y + e.y), maxf(hi.z, c.z + e.z))
	var o: Vector3 = (tk as Node3D).global_position
	return [lo - o, hi - lo]


## Sample every visible jar once per frame: traces[instance id] = [{t, pos, frac, lid, tb}], tb = the truck's region (padded) at that frame.
func _record(m: Node, tk: Node, off: Array, traces: Dictionary, stop: Callable, timeout: float) -> void:
	var t0: int = Time.get_ticks_msec()
	var last: int = t0
	var gt: float = 0.0
	for k in traces:
		var arr: Array = traces[k]
		gt = maxf(gt, float((arr[arr.size() - 1] as Dictionary)["t"]))
	while float(Time.get_ticks_msec() - t0) < timeout * 1000.0 and not stop.call():
		await process_frame
		var now: int = Time.get_ticks_msec()
		gt += float(now - last) / 1000.0 * Engine.time_scale
		last = now
		var tb: AABB = AABB((tk as Node3D).global_position + (off[0] as Vector3), off[1] as Vector3).grow(0.4)
		for j in _vis_jars(m):
			var id: int = j.get_instance_id()
			if not traces.has(id):
				traces[id] = []
			(traces[id] as Array).append({"t": gt, "pos": (j as Node3D).global_position, "frac": _jar_frac(j), "lid": _jar_lid_shown(j), "tb": tb})


## The flight inside a trace: from the last sample inside `origin` (before the first arrival) to the first arrival in `dest`. [] if none.
func _cut_flight(trace: Array, origin: Callable, dest: Callable) -> Array:
	var first_o: int = -1
	for i in trace.size():
		if origin.call(trace[i]):
			first_o = i
			break
	if first_o < 0:
		return []
	var arr: int = -1
	for i in range(first_o + 1, trace.size()):
		if dest.call(trace[i]):
			arr = i
			break
	if arr < 0:
		return []
	var start: int = first_o
	for i in range(first_o, arr):
		if origin.call(trace[i]):
			start = i
	return trace.slice(start, arr + 1)


## What is wrong with a flight (empty = nothing): it must be a real flight, not a jump, lasting about jar_fly_seconds.
func _flight_problems(fl: Array, fly_s: float, origin: Callable, dest: Callable) -> Array:
	var bad: Array = []
	if fl.size() < 2:
		return ["no flight found"]
	var air: int = 0
	for i in fl.size():
		var s: Dictionary = fl[i]
		if i > 0 and i < fl.size() - 1 and not origin.call(s) and not dest.call(s):
			air += 1
	var dur: float = float((fl[fl.size() - 1] as Dictionary)["t"]) - float((fl[0] as Dictionary)["t"])
	if air < FLIGHT_MIN_AIR:
		bad.append("only %d samples in the air (need %d): a jump, not a flight" % [air, FLIGHT_MIN_AIR])
	if dur < fly_s * 0.5 or dur > fly_s * 1.6 + 0.3:
		bad.append("lasted %.2f s, jar_fly_seconds is %.2f" % [dur, fly_s])
	return bad


## A synthetic flight: n samples from a to b over `secs`.
func _fake_flight(a: Vector3, b: Vector3, secs: float, n: int) -> Array:
	var out: Array = []
	for i in n:
		var f: float = float(i) / float(n - 1)
		out.append({"t": secs * f, "pos": a.lerp(b, f), "frac": 0.0, "lid": false, "tb": AABB()})
	return out


func t_flight_judge_can_fail() -> void:
	var a := Vector3(0.0, 0.0, 0.0)
	var b := Vector3(3.0, 0.0, 0.0)
	var at_a: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(a) <= 0.4
	var at_b: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(b) <= 0.4
	var good: Array = _fake_flight(a, b, 0.5, 40)
	var cut: Array = _cut_flight(good, at_a, at_b)
	ck(cut.size() > 4, "the cutter finds a flight in a good trace (%d samples)" % cut.size())
	eq(_flight_problems(cut, 0.5, at_a, at_b).size(), 0, "a smooth flight of the right length has no problem")
	var jump: Array = [{"t": 0.0, "pos": a, "frac": 0.0, "lid": false, "tb": AABB()}, {"t": 0.016, "pos": b, "frac": 0.0, "lid": false, "tb": AABB()}]
	ck(_flight_problems(_cut_flight(jump, at_a, at_b), 0.5, at_a, at_b).size() > 0, "a teleport is a problem")
	ck(_flight_problems(_cut_flight(_fake_flight(a, b, 3.0, 40), at_a, at_b), 0.5, at_a, at_b).size() > 0, "a flight six times too slow is a problem")
	ck(_flight_problems(_cut_flight(_fake_flight(a, b, 0.05, 40), at_a, at_b), 0.5, at_a, at_b).size() > 0, "a flight ten times too fast is a problem")
	ck(_cut_flight(_fake_flight(a, Vector3(1.5, 0.0, 0.0), 0.5, 40), at_a, at_b).is_empty(), "a jar that never arrives has no flight")
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


## Any node named ContinueButton, or any Button whose text says Continue (case-insensitive), under n.
func _continue_nodes(n: Node) -> Array:
	var out: Array = []
	for c in n.find_children("*", "", true, false):
		if String(c.name) == "ContinueButton" or (c is Button and (c as Button).text.to_lower().contains("continue")):
			out.append(c)
	return out


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

# Spec 1: the zoom frames the WHOLE risen rack (the risen frame: every cell, its bars), every cell at least min_cell_px; the bucket shows
# at least its rim and mouth (BucketMouth), its lower part may be off-screen. Nothing says the hive must be in view any more.
func t_zoom_view_option_a() -> void:
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var vp := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var hive: Node = p["Hive"]
	var c: Node = p["Centrifuge"]
	var hc: Node = hive.find_child("Honeycomb", true, false)
	ck(hc != null, "Honeycomb exists")
	var fb: Node = hive.find_child("FrameBar%d" % (int(tr["risen"]) + 1), true, false)
	var rack: Array = _obbs(hc) if hc != null else []
	if fb != null:
		rack.append_array(_obbs(fb))
	ck(rack.size() >= _cpf(), "the risen rack has boxes (%d: %d cells and the bar)" % [rack.size(), _cpf()])
	var back: Rect2 = (p["BackButton"] as Control).get_global_rect()
	var r: Rect2 = _screen_of(rack, cam)
	ck(vp.encloses(r), "the whole risen rack is on screen (screen box %s, viewport %s)" % [str(r), str(vp)])
	ck(not Rect2(Vector2.ZERO, vp.size * 0.1).encloses(r), "the 'on screen' test can fail: the rack does not fit a tenth of the viewport")
	var off_cells: int = 0
	var narrow: int = 0
	var under: int = 0
	var seen: int = 0
	var lo: float = 1.0e9
	if hc != null:
		for mi in hc.find_children("*", "MeshInstance3D", true, false):
			var mm: MeshInstance3D = mi as MeshInstance3D
			if mm.mesh == null or not mm.is_visible_in_tree():
				continue
			seen += 1
			var cr: Rect2 = _screen_of(_obbs(mm), cam)
			if not vp.encloses(cr):
				off_cells += 1
			if cr.intersects(back):
				under += 1
			var w: float = _cell_face_w(mm, cam)
			lo = minf(lo, w)
			if w < float(cv("min_cell_px")):
				narrow += 1
	eq(seen, _cpf(), "all %d cells of the risen frame were examined" % _cpf())
	eq(off_cells, 0, "every cell lies entirely on screen")
	eq(narrow, 0, "every cell is at least min_cell_px wide (smallest %.1f px, min_cell_px %s)" % [lo, str(cv("min_cell_px"))])
	eq(under, 0, "BackButton covers no cell")
	var mouth: Node3D = _nn(m, "BucketMouth") as Node3D
	if mouth != null:
		var mp: Vector2 = cam.unproject_position(mouth.global_position)
		ck(not cam.is_position_behind(mouth.global_position) and vp.has_point(mp), "BucketMouth is on screen (%s in %s)" % [str(mp), str(vp)])
		ck(not back.has_point(mp), "BucketMouth is not under BackButton")
	var glass: Array = _glass_of(c)
	ck(glass.size() > 0, "the bucket glass has a box")
	if glass.size() > 0:
		var gc: Vector3 = glass[0]
		var gax: Array = glass[1]
		var top_ok: int = 0
		# the rim: the four corners of the glass box's top face (the axis most aligned with world up)
		var best_axis: int = 0
		for i in 3:
			if absf((gax[i] as Vector3).y) > absf((gax[best_axis] as Vector3).y):
				best_axis = i
		var up: Vector3 = gax[best_axis]
		if up.y < 0.0:
			up = -up
		var other: Array = []
		for i in 3:
			if i != best_axis:
				other.append(gax[i])
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var corner: Vector3 = gc + up + (other[0] as Vector3) * sa + (other[1] as Vector3) * sb
				var cp: Vector2 = cam.unproject_position(corner)
				if vp.has_point(cp) and not back.has_point(cp):
					top_ok += 1
		eq(top_ok, 4, "the bucket's top rim (four corners of its top face) is on screen and clear of BackButton")
	_fin()


# ---------------------------------------------------------------- hive vs truck (spec change 2)

# Spec 2: a small backyard box beside the truck: height with the lid on <= 0.6 of the truck's roof height, footprint <= 1.7.
func t_hive_size_vs_truck() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	var tk: Node = _nn(m, "Truck")
	if hive == null or tk == null:
		_fin()
		return
	var hb: Array = _obbs(hive)
	var tb: Array = _obbs(tk, [tk.find_child("BedJars", true, false)])
	ck(hb.size() > 0 and tb.size() > 0, "hive (%d boxes) and truck (%d boxes) have boxes" % [hb.size(), tb.size()])
	if hb.is_empty() or tb.is_empty():
		_fin()
		return
	var hy: Vector2 = _box_corners_y(hb)
	var ty: Vector2 = _box_corners_y(tb)
	var hive_h: float = hy.y - hy.x
	var roof_h: float = ty.y - ty.x
	print("MEASURE hive height with the lid on %.2f, truck height (ground to roof, jars excluded) %.2f, ratio %.2f" % [hive_h, roof_h, hive_h / maxf(roof_h, 0.001)])
	ck(roof_h > 0.5, "the truck's height is plausible (%.2f)" % roof_h)
	ck(hive_h <= 0.6 * roof_h, "the hive with its lid on is at most 0.6 of the truck's roof height (%.2f vs %.2f x 0.6 = %.2f)" % [hive_h, roof_h, 0.6 * roof_h])
	ck(hive_h >= 0.2 * roof_h, "the hive is not flattened away (%.2f is at least 0.2 of the roof %.2f)" % [hive_h, roof_h])
	var hbody: Node = hive.find_child("HiveBody", true, false)
	var body: Array = _obbs(hbody if hbody != null else hive, [hive.find_child("HiveLid", true, false), hive.find_child("Honeycomb", true, false), hive.find_child("FrameBars", true, false)])
	var sp: Array = _span_xz(body)
	var w: float = float(sp[2]) - float(sp[0])
	var d: float = float(sp[3]) - float(sp[1])
	ck(w <= 1.7 and d <= 1.7, "the hive footprint is at most 1.7 x 1.7 (%.2f x %.2f)" % [w, d])
	var ts: Array = _span_xz(tb)
	var tl: float = maxf(float(ts[2]) - float(ts[0]), float(ts[3]) - float(ts[1]))
	ck(tl >= 2.4 and tl <= 4.0, "the truck is about 3.2 long (measured %.2f; the reference the hive is measured against)" % tl)
	ck(maxf(w, d) < tl * 0.6, "the hive is clearly smaller than the truck's length (%.2f vs %.2f)" % [maxf(w, d), tl])
	_fin()


# ---------------------------------------------------------------- the centrifuge lid rests clear (spec change 3)

# Spec 3: the resting lid (CentrifugeLidSpot, EMPTY) overlaps neither the bucket, its base ring, the spigot (all part of the centrifuge's
# own boxes), nor the hive nor the crate. Oriented boxes, separating-axis test; touching the ground or a neighbour's face is allowed.
func t_centrifuge_lid_rests_clear() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var hive: Node = _nn(m, "Hive")
	var lid: Node3D = c.find_child("Lid", true, false) as Node3D
	var spot: Node3D = c.find_child("CentrifugeLidSpot", true, false) as Node3D
	var crate: Node = _crate_root(m)
	if lid == null or spot == null or crate == null:
		ck(lid != null, "the centrifuge has a Lid")
		ck(spot != null, "CentrifugeLidSpot exists")
		ck(crate != null, "the crate was found")
		_fin()
		return
	await _frames(3)
	ck(lid.global_position.distance_to(spot.global_position) <= 0.02 and _angle_between(lid.global_basis, spot.global_basis) <= 0.03, "an EMPTY centrifuge's lid sits at CentrifugeLidSpot")
	var lb: Array = _obbs(lid)
	ck(lb.size() > 0, "the resting lid has boxes")
	var own: Array = _obbs(c, [lid, c.find_child("HeapRoot", true, false), c.find_child("SpigotJar", true, false)])
	var parts: Dictionary = {
		"the bucket, its base ring and the spigot (the centrifuge's own boxes)": own,
		"the hive": _obbs(hive),
		"the crate (jars included)": _obbs(crate),
	}
	for k in parts:
		var bodies: Array = parts[k]
		ck(bodies.size() > 0, "%s has boxes to test against" % k)
		var pen: float = _max_pen(lb, bodies)
		var who: String = ""
		for l in lb:
			for b in bodies:
				if _obb_pen(l as Array, b as Array) >= pen - 1.0e-6 and pen > CONTACT_EPS:
					who = "lid mesh %s into %s" % [str((l as Array)[2].name), str((b as Array)[2].name)]
		ck(pen <= CONTACT_EPS, "the resting lid does not overlap %s (worst penetration %.3f, contact allowed up to %.2f; %s)" % [k, pen, CONTACT_EPS, who])
	# the test can fail: put the lid into the middle of the bucket and the same measure must flag it
	var glass: Array = _glass_of(c)
	if glass.size() > 0:
		var home: Transform3D = lid.global_transform
		lid.global_position = glass[0] as Vector3
		var forced: float = _max_pen(_obbs(lid), own)
		ck(forced > CONTACT_EPS, "control: a lid forced into the bucket IS flagged (penetration %.3f)" % forced)
		lid.global_transform = home
	_fin()


# ---------------------------------------------------------------- nodes and config of 0.1.2

func t_node_contract_012() -> void:
	var ps: Variant = load("res://scenes/props/jar_crate.tscn")
	ck(ps != null, "jar_crate.tscn loads")
	if ps != null:
		var cr: Node = (ps as PackedScene).instantiate()
		_to_free.append(cr)
		for nm in ["CrateEmpties", "CrateFulls"]:
			var n: Node = cr.find_child(nm, true, false)
			ck(n != null and n is Node3D, "jar_crate.tscn has a Node3D marker %s" % nm)
		var e: Node = cr.find_child("CrateEmpties", true, false)
		var f: Node = cr.find_child("CrateFulls", true, false)
		if e is Node3D and f is Node3D:
			ck((e as Node3D).position.distance_to((f as Node3D).position) >= 0.2, "the two groups are apart (markers %.2f apart)" % (e as Node3D).position.distance_to((f as Node3D).position))
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	for nm in ["SummaryModal", "SummaryJarsLabel", "SummaryValueLabel", "SummaryTotalLabel", "SummaryOkButton", "CrateEmpties", "CrateFulls", "BucketMouth", "ZoomFraming"]:
		_nn(m, nm)
	ck(m.find_child("SummaryBonusLabel", true, false) == null, "SummaryBonusLabel is removed (spec change 7)")
	ck(m.find_child("ContinueButton", true, false) == null, "ContinueButton is removed (spec change 6)")
	_fin()


func t_config_012() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres loads")
	if c == null:
		_fin()
		return
	for pair in [["jar_fly_seconds", 0.5], ["crate_empty_jars_shown", 10.0]]:
		var v: Variant = c.get(pair[0])
		ck(v != null, "default_config.tres has '%s'" % pair[0])
		if v != null:
			near(float(v), float(pair[1]), "default %s" % pair[0])
	ck(float(c.get("zoom_size")) > 0.0 and float(c.get("frame_rise")) > 0.0, "zoom_size and frame_rise are Bob's positive values")
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd readable")
	if f != null:
		var text: String = f.get_as_text()
		f.close()
		for nm in ["jar_fly_seconds", "crate_empty_jars_shown"]:
			ck(text.contains("@export var %s" % nm), "game_config.gd has @export var %s (Dev mode lists exported values)" % nm)
	_set_dev_mode(true)
	var panel: Node = await _mk_panel()
	if panel != null:
		for nm in ["jar_fly_seconds", "crate_empty_jars_shown", "zoom_size", "frame_rise"]:
			ck(_row_spin(panel, nm) != null, "the Dev panel has a row for %s" % nm)
	_fin()


# ---------------------------------------------------------------- the crate and the jar flights (spec change 5)

# Spec 5: the crate shows EMPTY jars (clear glass, no honey, no lid), up to crate_empty_jars_shown, on the CrateEmpties side, and no full
# jar while nothing has been bottled. The number is read from the config (a changed value changes what is drawn).
func t_crate_shows_empties() -> void:
	for want_n in [int(cv("crate_empty_jars_shown")), 4]:
		_set_cfg("crate_empty_jars_shown", want_n)
		var m: Node = await _mk_main()
		if m == null:
			_fin()
			return
		_set_cfg("base_seconds_per_jar", 1.0e9)
		var geo: Dictionary = _geo_crate(m)
		if geo.is_empty():
			_fin()
			return
		await _frames(4)
		var empties: int = 0
		var fulls: int = 0
		var stray: int = 0
		var mk: Node3D = m.find_child("CrateEmpties", true, false) as Node3D
		var near_m: int = 0
		for j in _vis_jars(m):
			var jp: Vector3 = (j as Node3D).global_position
			if not _in_crate(geo, jp):
				stray += 1
			elif _empties_side(geo, jp):
				empties += 1
				ck(_jar_empty(j), "a jar on the CrateEmpties side is empty: no honey, no lid (fraction %.2f, lid %s)" % [_jar_frac(j), str(_jar_lid_shown(j))])
				if jp.distance_to(mk.global_position) <= 1.5:
					near_m += 1
			else:
				fulls += 1
		eq(empties, want_n, "the crate shows %d empty jars (crate_empty_jars_shown)" % want_n)
		eq(fulls, 0, "no full jar in the crate before anything is bottled")
		eq(stray, 0, "no jar shows outside the crate before bottling (the spigot jar is hidden)")
		eq(near_m, want_n, "the empties stand around the CrateEmpties marker (within 1.5)")
		m.get_parent().remove_child(m)
		m.free()
		_to_free.erase(m)
	_fin()


## Common set-up for the flight tests: the scene, the crate's place, the truck's region.
func _bottling_rig(fly: float, spj: float) -> Dictionary:
	_set_cfg("jar_fly_seconds", fly)
	_set_cfg("bottling_seconds_per_jar", spj)
	var m: Node = await _mk_main()
	if m == null:
		return {}
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var tk: Node = _nn(m, "Truck")
	var geo: Dictionary = _geo_crate(m)
	if c == null or tk == null or geo.is_empty():
		return {}
	await _frames(4)
	return {"m": m, "c": c, "tk": tk, "geo": geo, "off": _truck_box_off(tk)}


## One frame of cells (2 jars), lid on, cranked to the end by calls: from here on the game must carry on by itself.
func _crank_unaided(c: Node) -> void:
	var cells: int = _cpf()
	c.call("add_cells", cells, _jars_of(cells))
	c.call("close_lid")
	c.call("begin_crank")
	_crank_done(c)


## Where the jar stands while its honey fills (fraction 0.25 to 0.75, no lid): the place under the spigot, measured, not assumed.
func _spigot_spot(traces: Dictionary) -> Dictionary:
	var pts: Array = []
	for k in traces:
		for s in (traces[k] as Array):
			var sd: Dictionary = s
			if not bool(sd["lid"]) and float(sd["frac"]) > 0.25 and float(sd["frac"]) < 0.75:
				pts.append(sd["pos"])
	if pts.size() < 3:
		return {}
	var mean := Vector3.ZERO
	for p in pts:
		mean += p as Vector3
	mean /= float(pts.size())
	var spread: float = 0.0
	for p in pts:
		spread = maxf(spread, (p as Vector3).distance_to(mean))
	return {"pos": mean, "spread": spread, "n": pts.size()}


func _bed_count(tk: Node) -> int:
	var bed: Node = tk.find_child("BedJars", true, false)
	var n: int = 0
	if bed != null:
		for j in bed.get_children():
			if (j as Node3D).is_visible_in_tree() and not (j is Label3D):
				n += 1
	return n


# Spec 5: bottling starts, the first empty jar FLIES from the crate to under the spigot (jar_fly_seconds), fills over
# bottling_seconds_per_jar, gets its lid, then flies to the truck's bed (the truck is home); then the next empty jar flies in.
# The crate shows its empties again afterwards (unlimited supply). Jars are followed frame by frame through the real scene.
func t_jar_flights_to_spigot_and_truck() -> void:
	var fly: float = 0.8
	var spj: float = 1.5
	var rig: Dictionary = await _bottling_rig(fly, spj)
	if rig.is_empty():
		_fin()
		return
	var m: Node = rig["m"]
	var c: Node = rig["c"]
	var tk: Node = rig["tk"]
	var geo: Dictionary = rig["geo"]
	var off: Array = rig["off"]
	var jars_n: int = int(floorf(_jars_of(_cpf()) + 0.000001))
	var empty: int = _st(c, "EMPTY")
	_crank_unaided(c)
	var traces: Dictionary = {}
	await _record(m, tk, off, traces, func() -> bool: return int(c.get("state")) == empty, (spj + 2.0 * fly) * float(jars_n) + 8.0)
	eq(int(c.get("state")), empty, "bottling ended")
	await _record(m, tk, off, traces, func() -> bool: return false, fly + 0.8)
	var spot: Dictionary = _spigot_spot(traces)
	ck(not spot.is_empty(), "a jar was seen filling (honey between a quarter and three quarters, no lid): the spigot spot exists")
	if spot.is_empty():
		_fin()
		return
	var sp: Vector3 = spot["pos"]
	ck(float(spot["spread"]) <= 0.08, "the jar stands still while it fills (spread %.3f)" % float(spot["spread"]))
	var cpos: Vector3 = (c as Node3D).global_position
	ck(Vector2(sp.x - cpos.x, sp.z - cpos.z).length() <= 2.5, "the fill spot is at the centrifuge (%.2f from its origin)" % Vector2(sp.x - cpos.x, sp.z - cpos.z).length())
	ck(not _in_crate(geo, sp), "the fill spot is not in the crate")
	var in_origin: Callable = func(s: Dictionary) -> bool: return _in_crate(geo, s["pos"]) and _empties_side(geo, s["pos"])
	var at_spigot: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(sp) <= 0.35
	var on_truck: Callable = func(s: Dictionary) -> bool: return (s["tb"] as AABB).has_point(s["pos"])
	var flights_in: Array = []
	var landings: Array = []
	var arrivals: Array = []
	var fulls_at: Array = []
	for k in traces:
		var tr: Array = traces[k]
		var fin: Array = _cut_flight(tr, in_origin, at_spigot)
		if fin.size() > 0:
			flights_in.append(fin)
			var arrive_t: float = float((fin[fin.size() - 1] as Dictionary)["t"])
			arrivals.append(arrive_t)
			var full_t: float = -1.0
			for s in tr:
				var sd: Dictionary = s
				if float(sd["t"]) >= arrive_t and bool(sd["lid"]) and float(sd["frac"]) >= 0.98:
					full_t = float(sd["t"])
					break
			fulls_at.append(full_t)
		var land: Array = _cut_flight(tr, at_spigot, on_truck)
		if land.size() > 0:
			landings.append(land)
			var lastp: Dictionary = tr[tr.size() - 1]
			ck(float(lastp["frac"]) >= 0.98 and bool(lastp["lid"]), "a jar that reached the truck is full with its lid (fraction %.2f)" % float(lastp["frac"]))
	ck(flights_in.size() >= jars_n, "%d empty jars flew from the crate to the spigot (found %d)" % [jars_n, flights_in.size()])
	for fl in flights_in:
		var bad: Array = _flight_problems(fl, fly, in_origin, at_spigot)
		ck(bad.is_empty(), "crate-to-spigot flight: %s" % "; ".join(bad))
	for i in fulls_at.size():
		var rise: float = float(fulls_at[i]) - float(arrivals[i])
		ck(float(fulls_at[i]) >= 0.0 and rise >= spj * 0.7 and rise <= spj * 1.15 + 0.25, "the jar fills over bottling_seconds_per_jar after it arrives: %.2f s (bottling_seconds_per_jar %.2f)" % [rise, spj])
	ck(landings.size() >= jars_n, "%d full jars flew from the spigot onto the truck (found %d)" % [jars_n, landings.size()])
	for fl in landings:
		var bad2: Array = _flight_problems(fl, fly, at_spigot, on_truck)
		ck(bad2.is_empty(), "spigot-to-truck flight: %s" % "; ".join(bad2))
	arrivals.sort()
	if arrivals.size() >= 2 and fulls_at.size() >= 1:
		ck(float(arrivals[1]) >= float(fulls_at.min()) - 0.05, "the next empty jar flies in after the first one is full (second arrival %.2f, first full %.2f)" % [float(arrivals[1]), float(fulls_at.min())])
	eq(int(tk.get("loaded_jars")), jars_n, "%d jars are on the truck (the count logic is unchanged)" % jars_n)
	eq(int(tk.get("crate_jars")), 0, "none went to the crate while the truck was home")
	eq(_bed_count(tk), jars_n, "the landed jars show on the truck's bed")
	var empties_now: int = 0
	var fulls_in_crate: int = 0
	for j in _vis_jars(m):
		var jp: Vector3 = (j as Node3D).global_position
		if _in_crate(geo, jp):
			if _empties_side(geo, jp):
				empties_now += 1
			else:
				fulls_in_crate += 1
	eq(empties_now, int(cv("crate_empty_jars_shown")), "the crate shows its empties again: a jar taken is replaced (unlimited supply)")
	eq(fulls_in_crate, 0, "no full jar in the crate")
	_fin()


# Spec 5: with the truck AWAY the filled jar flies back into the crate, full with its lid, to the CrateFulls side, and the crate_jars count follows.
func t_jar_lands_in_crate_when_truck_away() -> void:
	var fly: float = 0.8
	var spj: float = 1.0
	_set_cfg("truck_trip_seconds", 120.0)
	var rig: Dictionary = await _bottling_rig(fly, spj)
	if rig.is_empty():
		_fin()
		return
	var m: Node = rig["m"]
	var c: Node = rig["c"]
	var tk: Node = rig["tk"]
	var geo: Dictionary = rig["geo"]
	var off: Array = rig["off"]
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	tk.call("sell")
	ck(bool(tk.get("away")), "the truck is away")
	await _frames(3)
	var jars_n: int = int(floorf(_jars_of(_cpf()) + 0.000001))
	var empty: int = _st(c, "EMPTY")
	_crank_unaided(c)
	var traces: Dictionary = {}
	await _record(m, tk, off, traces, func() -> bool: return int(c.get("state")) == empty, (spj + 2.0 * fly) * float(jars_n) + 8.0)
	await _record(m, tk, off, traces, func() -> bool: return false, fly + 0.8)
	var spot: Dictionary = _spigot_spot(traces)
	ck(not spot.is_empty(), "a jar was seen filling")
	if spot.is_empty():
		_fin()
		return
	var sp: Vector3 = spot["pos"]
	var at_spigot: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(sp) <= 0.35
	var in_fulls: Callable = func(s: Dictionary) -> bool: return _in_crate(geo, s["pos"]) and not _empties_side(geo, s["pos"])
	var landings: Array = []
	for k in traces:
		var land: Array = _cut_flight(traces[k], at_spigot, in_fulls)
		if land.size() > 0:
			landings.append(land)
	ck(landings.size() >= jars_n, "%d full jars flew from the spigot back into the crate's full group (found %d)" % [jars_n, landings.size()])
	for fl in landings:
		var bad: Array = _flight_problems(fl, fly, at_spigot, in_fulls)
		ck(bad.is_empty(), "spigot-to-crate flight: %s" % "; ".join(bad))
	eq(int(tk.get("crate_jars")), jars_n, "crate_jars counts the %d jars" % jars_n)
	eq(int(tk.get("loaded_jars")), 0, "nothing on the away truck")
	var fulls: int = 0
	var empties: int = 0
	for j in _vis_jars(m):
		var jp: Vector3 = (j as Node3D).global_position
		if not _in_crate(geo, jp):
			continue
		if _empties_side(geo, jp):
			empties += 1
			ck(_jar_empty(j), "a jar on the empties side stays empty")
		else:
			fulls += 1
			ck(_jar_full(j), "a jar landed in the crate is full with its lid (fraction %.2f)" % _jar_frac(j))
	eq(fulls, jars_n, "%d full jars stand on the CrateFulls side" % jars_n)
	eq(empties, int(cv("crate_empty_jars_shown")), "the empties are still there, apart from the fulls")
	_fin()


# Spec 5: when the truck returns, the crate's full jars fly onto it up to its capacity; the rest stay in the crate.
func t_crate_fulls_fly_to_truck_on_return() -> void:
	var fly: float = 0.6
	_set_cfg("truck_capacity_jars", 3)
	_set_cfg("truck_trip_seconds", 2.0)
	var rig: Dictionary = await _bottling_rig(fly, 1.0)
	if rig.is_empty():
		_fin()
		return
	var m: Node = rig["m"]
	var tk: Node = rig["tk"]
	var geo: Dictionary = rig["geo"]
	var off: Array = rig["off"]
	var cap: int = int(cv("truck_capacity_jars"))
	for i in cap:
		tk.call("receive_jar")
	tk.call("sell")
	var extra: int = cap + 2
	for i in extra:
		tk.call("receive_jar")
	eq(int(tk.get("crate_jars")), extra, "%d full jars wait in the crate" % extra)
	await _frames(4)
	var shown0: int = 0
	for j in _vis_jars(m):
		var jp: Vector3 = (j as Node3D).global_position
		if _in_crate(geo, jp) and not _empties_side(geo, jp):
			shown0 += 1
			ck(_jar_full(j), "a jar in the crate's full group is full with its lid")
	ck(shown0 >= 1, "the crate shows its full jars (%d drawn for %d in the count)" % [shown0, extra])
	var traces: Dictionary = {}
	await _record(m, tk, off, traces, func() -> bool: return not bool(tk.get("away")), 10.0)
	ck(not bool(tk.get("away")), "the truck came back")
	await _record(m, tk, off, traces, func() -> bool: return false, fly + 1.2)
	var in_fulls: Callable = func(s: Dictionary) -> bool: return _in_crate(geo, s["pos"]) and not _empties_side(geo, s["pos"])
	var on_truck: Callable = func(s: Dictionary) -> bool: return (s["tb"] as AABB).has_point(s["pos"]) and not _in_crate(geo, s["pos"])
	var flights: Array = []
	for k in traces:
		var fl: Array = _cut_flight(traces[k], in_fulls, on_truck)
		if fl.size() > 0:
			flights.append(fl)
	eq(flights.size(), cap, "exactly truck_capacity_jars (%d) full jars flew from the crate onto the truck" % cap)
	for fl in flights:
		var bad: Array = _flight_problems(fl, fly, in_fulls, on_truck)
		ck(bad.is_empty(), "crate-to-truck flight: %s" % "; ".join(bad))
	eq(int(tk.get("loaded_jars")), cap, "the truck holds its capacity")
	eq(int(tk.get("crate_jars")), extra - cap, "the rest stay in the crate")
	eq(_bed_count(tk), cap, "the jars show on the truck's bed")
	_fin()


# ---------------------------------------------------------------- bottling by itself, no Continue (spec change 6)

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

# Spec 7: bottling shows no summary. Tapping Sell (a real press on the icon) credits the money, sends the truck off, and shows the modal:
# jars sold, price per jar, total, OK to close; no bonus line. Distinct numbers (4 jars, 7 each, 28) so a wrong line cannot pass by luck.
func t_summary_after_sell() -> void:
	_set_cfg("truck_capacity_jars", 4)
	_set_cfg("sale_value_per_jar", 7)
	_set_cfg("bottling_seconds_per_jar", 0.4)
	_set_cfg("jar_fly_seconds", 0.2)
	_set_cfg("truck_trip_seconds", 60.0)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var c: Node = p["Centrifuge"]
	var tk: Node = p["Truck"]
	var e: Node = _eco()
	var modal: Node = p["SummaryModal"]
	await _frames(3)
	ck(not _shown(modal), "no summary at the start")
	# bottle 2 jars through the real centrifuge: the modal must stay hidden for the whole run and after it
	var empty: int = _st(c, "EMPTY")
	_crank_unaided(c)
	var seen_modal: bool = false
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 12000:
		await process_frame
		if _shown(modal):
			seen_modal = true
		if int(c.get("state")) == empty and Time.get_ticks_msec() - t0 >= 1500:
			break
	await _wait(0.8)
	if _shown(modal):
		seen_modal = true
	eq(int(c.get("state")), empty, "bottling ended")
	ck(not seen_modal, "no summary while or after bottling (it comes after Sell)")
	eq(int(tk.get("loaded_jars")), 2, "two jars bottled onto the truck")
	for i in 2:
		tk.call("receive_jar")
	await _frames(4)
	ck(bool(tk.call("can_sell")), "the truck is full and home")
	ck(_shown(p["SellIcon"]), "the Sell icon shows")
	var money0: int = int(e.get("money"))
	var x0: float = (tk as Node3D).global_position.x
	var z0: float = (tk as Node3D).global_position.z
	var clicked: bool = await fi.click_icon(p["SellIcon"] as Control)
	ck(clicked, "the press went to where the Sell icon is drawn")
	var shown: bool = await _until(func() -> bool: return _shown(modal), 3.0)
	ck(shown, "the summary shows after Sell")
	eq(int(e.get("money")), money0 + 28, "Sell credited 4 x 7 = 28")
	ck(bool(tk.get("away")), "the truck is away")
	if shown:
		var jl: Node = m.find_child("SummaryJarsLabel", true, false)
		var vl: Node = m.find_child("SummaryValueLabel", true, false)
		var tl: Node = m.find_child("SummaryTotalLabel", true, false)
		var jt: String = String(jl.get("text")) if jl != null else ""
		var vt: String = String(vl.get("text")) if vl != null else ""
		var tt: String = String(tl.get("text")) if tl != null else ""
		print("MEASURE summary texts: jars '%s', value '%s', total '%s'" % [jt, vt, tt])
		ck(jt.contains("4") and not jt.contains("28") and not jt.contains("7"), "the jars line shows 4 jars sold ('%s')" % jt)
		ck(vt.contains("7") and not vt.contains("28"), "the price line shows 7 per jar ('%s')" % vt)
		ck(tt.contains("28"), "the total line shows 28 ('%s')" % tt)
		ck(m.find_child("SummaryBonusLabel", true, false) == null, "no bonus line")
		await _wait(0.6)
		var moved: float = Vector2((tk as Node3D).global_position.x - x0, (tk as Node3D).global_position.z - z0).length()
		ck(moved > 0.2 and _shown(modal), "the truck drives off behind the open modal (moved %.2f)" % moved)
		await fi.click_ctl(p["SummaryOkButton"] as Control)
		await _frames(3)
		ck(not _shown(modal), "OK closes the summary")
	_fin()
