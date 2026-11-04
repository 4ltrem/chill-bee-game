# Quinn: Prototype 0 revision 3 unit tests, written from game/specs/prototype-0.md (approved 2026-11-04) BEFORE the code.
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
#  * Patricia's scripts are loaded at run time with load() (no class_name references), and each load is asserted:
#    can_instantiate(), a non-null instance, instance.get_script() == the loaded script.
#  * Silent-PASS guards: every test must reach its final _fin() line and make at least one check, else it FAILS;
#    a harness self-check proves eq() can fail; the run ends with "RAN n of n".
#  * CB_SCRIPTS=res://tests/broken/ (env var) points the loads at a broken copy of the scripts folder, to show a
#    test fails for the right reason (Done when, last bullet of the unit-test list).
# Spec line numbers in the comments above each test refer to game/specs/prototype-0.md.
extends SceneTree

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
	var tests: Array[String] = [
		# economy (L67, L122)
		"t_cost_formula", "t_cost_max_level", "t_buy_deducts_and_levels", "t_buy_blocked_unaffordable",
		"t_fill_multiplier", "t_bee_count", "t_fill_multiplier_is_bees_over_base", "t_economy_removed_jars",
		"t_earn_and_jar_value", "t_drawn_count_capped",
		# hive (L53, L123)
		"t_fill_time_level0", "t_fill_time_with_levels", "t_hive_rate_is_live", "t_overflow_and_pause",
		"t_take_frame_not_full", "t_take_frame_with_overflow", "t_became_full_count_full_overflow",
		"t_became_full_once_while_filling",
		# honeycomb (L124)
		"t_cell_transitions", "t_cell_reset_on_next_harvest", "t_uncap_only_from_capped", "t_all_uncapped_signal",
		# centrifuge (L61-L65, L125, L222-L226)
		"t_centrifuge_state_flow", "t_has_room", "t_taps_per_frame", "t_tap_cap", "t_tap_cap_is_live",
		"t_hold_at_cap", "t_hold_ramp_is_visual_only", "t_hold_never_slower", "t_hold_release_stops",
		"t_crank_ignored_outside_cranking", "t_real_mouse_taps_crank", "t_real_mouse_hold_cranks",
		"t_real_touch_taps_crank", "t_button_press_is_not_a_crank",
		# bottling and truck (L65-L66, L229-L230)
		"t_bottling_timing", "t_bottling_time_is_live", "t_truck_full_and_can_sell", "t_truck_sell_credits_at_once",
		"t_truck_crate_while_away", "t_truck_return_loads_crate", "t_truck_trip_time_is_live",
		# scene-level flow (L55-L56, L72-L78, L227-L228)
		"t_back_keeps_frame", "t_fork_hidden_unless_empty", "t_state_table_icons",
		# floating icons (L127)
		"t_icon_follows_anchor", "t_icon_hidden_behind_camera",
		# config and dev mode (L95-L113, L205-L215, L231)
		"t_config_values", "t_config_placeholders_marked", "t_dev_mode_setting", "t_dev_no_panel_when_off",
		"t_dev_panel_when_on", "t_dev_max_tap_rate", "t_dev_bottling_seconds", "t_dev_save_reset_roundtrip",
		"t_dev_user_file_ignored_when_off", "t_dev_backquote_opens", "t_dev_three_finger_opens", "t_dev_actions",
	]
	_selfcheck()
	_backup_user_cfg()
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


func near(actual: float, expected: float, what: String, tol: float = 0.001) -> void:
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
	ck(false, "no enum member %s in %s (spec: state machine EMPTY, FULL, CRANKING, DONE, BOTTLING)" % [state_name, o.get_script().resource_path])
	return -999


func _add_root(n: Node) -> void:
	n.set_process(false)
	n.set_physics_process(false)
	root.add_child(n)
	n.set_process(false)
	n.set_physics_process(false)


func _mk_hive() -> Object:
	var h: Object = _make("hive.gd")
	if h != null:
		_give_config(h)
	return h


func _mk_cen() -> Object:
	var c: Object = _make("centrifuge.gd")
	if c == null:
		return null
	_give_config(c)
	_add_root(c as Node)
	await process_frame
	(c as Node).set_process(false)
	(c as Node).set_physics_process(false)
	return c


func _mk_truck() -> Object:
	var t: Object = _make("truck.gd")
	if t == null:
		return null
	_give_config(t)
	_add_root(t as Node)
	await process_frame
	(t as Node).set_process(false)
	(t as Node).set_physics_process(false)
	return t


func _mk_honeycomb() -> Object:
	var h: Object = _make("honeycomb.gd")
	if h == null:
		return null
	_give_config(h)
	root.add_child(h as Node)   # the spec builds the cells in _ready
	await process_frame
	if "active" in h:
		h.set("active", true)
	return h


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _bump() -> void:
	_counter += 1


## Fill a centrifuge and start cranking (EMPTY -> FULL -> CRANKING).
func _to_cranking(c: Object) -> void:
	c.call("fill", int(cv("frame_jars")))
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


func _to_window() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func _push_mouse(vp_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos * _to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(ev)


## An empty point of the screen: no Control there, so the press reaches _unhandled_input like a real tap.
const EMPTY_SPOT := Vector2(360.0, 640.0)


func _cell_state(hc: Object, i: int) -> int:
	if not hc.has_method("get_state"):
		ck(false, "honeycomb has no get_state(i): the contract names no cell-state getter, so I cannot read cells")
		return -1
	return int(hc.call("get_state", i))


func _fill_hive_to_capacity(h: Object) -> void:
	# exactly one frame in storage, overflow empty (a long advance would also fill the overflow)
	var jars: float = float(cv("frame_jars"))
	var secs: float = float(cv("base_seconds_per_jar"))
	h.call("advance", jars * secs, 1.0)


# ---------------------------------------------------------------- economy

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


# ---------------------------------------------------------------- hive

# L53, L101: one frame fills in frame_jars x base_seconds_per_jar.
func t_fill_time_level0() -> void:
	var h: Object = _mk_hive()
	var jars: float = float(cv("frame_jars"))
	var secs: float = float(cv("base_seconds_per_jar"))
	var full_t: float = jars * secs
	var steps: int = int((full_t - 1.0) / 0.1)
	for i in steps:
		h.call("advance", 0.1, 1.0)
	ck(not h.call("is_full"), "not full 1 s before the full time")
	near(float(h.get("storage")), steps * 0.1 / secs, "storage before full", 0.01)
	h.call("advance", 2.0, 1.0)
	ck(h.call("is_full"), "full 1 s after the full time")
	eq(h.get("capacity"), int(jars), "capacity = frame_jars")
	_fin()


# L53, L67: the fill rate scales with the bee count.
func t_fill_time_with_levels() -> void:
	var e: Node = _eco()
	e.set("swarm_level", 1)
	var m: float = float(e.call("fill_multiplier"))
	var h: Object = _mk_hive()
	var full_t: float = float(cv("frame_jars")) * float(cv("base_seconds_per_jar")) / m
	h.call("advance", full_t - 1.0, m)
	ck(not h.call("is_full"), "level 1 not full 1 s early")
	h.call("advance", 2.0, m)
	ck(h.call("is_full"), "level 1 full 1 s late")
	_fin()


# L97: no cached config; Dev mode edits apply at once.
func t_hive_rate_is_live() -> void:
	var h: Object = _mk_hive()
	var secs: float = float(cv("base_seconds_per_jar"))
	h.call("advance", secs * 2.0, 1.0)
	near(float(h.get("storage")), 2.0, "2 jars after 2 x base seconds", 0.01)
	_set_cfg("base_seconds_per_jar", secs / 2.0)
	var before: float = float(h.get("storage"))
	h.call("advance", secs, 1.0)   # at the halved time per jar this is 2 more jars
	near(float(h.get("storage")) - before, 2.0, "rate change applies to the next advance", 0.01)
	_fin()


# L53: past capacity into the overflow buffer of overflow_frames frames; then paused.
func t_overflow_and_pause() -> void:
	var h: Object = _mk_hive()
	var jars: float = float(cv("frame_jars"))
	var secs: float = float(cv("base_seconds_per_jar"))
	var ocap: float = jars * float(cv("overflow_frames"))
	h.call("advance", jars * secs, 1.0)
	ck(h.call("is_full"), "full after one frame of time")
	near(float(h.get("overflow")), 0.0, "overflow starts empty")
	ck(not h.call("is_paused"), "not paused yet")
	h.call("advance", ocap * secs / 2.0, 1.0)
	near(float(h.get("overflow")), ocap / 2.0, "overflow half full", 0.01)
	near(float(h.get("storage")), jars, "storage stays at capacity")
	ck(not h.call("is_paused"), "not paused at half overflow")
	h.call("advance", ocap * secs / 2.0 + 1.0, 1.0)
	near(float(h.get("overflow")), ocap, "overflow full", 0.01)
	ck(h.call("is_paused"), "paused when both are full")
	h.call("advance", 1000.0, 1.0)
	near(float(h.get("overflow")), ocap, "overflow capped", 0.01)
	near(float(h.get("storage")), jars, "storage capped")
	_fin()


# L123
func t_take_frame_not_full() -> void:
	var h: Object = _mk_hive()
	var jars: float = float(cv("frame_jars"))
	var secs: float = float(cv("base_seconds_per_jar"))
	h.call("advance", jars * secs / 2.0, 1.0)
	eq(h.call("take_frame"), 0, "take_frame when not full returns 0")
	near(float(h.get("storage")), jars / 2.0, "storage untouched", 0.01)
	_fin()


# L123: take_frame() returns a frame and the overflow moves into storage.
func t_take_frame_with_overflow() -> void:
	var h: Object = _mk_hive()
	var jars: float = float(cv("frame_jars"))
	var secs: float = float(cv("base_seconds_per_jar"))
	h.call("advance", jars * secs + jars * secs / 2.0, 1.0)   # full + half a frame of overflow
	eq(h.call("take_frame"), int(jars), "take_frame returns one frame")
	near(float(h.get("storage")), jars / 2.0, "overflow moved into storage", 0.01)
	near(float(h.get("overflow")), 0.0, "overflow emptied", 0.01)
	ck(not h.call("is_full"), "not full after taking")
	h.call("advance", jars * secs, 1.0)
	ck(h.call("is_full"), "refills")
	var h2: Object = _mk_hive()
	h2.call("advance", 100000.0, 1.0)
	eq(h2.call("take_frame"), int(jars), "take from a paused hive")
	near(float(h2.get("storage")), minf(jars, jars * float(cv("overflow_frames"))), "a full overflow refills storage", 0.01)
	ck(not h2.call("is_paused"), "unpaused after take_frame")
	_fin()


func t_became_full_count_full_overflow() -> void:
	var h: Object = _mk_hive()
	var jars: float = float(cv("frame_jars"))
	var secs: float = float(cv("base_seconds_per_jar"))
	_counter = 0
	h.connect("became_full", _bump)
	h.call("advance", jars * secs, 1.0)
	eq(_counter, 1, "became_full on first fill")
	h.call("advance", jars * secs, 1.0)
	eq(_counter, 1, "no repeat while full or overflowing")
	h.call("advance", 100000.0, 1.0)
	h.call("take_frame")
	eq(_counter, 2, "became_full emitted exactly once by take_frame with a full overflow")
	h.call("advance", 5.0, 1.0)
	eq(_counter, 2, "no extra emit afterwards")
	_fin()


func t_became_full_once_while_filling() -> void:
	var h: Object = _mk_hive()
	var total: float = (float(cv("frame_jars")) * float(cv("base_seconds_per_jar"))) + 10.0
	_counter = 0
	h.connect("became_full", _bump)
	var steps: int = int(total / 0.1)
	for i in steps:
		h.call("advance", 0.1, 1.0)
	eq(_counter, 1, "one emit across the fill")
	_fin()


# ---------------------------------------------------------------- honeycomb

# L124: 0 = Capped, 1 = Uncapped, 2 = Extracted; frame of grid_cols x grid_rows cells (7 x 5 = 35).
func t_cell_transitions() -> void:
	var hc: Object = await _mk_honeycomb()
	if hc == null:
		_fin()
		return
	var n: int = int(cv("grid_cols")) * int(cv("grid_rows"))
	for i in n:
		eq(_cell_state(hc, i), 0, "initial state of cell %d" % i)
	ck(not hc.call("all_uncapped"), "not all uncapped at start")
	ck(hc.call("uncap_at", 3), "uncap_at(3) returns true")
	eq(_cell_state(hc, 3), 1, "cell 3 Uncapped")
	for i in n:
		hc.call("uncap_at", i)
	ck(hc.call("all_uncapped"), "all uncapped")
	for i in n:
		eq(_cell_state(hc, i), 1, "state %d" % i)
	hc.call("extract_all")
	for i in n:
		eq(_cell_state(hc, i), 2, "extracted %d" % i)
	_fin()


# L68, L227 (new open shows all Capped)
func t_cell_reset_on_next_harvest() -> void:
	var hc: Object = await _mk_honeycomb()
	if hc == null:
		_fin()
		return
	var n: int = int(cv("grid_cols")) * int(cv("grid_rows"))
	for i in n:
		hc.call("uncap_at", i)
	hc.call("extract_all")
	hc.call("reset")
	for i in n:
		eq(_cell_state(hc, i), 0, "Capped after reset %d" % i)
	ck(not hc.call("all_uncapped"), "not all uncapped after reset")
	for i in n:
		hc.call("uncap_at", i)
	ck(hc.call("all_uncapped"), "second round uncaps")
	_fin()


# L55: uncapping is state 0 -> 1 only.
func t_uncap_only_from_capped() -> void:
	var hc: Object = await _mk_honeycomb()
	if hc == null:
		_fin()
		return
	var n: int = int(cv("grid_cols")) * int(cv("grid_rows"))
	ck(hc.call("uncap_at", 0), "first uncap")
	ck(not hc.call("uncap_at", 0), "second uncap of the same cell is a no-op")
	ck(not hc.call("uncap_at", -1), "negative index")
	ck(not hc.call("uncap_at", n), "out of range")
	hc.call("extract_all")
	ck(not hc.call("uncap_at", 0), "an Extracted cell cannot be uncapped")
	eq(_cell_state(hc, 0), 2, "still Extracted")
	_fin()


# L124
func t_all_uncapped_signal() -> void:
	var hc: Object = await _mk_honeycomb()
	if hc == null:
		_fin()
		return
	var n: int = int(cv("grid_cols")) * int(cv("grid_rows"))
	_counter = 0
	hc.connect("all_cells_uncapped", _bump)
	for i in n - 1:
		hc.call("uncap_at", i)
	eq(_counter, 0, "not emitted one cell short")
	hc.call("uncap_at", n - 1)
	eq(_counter, 1, "emitted once at the last cell")
	_fin()


# ---------------------------------------------------------------- centrifuge

# L125, L59-L65: EMPTY -> FULL -> CRANKING -> DONE -> BOTTLING -> EMPTY, with state_changed(state).
func t_centrifuge_state_flow() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var jars: int = int(cv("frame_jars"))
	var rate: float = float(cv("max_tap_rate"))
	var seen: Array = []
	c.connect("state_changed", func(s: Variant) -> void: seen.append(int(s)))
	eq(c.get("state"), _st(c, "EMPTY"), "starts EMPTY")
	c.call("fill", jars)
	eq(c.get("state"), _st(c, "FULL"), "fill() -> FULL")
	eq(c.get("jars_total"), jars, "jars_total after fill")
	c.call("begin_crank")
	eq(c.get("state"), _st(c, "CRANKING"), "begin_crank() -> CRANKING")
	_tap_spaced(c, int(cv("taps_per_frame")), 1.0 / rate + 0.01)
	eq(c.get("state"), _st(c, "DONE"), "all turns counted -> DONE")
	c.call("open_spigot")
	eq(c.get("state"), _st(c, "BOTTLING"), "open_spigot() -> BOTTLING")
	c.call("advance", float(cv("bottling_seconds_per_jar")) * jars + 1.0)
	eq(c.get("state"), _st(c, "EMPTY"), "last jar bottled -> EMPTY")
	eq(seen, [_st(c, "FULL"), _st(c, "CRANKING"), _st(c, "DONE"), _st(c, "BOTTLING"), _st(c, "EMPTY")], "state_changed order")
	_fin()


# L58, L106: capacity of 1 frame, so there is never room while it holds a frame.
func t_has_room() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	eq(int(cv("centrifuge_capacity_frames")), 1, "prototype capacity is 1 frame (L106)")
	ck(c.call("has_room"), "EMPTY has room")
	c.call("fill", int(cv("frame_jars")))
	ck(not c.call("has_room"), "FULL has no room with capacity 1")
	c.call("begin_crank")
	ck(not c.call("has_room"), "CRANKING has no room")
	_fin()


# L222: taps_per_frame counted turns extract frame_jars jars and give extraction_done.
func t_taps_per_frame() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var n: int = int(cv("taps_per_frame"))
	var jars: int = int(cv("frame_jars"))
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01   # every tap clears the cap
	var done: Array = [0]
	var progress: Array = []
	c.connect("extraction_done", func() -> void: done[0] += 1)
	c.connect("extraction_progress", func(d: Variant, t: Variant) -> void: progress.append([d, t]))
	_to_cranking(c)
	var counted: int = _tap_spaced(c, n - 1, gap)
	eq(counted, n - 1, "every spaced tap counts (n-1)")
	eq(done[0], 0, "not done one turn short")
	ck(int(c.get("jars_extracted")) < jars, "jars_extracted below the total one turn short (%s)" % str(c.get("jars_extracted")))
	ck(c.call("tap"), "the last tap counts")
	eq(done[0], 1, "extraction_done emitted once at taps_per_frame turns")
	eq(c.get("jars_extracted"), jars, "frame_jars jars extracted")
	eq(c.get("state"), _st(c, "DONE"), "state DONE")
	ck(progress.size() > 0, "extraction_progress emitted")
	if progress.size() > 0:
		eq(progress[progress.size() - 1], [jars, jars], "last extraction_progress(done, total) in jars")
	c.call("advance", gap)
	ck(not c.call("tap"), "a turn after DONE is not counted")
	eq(done[0], 1, "extraction_done not repeated")
	_fin()


# L223: taps closer than 1/max_tap_rate to the last counted turn are ignored.
# 30 taps evenly spaced over 1 s (6 per 1/max_tap_rate) count as max_tap_rate.
func t_tap_cap() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var rate: float = float(cv("max_tap_rate"))
	var per_interval: int = 6
	var n: int = int(roundf(rate * per_interval))   # 30 at the default 5/s
	_to_cranking(c)
	var counted: int = _tap_spaced(c, n, 1.0 / (rate * per_interval))
	eq(counted, int(roundf(rate)), "%d taps over 1 s count as max_tap_rate (%s/s)" % [n, str(rate)])
	# and a burst with no time between taps counts at most one
	var c2: Object = await _mk_cen()
	_to_cranking(c2)
	var burst: int = 0
	for i in 20:
		if c2.call("tap"):
			burst += 1
	eq(burst, 1, "20 taps in zero time count 1")
	_fin()


# L61, L97: the cap is read live (Dev mode edits apply at once).
func t_tap_cap_is_live() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var rate: float = float(cv("max_tap_rate"))
	_set_cfg("max_tap_rate", rate * 2.0)
	_to_cranking(c)
	ck(c.call("tap"), "first tap counts")
	c.call("advance", 1.2 / (rate * 2.0))   # past the new interval, inside the old one
	ck(c.call("tap"), "a tap after 1.2 / new rate counts (the old cap would have ignored it)")
	_fin()


# L62, L224: a hold counts one turn on press, then max_tap_rate turns per second:
# a frame finishes in (taps_per_frame - 1) / max_tap_rate seconds, +- one frame.
func t_hold_at_cap() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var dt: float = 1.0 / 60.0
	var expected: float = (float(cv("taps_per_frame")) - 1.0) / float(cv("max_tap_rate"))
	var t: float = _hold_to_done(c, dt, expected * 3.0 + 5.0)
	eq(c.get("state"), _st(c, "DONE"), "hold reached DONE")
	near(t, expected, "hold finish time (taps_per_frame - 1) / max_tap_rate", dt + 0.002)
	_fin()


# L62: hold_ramp_seconds is visual only; it must not change when turns are counted.
func t_hold_ramp_is_visual_only() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_set_cfg("hold_ramp_seconds", float(cv("hold_ramp_seconds")) * 4.0 + 5.0)
	_to_cranking(c)
	var dt: float = 1.0 / 60.0
	var expected: float = (float(cv("taps_per_frame")) - 1.0) / float(cv("max_tap_rate"))
	var t: float = _hold_to_done(c, dt, expected * 3.0 + 5.0)
	near(t, expected, "hold finish time with a long ramp", dt + 0.002)
	_fin()


# L62, L225: holding is never slower than tapping at exactly max_tap_rate.
func t_hold_never_slower() -> void:
	var rate: float = float(cv("max_tap_rate"))
	var n: int = int(cv("taps_per_frame"))
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
	# the last tap that finished the frame happened at (n - 1) steps, before its advance
	var tap_finish: float = t_tap - step
	eq(tapper.get("state"), _st(tapper, "DONE"), "tapped frame reached DONE")
	_to_cranking(holder)
	var t_hold: float = _hold_to_done(holder, dt, 1000.0)
	ck(t_hold <= tap_finish + dt + 0.002, "held frame (%.3f s) finishes no later than the same frame tapped at max_tap_rate (%.3f s, %d taps)" % [t_hold, tap_finish, n])
	_fin()


# L62: releasing stops the counting.
func t_hold_release_stops() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	c.call("tap")
	c.call("set_holding", true)
	var rate: float = float(cv("max_tap_rate"))
	for i in 60:
		c.call("advance", 1.0 / 60.0)
	c.call("set_holding", false)
	var before: int = int(c.get("jars_extracted"))
	for i in 600:
		c.call("advance", 1.0 / 60.0)
	eq(c.get("jars_extracted"), before, "no progress after release (10 s idle)")
	eq(c.get("state"), _st(c, "CRANKING"), "still CRANKING after release")
	ck(rate > 0.0, "max_tap_rate positive")
	_fin()


## Mouse press event at an empty screen spot, through the real viewport input path.
func _real_click(pos: Vector2) -> void:
	_push_mouse(pos, true)
	_push_mouse(pos, false)


# L61, L226: crank input counts only in CRANKING. tap() returns false in every other state, and a real
# input event in those states changes nothing; in CRANKING the same events count (positive control).
func t_crank_ignored_outside_cranking() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var jars: int = int(cv("frame_jars"))
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	var n: int = int(cv("taps_per_frame"))
	var burst: int = n * 3
	# EMPTY
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("jars_extracted"), 0, "EMPTY: input extracted nothing")
	eq(c.get("state"), _st(c, "EMPTY"), "EMPTY unchanged by input")
	# FULL
	c.call("fill", jars)
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("jars_extracted"), 0, "FULL: input extracted nothing")
	eq(c.get("state"), _st(c, "FULL"), "FULL unchanged by input (begin_crank starts cranking, not a tap)")
	# CRANKING: positive control, the same real events now count and finish the frame
	c.call("begin_crank")
	var cranking: int = _st(c, "CRANKING")
	for i in n + 5:
		if int(c.get("state")) != cranking:
			break
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "DONE"), "CRANKING: real clicks counted and finished the frame (positive control)")
	# DONE
	var extracted: int = int(c.get("jars_extracted"))
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "DONE"), "DONE unchanged by input")
	eq(c.get("jars_extracted"), extracted, "DONE: no extra extraction")
	# BOTTLING
	c.call("open_spigot")
	var bottling: int = _st(c, "BOTTLING")
	for i in 3:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), bottling, "BOTTLING unchanged by input (3 turns of bottling time may have passed)")
	eq(c.get("jars_extracted"), extracted, "BOTTLING: no extra extraction")
	_fin()


# L61: a real mouse click anywhere that is not a button counts as one turn (spaced clicks finish a frame).
func t_real_mouse_taps_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	var n: int = int(cv("taps_per_frame"))
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < n * 2:
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
		sent += 1
	eq(sent, n, "exactly taps_per_frame real clicks finish the frame")
	eq(c.get("state"), _st(c, "DONE"), "DONE")
	# a click burst inside one cap interval counts once
	var c2: Object = await _mk_cen()
	_to_cranking(c2)
	for i in 15:
		_real_click(EMPTY_SPOT)
	var counted_after_burst: bool = c2.call("tap")
	ck(not counted_after_burst, "15 real clicks in zero time were already counted once, so a 16th tap is capped")
	_fin()


# L62: a real mouse press-and-hold cranks continuously; release stops it.
func t_real_mouse_hold_cranks() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var dt: float = 1.0 / 60.0
	var expected: float = (float(cv("taps_per_frame")) - 1.0) / float(cv("max_tap_rate"))
	var cranking: int = _st(c, "CRANKING")
	_push_mouse(EMPTY_SPOT, true)
	var t: float = 0.0
	while int(c.get("state")) == cranking and t < expected * 3.0 + 5.0:
		c.call("advance", dt)
		t += dt
	_push_mouse(EMPTY_SPOT, false)
	eq(c.get("state"), _st(c, "DONE"), "a real press-and-hold finished the frame")
	near(t, expected, "real hold finish time", dt + 0.002)
	# release stops: press, hold 1 s, release, 5 idle seconds -> no more progress
	var c2: Object = await _mk_cen()
	_to_cranking(c2)
	_push_mouse(EMPTY_SPOT, true)
	for i in 60:
		c2.call("advance", dt)
	_push_mouse(EMPTY_SPOT, false)
	var at_release: int = int(c2.get("jars_extracted"))
	for i in 300:
		c2.call("advance", dt)
	eq(c2.get("jars_extracted"), at_release, "no progress after the real release")
	ck(at_release > 0, "the real hold made progress before release (%d jars)" % at_release)
	_fin()


# L61 (tap or hold on a phone): a touch counts like a click. Sent with root.push_input: headless, Input.parse_input_event
# dispatches nothing (mouse included), so the windowed tests/touch_windowed.gd covers the Input.parse_input_event path.
func t_real_touch_taps_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	var n: int = int(cv("taps_per_frame"))
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < n * 2:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = EMPTY_SPOT * _to_window()
		root.push_input(down)   # headless: Input.parse_input_event dispatches nothing (mouse included); play_loop covers it windowed
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = down.position
		root.push_input(up)
		c.call("advance", gap)
		sent += 1
	eq(c.get("state"), _st(c, "DONE"), "touch taps finished the frame (%d sent)" % sent)
	_fin()


# L61: presses on buttons never count as cranks (taps arrive through _unhandled_input).
func t_button_press_is_not_a_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var layer := CanvasLayer.new()
	var btn := Button.new()
	btn.position = Vector2(100.0, 900.0)
	btn.size = Vector2(300.0, 150.0)
	btn.text = "Upgrade"
	layer.add_child(btn)
	root.add_child(layer)
	_to_free.append(layer)
	await process_frame
	_to_cranking(c)
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	var n: int = int(cv("taps_per_frame"))
	var on_button: Vector2 = btn.get_global_rect().get_center()
	for i in n * 2:
		_real_click(on_button)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "CRANKING"), "clicks on a button did not crank")
	eq(c.get("jars_extracted"), 0, "no jars from button clicks")
	# positive control: the same number of clicks off the button finishes the frame
	var cranking: int = _st(c, "CRANKING")
	for i in n * 2:
		if int(c.get("state")) != cranking:
			break
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "DONE"), "clicks off the button finish the frame (positive control)")
	_fin()


# ---------------------------------------------------------------- bottling and truck

# L65, L229: one jar every bottling_seconds_per_jar, each to the truck; bottling_done(jars) at the end.
func t_bottling_timing() -> void:
	var c: Object = await _mk_cen()
	var t: Object = await _mk_truck()
	if c == null or t == null:
		_fin()
		return
	var jars: int = int(cv("frame_jars"))
	var spj: float = float(cv("bottling_seconds_per_jar"))
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	_to_cranking(c)
	_tap_spaced(c, int(cv("taps_per_frame")), gap)
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
		t.call("advance", dt)
	eq(times.size(), jars, "one jar_bottled per jar")
	for k in times.size():
		near(float(times[k]), (k + 1) * spj, "jar %d bottled at (k x bottling_seconds_per_jar)" % (k + 1), dt * 2.0 + 0.01)
	eq(counts, range(1, jars + 1), "jar_bottled(count) counts 1..n")
	eq(done_args, [jars], "bottling_done(jars) emitted once")
	eq(c.get("jars_bottled"), jars, "jars_bottled")
	eq(c.get("state"), _st(c, "EMPTY"), "centrifuge EMPTY again")
	eq(t.get("loaded_jars"), jars, "every jar went to the truck (loaded_jars)")
	eq(t.get("crate_jars"), 0, "nothing in the crate while the truck was home")
	_fin()


# L97: bottling_seconds_per_jar is read live: an edit applies to the next jar.
func t_bottling_time_is_live() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var jars: int = int(cv("frame_jars"))
	var spj: float = float(cv("bottling_seconds_per_jar"))
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	_to_cranking(c)
	_tap_spaced(c, int(cv("taps_per_frame")), gap)
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
	ck(jars > 1, "frame has more than one jar")
	_fin()


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


# ---------------------------------------------------------------- scene-level flow (needs Bob's rebuilt scenes)

func _mk_main() -> Node:
	var ps: Variant = load("res://scenes/main.tscn")
	ck(ps != null, "res://scenes/main.tscn failed to load")
	if ps == null:
		return null
	var m: Node = (ps as PackedScene).instantiate()
	ck(m != null, "main.tscn failed to instantiate")
	if m == null:
		return null
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


# L56, L227: Back returns to the farm; the frame stays in the hive (storage unchanged), the centrifuge is
# EMPTY, the fork shows again, and the next open shows every cell Capped.
func t_back_keeps_frame() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	var cen: Node = _nn(m, "Centrifuge")
	var fork: Node = _nn(m, "ForkIcon")
	var farm: Node = _nn(m, "FarmWorld")
	if hive == null or cen == null or fork == null or farm == null:
		_fin()
		return
	# exactly one frame in storage and an almost-empty overflow, so a wrongly run take_frame() shows
	hive.call("advance", 100000.0, 1.0)
	hive.call("take_frame")   # storage back to one frame (overflow moved in), overflow empty
	var jars: float = float(cv("frame_jars"))
	var ocap: float = jars * float(cv("overflow_frames"))
	await _frames(3)
	ck(hive.call("is_full"), "precondition: hive full")
	ck(float(hive.get("overflow")) < ocap * 0.5, "precondition: overflow well under a frame (%s)" % str(hive.get("overflow")))
	var storage_before: float = float(hive.get("storage"))
	ck(_shown(fork), "fork icon shown with a full hive and an EMPTY centrifuge")
	if fork is BaseButton:
		(fork as BaseButton).pressed.emit()
	await _wait(0.8)
	var hc: Node = m.find_child("Honeycomb", true, false)
	ck(hc != null, "tapping the fork opened the close-up (Honeycomb present)")
	ck(not (farm as Node3D).visible, "FarmWorld hidden during the close-up")
	ck(not _shown(fork), "farm UI hidden during the close-up")
	if hc != null:
		for i in 5:
			hc.call("uncap_at", i)
	var back: Node = _nn(m, "BackButton")
	if back != null and back is BaseButton:
		(back as BaseButton).pressed.emit()
	await _wait(0.8)
	var hc2: Node = m.find_child("Honeycomb", true, false)
	ck(hc2 == null or hc2.is_queued_for_deletion(), "close-up freed after Back")
	ck((farm as Node3D).visible, "FarmWorld visible again")
	ck(float(hive.get("storage")) >= storage_before - 0.0001, "hive storage unchanged after Back (take_frame did not run): before %s now %s" % [str(storage_before), str(hive.get("storage"))])
	ck(hive.call("is_full"), "hive still full after Back")
	eq(cen.get("state"), _st(cen, "EMPTY"), "centrifuge EMPTY after Back")
	ck(_shown(fork), "fork icon shows again after Back")
	if fork is BaseButton:
		(fork as BaseButton).pressed.emit()
	await _wait(0.8)
	var hc3: Node = m.find_child("Honeycomb", true, false)
	ck(hc3 != null, "second open: Honeycomb present")
	if hc3 != null:
		var n: int = int(cv("grid_cols")) * int(cv("grid_rows"))
		var capped: int = 0
		for i in n:
			if _cell_state(hc3, i) == 0:
				capped += 1
		eq(capped, n, "the next open shows every cell Capped (35 at the default)")
	_fin()


# L54, L228: the fork is hidden while the centrifuge is not EMPTY, even with a full hive.
func t_fork_hidden_unless_empty() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	var cen: Node = _nn(m, "Centrifuge")
	var fork: Node = _nn(m, "ForkIcon")
	if hive == null or cen == null or fork == null:
		_fin()
		return
	cen.set_process(false)
	hive.call("advance", 100000.0, 1.0)   # frame plus a full overflow: as full as it gets
	await _frames(3)
	ck(hive.call("is_full"), "precondition: hive full")
	ck(_shown(fork), "EMPTY + full hive: fork shown (positive control)")
	cen.call("fill", int(cv("frame_jars")))
	await _frames(3)
	ck(not _shown(fork), "FULL: fork hidden although the hive is full")
	cen.call("begin_crank")
	await _frames(3)
	ck(not _shown(fork), "CRANKING: fork hidden")
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	_tap_spaced(cen, int(cv("taps_per_frame")), gap)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "DONE"), "precondition: DONE")
	ck(not _shown(fork), "DONE: fork hidden")
	cen.call("open_spigot")
	await _frames(3)
	ck(not _shown(fork), "BOTTLING: fork hidden")
	_fin()


# L72-L78: the state table. Fork, centrifuge icon, Continue per state; Sell icon follows the truck.
func t_state_table_icons() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	var cen: Node = _nn(m, "Centrifuge")
	var truck: Node = _nn(m, "Truck")
	var fork: Node = _nn(m, "ForkIcon")
	var cicon: Node = _nn(m, "CentrifugeIcon")
	var cont: Node = _nn(m, "ContinueButton")
	var sell: Node = _nn(m, "SellIcon")
	if hive == null or cen == null or truck == null or fork == null or cicon == null or cont == null or sell == null:
		_fin()
		return
	cen.set_process(false)
	truck.set_process(false)
	hive.call("advance", 100000.0, 1.0)
	var gap: float = 1.0 / float(cv("max_tap_rate")) + 0.01
	await _frames(3)
	ck(_shown(fork), "EMPTY: fork shown")
	ck(not _shown(cicon), "EMPTY: centrifuge icon hidden")
	ck(not _shown(cont), "EMPTY: Continue hidden")
	eq(_shown(sell), bool(truck.call("can_sell")), "EMPTY: Sell icon follows the truck (empty)")
	cen.call("fill", int(cv("frame_jars")))
	await _frames(3)
	ck(not _shown(fork), "FULL: fork hidden")
	ck(_shown(cicon), "FULL: centrifuge icon shown")
	ck(not _shown(cont), "FULL: Continue hidden")
	cen.call("begin_crank")
	await _frames(3)
	ck(not _shown(fork), "CRANKING: fork hidden")
	ck(not _shown(cicon), "CRANKING: centrifuge icon hidden")
	ck(not _shown(cont), "CRANKING: Continue hidden")
	_tap_spaced(cen, int(cv("taps_per_frame")), gap)
	await _frames(3)
	ck(not _shown(fork), "DONE: fork hidden")
	ck(not _shown(cicon), "DONE: centrifuge icon hidden")
	ck(_shown(cont), "DONE: Continue shown")
	# fill the truck while DONE: the Sell icon must appear in the same state (the table says "as truck allows")
	for i in int(cv("truck_capacity_jars")):
		truck.call("receive_jar")
	await _frames(3)
	ck(_shown(sell), "DONE: Sell icon shown once the truck is full and home")
	cen.call("open_spigot")
	await _frames(3)
	ck(not _shown(fork), "BOTTLING: fork hidden")
	ck(not _shown(cicon), "BOTTLING: centrifuge icon hidden")
	ck(not _shown(cont), "BOTTLING: Continue hidden")
	ck(_shown(sell), "BOTTLING: Sell icon shown with a full truck at home")
	# the truck away: the Sell icon is hidden
	truck.call("sell")
	await _frames(3)
	ck(not _shown(sell), "truck away: Sell icon hidden")
	_fin()


# ---------------------------------------------------------------- floating icons

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


# L91-L113, L231: every new config value matches the Values table (checked on the defaults file itself).
func t_config_values() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres failed to load")
	if c == null:
		_fin()
		return
	var table: Dictionary = {
		"frame_jars": 10, "overflow_frames": 1, "sale_value_per_jar": 3, "taps_per_frame": 40,
		"centrifuge_capacity_frames": 1, "truck_capacity_jars": 10, "truck_trip_seconds": 30.0,
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
	ck(c.get("hold_taps_per_second") == null, "hold_taps_per_second must be removed (L113)")
	ck(c.get("hold_mode") == null and c.get("no_rapid_tap_mode") == null, "hold_mode / no_rapid_tap_mode must not exist (L26)")
	var e: Node = _eco()
	eq(e.call("bee_count"), 20, "base swarm of 20 bees at level 0 (L105; assumes no user dev_config override)")
	_fin()


# L95: every placeholder is marked `# PLACEHOLDER (GDD TBD)` in game_config.gd.
func t_config_placeholders_marked() -> void:
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd unreadable")
	if f == null:
		_fin()
		return
	var lines: PackedStringArray = f.get_as_text().split("\n")
	f.close()
	for name in ["taps_per_frame", "centrifuge_capacity_frames", "truck_capacity_jars", "truck_trip_seconds",
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
	_fin()


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
	_tap_spaced(c, int(cv("taps_per_frame")), 1.0 / float(cv("max_tap_rate")) + 0.01)
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
		near(float(fresh.get("taps_per_frame")), float(def.get("taps_per_frame")), "an unedited value stays at its default")
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
	if fast != null:
		fast.pressed.emit()
		eq(Engine.time_scale, 5.0, "game speed x5 sets Engine.time_scale")
	_fin()
