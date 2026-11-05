extends "res://tests/test_jars.gd"

# Quinn: speed tests (0.1.3a), written from game/specs/0.1.3-next-revision.md Changes item 1 and Contract -> Quinn before the code.
# The game speed is Engine.time_scale, set through the Dev panel's speed row (buttons found by their text: x0.25 x0.5 x1 x2 x5 x10 x20) or the
# hotkeys [ and ] (real key events pushed into the viewport). The timing tests measure wall-clock seconds from the start of a motion to its
# end at x1 and at the other speeds: a motion that follows the speed takes (x1 time) / N, within one frame. A motion that ignores the
# engine clock (a tween with ignore_time_scale, a wall-clock timer) keeps its x1 time and fails.
const CellFlightScript := preload("res://scripts/cell_flight.gd")

const SPEED_ROW: Array[float] = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0]


# A button of the speed row: text is "x" or the multiplication sign, then the number (0.25, 0.5, 1, 2, 5, 10, 20).
func _speed_button(panel: Node, n: float) -> Button:
	for b in panel.find_children("*", "Button", true, false):
		var t: String = (b as Button).text.strip_edges()
		if t.begins_with("×") or t.to_lower().begins_with("x"):
			var num: String = t.substr(1).strip_edges()
			if num.is_valid_float() and is_equal_approx(num.to_float(), n):
				return b as Button
	return null


## Press the row's button for speed n (as the panel's own button does). False, with a failed check, when the row has no such button.
func _press_speed(m: Node, n: float) -> bool:
	var p: Node = _find_dev_panel(m)
	ck(p != null, "dev panel exists (Dev mode on)")
	if p == null:
		return false
	var b: Button = _speed_button(p, n)
	ck(b != null, "the speed row has a button for x%s" % str(n))
	if b == null:
		return false
	b.pressed.emit()
	return true


## Run `start`, then wait frames until `done` is true. Returns {secs: wall seconds, frame: longest frame (s) seen, ok: finished in time}.
func _timed(start: Callable, done: Callable, timeout: float) -> Dictionary:
	var t0: int = Time.get_ticks_usec()
	start.call()
	var last: int = t0
	var worst: float = 0.0
	var ok: bool = false
	while float(Time.get_ticks_usec() - t0) / 1.0e6 < timeout:
		await process_frame
		var now: int = Time.get_ticks_usec()
		worst = maxf(worst, float(now - last) / 1.0e6)
		last = now
		if done.call():
			ok = true
			break
	return {"secs": float(last - t0) / 1.0e6, "frame": worst, "ok": ok}


## One measurement of a motion at speed n with its nominal duration d game seconds. `kind`: "jar", "lid" or "cell". Wall seconds, or -1.
func _measure(kind: String, d: float, n: float) -> Dictionary:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		return {"secs": -1.0, "frame": 0.0, "ok": false}
	_set_cfg("base_seconds_per_jar", 1.0e9)
	if n != 1.0 and not await _press_speed(m, n):
		return {"secs": -1.0, "frame": 0.0, "ok": false}
	var r: Dictionary = {}
	if kind == "jar":
		_set_cfg("bottling_seconds_per_jar", d * 0.5)   # two jars: one frame of cells
		_set_cfg("jar_fly_seconds", d * 0.125)
		var c: Node = _nn(m, "Centrifuge")
		var empty: int = _st(c, "EMPTY")
		var go: Callable = func() -> void:
			var cells: int = _cpf()
			c.call("add_cells", cells, _jars_of(cells))
			c.call("close_lid")
			c.call("begin_crank")
			_crank_done(c)
		r = await _timed(go, func() -> bool: return int(c.get("state")) == empty, d / n * 3.0 + 6.0)
	elif kind == "lid":
		_set_cfg("lid_lift_seconds", d * 0.5)
		_set_cfg("lid_drop_seconds", d * 0.5)
		var hive: Node = _nn(m, "Hive")
		var lid: Node3D = hive.find_child("HiveLid", true, false) as Node3D
		var spot: Node3D = hive.find_child("HiveLidSpot", true, false) as Node3D
		ck(lid != null and spot != null, "hive has HiveLid and HiveLidSpot")
		if lid == null or spot == null:
			return {"secs": -1.0, "frame": 0.0, "ok": false}
		await _frames(2)
		r = await _timed(func() -> void: hive.call("open_lid"),
				func() -> bool: return lid.position.distance_to(spot.position) < 0.0001, d / n * 3.0 + 6.0)
	else:
		_set_cfg("cell_fly_seconds", d)
		var host := Node3D.new()
		root.add_child(host)
		_to_free.append(host)
		var landed: Array = [false]
		r = await _timed(func() -> void:
				CellFlightScript.launch(host, Vector3.ZERO, Vector3(2, 0, 0), d, 1.5, 0.0, 1.0, 1.0, func() -> void: landed[0] = true),
				func() -> bool: return landed[0], d / n * 3.0 + 6.0)
	Engine.time_scale = 1.0
	ck(bool(r["ok"]), "%s at x%s finished" % [kind, str(n)])
	return r


## At x5, x20 and x0.25 the motion takes 1/N of its x1 time, within one frame.
func _speed_scales(kind: String) -> void:
	# x1 references: 4 s for the fast speeds (x20 then lasts 0.2 s), 1 s for the slow one (x0.25 then lasts 4 s)
	var ref_hi: Dictionary = await _measure(kind, 4.0, 1.0)
	var ref_lo: Dictionary = await _measure(kind, 1.0, 1.0)
	ck(bool(ref_hi["ok"]) and bool(ref_lo["ok"]), "%s: the x1 references finished" % kind)
	if not (bool(ref_hi["ok"]) and bool(ref_lo["ok"])):
		return
	for n in [5.0, 20.0, 0.25]:
		var ref: Dictionary = ref_lo if n < 1.0 else ref_hi
		var d: float = 1.0 if n < 1.0 else 4.0
		var got: Dictionary = await _measure(kind, d, n)
		if not bool(got["ok"]):
			continue
		var want: float = float(ref["secs"]) / n
		# a measurement is quantised to frames at its start and at its end: one frame each, at the speed measured
		var tol: float = 2.0 * float(got["frame"]) + 2.0 * float(ref["frame"]) / n + 0.002
		ck(absf(float(got["secs"]) - want) <= tol, "%s at x%s took %.3f s; x1 took %.3f s so %.3f s +- %.3f s (a frame at each end) is expected" %
				[kind, str(n), float(got["secs"]), float(ref["secs"]), want, tol])


func t_speed_jar_cycle() -> void:
	await _speed_scales("jar")
	_fin()


func t_speed_lid_lift() -> void:
	await _speed_scales("lid")
	_fin()


func t_speed_cell_flight() -> void:
	await _speed_scales("cell")
	_fin()


# --- hotkeys, tag, reset ---

func _key(code: int, shifted: bool = false) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code as Key
		e.physical_keycode = code as Key
		e.pressed = pressed
		root.push_input(e)
	await _frames(2)


func _speed_now() -> float:
	return Engine.time_scale


## [ and ] step along the seven speeds and stop at the ends (Dev mode on, panel closed); with Dev mode off they do nothing.
func t_speed_hotkeys() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	eq(_speed_now(), 1.0, "the game starts at x1")
	var up: Array = []
	for i in 9:   # four steps reach x20, the rest must stay there
		await _key(KEY_BRACKETRIGHT)
		up.append(_speed_now())
	eq(up, [2.0, 5.0, 10.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0], "] steps x1 > x2 > x5 > x10 > x20 and stops at x20")
	var down: Array = []
	for i in 8:   # x20 to x0.25 is six steps, the rest must stay there
		await _key(KEY_BRACKETLEFT)
		down.append(_speed_now())
	eq(down, [10.0, 5.0, 2.0, 1.0, 0.5, 0.25, 0.25, 0.25], "[ steps x20 > x10 > x5 > x2 > x1 > x0.5 > x0.25 and stops at x0.25")
	Engine.time_scale = 1.0
	# Dev mode off: no panel, the keys change nothing (the first scene, with its panel, is taken out of the tree first)
	m.get_parent().remove_child(m)
	m.free()
	_set_dev_mode(false)
	var m2: Node = await _mk_main()
	if m2 != null:
		await _key(KEY_BRACKETRIGHT)
		await _key(KEY_BRACKETRIGHT)
		eq(_speed_now(), 1.0, "with Dev mode off ] does not change the speed")
		await _key(KEY_BRACKETLEFT)
		eq(_speed_now(), 1.0, "with Dev mode off [ does not change the speed")
	_fin()


## The tag node: DevSpeedTag (Bob's proposed name), else a visible-looking Label outside the panel whose text is "x" or the multiplication sign plus a number.
func _speed_tag(m: Node) -> Control:
	var named: Node = m.find_child("DevSpeedTag", true, false)
	if named != null and named is Control:
		return named as Control
	return null


func _tag_value(tag: Control) -> float:
	var t: String = str(tag.get("text")).strip_edges()
	if t.begins_with("×") or t.to_lower().begins_with("x"):
		t = t.substr(1).strip_edges()
	return t.to_float() if t.is_valid_float() else -1.0


## The "xN" tag is shown at every speed but x1 and reads the speed; at x1 it is hidden.
func t_speed_tag() -> void:
	_set_dev_mode(true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var tag: Control = _speed_tag(m)
	ck(tag != null, "main.tscn has the speed tag node DevSpeedTag (Control)")
	if tag == null:
		_fin()
		return
	ck(not tag.is_visible_in_tree(), "the tag is hidden at x1")
	for i in 4:
		await _key(KEY_BRACKETRIGHT)
		var s: float = _speed_now()
		ck(tag.is_visible_in_tree(), "the tag is shown at x%s" % str(s))
		near(_tag_value(tag), s, "the tag reads x%s (text '%s')" % [str(s), str(tag.get("text"))], 0.0001)
	for i in 4:
		await _key(KEY_BRACKETLEFT)
	eq(_speed_now(), 1.0, "back at x1 after four steps down")
	ck(not tag.is_visible_in_tree(), "the tag is hidden again at x1")
	for i in 3:
		await _key(KEY_BRACKETLEFT)
		var s2: float = _speed_now()
		ck(tag.is_visible_in_tree(), "the tag is shown at x%s" % str(s2))
		near(_tag_value(tag), s2, "the tag reads x%s (text '%s')" % [str(s2), str(tag.get("text"))], 0.0001)
	_fin()


## "Reset to defaults" sets the speed back to x1 (and the tag goes), from a fast speed and from a slow one.
func t_speed_reset() -> void:
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
	var reset: Button = _button_with(p, "default")
	ck(reset != null, "dev panel has the Reset to defaults button")
	if reset == null:
		_fin()
		return
	for start in [5.0, 0.25]:
		if not await _press_speed(m, start):
			continue
		eq(_speed_now(), start, "speed set to x%s" % str(start))
		reset.pressed.emit()
		await _frames(2)
		eq(_speed_now(), 1.0, "Reset to defaults sets x1 (was x%s)" % str(start))
		var tag: Control = _speed_tag(m)
		if tag != null:
			ck(not tag.is_visible_in_tree(), "the tag is hidden after Reset")
	_fin()


# Spec item 1: "no game code reads wall-clock time for gameplay or animation". Every script in game/scripts/ is scanned (comments and
# strings after # ignored) for Time.get_ticks_*, Time.get_unix_time* and OS.get_ticks*. The allowlist (file name -> why) is empty for now.
const WALL_CLOCK_ALLOWLIST: Dictionary = {}


func _wall_clock_hits(dir_path: String) -> Array:
	var rx := RegEx.new()
	rx.compile("\\b(Time\\.get_ticks_\\w*|Time\\.get_unix_time\\w*|OS\\.get_ticks\\w*)")
	var hits: Array = []
	var d: DirAccess = DirAccess.open(dir_path)
	if d == null:
		return [dir_path + ": cannot open"]
	for f in d.get_files():
		if not f.ends_with(".gd") or WALL_CLOCK_ALLOWLIST.has(f):
			continue
		var fa: FileAccess = FileAccess.open(dir_path + f, FileAccess.READ)
		var n: int = 0
		for line in fa.get_as_text().split("\n"):
			n += 1
			var code: String = line.split("#")[0]
			if rx.search(code) != null:
				hits.append("%s:%d %s" % [f, n, line.strip_edges()])
	return hits


func t_no_wall_clock_in_scripts() -> void:
	var rx := RegEx.new()
	ck(rx.compile("x") == OK, "regex compiles")
	var scripts: int = DirAccess.get_files_at("res://scripts/").size()
	ck(scripts > 10, "scripts folder was read (%d files)" % scripts)
	var hits: Array = _wall_clock_hits("res://scripts/")
	eq(hits, [], "no script in game/scripts/ reads wall-clock time")
	_fin()
