extends "res://tests/test_dev.gd"

# Quinn: lids tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

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


## The largest-volume box of a lid, as its tilt from flat in degrees (angle between its thinnest axis and world up).
func _lid_tilt(lid: Node3D) -> float:
	var best: Array = []
	var vol: float = -1.0
	for b in _obbs(lid):
		var ax: Array = (b as Array)[1]
		var v: float = (ax[0] as Vector3).length() * (ax[1] as Vector3).length() * (ax[2] as Vector3).length()
		if v > vol:
			vol = v
			best = b
	if best.is_empty():
		return -1.0
	var axs: Array = best[1]
	var thin: int = 0
	for i in 3:
		if (axs[i] as Vector3).length() < (axs[thin] as Vector3).length():
			thin = i
	var n: Vector3 = (axs[thin] as Vector3).normalized()
	return rad_to_deg(acos(clampf(absf(n.y), 0.0, 1.0)))


# Spec 2: the open pose: leaning about 60-70 degrees from flat, lower edge on the ground, not toward the centrifuge (0.1.3c: offset along the centrifuge direction <= 0.05), never
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
	ck((lc - hc).dot(away) <= 0.05, "the lid does not rest toward the centrifuge (0.1.3c: offset along the centrifuge direction %.2f, limit 0.05)" % (lc - hc).dot(away))
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


# Spec 2: the centrifuge lid gets the same lift, so it no longer passes through the bucket; lands flat on the ground beside it.
func t_centrifuge_lid_paths() -> void:   # 0.1.3c: the lid opens to LidLeanSpot and leans (screen upper-left, centrifuge-local -x)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	_set_cfg("bottling_seconds_per_jar", 0.5)
	var c: Node = _nn(m, "Centrifuge")
	var lid: Node3D = c.find_child("Lid", true, false) as Node3D
	var spot: Node3D = c.find_child("LidLeanSpot", true, false) as Node3D
	ck(lid != null, "the centrifuge has a lid node named Lid (0.1.0 name)")
	ck(spot != null, "the centrifuge has a LidLeanSpot marker")
	if lid == null or spot == null:
		_fin()
		return
	await _frames(3)
	var body_fn: Callable = func() -> Array: return _obbs(c, [lid, c.find_child("HeapRoot", true, false), c.find_child("SpigotJar", true, false)])
	var body0: Array = body_fn.call()
	ck(body0.size() > 0, "the centrifuge body has boxes")
	var ground: float = _box_corners_y(body0).x
	var open_xf: Transform3D = spot.global_transform
	ck(lid.global_position.distance_to(open_xf.origin) <= 0.02 and _angle_between(lid.global_basis, open_xf.basis) <= 0.03, "an EMPTY centrifuge's lid sits at LidLeanSpot (full transform)")
	var lb0: Array = _obbs(lid)
	var tilt0: float = _lid_tilt(lid)
	ck(tilt0 >= 55.0 and tilt0 <= 75.0, "the open centrifuge lid leans (%.1f deg from flat, accepted 55 to 75)" % tilt0)
	var local_x: float = ((c as Node3D).global_basis.inverse() * (lid.global_position - (c as Node3D).global_position)).x
	ck(local_x < 0.0, "the leaned lid is on the centrifuge's local -x side, screen upper-left (local x %.2f)" % local_x)
	ck(absf(_box_corners_y(lb0).x - ground) <= 0.1, "the leaned centrifuge lid's lower edge is on the ground (%.3f vs %.3f)" % [_box_corners_y(lb0).x, ground])
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
	var tilt1: float = _lid_tilt(lid)
	ck(tilt1 >= 55.0 and tilt1 <= 75.0, "the opened centrifuge lid lands leaning (%.1f deg from flat)" % tilt1)
	_fin()


# Spec 3 (0.1.3c: leaned at LidLeanSpot): the resting lid (EMPTY) overlaps neither the bucket, its base ring, the spigot (all part of the centrifuge's
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
	var spot: Node3D = c.find_child("LidLeanSpot", true, false) as Node3D
	var crate: Node = _crate_root(m)
	if lid == null or spot == null or crate == null:
		ck(lid != null, "the centrifuge has a Lid")
		ck(spot != null, "LidLeanSpot exists")
		ck(crate != null, "the crate was found")
		_fin()
		return
	await _frames(3)
	ck(lid.global_position.distance_to(spot.global_position) <= 0.02 and _angle_between(lid.global_basis, spot.global_basis) <= 0.03, "an EMPTY centrifuge's lid sits at LidLeanSpot")
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


# 0.1.3c Barrel stop: after a spin the barrel eases to rest over barrel_stop_seconds (game time, +-1 frame), speed falling monotonically,
# no snap, resting on a quarter turn, and the lid starts lifting only after it rests. Real frames, sampled after each one.
func t_barrel_eases_to_stop() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	_set_cfg("bottling_seconds_per_jar", 0.3)
	_set_cfg("spin_decay", 0.0)   # the barrel is still spinning when bottling ends, so the stop has something to ease
	var stop_s: float = float(cv("barrel_stop_seconds"))
	ck(stop_s > 0.0, "barrel_stop_seconds is a positive config value (%.2f)" % stop_s)
	var c: Node = _nn(m, "Centrifuge")
	var spinner: Node3D = c.find_child("Spinner", true, false) as Node3D
	ck(spinner != null, "the centrifuge has a Spinner node")
	if spinner == null:
		_fin()
		return
	await _frames(3)
	c.call("add_cells", 20, _jars_of(20))
	c.call("close_lid")
	await _wait(float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + float(cv("close_delay_seconds")) + 0.4)
	c.call("begin_crank")
	_crank_done(c)
	var ev: Dictionary = {"t0": -1.0, "w_before": 0.0}
	c.connect("lid_moved", func(open: bool) -> void:
		if open and ev["t0"] < 0.0:
			ev["t0"] = float(_gus()) / 1.0e6
			ev["w_before"] = float(c.get("spin_speed")))
	var samples: Array = []   # {t, w, a (unwrapped rad), p (lid progress)}
	var prev: Dictionary = {}
	var unwrapped: float = 0.0
	var last_raw: float = 0.0
	var limit: float = float(cv("bottling_seconds_per_jar")) * 6.0 + stop_s + 4.0
	var t_begin: float = float(_gus()) / 1.0e6
	var end_t: float = -1.0
	while float(_gus()) / 1.0e6 - t_begin < limit and (end_t < 0.0 or float(_gus()) / 1.0e6 < end_t):
		await process_frame
		var bx: Basis = spinner.transform.basis
		var raw: float = atan2(-bx.x.z, bx.x.x)
		unwrapped += wrapf(raw - last_raw, -PI, PI)
		last_raw = raw
		var lm: Variant = c.get("_lid_motion")
		var smp: Dictionary = {"t": float(_gus()) / 1.0e6, "w": float(c.get("spin_speed")), "a": unwrapped, "d": m.get_process_delta_time() * Engine.time_scale, "p": float((lm as LidMotion).progress) if lm != null else 0.0, "open": ev["t0"] >= 0.0}
		if ev["t0"] >= 0.0:
			if end_t < 0.0:
				end_t = ev["t0"] + stop_s + float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.6
				samples.append(prev)   # the last frame before the lid opened: the speed the stop starts from
			samples.append(smp)
		prev = smp
	ck(ev["t0"] >= 0.0, "bottling ended and the lid opened")
	ck(float(ev["w_before"]) >= 5.0, "the barrel was spinning when the lid was ordered open (%.2f rad/s)" % float(ev["w_before"]))
	if ev["t0"] < 0.0 or samples.size() < 3:
		_fin()
		return
	var t0: float = ev["t0"]
	var dtmax: float = 0.0
	for i in range(1, samples.size()):
		dtmax = maxf(dtmax, float(samples[i]["t"]) - float(samples[i - 1]["t"]))
	# speed falls monotonically to 0 (the samples start with the frame before the lid opened)
	var mono: bool = true
	var rest_i: int = -1
	for i in range(1, samples.size()):
		if float(samples[i]["w"]) > float(samples[i - 1]["w"]) + 1.0e-4:
			mono = false
		if rest_i < 0 and float(samples[i]["w"]) <= 1.0e-4:
			rest_i = i
	ck(mono, "the barrel's angular speed never rises while it stops")
	ck(rest_i > 0, "the barrel's angular speed reaches 0")
	var final_w: float = float(samples[samples.size() - 1]["w"])
	ck(final_w <= 1.0e-4, "it stays at rest (%.4f rad/s)" % final_w)
	if rest_i < 0:
		_fin()
		return
	var took: float = float(samples[rest_i]["t"]) - t0
	ck(absf(took - stop_s) <= dtmax + 0.02, "it comes to rest in barrel_stop_seconds (%.3f s, config %.3f, one frame %.3f)" % [took, stop_s, dtmax])
	# no snap: the angle covered per game second (the frame's process delta x time_scale, so wall-clock jitter cannot fake a rise) never grows frame to frame (the last frame is clipped, so it can only be smaller)
	var worst: float = 0.0
	var worst_at: int = 0
	for i in range(2, rest_i + 1):
		var r1: float = absf(float(samples[i]["a"]) - float(samples[i - 1]["a"])) / maxf(float(samples[i]["d"]), 1.0e-6)
		var r0: float = absf(float(samples[i - 1]["a"]) - float(samples[i - 2]["a"])) / maxf(float(samples[i - 1]["d"]), 1.0e-6)
		if r1 - r0 > worst:
			worst = r1 - r0
			worst_at = i
	ck(worst <= 0.35, "no frame turns the barrel faster than the frame before it (worst rise %.2f rad/s at sample %d)" % [worst, worst_at])
	var jump: float = absf(float(samples[rest_i]["a"]) - float(samples[rest_i - 1]["a"]))
	var prior: float = absf(float(samples[rest_i - 1]["a"]) - float(samples[rest_i - 2]["a"])) if rest_i >= 2 else jump
	ck(jump <= prior + 0.02, "the step into rest is not a snap (%.3f rad, the frame before turned %.3f)" % [jump, prior])
	var rest_deg: float = rad_to_deg(float(samples[rest_i]["a"]))
	var off: float = absf(rest_deg - roundf(rest_deg / 90.0) * 90.0)
	ck(off <= 1.0, "it rests on a multiple of 90 degrees (%.2f deg, %.2f off)" % [rest_deg, off])
	# the lid starts lifting only after the barrel rests
	var early: String = ""
	var lifted: bool = false
	for s in samples:
		if float(s["p"]) > 0.001:
			lifted = true
			if float(s["t"]) - t0 < stop_s - dtmax - 0.02 and early == "":
				early = "lid progress %.3f at %.3f s after the lid was ordered, barrel rests at %.3f s" % [float(s["p"]), float(s["t"]) - t0, took]
	ck(lifted, "the lid does lift once the barrel has rested")
	ck(early == "", "the lid does not lift before the barrel rests (%s)" % early)
	_fin()


# ---------------------------------------------------------------- nodes and config of 0.1.2
