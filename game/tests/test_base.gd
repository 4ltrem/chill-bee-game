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

# Test speed (designer 2026-11-05): run_tests.gd sets Engine.time_scale from env CB_TIME_SCALE (default 1). Every wait in a test counts GAME
# time (_gms/_gus: wall time times Engine.time_scale, summed per frame), so a timeout in seconds means game seconds at any scale. The tests
# in X1_TESTS (run_tests.gd) read the wall clock on purpose or own Engine.time_scale; they run at x1 and _gms/_gus give plain wall time there.
var _run_scale: float = 1.0
var _wall_clock: bool = false
var _clk_us: float = 0.0
var _clk_last: int = -1

const USER_CFG := GameConfig.DEV_PATH
const OLD_USER_CFG := "user://dev_config.tres"   # the retired full-snapshot format: never read
const DEFAULT_CFG := "res://scripts/default_config.tres"
const DEV_SETTING := "chill_bee/dev_mode"



## An empty point of the screen: no Control there, so the press reaches _unhandled_input like a real tap.
const EMPTY_SPOT := Vector2(360.0, 640.0)


const SCENE_NODES := ["Hive", "Centrifuge", "Pile", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon",
		"UpgradeButton", "BackButton", "HintLabel", "SummaryModal", "SummaryOkButton", "CentrifugeLabel", "MoneyLabel",
		"HiveCountLabel", "BeeCountLabel", "ShopPanel"]   # 0.1.4-ui-placement item 1: "The top Hive bar is removed" (FillLabel); the count is HiveCountLabel


## Two boxes lying in contact (resting lid, leaning lid) are not an overlap: the penetration must exceed this many units.
const CONTACT_EPS: float = 0.03


const FLIGHT_MIN_AIR: int = 4
const FLIGHT_STILL: float = 0.003   # a jar that moved less than this between two frames is standing still (launch)
const FLIGHT_REST: float = 0.01     # landed: it then stays within this of its place ...
const FLIGHT_REST_S: float = 0.1    # ... for this many seconds


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


func _eco() -> Node:
	return root.get_node_or_null("Economy")


## The live config. The spec never says where scripts get it; Economy.config is where revision 2 kept it.
func _cfg() -> Variant:
	var e: Node = _eco()
	if e != null and e.get("config") != null:
		return e.get("config")
	return null


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
	_clk_tick()
	Engine.time_scale = _run_scale
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


func _eco_reset() -> void:
	var e: Node = _eco()
	if e == null:
		return
	if e.has_method("reset"):
		e.call("reset")
	else:
		e.set("money", 0)
		e.set("swarm_level", 0)


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


func _wait(sec: float) -> void:   # create_timer follows Engine.time_scale: game seconds
	await create_timer(sec).timeout


## Accumulate game time (wall time x Engine.time_scale). Called every frame (run_tests.gd) and by every read, so a mid-test scale change is
## off by at most one frame.
func _clk_tick() -> void:
	var now: int = Time.get_ticks_usec()
	if _clk_last >= 0:
		_clk_us += float(now - _clk_last) * Engine.time_scale
	_clk_last = now


## Game microseconds / milliseconds since the run began (wall clock in an x1 test).
func _gus() -> int:
	if _wall_clock:
		return Time.get_ticks_usec()
	_clk_tick()
	return int(_clk_us)


func _gms() -> int:
	return _gus() / 1000


## Put the run's scale back (for a test that sets its own slow-motion and is done with it).
func _restore_scale() -> void:
	_clk_tick()
	Engine.time_scale = _run_scale


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Poll until cond.call() is true or timeout (s).
func _until(cond: Callable, timeout: float) -> bool:
	var t0: int = _gms()
	while float(_gms() - t0) < timeout * 1000.0:
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
