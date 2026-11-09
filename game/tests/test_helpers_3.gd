extends "res://tests/test_helpers_2.gd"

# Quinn: shared helpers (part 3), split from run_tests.gd 2026-11-05. Each file extends the one before it.

func _span_xz(boxes: Array) -> Array:   # [min x, min z, max x, max z]
	var lo := Vector2(1.0e9, 1.0e9)
	var hi := Vector2(-1.0e9, -1.0e9)
	for bx in boxes:
		var cc: Vector3 = (bx as Array)[0]
		var axs: Array = (bx as Array)[1]
		var ex: float = absf((axs[0] as Vector3).x) + absf((axs[1] as Vector3).x) + absf((axs[2] as Vector3).x)
		var ez: float = absf((axs[0] as Vector3).z) + absf((axs[1] as Vector3).z) + absf((axs[2] as Vector3).z)
		lo = Vector2(minf(lo.x, cc.x - ex), minf(lo.y, cc.z - ez))
		hi = Vector2(maxf(hi.x, cc.x + ex), maxf(hi.y, cc.z + ez))
	return [lo.x, lo.y, hi.x, hi.y]


## Drawn cells under a node: visible MultiMesh instances, or visible direct Node3D children that are not labels or markers.
func _drawn_positions(n: Node) -> Array:
	var out: Array = []
	if n == null:
		return out
	for mm in n.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi: MultiMeshInstance3D = mm as MultiMeshInstance3D
		if mmi.multimesh == null or not mmi.is_visible_in_tree():
			continue
		var k: int = mmi.multimesh.visible_instance_count if mmi.multimesh.visible_instance_count >= 0 else mmi.multimesh.instance_count
		for i in k:
			out.append(mmi.global_transform * mmi.multimesh.get_instance_transform(i).origin)
	for ch in n.get_children():
		if ch is Node3D and not (ch is Label3D) and not (ch is Marker3D) and not (ch is MultiMeshInstance3D) and (ch as Node3D).is_visible_in_tree():
			out.append((ch as Node3D).global_position)
	return out


func _mat_path(mi: MeshInstance3D) -> String:
	var mat: Material = _mesh_mat(mi)
	return mat.resource_path if mat != null else ""


## Honey height of a jar as a fraction between its two markers: the top of JarHoney's box. 0 when JarHoney is hidden.
func _jar_frac(jar: Node) -> float:
	var hn: Node3D = jar.find_child("JarHoney", true, false) as Node3D
	var b: Node3D = jar.find_child("JarHoneyBottom", true, false) as Node3D
	var t: Node3D = jar.find_child("JarHoneyTop", true, false) as Node3D
	if hn == null or b == null or t == null:
		return -1.0
	if not hn.is_visible_in_tree():
		return 0.0
	var bx: Array = _obbs(hn)
	if bx.is_empty():
		return 0.0
	var top: float = _box_corners_y(bx).y
	return (top - b.global_position.y) / (t.global_position.y - b.global_position.y)


func _jar_lid_shown(jar: Node) -> bool:
	var ld: Node3D = jar.find_child("JarLid", true, false) as Node3D
	return ld != null and ld.is_visible_in_tree()


## Total angle (rad) the offset between two nodes turned over the samples. Both nodes' positions move with the truck; their difference does not.
func _offset_turn(offsets: Array) -> float:
	var tot: float = 0.0
	for i in range(1, offsets.size()):
		var a: Vector3 = offsets[i - 1]
		var b: Vector3 = offsets[i]
		if a.length() > 1.0e-6 and b.length() > 1.0e-6:
			tot += a.angle_to(b)
	return tot


func _albedo_of(mi: MeshInstance3D) -> Color:
	var mat: Material = _mesh_mat(mi)
	if mat is BaseMaterial3D:
		return (mat as BaseMaterial3D).albedo_color
	return Color(0.0, 0.0, 0.0)


# ---------------------------------------------------------------- the zoom at the new angle (spec 3)

## Screen width (px) of one cell's hexagonal face: its two flat sides through the cell centre along the mesh's local X (the frame's width axis).
func _cell_face_w(mi: MeshInstance3D, cam: Camera3D) -> float:
	var aabb: AABB = mi.mesh.get_aabb()
	var c: Vector3 = aabb.position + aabb.size * 0.5
	c.y = aabb.end.y
	var hx := Vector3(aabb.size.x * 0.5, 0.0, 0.0)
	var gt: Transform3D = mi.global_transform
	return cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx)))


func _zoom_open_main() -> Dictionary:
	var m: Node = await _mk_main()
	if m == null:
		return {}
	var p: Dictionary = _parts(m)
	if p.is_empty():
		return {}
	var tr: Dictionary = _track(p["Hive"])
	_full_hive_frozen(p["Hive"])
	await _frames(4)
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "the zoom opened with a risen frame")
	return {"m": m, "p": p, "tr": tr}


## Every visible jar of the scene: the parent of each JarGlass.
func _vis_jars(m: Node) -> Array:
	var out: Array = []
	for g in m.find_children("JarGlass", "", true, false):
		var j: Node = g.get_parent()
		if j is Node3D and (j as Node3D).is_visible_in_tree() and not out.has(j):
			out.append(j)
	return out


func _crate_root(m: Node) -> Node:
	var n: Node = m.find_child("CrateEmpties", true, false)
	while n != null and n != m:
		if n.scene_file_path.ends_with("jar_crate.tscn"):
			return n
		n = n.get_parent()
	var cj: Node = m.find_child("CrateJars", true, false)
	return cj.get_parent() if cj != null else null


## The crate's place: its two group markers and a disc (x, z) around its own boxes (jars not counted) that "in the crate" means.
func _geo_crate(m: Node) -> Dictionary:
	var crate: Node = _crate_root(m)
	var em: Node3D = _nn(m, "CrateEmpties") as Node3D
	var fu: Node3D = _nn(m, "CrateFulls") as Node3D
	ck(crate != null, "the crate (a jar_crate.tscn instance holding CrateEmpties) was found")
	if crate == null or em == null or fu == null:
		return {}
	var jars: Array = []
	for g in crate.find_children("JarGlass", "", true, false):
		jars.append(g.get_parent())
	var boxes: Array = _obbs(crate, jars)
	ck(boxes.size() > 0, "the crate has boxes of its own")
	if boxes.is_empty():
		return {}
	var sp: Array = _span_xz(boxes)
	var ys: Vector2 = _box_corners_y(boxes)
	var cen := Vector2((float(sp[0]) + float(sp[2])) * 0.5, (float(sp[1]) + float(sp[3])) * 0.5)
	var rad: float = Vector2(float(sp[2]) - float(sp[0]), float(sp[3]) - float(sp[1])).length() * 0.5 + 0.3
	return {"cen": cen, "rad": rad, "ylo": ys.x - 0.3, "yhi": ys.y + 1.5, "em": em.global_position, "fu": fu.global_position}


func _in_crate(geo: Dictionary, p: Vector3) -> bool:
	var cen: Vector2 = geo["cen"]
	return Vector2(p.x - cen.x, p.z - cen.y).length() <= float(geo["rad"]) and p.y >= float(geo["ylo"]) and p.y <= float(geo["yhi"])


func _empties_side(geo: Dictionary, p: Vector3) -> bool:
	return p.distance_to(geo["em"] as Vector3) <= p.distance_to(geo["fu"] as Vector3)


func _jar_empty(j: Node) -> bool:
	return _jar_frac(j) <= 0.15 and not _jar_lid_shown(j)


func _jar_full(j: Node) -> bool:
	return _jar_frac(j) >= 0.98 and _jar_lid_shown(j)


## Offsets (lo, size) of the truck's boxes (jars on the bed not counted) from its origin, so its region can follow it while it drives.
func _truck_box_off(tk: Node) -> Array:
	var bed: Node = tk.find_child("BedJars", true, false)
	var boxes: Array = _obbs(tk, [bed])
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		var e := Vector3(absf((ax[0] as Vector3).x) + absf((ax[1] as Vector3).x) + absf((ax[2] as Vector3).x), absf((ax[0] as Vector3).y) + absf((ax[1] as Vector3).y) + absf((ax[2] as Vector3).y), absf((ax[0] as Vector3).z) + absf((ax[1] as Vector3).z) + absf((ax[2] as Vector3).z))
		lo = Vector3(minf(lo.x, c.x - e.x), minf(lo.y, c.y - e.y), minf(lo.z, c.z - e.z))
		hi = Vector3(maxf(hi.x, c.x + e.x), maxf(hi.y, c.y + e.y), maxf(hi.z, c.z + e.z))
	var o: Vector3 = (tk as Node3D).global_position
	return [lo - o, hi - lo]


## Sample every visible jar once per frame: traces[instance id] = [{t, pos, frac, lid, tb}], tb = the truck's region (padded) at that frame.
func _record(m: Node, tk: Node, off: Array, traces: Dictionary, stop: Callable, timeout: float) -> void:
	var t0: int = _gms()
	var last: int = t0
	var gt: float = 0.0
	for k in traces:
		var arr: Array = traces[k]
		gt = maxf(gt, float((arr[arr.size() - 1] as Dictionary)["t"]))
	while float(_gms() - t0) < timeout * 1000.0 and not stop.call():
		await process_frame
		var now: int = _gms()
		gt += float(now - last) / 1000.0   # game clock
		last = now
		var tb: AABB = AABB((tk as Node3D).global_position + (off[0] as Vector3), off[1] as Vector3).grow(0.4)
		for j in _vis_jars(m):
			var id: int = j.get_instance_id()
			if not traces.has(id):
				traces[id] = []
			(traces[id] as Array).append({"t": gt, "pos": (j as Node3D).global_position, "frac": _jar_frac(j), "lid": _jar_lid_shown(j), "tb": tb})


## The flight inside a trace: from the last sample inside `origin` (before the first arrival) to the first arrival in `dest`. [] if none.
func _cut_flight(trace: Array, origin: Callable, dest: Callable) -> Array:
	var first_o: int = -1
	for i in trace.size():
		if origin.call(trace[i]):
			first_o = i
			break
	if first_o < 0:
		return []
	var arr: int = -1
	for i in range(first_o + 1, trace.size()):
		if dest.call(trace[i]):
			arr = i
			break
	if arr < 0:
		return []
	var start: int = first_o
	for i in range(first_o, arr):
		if origin.call(trace[i]):
			start = i
	# Clarifications 2026-11-04: a flight is measured from launch to landing, not from the moment the jar crosses into a zone. The zones
	# (a crate disc, the truck's box) are bigger than the places the jar leaves from and lands on, so walk the start back to the last
	# sample where the jar still stood still, and the end on to the first sample from which it rests (moves under FLIGHT_REST for FLIGHT_REST_S).
	while start > 0 and ((trace[start - 1] as Dictionary)["pos"] as Vector3).distance_to((trace[start] as Dictionary)["pos"]) > FLIGHT_STILL:
		start -= 1
	while arr + 1 < trace.size() and not _rests_from(trace, arr):
		arr += 1
	return trace.slice(start, arr + 1)


## True when the jar stays within FLIGHT_REST of its position at sample i for the next FLIGHT_REST_S seconds (or to the end of the trace).
func _rests_from(trace: Array, i: int) -> bool:
	var p0: Vector3 = (trace[i] as Dictionary)["pos"]
	var t0: float = float((trace[i] as Dictionary)["t"])
	for j in range(i + 1, trace.size()):
		var sj: Dictionary = trace[j]
		if float(sj["t"]) - t0 > FLIGHT_REST_S:
			return true
		if (sj["pos"] as Vector3).distance_to(p0) > FLIGHT_REST:
			return false
	return true


## What is wrong with a flight (empty = nothing): it must be a real flight, not a jump, lasting about jar_fly_seconds.
func _flight_problems(fl: Array, fly_s: float, origin: Callable, dest: Callable) -> Array:
	var bad: Array = []
	if fl.size() < 2:
		return ["no flight found"]
	var air: int = 0
	for i in fl.size():
		var s: Dictionary = fl[i]
		if i > 0 and i < fl.size() - 1 and not origin.call(s) and not dest.call(s):
			air += 1
	var dur: float = float((fl[fl.size() - 1] as Dictionary)["t"]) - float((fl[0] as Dictionary)["t"])
	if air < FLIGHT_MIN_AIR:
		bad.append("only %d samples in the air (need %d): a jump, not a flight" % [air, FLIGHT_MIN_AIR])
	if dur < fly_s * 0.5 or dur > fly_s * 1.6 + 0.3:
		bad.append("lasted %.2f s, jar_fly_seconds is %.2f" % [dur, fly_s])
	return bad


## A synthetic flight: n samples from a to b over `secs`.
func _fake_flight(a: Vector3, b: Vector3, secs: float, n: int) -> Array:
	var out: Array = []
	for i in n:
		var f: float = float(i) / float(n - 1)
		out.append({"t": secs * f, "pos": a.lerp(b, f), "frac": 0.0, "lid": false, "tb": AABB()})
	return out


## Any node named ContinueButton, or any Button whose text says Continue (case-insensitive), under n.
func _continue_nodes(n: Node) -> Array:
	var out: Array = []
	for c in n.find_children("*", "", true, false):
		if String(c.name) == "ContinueButton" or (c is Button and (c as Button).text.to_lower().contains("continue")):
			out.append(c)
	return out


## Common set-up for the flight tests: the scene, the crate's place, the truck's region.
func _bottling_rig(fly: float, spj: float) -> Dictionary:
	_set_cfg("jar_fly_seconds", fly)
	_set_cfg("bottling_seconds_per_jar", spj)
	var m: Node = await _mk_main()
	if m == null:
		return {}
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var c: Node = _nn(m, "Centrifuge")
	var tk: Node = _nn(m, "Truck")
	var geo: Dictionary = _geo_crate(m)
	if c == null or tk == null or geo.is_empty():
		return {}
	await _frames(4)
	return {"m": m, "c": c, "tk": tk, "geo": geo, "off": _truck_box_off(tk)}


## One frame of cells (2 jars), lid on, cranked to the end by calls: from here on the game must carry on by itself.
func _crank_unaided(c: Node) -> void:
	var cells: int = _cpf()
	c.call("add_cells", cells, _jars_of(cells))
	c.call("close_lid")
	c.call("begin_crank")
	_crank_done(c)


## Where the jar stands while its honey fills (fraction 0.25 to 0.75, no lid): the place under the spigot, measured, not assumed.
func _spigot_spot(traces: Dictionary) -> Dictionary:
	var pts: Array = []
	for k in traces:
		for s in (traces[k] as Array):
			var sd: Dictionary = s
			if not bool(sd["lid"]) and float(sd["frac"]) > 0.25 and float(sd["frac"]) < 0.75:
				pts.append(sd["pos"])
	if pts.size() < 3:
		return {}
	var mean := Vector3.ZERO
	for p in pts:
		mean += p as Vector3
	mean /= float(pts.size())
	var spread: float = 0.0
	for p in pts:
		spread = maxf(spread, (p as Vector3).distance_to(mean))
	return {"pos": mean, "spread": spread, "n": pts.size()}


func _bed_count(tk: Node) -> int:
	var bed: Node = tk.find_child("BedJars", true, false)
	var n: int = 0
	if bed != null:
		for j in bed.get_children():
			if (j as Node3D).is_visible_in_tree() and not (j is Label3D):
				n += 1
	return n
