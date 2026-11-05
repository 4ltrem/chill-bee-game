extends "res://tests/test_truck.gd"

# Quinn: zoom tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

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
	# Clarifications 2026-11-04: option A's bucket check is BucketMouth on screen (above), not the whole rim.
	_fin()


# ---------------------------------------------------------------- hive vs truck (spec change 2)
