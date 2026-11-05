extends "res://tests/test_base.gd"

# Quinn: shared helpers (part 1), split from run_tests.gd 2026-11-05. Each file extends the one before it.

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


## Lid time of 0.1.1: the lift then the fall (lid_lift_seconds is absent from a 0.1.0 config: counts as 0 so the old waits still work).
func _lid_t() -> float:
	var c: Variant = _cfg()
	var lift: Variant = c.get("lid_lift_seconds") if c != null else null
	return float(cv("lid_drop_seconds")) + (float(lift) if lift != null else 0.0)


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


func _load_script_static(file: String, method: String) -> Variant:
	var s: Variant = load(_script_path(file))
	ck(s != null, "%s failed to load" % file)
	if s == null:
		return null
	return (s as GDScript).call(method)

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


func _panel_open(p: Node) -> bool:
	if p is CanvasLayer:
		return (p as CanvasLayer).visible
	if p is CanvasItem:
		return (p as CanvasItem).is_visible_in_tree()
	return true


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
