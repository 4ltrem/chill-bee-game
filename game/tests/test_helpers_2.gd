extends "res://tests/test_helpers_1.gd"

# Quinn: shared helpers (part 2), split from run_tests.gd 2026-11-05. Each file extends the one before it.

## Oriented boxes of every visible MeshInstance3D under `n` (inclusive), skipping the subtrees in `skip`: [centre, [3 half axes], mesh].
func _obbs(n: Node, skip: Array = []) -> Array:
	var out: Array = []
	var meshes: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		meshes.append(n)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var skipped: bool = false
		for s in skip:
			if s != null and (s == mi or (s as Node).is_ancestor_of(mi)):
				skipped = true
		if skipped:
			continue
		var a: AABB = mi.mesh.get_aabb()
		var gt: Transform3D = mi.global_transform
		out.append([gt * (a.position + a.size * 0.5), [gt.basis.x * (a.size.x * 0.5), gt.basis.y * (a.size.y * 0.5), gt.basis.z * (a.size.z * 0.5)], mi])
	return out


## Separating-axis penetration depth of two oriented boxes (15 axes): <= 0 when separated, else the smallest overlap along any axis.
func _obb_pen(a: Array, b: Array) -> float:
	var aa: Array = a[1]
	var ab: Array = b[1]
	var axes: Array = []
	for v in aa:
		axes.append(v)
	for v in ab:
		axes.append(v)
	for i in 3:
		for j in 3:
			axes.append((aa[i] as Vector3).cross(ab[j] as Vector3))
	var d: Vector3 = (b[0] as Vector3) - (a[0] as Vector3)
	var best: float = 1.0e9
	for ax in axes:
		var l: float = (ax as Vector3).length()
		if l < 1.0e-4:
			continue
		var u: Vector3 = (ax as Vector3) / l
		var ra: float = 0.0
		for v in aa:
			ra += absf((v as Vector3).dot(u))
		var rb: float = 0.0
		for v in ab:
			rb += absf((v as Vector3).dot(u))
		var pen: float = ra + rb - absf(d.dot(u))
		if pen <= 0.0:
			return pen
		best = minf(best, pen)
	return best


## Largest penetration of any box of `lid` into any box of `body` (<= CONTACT_EPS means touching or clear).
func _max_pen(lid: Array, body: Array) -> float:
	var worst: float = -1.0e9
	for l in lid:
		for b in body:
			worst = maxf(worst, _obb_pen(l as Array, b as Array))
	return worst


func _box_corners_y(boxes: Array) -> Vector2:   # (min y, max y) of the corners
	var lo: float = 1.0e9
	var hi: float = -1.0e9
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		var ext: float = absf((ax[0] as Vector3).y) + absf((ax[1] as Vector3).y) + absf((ax[2] as Vector3).y)
		lo = minf(lo, c.y - ext)
		hi = maxf(hi, c.y + ext)
	return Vector2(lo, hi)


func _mk_box(size: Vector3, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	root.add_child(mi)
	mi.global_transform = xf
	_to_free.append(mi)
	return mi


func _angle_between(a: Basis, b: Basis) -> float:
	return (a.orthonormalized().inverse() * b.orthonormalized()).get_rotation_quaternion().get_angle()


## Sample a lid's global transform and its worst penetration into the body, once per frame, for `game_secs` of game time.
## Engine.time_scale slows the game so a tween of 0.65 s gives well over 30 frames.
func _sample_lid(lid: Node3D, body_fn: Callable, game_secs: float, scale: float = 0.25) -> Array:
	var out: Array = []
	_clk_tick()
	Engine.time_scale = scale
	var t_end: int = _gms() + int(game_secs * 1000.0)
	while _gms() < t_end:
		await process_frame
		out.append({"xf": lid.global_transform, "pen": _max_pen(_obbs(lid), body_fn.call() as Array)})
	_restore_scale()
	return out


## Checks every path must satisfy: >= 30 samples, really moving (a teleport passes an overlap test trivially), no overlap, ends at `end_xf`.
func _judge_path(tag: String, s: Array, end_xf: Transform3D, lift: float, check_lift: bool, rot_locked_in_lift: bool) -> void:
	ck(s.size() >= 30, "%s: at least 30 samples (%d)" % [tag, s.size()])
	if s.size() < 2:
		return
	var moving: int = 0
	var worst: float = -1.0e9
	var worst_i: int = 0
	var y0: float = ((s[0] as Dictionary)["xf"] as Transform3D).origin.y
	var o0: Vector3 = ((s[0] as Dictionary)["xf"] as Transform3D).origin
	var peak: float = 0.0
	for i in s.size():
		var xf: Transform3D = (s[i] as Dictionary)["xf"]
		if i > 0 and not xf.origin.is_equal_approx(((s[i - 1] as Dictionary)["xf"] as Transform3D).origin):
			moving += 1
		var pen: float = float((s[i] as Dictionary)["pen"])
		if pen > worst:
			worst = pen
			worst_i = i
		peak = maxf(peak, xf.origin.y - y0)
	ck(moving >= 20, "%s: the lid really moves over the samples (%d of %d samples differ from the previous one)" % [tag, moving, s.size()])
	ck(worst <= CONTACT_EPS, "%s: the lid box never overlaps the body or a frame: worst penetration %.3f at sample %d of %d (contact allowed up to %.2f)" % [tag, worst, worst_i, s.size(), CONTACT_EPS])
	var last: Transform3D = (s[s.size() - 1] as Dictionary)["xf"]
	ck(last.origin.distance_to(end_xf.origin) <= 0.02, "%s: ends at the target position (off by %.3f)" % [tag, last.origin.distance_to(end_xf.origin)])
	ck(_angle_between(last.basis, end_xf.basis) <= 0.03, "%s: ends at the target rotation (off by %.1f deg)" % [tag, rad_to_deg(_angle_between(last.basis, end_xf.basis))])
	if check_lift:
		ck(peak >= lift * 0.95, "%s: the lid rises by lid_lift_height first (peak rise %.3f, lift %.3f)" % [tag, peak, lift])
		var reached: int = -1
		for i in s.size():
			if ((s[i] as Dictionary)["xf"] as Transform3D).origin.y - y0 >= lift * 0.98:
				reached = i
				break
		ck(reached >= 0, "%s: a sample reaches the lift height" % tag)
		if reached >= 0:
			var sideways: float = 0.0
			var turned: float = 0.0
			for i in reached + 1:
				var xf2: Transform3D = (s[i] as Dictionary)["xf"]
				sideways = maxf(sideways, Vector2(xf2.origin.x - o0.x, xf2.origin.z - o0.z).length())
				turned = maxf(turned, _angle_between(((s[0] as Dictionary)["xf"] as Transform3D).basis, xf2.basis))
			ck(sideways <= 0.03, "%s: the lift is straight up (sideways drift %.3f before the top)" % [tag, sideways])
			if rot_locked_in_lift:
				ck(turned <= 0.05, "%s: no tipping before the top of the lift (%.1f deg)" % [tag, rad_to_deg(turned)])


func _hive_body(hive: Node) -> Callable:
	var lid: Node = hive.find_child("HiveLid", true, false)
	var hc: Node = hive.find_child("Honeycomb", true, false)
	return func() -> Array: return _obbs(hive, [lid, hc])


func _hive_setup() -> Dictionary:
	var m: Node = await _mk_main()
	if m == null:
		return {}
	_set_cfg("base_seconds_per_jar", 1.0e9)
	var hive: Node = _nn(m, "Hive")
	if hive == null:
		return {}
	var lid: Node = hive.find_child("HiveLid", true, false)
	var spot: Node = hive.find_child("HiveLidSpot", true, false)
	ck(lid != null, "the hive has a lid node named HiveLid (0.1.0 name; the spec names only HiveLidSpot)")
	ck(spot != null, "HiveLidSpot exists")
	if lid == null or spot == null:
		return {}
	await _frames(3)
	return {"m": m, "hive": hive, "lid": lid, "spot": spot}


func _screen_of(boxes: Array, cam: Camera3D) -> Rect2:
	var have: bool = false
	var r := Rect2()
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var p: Vector2 = cam.unproject_position(c + (ax[0] as Vector3) * sx + (ax[1] as Vector3) * sy + (ax[2] as Vector3) * sz)
					if not have:
						r = Rect2(p, Vector2.ZERO)
						have = true
					else:
						r = r.expand(p)
	return r


## The material a mesh instance draws with: override, surface override, the primitive mesh's own, then surface 0
## (the dummy renderer of a headless run cannot count surfaces of a primitive mesh).
func _mesh_mat(mi: MeshInstance3D) -> Material:
	var mat: Material = mi.material_override
	if mat == null:
		mat = mi.get_surface_override_material(0)
	if mat == null and mi.mesh is PrimitiveMesh:
		mat = (mi.mesh as PrimitiveMesh).material
	if mat == null and mi.mesh != null and not (mi.mesh is PrimitiveMesh) and mi.mesh.get_surface_count() > 0:
		mat = mi.mesh.surface_get_material(0)
	return mat


func _glass_of(c: Node) -> Array:   # the largest glass.tres box of the centrifuge that is not the jar's
	var best: Array = []
	var vol: float = -1.0
	for mi in c.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if m.mesh == null:
			continue
		var mat: Material = _mesh_mat(m)
		if mat == null or not mat.resource_path.ends_with("glass.tres"):
			continue
		var in_jar: bool = false
		var p: Node = m.get_parent()
		while p != null and p != c:
			if p.name == "SpigotJar":
				in_jar = true
			p = p.get_parent()
		if in_jar:
			continue
		var bx: Array = _obbs(m)
		if bx.is_empty():
			continue
		var ax: Array = (bx[0] as Array)[1]
		var v: float = (ax[0] as Vector3).length() * (ax[1] as Vector3).length() * (ax[2] as Vector3).length()
		if v > vol:
			vol = v
			best = bx[0]
	return best
