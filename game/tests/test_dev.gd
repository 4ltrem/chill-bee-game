extends "res://tests/test_icons.gd"

# Quinn: dev tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

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
	# Counts only the overlay's own drawing (0.1.4 C5, 2026-11-08): a count over the whole tree also caught game nodes
	# that show by themselves in those frames (meter fill, combs in the hive) and failed 15 -> 17 with the overlay gone.
	var count_vis: Callable = func() -> int:
		var k: int = 0
		for overlay in root.find_children("UiBoundsOverlay", "", true, false):
			if not (overlay as Node).is_queued_for_deletion():
				for n in (overlay as Node).find_children("*", "CanvasItem", true, false):
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

# L213: the project setting exists and is true for prototypes.
func t_dev_mode_setting() -> void:
	ck(ProjectSettings.has_setting(DEV_SETTING), "project setting %s does not exist" % DEV_SETTING)
	if ProjectSettings.has_setting(DEV_SETTING):
		eq(ProjectSettings.get_setting(DEV_SETTING), true, "chill_bee/dev_mode is true for prototypes")
	_fin()


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
	var fast: Button = _button_with(p, "×5")
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
