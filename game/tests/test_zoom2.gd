extends "res://tests/test_zoom.gd"

# Quinn: zoom2 tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

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
