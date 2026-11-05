extends "res://tests/test_lids.gd"

# Quinn: jars tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

# Spec 5: at the spigot the empty jar has no lid, the honey rises over bottling_seconds_per_jar, then the lid goes on.
func t_jar_fills_then_lid() -> void:
	_set_cfg("bottling_seconds_per_jar", 1.5)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var spj: float = float(cv("bottling_seconds_per_jar"))
	var cells: int = _cpf()   # one frame: 2 jars
	c.call("add_cells", cells, _jars_of(cells))
	c.call("close_lid")
	c.call("begin_crank")
	_crank_done(c)
	_ext(c, "extracted before bottling")
	_begin_bottling(c)
	# Clarifications 2026-11-04: the jar at the spigot is whichever flying jar is filling (SpigotJar may stay hidden): every visible jar
	# is sampled each frame, and the jar that shows honey between 0.3 and 0.7 with no lid is the one under test.
	var per_jar: Dictionary = {}   # instance id -> [t, visible, frac, lid shown, position]
	var t0: int = Time.get_ticks_msec()
	var empty: int = _st(c, "EMPTY")
	while Time.get_ticks_msec() - t0 < int((spj * 2.0 + 2.0) * 1000.0) and int(c.get("state")) != empty:
		await process_frame
		for j in _vis_jars(m):
			var jid: int = j.get_instance_id()
			if not per_jar.has(jid):
				per_jar[jid] = []
			(per_jar[jid] as Array).append([float(Time.get_ticks_msec() - t0) / 1000.0, true, _jar_frac(j), _jar_lid_shown(j), (j as Node3D).global_position])
	var samples: Array = []
	for jid in per_jar:
		for s0 in (per_jar[jid] as Array):
			if not bool(s0[3]) and float(s0[2]) > 0.3 and float(s0[2]) < 0.7:
				samples = per_jar[jid]
				break
		if samples.size() > 0:
			break
	ck(samples.size() > 0, "a flying jar was seen filling (no visible jar showed honey between 0.3 and 0.7)")
	ck(samples.size() >= 30, "enough samples while bottling (%d)" % samples.size())
	var seen_full_lid: bool = false
	var seen_mid: bool = false
	var bad_lid: int = 0
	var shrink: int = 0
	var first_vis: float = -1.0
	var first_frac: float = -2.0
	var first_lid: bool = true
	var t_full: float = -1.0
	var prev: float = -1.0
	for s in samples:
		var vis: bool = s[1]
		var f: float = s[2]
		var lid: bool = s[3]
		if not vis:
			prev = -1.0
			continue
		if first_vis < 0.0:
			first_vis = s[0]
			first_frac = f
			first_lid = lid
		if lid and f < 0.98:
			bad_lid += 1
		if f >= 0.98 and lid:
			seen_full_lid = true
			if t_full < 0.0:
				t_full = s[0]
		if f > 0.3 and f < 0.7:
			seen_mid = true
		if prev >= 0.0 and f < prev - 0.02 and not (f <= 0.15):
			shrink += 1
		prev = f
	ck(first_vis >= 0.0, "the jar appeared at the spigot")
	ck(first_frac >= -0.5 and first_frac <= 0.15, "the jar appears empty (honey fraction %.2f)" % first_frac)
	ck(not first_lid, "the jar appears without its lid")
	eq(bad_lid, 0, "the lid is shown only when the jar is full (samples with lid and honey below full)")
	eq(shrink, 0, "the honey only rises within one jar")
	ck(seen_mid, "the honey passes through the middle of the jar (rises gradually)")
	ck(seen_full_lid, "the lid shows once the jar is full")
	if first_vis >= 0.0 and t_full >= 0.0:
		var rise: float = t_full - first_vis
		# 0.1.2: the jar first flies in from the crate (jar_fly_seconds); the fill time counts from its arrival at the spigot,
		# the place where the full jar (lid on) was first seen
		var end_pos: Vector3 = Vector3.ZERO
		for s2 in samples:
			if bool(s2[1]) and bool(s2[3]) and float(s2[2]) >= 0.98:
				end_pos = s2[4]
				break
		var arrive: float = first_vis
		for s2 in samples:
			if bool(s2[1]) and (s2[4] as Vector3).distance_to(end_pos) <= 0.3:
				arrive = float(s2[0])
				break
		rise = t_full - arrive
		var fly: float = float(cv("jar_fly_seconds"))
		var want: float = spj - fly   # Clarifications: the cycle is bottling_seconds_per_jar with the fly-in inside it
		ck(rise >= want * 0.7 and rise <= want * 1.15 + 0.1, "the honey rises over the rest of the cycle after the fly-in: %.2f s, wanted bottling_seconds_per_jar %.2f - jar_fly_seconds %.2f = %.2f" % [rise, spj, fly, want])
	_fin()


func t_flight_judge_can_fail() -> void:
	var a := Vector3(0.0, 0.0, 0.0)
	var b := Vector3(3.0, 0.0, 0.0)
	var at_a: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(a) <= 0.4
	var at_b: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(b) <= 0.4
	var good: Array = _fake_flight(a, b, 0.5, 40)
	var cut: Array = _cut_flight(good, at_a, at_b)
	ck(cut.size() > 4, "the cutter finds a flight in a good trace (%d samples)" % cut.size())
	eq(_flight_problems(cut, 0.5, at_a, at_b).size(), 0, "a smooth flight of the right length has no problem")
	var jump: Array = [{"t": 0.0, "pos": a, "frac": 0.0, "lid": false, "tb": AABB()}, {"t": 0.016, "pos": b, "frac": 0.0, "lid": false, "tb": AABB()}]
	ck(_flight_problems(_cut_flight(jump, at_a, at_b), 0.5, at_a, at_b).size() > 0, "a teleport is a problem")
	ck(_flight_problems(_cut_flight(_fake_flight(a, b, 3.0, 40), at_a, at_b), 0.5, at_a, at_b).size() > 0, "a flight six times too slow is a problem")
	ck(_flight_problems(_cut_flight(_fake_flight(a, b, 0.05, 40), at_a, at_b), 0.5, at_a, at_b).size() > 0, "a flight ten times too fast is a problem")
	ck(_cut_flight(_fake_flight(a, Vector3(1.5, 0.0, 0.0), 0.5, 40), at_a, at_b).is_empty(), "a jar that never arrives has no flight")
	# the duration is launch to landing: a big landing zone entered half way must not make a flight of 1.4 s look like 0.7 s
	var at_big: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(b) <= 1.5
	var slow_big: Array = _cut_flight(_fake_flight(a, b, 1.4, 60), at_a, at_big)
	ck(_flight_problems(slow_big, 0.5, at_a, at_big).size() > 0, "a slow flight into a big zone is still a problem (it is timed to the landing, not to the zone entry)")
	eq(_flight_problems(_cut_flight(_fake_flight(a, b, 0.5, 40), at_a, at_big), 0.5, at_a, at_big).size(), 0, "a right-length flight into a big zone has no problem")
	_fin()


# Spec 5: the crate shows EMPTY jars (clear glass, no honey, no lid), up to crate_empty_jars_shown, on the CrateEmpties side, and no full
# jar while nothing has been bottled. The number is read from the config (a changed value changes what is drawn).
func t_crate_shows_empties() -> void:
	for want_n in [int(cv("crate_empty_jars_shown")), 4]:
		_set_cfg("crate_empty_jars_shown", want_n)
		var m: Node = await _mk_main()
		if m == null:
			_fin()
			return
		_set_cfg("base_seconds_per_jar", 1.0e9)
		var geo: Dictionary = _geo_crate(m)
		if geo.is_empty():
			_fin()
			return
		await _frames(4)
		var empties: int = 0
		var fulls: int = 0
		var stray: int = 0
		var mk: Node3D = m.find_child("CrateEmpties", true, false) as Node3D
		var near_m: int = 0
		for j in _vis_jars(m):
			var jp: Vector3 = (j as Node3D).global_position
			if not _in_crate(geo, jp):
				stray += 1
			elif _empties_side(geo, jp):
				empties += 1
				ck(_jar_empty(j), "a jar on the CrateEmpties side is empty: no honey, no lid (fraction %.2f, lid %s)" % [_jar_frac(j), str(_jar_lid_shown(j))])
				if jp.distance_to(mk.global_position) <= 1.5:
					near_m += 1
			else:
				fulls += 1
		eq(empties, want_n, "the crate shows %d empty jars (crate_empty_jars_shown)" % want_n)
		eq(fulls, 0, "no full jar in the crate before anything is bottled")
		eq(stray, 0, "no jar shows outside the crate before bottling (the spigot jar is hidden)")
		eq(near_m, want_n, "the empties stand around the CrateEmpties marker (within 1.5)")
		m.get_parent().remove_child(m)
		m.free()
		_to_free.erase(m)
	_fin()


# Spec 5: bottling starts, the first empty jar FLIES from the crate to under the spigot (jar_fly_seconds), fills over
# bottling_seconds_per_jar, gets its lid, then flies to the truck's bed (the truck is home); then the next empty jar flies in.
# The crate shows its empties again afterwards (unlimited supply). Jars are followed frame by frame through the real scene.
func t_jar_flights_to_spigot_and_truck() -> void:
	var fly: float = 0.8
	var spj: float = 1.5
	var rig: Dictionary = await _bottling_rig(fly, spj)
	if rig.is_empty():
		_fin()
		return
	var m: Node = rig["m"]
	var c: Node = rig["c"]
	var tk: Node = rig["tk"]
	var geo: Dictionary = rig["geo"]
	var off: Array = rig["off"]
	var jars_n: int = int(floorf(_jars_of(_cpf()) + 0.000001))
	var empty: int = _st(c, "EMPTY")
	_crank_unaided(c)
	var traces: Dictionary = {}
	await _record(m, tk, off, traces, func() -> bool: return int(c.get("state")) == empty, (spj + 2.0 * fly) * float(jars_n) + 8.0)
	eq(int(c.get("state")), empty, "bottling ended")
	await _record(m, tk, off, traces, func() -> bool: return false, fly + 0.8)
	var spot: Dictionary = _spigot_spot(traces)
	ck(not spot.is_empty(), "a jar was seen filling (honey between a quarter and three quarters, no lid): the spigot spot exists")
	if spot.is_empty():
		_fin()
		return
	var sp: Vector3 = spot["pos"]
	ck(float(spot["spread"]) <= 0.08, "the jar stands still while it fills (spread %.3f)" % float(spot["spread"]))
	var cpos: Vector3 = (c as Node3D).global_position
	ck(Vector2(sp.x - cpos.x, sp.z - cpos.z).length() <= 2.5, "the fill spot is at the centrifuge (%.2f from its origin)" % Vector2(sp.x - cpos.x, sp.z - cpos.z).length())
	ck(not _in_crate(geo, sp), "the fill spot is not in the crate")
	var in_origin: Callable = func(s: Dictionary) -> bool: return _in_crate(geo, s["pos"]) and _empties_side(geo, s["pos"])
	var at_spigot: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(sp) <= 0.35
	var on_truck: Callable = func(s: Dictionary) -> bool: return (s["tb"] as AABB).has_point(s["pos"])
	var flights_in: Array = []
	var landings: Array = []
	var arrivals: Array = []
	var fulls_at: Array = []
	for k in traces:
		var tr: Array = traces[k]
		var fin: Array = _cut_flight(tr, in_origin, at_spigot)
		if fin.size() > 0:
			flights_in.append(fin)
			var arrive_t: float = float((fin[fin.size() - 1] as Dictionary)["t"])
			arrivals.append(arrive_t)
			var full_t: float = -1.0
			for s in tr:
				var sd: Dictionary = s
				if float(sd["t"]) >= arrive_t and bool(sd["lid"]) and float(sd["frac"]) >= 0.98:
					full_t = float(sd["t"])
					break
			fulls_at.append(full_t)
		var land: Array = _cut_flight(tr, at_spigot, on_truck)
		if land.size() > 0:
			landings.append(land)
			var lastp: Dictionary = tr[tr.size() - 1]
			ck(float(lastp["frac"]) >= 0.98 and bool(lastp["lid"]), "a jar that reached the truck is full with its lid (fraction %.2f)" % float(lastp["frac"]))
	ck(flights_in.size() >= jars_n, "%d empty jars flew from the crate to the spigot (found %d)" % [jars_n, flights_in.size()])
	for fl in flights_in:
		var bad: Array = _flight_problems(fl, fly, in_origin, at_spigot)
		ck(bad.is_empty(), "crate-to-spigot flight: %s" % "; ".join(bad))
	for i in fulls_at.size():
		var rise: float = float(fulls_at[i]) - float(arrivals[i])
		var want: float = spj - fly   # Clarifications 2026-11-04: the cycle is bottling_seconds_per_jar with the fly-in inside it
		ck(float(fulls_at[i]) >= 0.0 and rise >= want * 0.7 and rise <= want * 1.15 + 0.25, "the jar fills over bottling_seconds_per_jar - jar_fly_seconds after it arrives: %.2f s (wanted %.2f - %.2f = %.2f)" % [rise, spj, fly, want])
	ck(landings.size() >= jars_n, "%d full jars flew from the spigot onto the truck (found %d)" % [jars_n, landings.size()])
	for fl in landings:
		var bad2: Array = _flight_problems(fl, fly, at_spigot, on_truck)
		ck(bad2.is_empty(), "spigot-to-truck flight: %s" % "; ".join(bad2))
	arrivals.sort()
	if arrivals.size() >= 2 and fulls_at.size() >= 1:
		ck(float(arrivals[1]) >= float(fulls_at.min()) - 0.05, "the next empty jar flies in after the first one is full (second arrival %.2f, first full %.2f)" % [float(arrivals[1]), float(fulls_at.min())])
	eq(int(tk.get("loaded_jars")), jars_n, "%d jars are on the truck (the count logic is unchanged)" % jars_n)
	eq(int(tk.get("crate_jars")), 0, "none went to the crate while the truck was home")
	eq(_bed_count(tk), jars_n, "the landed jars show on the truck's bed")
	var empties_now: int = 0
	var fulls_in_crate: int = 0
	for j in _vis_jars(m):
		var jp: Vector3 = (j as Node3D).global_position
		if _in_crate(geo, jp):
			if _empties_side(geo, jp):
				empties_now += 1
			else:
				fulls_in_crate += 1
	eq(empties_now, int(cv("crate_empty_jars_shown")), "the crate shows its empties again: a jar taken is replaced (unlimited supply)")
	eq(fulls_in_crate, 0, "no full jar in the crate")
	_fin()


# Spec 5: with the truck AWAY the filled jar flies back into the crate, full with its lid, to the CrateFulls side, and the crate_jars count follows.
func t_jar_lands_in_crate_when_truck_away() -> void:
	var fly: float = 0.8
	var spj: float = 1.0
	_set_cfg("truck_trip_seconds", 120.0)
	var rig: Dictionary = await _bottling_rig(fly, spj)
	if rig.is_empty():
		_fin()
		return
	var m: Node = rig["m"]
	var c: Node = rig["c"]
	var tk: Node = rig["tk"]
	var geo: Dictionary = rig["geo"]
	var off: Array = rig["off"]
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	tk.call("sell")
	ck(bool(tk.get("away")), "the truck is away")
	await _frames(3)
	var jars_n: int = int(floorf(_jars_of(_cpf()) + 0.000001))
	var empty: int = _st(c, "EMPTY")
	_crank_unaided(c)
	var traces: Dictionary = {}
	await _record(m, tk, off, traces, func() -> bool: return int(c.get("state")) == empty, (spj + 2.0 * fly) * float(jars_n) + 8.0)
	await _record(m, tk, off, traces, func() -> bool: return false, fly + 0.8)
	var spot: Dictionary = _spigot_spot(traces)
	ck(not spot.is_empty(), "a jar was seen filling")
	if spot.is_empty():
		_fin()
		return
	var sp: Vector3 = spot["pos"]
	var at_spigot: Callable = func(s: Dictionary) -> bool: return (s["pos"] as Vector3).distance_to(sp) <= 0.35
	var in_fulls: Callable = func(s: Dictionary) -> bool: return _in_crate(geo, s["pos"]) and not _empties_side(geo, s["pos"])
	var landings: Array = []
	for k in traces:
		var land: Array = _cut_flight(traces[k], at_spigot, in_fulls)
		if land.size() > 0:
			landings.append(land)
	ck(landings.size() >= jars_n, "%d full jars flew from the spigot back into the crate's full group (found %d)" % [jars_n, landings.size()])
	for fl in landings:
		var bad: Array = _flight_problems(fl, fly, at_spigot, in_fulls)
		ck(bad.is_empty(), "spigot-to-crate flight: %s" % "; ".join(bad))
	eq(int(tk.get("crate_jars")), jars_n, "crate_jars counts the %d jars" % jars_n)
	eq(int(tk.get("loaded_jars")), 0, "nothing on the away truck")
	var fulls: int = 0
	var empties: int = 0
	for j in _vis_jars(m):
		var jp: Vector3 = (j as Node3D).global_position
		if not _in_crate(geo, jp):
			continue
		if _empties_side(geo, jp):
			empties += 1
			ck(_jar_empty(j), "a jar on the empties side stays empty")
		else:
			fulls += 1
			ck(_jar_full(j), "a jar landed in the crate is full with its lid (fraction %.2f)" % _jar_frac(j))
	eq(fulls, jars_n, "%d full jars stand on the CrateFulls side" % jars_n)
	eq(empties, int(cv("crate_empty_jars_shown")), "the empties are still there, apart from the fulls")
	_fin()


# Spec 5: when the truck returns, the crate's full jars fly onto it up to its capacity; the rest stay in the crate.
func t_crate_fulls_fly_to_truck_on_return() -> void:
	var fly: float = 0.6
	_set_cfg("truck_capacity_jars", 3)
	_set_cfg("truck_trip_seconds", 2.0)
	var rig: Dictionary = await _bottling_rig(fly, 1.0)
	if rig.is_empty():
		_fin()
		return
	var m: Node = rig["m"]
	var tk: Node = rig["tk"]
	var geo: Dictionary = rig["geo"]
	var off: Array = rig["off"]
	var cap: int = int(cv("truck_capacity_jars"))
	for i in cap:
		tk.call("receive_jar")
	tk.call("sell")
	var extra: int = cap + 2
	for i in extra:
		tk.call("receive_jar")
	eq(int(tk.get("crate_jars")), extra, "%d full jars wait in the crate" % extra)
	await _frames(4)
	var shown0: int = 0
	for j in _vis_jars(m):
		var jp: Vector3 = (j as Node3D).global_position
		if _in_crate(geo, jp) and not _empties_side(geo, jp):
			shown0 += 1
			ck(_jar_full(j), "a jar in the crate's full group is full with its lid")
	ck(shown0 >= 1, "the crate shows its full jars (%d drawn for %d in the count)" % [shown0, extra])
	var traces: Dictionary = {}
	await _record(m, tk, off, traces, func() -> bool: return not bool(tk.get("away")), 10.0)
	ck(not bool(tk.get("away")), "the truck came back")
	await _record(m, tk, off, traces, func() -> bool: return false, fly + 1.2)
	var in_fulls: Callable = func(s: Dictionary) -> bool: return _in_crate(geo, s["pos"]) and not _empties_side(geo, s["pos"])
	var on_truck: Callable = func(s: Dictionary) -> bool: return (s["tb"] as AABB).has_point(s["pos"]) and not _in_crate(geo, s["pos"])
	var flights: Array = []
	for k in traces:
		var fl: Array = _cut_flight(traces[k], in_fulls, on_truck)
		if fl.size() > 0:
			flights.append(fl)
	eq(flights.size(), cap, "exactly truck_capacity_jars (%d) full jars flew from the crate onto the truck" % cap)
	for fl in flights:
		var bad: Array = _flight_problems(fl, fly, in_fulls, on_truck)
		ck(bad.is_empty(), "crate-to-truck flight: %s" % "; ".join(bad))
	eq(int(tk.get("loaded_jars")), cap, "the truck holds its capacity")
	eq(int(tk.get("crate_jars")), extra - cap, "the rest stay in the crate")
	eq(_bed_count(tk), cap, "the jars show on the truck's bed")
	_fin()


# ---------------------------------------------------------------- bottling by itself, no Continue (spec change 6)
