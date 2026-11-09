extends "res://tests/test_economy.gd"

# Quinn: hive tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

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
	# 0.1.3: the whole hive is scaled by config hive_scale (spec Changes 2), so the 1.7 and 0.8 limits scale with it
	var hs: float = float(cv("hive_scale"))
	ck(w <= 1.7 * hs and dpt <= 1.7 * hs, "the hive footprint is 1.7 x 1.7 or less times hive_scale %.2f (measured %.2f x %.2f)" % [hs, w, dpt])
	ck(w >= 0.8 * hs and dpt >= 0.8 * hs, "the hive footprint is not degenerate (measured %.2f x %.2f)" % [w, dpt])
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
	xs.sort()
	for i in range(1, xs.size()):
		ck(float(xs[i]) - float(xs[i - 1]) > 0.05, "the frames stand in a row along X, one beside the next (gap %.3f; Clarifications 2026-11-04)" % (float(xs[i]) - float(xs[i - 1])))
	if zs.size() > 0:
		ck(float(zs.max()) - float(zs.min()) <= 0.05, "all frames share one Z: a row along X (spread %.3f)" % (float(zs.max()) - float(zs.min())))
	_fin()


# ---------------------------------------------------------------- heap and pile show every cell (spec 4)

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
	# 0.1.3: the hive is scaled by hive_scale and the truck by its own node scale (layout C); the 0.1.0 ratios are of the unscaled designs
	var hs: float = float(cv("hive_scale"))
	var tsc: float = (tk as Node3D).global_transform.basis.get_scale().y
	hive_h /= hs
	roof_h /= tsc
	ck(roof_h > 0.5, "the truck's height is plausible (%.2f, unscaled)" % roof_h)
	ck(hive_h <= 0.6 * roof_h, "the hive with its lid on is at most 0.6 of the truck's roof height, both unscaled (%.2f vs %.2f x 0.6 = %.2f)" % [hive_h, roof_h, 0.6 * roof_h])
	ck(hive_h >= 0.2 * roof_h, "the hive is not flattened away (%.2f is at least 0.2 of the roof %.2f)" % [hive_h, roof_h])
	var hbody: Node = hive.find_child("HiveBody", true, false)
	var body: Array = _obbs(hbody if hbody != null else hive, [hive.find_child("HiveLid", true, false), hive.find_child("Honeycomb", true, false), hive.find_child("FrameBars", true, false)])
	var sp: Array = _span_xz(body)
	var w: float = float(sp[2]) - float(sp[0])
	var d: float = float(sp[3]) - float(sp[1])
	ck(w <= 1.7 * hs and d <= 1.7 * hs, "the hive footprint is at most 1.7 x 1.7 times hive_scale %.2f (%.2f x %.2f)" % [hs, w, d])
	var ts: Array = _span_xz(tb)
	var tl: float = maxf(float(ts[2]) - float(ts[0]), float(ts[3]) - float(ts[1]))
	tl /= tsc
	ck(tl >= 2.4 and tl <= 4.0, "the truck is about 3.2 long, unscaled (measured %.2f; the reference the hive is measured against)" % tl)
	ck(maxf(w, d) / hs < tl * 0.6, "the hive is clearly smaller than the truck's length, both unscaled (%.2f vs %.2f)" % [maxf(w, d) / hs, tl])
	_fin()


# 0.1.4 item 19: after a harvest, a frame lowered back shows the hive's post-harvest fill (empty), not the full comb it was raised with;
# the overflow built up during the harvest then pours in at the fill rate, never in one step.
func t_lowered_frame_comes_back_empty_then_fills() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	var cpf: int = _cpf()
	var nf: int = _frames_n()
	var cap: float = _hive_jars()
	var ocap: float = cap * float(cv("overflow_hives"))
	h.call("advance", _secs_for_jars(cap + ocap) + _cell_secs() * 0.5, 1.0)   # full hive and a full overflow (one hive's worth)
	near(float(h.get("overflow")), ocap, "precondition: overflow built up", _cell_value() * 1.5)
	for f in nf:
		h.call("raise_frame", f)
		for c in cpf:
			h.call("scrape", f, c)
		eq(fi.capped(h as Node, f), 0, "frame %d scraped empty" % f)
		h.call("lower_frame")
		eq(fi.capped(h as Node, f), 0, "step lower, frame %d: right after lowering it shows empty, not the overflow poured in at once" % f)
	near(float(h.get("storage")), 0.0, "all frames lowered: storage is the post-harvest fill (empty)", _cell_value() * 0.5)
	ck(float(h.get("overflow")) > ocap - _cell_value() * 1.5, "the overflow is still waiting (%s)" % str(h.get("overflow")))
	var secs1: float = _secs_for_jars(1.0)
	h.call("advance", secs1, 1.0)
	near(float(h.get("storage")), 2.0, "step fill: after one jar's time the frames hold two jars (overflow pours at the fill rate on top of normal production, item 19)", _cell_value() * 1.5)
	ck(float(h.get("storage")) < cap * 0.5, "not poured back in a step (%s of %s jars)" % [str(h.get("storage")), str(cap)])
	h.call("advance", secs1 * 3.0, 1.0)
	near(float(h.get("storage")), 8.0, "step fill: eight jars after four jars' time while overflow lasts (2 x base)", _cell_value() * 2.5)
	_fin()


# ---------------------------------------------------------------- the centrifuge lid rests clear (spec change 3)
