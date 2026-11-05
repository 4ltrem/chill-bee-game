extends "res://tests/test_bottling.gd"

# Quinn: truck tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

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


# ---------------------------------------------------------------- the zoom (real input on the farm)

# Look: "the wheels turn while the truck drives, and their roll matches the direction of travel both ways (no skid)".
# No-skid means the contact point is at rest: v = omega x up (for a wheel of radius 1), so dot(omega x up, v) > 0 on the
# drive-off leg AND on the return leg. omega comes from the wheel's global basis between frames, v from its global position.
func t_truck_wheels_roll_with_travel() -> void:
	var ps: Variant = load("res://scenes/props/truck.tscn")
	ck(ps != null, "res://scenes/props/truck.tscn failed to load (spec: Models as reusable scenes)")
	if ps == null:
		_fin()
		return
	var tk: Node = (ps as PackedScene).instantiate()
	root.add_child(tk)
	_to_free.append(tk)
	_give_config(tk)
	await _frames(3)
	_set_cfg("truck_trip_seconds", 6.0)         # CHEAT (Dev): a short trip, slow enough that a wheel turns < 1 rad per frame
	_set_cfg("truck_slide_distance", 10.0)
	var names: Array = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	var cand: Dictionary = {}                   # wheel name -> Array of nodes (the wheel node and its Node3D descendants)
	for nm in names:
		var w: Node = tk.find_child(nm, true, false)
		ck(w != null, "truck.tscn has no node %s (spec)" % nm)
		if w == null:
			_fin()
			return
		var list: Array = [w]
		for d in w.find_children("*", "Node3D", true, false):
			list.append(d)
		cand[nm] = list
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	var series: Dictionary = {}                 # name -> Array of [pos, [basis per candidate]]
	for nm in names:
		series[nm] = []
	tk.call("sell")
	var t_end: int = Time.get_ticks_msec() + int((float(cv("truck_trip_seconds")) + 1.0) * 1000.0)
	while Time.get_ticks_msec() < t_end:
		await process_frame
		for nm in names:
			var bases: Array = []
			for n in (cand[nm] as Array):
				bases.append((n as Node3D).global_transform.basis)
			(series[nm] as Array).append([((cand[nm] as Array)[0] as Node3D).global_position, bases])
	for nm in names:
		var sr: Array = series[nm]
		ck(sr.size() > 20, "%s: enough frames sampled (%d)" % [nm, sr.size()])
		if sr.size() <= 20:
			continue
		var start: Vector3 = (sr[0] as Array)[0]
		var far_i: int = 0
		var far_d: float = 0.0
		for i in sr.size():
			var d: float = (((sr[i] as Array)[0]) as Vector3).distance_to(start)
			if d > far_d:
				far_d = d
				far_i = i
		ck(far_d > 1.0, "%s: the truck drove away (%.2f units)" % [nm, far_d])
		# the spinning node of this wheel: the candidate that turned the most
		var spin_k: int = 0
		var spin_tot: float = -1.0
		for k in (cand[nm] as Array).size():
			var tot: float = 0.0
			for i in range(1, sr.size()):
				var q: Quaternion = ((((sr[i] as Array)[1] as Array)[k] as Basis) * ((((sr[i - 1] as Array)[1] as Array)[k] as Basis).inverse())).orthonormalized().get_rotation_quaternion()
				tot += 2.0 * acos(clampf(absf(q.w), 0.0, 1.0))
			if tot > spin_tot:
				spin_tot = tot
				spin_k = k
		ck(spin_tot > 1.0, "%s: the wheel turned while the truck drove (total %.2f rad)" % [nm, spin_tot])
		var good: Array = [0, 0]
		var bad: Array = [0, 0]
		for i in range(1, sr.size()):
			var v: Vector3 = (((sr[i] as Array)[0]) as Vector3) - (((sr[i - 1] as Array)[0]) as Vector3)
			if v.length() < 1.0e-4:
				continue
			var b1: Basis = ((sr[i] as Array)[1] as Array)[spin_k]
			var b0: Basis = ((sr[i - 1] as Array)[1] as Array)[spin_k]
			var q: Quaternion = (b1 * b0.inverse()).orthonormalized().get_rotation_quaternion()
			if q.w < 0.0:
				q = -q
			var ang: float = 2.0 * acos(clampf(q.w, 0.0, 1.0))
			if ang < 1.0e-3:
				continue
			var axis: Vector3 = Vector3(q.x, q.y, q.z).normalized()
			var leg: int = 0 if i <= far_i else 1
			if (axis * ang).cross(Vector3.UP).dot(v) > 0.0:
				good[leg] += 1
			else:
				bad[leg] += 1
		# rolling without slipping: the wheel turns path / radius radians (a wheel that turns at the wrong speed skids or spins)
		var wm: MeshInstance3D = (cand[nm] as Array)[0] as MeshInstance3D
		if wm != null and wm.mesh is CylinderMesh:
			var rad: float = (wm.mesh as CylinderMesh).top_radius * wm.global_basis.get_scale().x
			var path: float = 0.0
			for i in range(1, sr.size()):
				path += (((sr[i] as Array)[0]) as Vector3).distance_to(((sr[i - 1] as Array)[0]) as Vector3)
			var want_rad: float = path / maxf(rad, 0.001)
			ck(spin_tot >= want_rad * 0.85 and spin_tot <= want_rad * 1.15, "%s: the wheel turns as far as it rolls: %.2f rad for a path of %.2f on a radius of %.3f (wanted %.2f)" % [nm, spin_tot, path, rad, want_rad])
		else:
			ck(false, "%s: the wheel is a CylinderMesh whose radius the test can read" % nm)
		ck(int(good[0]) + int(bad[0]) >= 5, "%s: the drive-off leg has measurable samples (%s)" % [nm, str([good[0], bad[0]])])
		ck(int(good[1]) + int(bad[1]) >= 5, "%s: the return leg has measurable samples (%s)" % [nm, str([good[1], bad[1]])])
		eq(bad[0], 0, "%s: drive-off leg: every sample rolls with the travel (no skid); %d good" % [nm, good[0]])
		eq(bad[1], 0, "%s: return leg: every sample rolls with the travel (no skid); %d good" % [nm, good[1]])
	_fin()


# Spec 5: jars on the truck and in the crate are full, with lids.
func t_truck_and_crate_jars_full_with_lids() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var tk: Node = _nn(m, "Truck")
	if tk == null:
		_fin()
		return
	for i in 3:
		tk.call("receive_jar")
	await _frames(3)
	var bed: Node = tk.find_child("BedJars", true, false)
	ck(bed != null, "BedJars exists on the truck (0.1.0 name)")
	var seen: int = 0
	if bed != null:
		for j in bed.get_children():
			if (j as Node3D).is_visible_in_tree() and not (j is Label3D):
				seen += 1
				ck(_jar_frac(j) >= 0.98, "a jar on the truck is full (fraction %.2f)" % _jar_frac(j))
				ck(_jar_lid_shown(j), "a jar on the truck has its lid")
	eq(seen, 3, "three jars show on the truck bed")
	for i in int(cv("truck_capacity_jars")) - 3:
		tk.call("receive_jar")
	tk.call("sell")
	tk.call("receive_jar")
	tk.call("receive_jar")
	await _frames(3)
	# 0.1.2: the crate also shows empty jars, on the CrateEmpties side; the full ones (with lids) are the ones on the CrateFulls side
	var geo: Dictionary = _geo_crate(m)
	var seen2: int = 0
	if not geo.is_empty():
		for j in _vis_jars(m):
			var jp: Vector3 = (j as Node3D).global_position
			if _in_crate(geo, jp) and not _empties_side(geo, jp):
				seen2 += 1
				ck(_jar_frac(j) >= 0.98, "a jar in the crate's full group is full (fraction %.2f)" % _jar_frac(j))
				ck(_jar_lid_shown(j), "a jar in the crate's full group has its lid")
	eq(seen2, 2, "two full jars show in the crate")
	_fin()


# ---------------------------------------------------------------- wheel rims (spec 6)

## The rotation measure has to fail on a mark that does not turn: a spinning wheel with the mark as a child, and with the mark beside it.
func t_rim_measure_can_fail() -> void:
	var wheel := Node3D.new()
	var rim := Node3D.new()
	var mark_child := Node3D.new()
	var mark_loose := Node3D.new()
	root.add_child(wheel)
	root.add_child(mark_loose)
	wheel.add_child(rim)
	wheel.add_child(mark_child)
	mark_child.position = Vector3(0.0, 0.3, 0.0)
	mark_loose.position = Vector3(0.0, 0.3, 0.0)
	_to_free.append(wheel)
	_to_free.append(mark_loose)
	var turning: Array = []
	var loose: Array = []
	for i in 20:
		wheel.rotate_x(0.1)
		turning.append(mark_child.global_position - rim.global_position)
		loose.append(mark_loose.global_position - rim.global_position)
	ck(_offset_turn(turning) > 1.5, "a mark on the wheel turns (%.2f rad)" % _offset_turn(turning))
	ck(_offset_turn(loose) < 0.001 or _offset_turn(loose) < 0.5 * _offset_turn(turning), "a mark beside the wheel is measured as not turning (%.2f rad)" % _offset_turn(loose))
	_fin()


# Spec 6: each wheel has a light-grey Rim and an off-centre contrasting RimMark as children; they turn with the wheel.
func t_wheel_rims() -> void:
	var ps: Variant = load("res://scenes/props/truck.tscn")
	ck(ps != null, "truck.tscn loads")
	if ps == null:
		_fin()
		return
	var tk: Node = (ps as PackedScene).instantiate()
	root.add_child(tk)
	_to_free.append(tk)
	_give_config(tk)
	await _frames(3)
	_set_cfg("truck_trip_seconds", 6.0)
	_set_cfg("truck_slide_distance", 10.0)
	var names: Array = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	var offs: Dictionary = {}
	var wheels: Dictionary = {}
	for nm in names:
		var w: Node3D = tk.find_child(nm, true, false) as Node3D
		ck(w != null, "%s exists" % nm)
		if w == null:
			_fin()
			return
		var rim: Node3D = w.get_node_or_null("Rim") as Node3D
		var mark: Node3D = w.get_node_or_null("RimMark") as Node3D
		ck(rim != null, "%s has a child named Rim" % nm)
		ck(mark != null, "%s has a child named RimMark" % nm)
		if rim == null or mark == null:
			_fin()
			return
		wheels[nm] = [w, rim, mark]
		offs[nm] = []
		ck((mark.global_position - rim.global_position).length() > 0.02, "%s: RimMark is off-centre from the rim (%.3f)" % [nm, (mark.global_position - rim.global_position).length()])
		var rm: Array = rim.find_children("*", "MeshInstance3D", true, false)
		if rim is MeshInstance3D:
			rm.append(rim)
		var mm: Array = mark.find_children("*", "MeshInstance3D", true, false)
		if mark is MeshInstance3D:
			mm.append(mark)
		ck(rm.size() > 0 and mm.size() > 0, "%s: Rim and RimMark are drawn (have meshes)" % nm)
		if rm.size() > 0 and mm.size() > 0:
			var rc: Color = _albedo_of(rm[0] as MeshInstance3D)
			var mc: Color = _albedo_of(mm[0] as MeshInstance3D)
			ck(rc.get_luminance() >= 0.55 and (maxf(rc.r, maxf(rc.g, rc.b)) - minf(rc.r, minf(rc.g, rc.b))) <= 0.2, "%s: the rim is light grey (albedo %s)" % [nm, str(rc)])
			ck(absf(rc.get_luminance() - mc.get_luminance()) >= 0.25 or (Vector3(rc.r, rc.g, rc.b) - Vector3(mc.r, mc.g, mc.b)).length() >= 0.4, "%s: the mark contrasts with the rim (%s on %s)" % [nm, str(mc), str(rc)])
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	tk.call("sell")
	var t_end: int = Time.get_ticks_msec() + int((float(cv("truck_trip_seconds")) + 1.0) * 1000.0)
	var wspin: Dictionary = {}
	for nm in names:
		wspin[nm] = []
	while Time.get_ticks_msec() < t_end:
		await process_frame
		for nm in names:
			var tr: Array = wheels[nm]
			(offs[nm] as Array).append((tr[2] as Node3D).global_position - (tr[1] as Node3D).global_position)
			(wspin[nm] as Array).append((tr[0] as Node3D).global_basis)
	for nm in names:
		var turn: float = _offset_turn(offs[nm])
		var wturn: float = 0.0
		var bs: Array = wspin[nm]
		for i in range(1, bs.size()):
			wturn += _angle_between(bs[i - 1], bs[i])
		ck(wturn > 1.0, "%s: the wheel turned while driving (%.2f rad)" % [nm, wturn])
		ck(turn > 1.0, "%s: RimMark turned around the rim (%.2f rad) so the roll is visible" % [nm, turn])
		ck(absf(turn - wturn) <= 0.25 * wturn + 0.3, "%s: RimMark turns with the wheel (mark %.2f rad, wheel %.2f rad)" % [nm, turn, wturn])
	_fin()


# Spec 7: bottling shows no summary. Tapping Sell (a real press on the icon) credits the money, sends the truck off, and shows the modal:
# jars sold, price per jar, total, OK to close; no bonus line. Distinct numbers (4 jars, 7 each, 28) so a wrong line cannot pass by luck.
func t_summary_after_sell() -> void:
	_set_cfg("truck_capacity_jars", 4)
	_set_cfg("sale_value_per_jar", 7)
	_set_cfg("bottling_seconds_per_jar", 0.4)
	_set_cfg("jar_fly_seconds", 0.2)
	_set_cfg("truck_trip_seconds", 60.0)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var c: Node = p["Centrifuge"]
	var tk: Node = p["Truck"]
	var e: Node = _eco()
	var modal: Node = p["SummaryModal"]
	await _frames(3)
	ck(not _shown(modal), "no summary at the start")
	# bottle 2 jars through the real centrifuge: the modal must stay hidden for the whole run and after it
	var empty: int = _st(c, "EMPTY")
	_crank_unaided(c)
	var seen_modal: bool = false
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 12000:
		await process_frame
		if _shown(modal):
			seen_modal = true
		if int(c.get("state")) == empty and Time.get_ticks_msec() - t0 >= 1500:
			break
	await _wait(0.8)
	if _shown(modal):
		seen_modal = true
	eq(int(c.get("state")), empty, "bottling ended")
	ck(not seen_modal, "no summary while or after bottling (it comes after Sell)")
	eq(int(tk.get("loaded_jars")), 2, "two jars bottled onto the truck")
	for i in 2:
		tk.call("receive_jar")
	await _frames(4)
	ck(bool(tk.call("can_sell")), "the truck is full and home")
	ck(_shown(p["SellIcon"]), "the Sell icon shows")
	var money0: int = int(e.get("money"))
	var x0: float = (tk as Node3D).global_position.x
	var z0: float = (tk as Node3D).global_position.z
	var clicked: bool = await fi.click_icon(p["SellIcon"] as Control)
	ck(clicked, "the press went to where the Sell icon is drawn")
	var shown: bool = await _until(func() -> bool: return _shown(modal), 3.0)
	ck(shown, "the summary shows after Sell")
	eq(int(e.get("money")), money0 + 28, "Sell credited 4 x 7 = 28")
	ck(bool(tk.get("away")), "the truck is away")
	if shown:
		var jl: Node = m.find_child("SummaryJarsLabel", true, false)
		var vl: Node = m.find_child("SummaryValueLabel", true, false)
		var tl: Node = m.find_child("SummaryTotalLabel", true, false)
		var jt: String = String(jl.get("text")) if jl != null else ""
		var vt: String = String(vl.get("text")) if vl != null else ""
		var tt: String = String(tl.get("text")) if tl != null else ""
		print("MEASURE summary texts: jars '%s', value '%s', total '%s'" % [jt, vt, tt])
		ck(jt.contains("4") and not jt.contains("28") and not jt.contains("7"), "the jars line shows 4 jars sold ('%s')" % jt)
		ck(vt.contains("7") and not vt.contains("28"), "the price line shows 7 per jar ('%s')" % vt)
		ck(tt.contains("28"), "the total line shows 28 ('%s')" % tt)
		ck(m.find_child("SummaryBonusLabel", true, false) == null, "no bonus line")
		await _wait(0.6)
		var moved: float = Vector2((tk as Node3D).global_position.x - x0, (tk as Node3D).global_position.z - z0).length()
		ck(moved > 0.2 and _shown(modal), "the truck drives off behind the open modal (moved %.2f)" % moved)
		await fi.click_ctl(p["SummaryOkButton"] as Control)
		await _frames(3)
		ck(not _shown(modal), "OK closes the summary")
	_fin()
