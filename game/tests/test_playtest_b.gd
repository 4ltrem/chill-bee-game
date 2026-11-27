extends "res://tests/test_playtest_a.gd"

# Quinn: 0.3.2 item 2 (tests for what the 0.3.1 play-test found), part B: Spin's size, the centrifuge lid for the pile, the paused crank.
# Written from game/specs/0.3.2-tests-and-quick-buy.md before the code. Taps are real mouse events; numbers come from the config and the scene.


## What is wrong with Spin's drawn circle against Harvest's right now: size, roundness and the glyph (every point of it) inside the circle.
func _pt_spin_problems(spin: FloatingIcon, want: Vector2, label: String) -> Array:
	var out: Array = []
	var vs: Vector2 = spin.visible_size()
	if not vs.is_equal_approx(want):
		out.append("%s: Spin's drawn circle is %s, Harvest's is %s" % [label, str(vs), str(want)])
	if absf(vs.x - vs.y) > 0.5:
		out.append("%s: Spin's drawn shape is not a circle: %s" % [label, str(vs)])
	var glyph: Node2D = spin.find_child("SpinGlyph", true, false) as Node2D
	if glyph == null:
		return out + ["%s: SpinGlyph is missing" % label]
	var circle: Rect2 = spin.visible_global_rect()
	var radius: float = circle.size.x * 0.5
	var pts: Array = _pt_glyph_points(glyph)
	if pts.is_empty():
		out.append("%s: SpinGlyph draws nothing" % label)
	for e in pts:
		var d: float = (e[0] as Vector2).distance_to(circle.get_center()) + float(e[1])
		if d > radius + 1.0:
			out.append("%s: a SpinGlyph point %s lies %.1f px from the centre, outside the radius %.1f" % [label, str(e[0]), d, radius])
			break
	return out


## Spin's drawn circle equals Harvest's (icon_visual_px, 88) in the farm view and in the first zoom; SpinGlyph stays inside the circle.
# goal T2.11
func t_spin_circle_equals_fork_in_farm_view_and_first_zoom_glyph_inside() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var fork: FloatingIcon = p["ForkIcon"] as FloatingIcon
	var spin: FloatingIcon = p["CentrifugeIcon"] as FloatingIcon
	_pt_full_bucket(p)
	await _frames(8)
	ck(_shown(fork) and _shown(spin), "farm view: Harvest and Spin both show with a full bucket")
	var want: Vector2 = fork.visible_size()
	near(want.x, float(cv("icon_visual_px")) + fork.size.x - FloatingIcon.MIN_TOUCH.x, 0.5, "farm view: Harvest's drawn circle is icon_visual_px")
	eq(_pt_spin_problems(spin, want, "farm view"), [], "farm view: Spin matches Harvest, glyph inside")
	_pt_drop(m)
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	await _fill_bucket_in_zoom(z)
	await _frames(8)
	var zspin: FloatingIcon = (z["p"] as Dictionary)["CentrifugeIcon"] as FloatingIcon
	ck(int((z["m"] as Node).get("zoom")) != 0 and _shown(zspin), "first zoom: Spin shows with a full bucket")
	eq(_pt_spin_problems(zspin, want, "first zoom"), [], "first zoom: Spin matches Harvest's farm-view circle, glyph inside")
	_fin()


## Bottling with a pile waiting: the lid's visual progress reaches open (1) before the first pile cell lands, then it closes. Twice.
# goal T2.6
func t_lid_opens_fully_before_first_pile_cell_lands_then_closes_twice() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)   # the hive stays still
	var cen: Node = p["Centrifuge"]
	var pile: Node = p["Pile"]
	var lm: Object = cen.get("_lid_motion") as Object
	ck(lm != null, "the centrifuge has a lid motion to read")
	if lm == null:
		_fin()
		return
	var n: int = _cpf()
	var limit: float = float(cv("bottling_seconds_per_jar")) * (_jars_of(n) + 4.0) + _lid_t() * 4.0 + float(cv("cell_fly_seconds")) * 4.0 + 10.0
	for run in [1, 2]:
		var L: String = "run %d" % run
		if int(cen.get("state")) == _st(cen, "EMPTY"):
			_load_bucket(cen, n)
		await _wait_lid_on(cen)
		_land_lid(cen)
		cen.call("begin_crank")
		_crank_done(cen)
		pile.call("add", n, _jars_of(n))
		var rec: Dictionary = {"armed": false, "landed": false, "peak": 0.0, "at_land": -1.0}
		var on_done: Callable = func(_j: Variant) -> void: rec["armed"] = true
		cen.connect("bottling_done", on_done)
		var cb: Callable = func() -> void:
			if not bool(rec["armed"]):
				return
			rec["peak"] = maxf(float(rec["peak"]), float(lm.get("progress")))
			if not bool(rec["landed"]) and int(cen.get("_landed")) > 0:
				rec["landed"] = true
				rec["at_land"] = float(rec["peak"])
		process_frame.connect(cb)
		var landed: bool = await _until(func() -> bool: return bool(rec["landed"]), limit)
		ck(landed, "%s step pile: a cell of the pile landed in the bucket (diag: state %s, pile %s)" % [L, str(cen.get("state")), str(pile.get("cells"))])
		ck(float(rec["at_land"]) >= 0.999, "%s step lid open: the lid's progress had reached open (1) before the first cell landed (peak %.3f)" % [L, float(rec["at_land"])])
		var closed: bool = await _until(func() -> bool: return bool(cen.call("lid_is_on")) and float(lm.get("progress")) <= 0.0, limit)
		ck(closed, "%s step close: the lid closes after the pile is in (progress %.3f)" % [L, float(lm.get("progress"))])
		eq(int(cen.get("cells")), n, "%s step close: the bucket holds the pile's cells" % L)
		process_frame.disconnect(cb)
		cen.disconnect("bottling_done", on_done)
	_fin()


## Crank at the second stop, Back, open the zoom with Harvest, uncap more, tap Spin: the camera reaches the second stop and the crank resumes
## (a real tap counts a turn from where it stopped). Twice: Back and the same again.
# goal T2.7
func t_paused_crank_spin_in_first_zoom_reaches_second_stop_and_resumes_twice() -> void:
	var s: Dictionary = await _cranking_at_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var cen: Node = s["cen"]
	var spin: Control = p["CentrifugeIcon"]
	for run in [1, 2]:
		var L: String = "run %d" % run
		await _wait(_tap_gap())
		eq(bool(m.call("at_second_stop")), true, "%s step start: the crank runs at the second stop" % L)
		await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
		await _until(func() -> bool: return not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
		await _wait(_zoom_settle() + float(cv("zoom_seconds")))
		eq(bool(m.call("at_second_stop")), false, "%s step Back: the second stop is left" % L)
		var kept: int = int(cen.get("turns_counted"))
		eq(cen.get("state"), _st(cen, "CRANKING"), "%s step Back: the crank is paused, not finished" % L)
		var tr: Dictionary = _track(p["Hive"])
		ck(await _open_zoom(m, p, tr), "%s step zoom: Harvest opens the first zoom after Back" % L)
		await _scrape_risen(m, p["Hive"], tr, 1)
		await _wait(float(cv("cell_fly_seconds")) + 0.3)
		ck(_shown(spin), "%s step zoom: Spin shows in the first zoom while the crank is paused" % L)
		await fi.tap_at(spin.get_global_rect().get_center())
		var reached: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01 and bool(m.call("at_second_stop")), float(cv("camera_pan_seconds")) + float(cv("zoom_seconds")) + _zoom_settle() + 6.0)
		await _wait(0.4)
		ck(reached, "%s step Spin: the camera reaches the second stop (size %.3f, pan_zoom_size %s)" % [L, _cam().size, str(cv("pan_zoom_size"))])
		eq(cen.get("state"), _st(cen, "CRANKING"), "%s step Spin: it is still the same crank" % L)
		eq(int(cen.get("turns_counted")), kept, "%s step Spin: the progress is kept, no turn lost or added by the trip" % L)
		await _wait(_tap_gap())
		await _tap_free(m)
		eq(int(cen.get("turns_counted")), kept + 1, "%s step resume: a real tap at the second stop counts a turn, so the crank resumed" % L)
	_fin()
