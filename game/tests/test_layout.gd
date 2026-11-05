extends "res://tests/test_speed.gd"

# Quinn: 0.1.3b layout tests, written from game/specs/0.1.3-next-revision.md (Changes 2, Contract "everywhere") and
# game/specs/0.1.3-farm-grid-layouts.md (layout C, cell 2.0) before the code. Each file extends the one before it.
# Cell centre: x = (col - 2) * 2.0, z = (row - 2) * 2.0. Layout C: hive (1,2), centrifuge (2,2), pile (2,3), crate (3,3)+(3,4),
# truck (4,3)+(4,4), flowers at (0,3) (1,4) (2,0), cells given as (col,row) below. The hive moves 1.25 up-right on screen (the
# round-5 pan-quarter), the truck (0.8, 0, 1.2) off its cells (Contract, Bob).

const LAYOUT_CELL: float = 2.0
const HIVE_PAN_OFFSET: float = 1.25
const POS_TOL: float = 0.06


func _cell_xz(col: float, row: float) -> Vector3:
	return Vector3((col - 2.0) * LAYOUT_CELL, 0.0, (row - 2.0) * LAYOUT_CELL)


## Jars (parent of each JarGlass) that belong to the crate: under its node, or inside its region.
func _crate_jars(m: Node, geo: Dictionary) -> Array:
	var crate: Node = _crate_root(m)
	var out: Array = []
	for j in _vis_jars(m):
		if (crate != null and crate.is_ancestor_of(j)) or _in_crate(geo, (j as Node3D).global_position):
			out.append(j)
	return out


## How far (units) any box corner of a jar lies outside the CrateBox footprint (x and z in the box's own space), less eps. <= 0: inside.
func _jar_overhang(box: MeshInstance3D, jar: Node, eps: float) -> float:
	var inv: Transform3D = box.global_transform.affine_inverse()
	var half: Vector3 = box.mesh.get_aabb().size * 0.5
	var ctr: Vector3 = box.mesh.get_aabb().position + half
	var worst: float = -1.0e9
	for bx in _obbs(jar):
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var q: Vector3 = inv * (c + (ax[0] as Vector3) * sx + (ax[1] as Vector3) * sy + (ax[2] as Vector3) * sz) - ctr
					worst = maxf(worst, maxf(absf(q.x) - half.x, absf(q.z) - half.z))
	return worst - eps


# Everywhere: no jar lies outside the crate's bounds (the box's footprint, in its own space so a turned crate is judged right).
func t_layout_no_jar_outside_crate() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	_set_cfg("jar_fly_seconds", 0.1)
	var tk: Node = _nn(m, "Truck")
	if tk == null:
		_fin()
		return
	# truck full and gone, so every jar bottled afterwards waits in the crate (empties group and full group)
	for i in int(cv("truck_capacity_jars")):
		tk.call("receive_jar")
	tk.call("sell")
	var extra: int = 6
	for i in extra:
		tk.call("receive_jar")
	await _wait(1.0)
	var geo: Dictionary = _geo_crate(m)
	if geo.is_empty():
		_fin()
		return
	var crate: Node = _crate_root(m)
	var box: MeshInstance3D = crate.find_child("CrateBox", true, false) as MeshInstance3D
	ck(box != null and box.mesh != null, "the crate has a CrateBox mesh")
	if box == null or box.mesh == null:
		_fin()
		return
	var jars: Array = _crate_jars(m, geo)
	ck(jars.size() >= extra, "the crate holds at least %d jars to measure (%d)" % [extra, jars.size()])
	var bad: int = 0
	var worst: float = -1.0e9
	for j in jars:
		var o: float = _jar_overhang(box, j, 0.01)
		worst = maxf(worst, o)
		if o > 0.0:
			bad += 1
	eq(bad, 0, "no jar hangs over the crate's edge (%d jars, worst overhang %.3f)" % [jars.size(), worst])
	# the check can fail: a jar moved 5 units sideways must be reported
	if jars.size() > 0:
		var j0: Node3D = jars[0] as Node3D
		var keep: Vector3 = j0.global_position
		j0.global_position = keep + Vector3(5.0, 0.0, 0.0)
		ck(_jar_overhang(box, j0, 0.01) > 1.0, "self-check: a jar 5 units away is reported as outside")
		j0.global_position = keep
	_fin()


## Largest |wheel bottom - ground top| and whether every wheel centre lies inside the ground's x/z rectangle.
func _wheel_ground(tk: Node, ground: MeshInstance3D) -> Dictionary:
	var ga: AABB = ground.mesh.get_aabb()
	var gy: float = (ground.global_transform * (ga.position + ga.size)).y
	var sp: Array = _span_xz(_obbs(ground))
	var off: float = 0.0
	var inside: bool = true
	var n: int = 0
	for nm in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var w: MeshInstance3D = tk.find_child(nm, true, false) as MeshInstance3D
		if w == null or not (w.mesh is CylinderMesh):
			return {}
		var cyl: CylinderMesh = w.mesh as CylinderMesh
		var gt: Transform3D = w.global_transform
		var a: AABB = cyl.get_aabb()
		var c: Vector3 = gt * (a.position + a.size * 0.5)
		var s: Vector3 = gt.basis.get_scale()
		# the cylinder's axis is its local Y; its radius is in the other two axes
		var ax_world: Vector3 = gt.basis.y.normalized()
		var r: float = maxf(cyl.top_radius, cyl.bottom_radius) * maxf(s.x, s.z)
		var low: float = c.y - r * sqrt(maxf(1.0 - ax_world.y * ax_world.y, 0.0))   # a lying cylinder: y of its lowest rim point
		off = maxf(off, absf(low - gy))
		if c.x < float(sp[0]) or c.x > float(sp[2]) or c.z < float(sp[1]) or c.z > float(sp[3]):
			inside = false
		n += 1
	return {"off": off, "inside": inside, "n": n, "gy": gy}


# Everywhere: the truck's wheels are on the ground plane (touching it, not hovering or sunk, and over it).
func t_layout_truck_wheels_on_ground() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var tk: Node = _nn(m, "Truck")
	var ground: MeshInstance3D = m.find_child("Ground", true, false) as MeshInstance3D
	ck(ground != null and ground.mesh != null, "the Ground mesh exists")
	if tk == null or ground == null or ground.mesh == null:
		_fin()
		return
	var r: Dictionary = _wheel_ground(tk, ground)
	ck(not r.is_empty() and int(r["n"]) == 4, "the four wheels are cylinders the test can read")
	if r.is_empty():
		_fin()
		return
	ck(float(r["off"]) <= 0.05, "the wheels' lowest points sit on the ground plane (worst %.3f off, ground top y %.3f)" % [float(r["off"]), float(r["gy"])])
	ck(bool(r["inside"]), "every wheel is over the ground plane's rectangle (the ground reaches under the truck)")
	# the check can fail: lift the ground and the wheels hover, move the ground away and they are outside
	var g0: Vector3 = ground.position
	ground.position = g0 + Vector3(0.0, 0.3, 0.0)
	ck(float(_wheel_ground(tk, ground)["off"]) > 0.1, "self-check: a ground 0.3 higher is reported")
	ground.position = g0 + Vector3(0.0, 0.0, -20.0)
	ck(not bool(_wheel_ground(tk, ground)["inside"]), "self-check: a ground moved away is reported")
	ground.position = g0
	_fin()


func _hive_extent(hive: Node) -> float:
	var sp: Array = _span_xz(_obbs(hive))
	return maxf(float(sp[2]) - float(sp[0]), float(sp[3]) - float(sp[1]))


# Contract: the hive is scaled by config hive_scale (1.4 by default), and a live change shows at once.
func t_layout_hive_scale_follows_config() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	if hive == null:
		_fin()
		return
	near(float(cv("hive_scale")), 1.4, "the default hive_scale is 1.4", 1e-6)
	var start: float = float(cv("hive_scale"))
	var e_start: float = _hive_extent(hive)
	_set_cfg("hive_scale", 1.0)
	await _frames(4)
	var e1: float = _hive_extent(hive)
	near(e_start / e1, start, "at the config's %.2f the hive is %.2f x its size at 1.0 (%.3f / %.3f)" % [start, start, e_start, e1], 0.02)
	_set_cfg("hive_scale", 2.0)
	await _frames(4)
	var e2: float = _hive_extent(hive)
	near(e2 / e1, 2.0, "a live change to 2.0 doubles the hive's size (%.3f -> %.3f)" % [e1, e2], 0.02)
	near((hive as Node3D).global_transform.basis.get_scale().x, 2.0, "the Hive node's scale is 2.0", 0.02)
	_set_cfg("hive_scale", 0.7)
	await _frames(4)
	near(_hive_extent(hive) / e1, 0.7, "a live change down to 0.7 shrinks it", 0.02)
	_fin()


# Item 2: the objects sit on layout C's cells at cell 2.0; the hive is moved 1.25 up-right (on screen) from its cell.
func t_layout_objects_on_cells() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Vector3 = (p["Hive"] as Node3D).global_position
	var cell: Vector3 = _cell_xz(2.0, 1.0)
	var d: Vector3 = hive - cell
	d.y = 0.0
	near(d.length(), HIVE_PAN_OFFSET, "the hive stands %.2f from its layout-C cell (col 2, row 1) (%.3f)" % [HIVE_PAN_OFFSET, d.length()], 0.03)
	# the camera looks along (-1,-1,-1): screen right is (1,0,-1), screen up on the ground is (-1,0,-1)
	ck(d.dot(Vector3(1.0, 0.0, -1.0).normalized()) > 0.1 and d.dot(Vector3(-1.0, 0.0, -1.0).normalized()) > 0.1, "the offset is up-right on screen (%s)" % str(d))
	var want: Array = [
		["Centrifuge", _cell_xz(2.0, 2.0)],
		["Pile", _cell_xz(3.0, 2.0)],
		["JarCrate", _cell_xz(3.5, 3.0)],
		["Truck", _cell_xz(3.5, 4.0) + Vector3(0.8, 0.0, 1.2)],
	]
	for w in want:
		var n: Node3D = m.find_child(w[0], true, false) as Node3D
		ck(n != null, "%s exists" % w[0])
		if n == null:
			continue
		var g: Vector3 = n.global_position
		var e: Vector3 = (w[1] as Vector3) - g
		e.y = 0.0
		ck(e.length() <= POS_TOL, "%s sits at %s (got %s, %.3f off)" % [w[0], str(w[1]), str(g), e.length()])
	var flowers: Array = [_cell_xz(3.0, 0.0), _cell_xz(4.0, 1.0), _cell_xz(0.0, 2.0)]
	for i in 3:
		var f: Node3D = m.find_child("FlowerPatch%d" % (i + 1), true, false) as Node3D
		ck(f != null, "FlowerPatch%d exists" % (i + 1))
		if f == null:
			continue
		var fe: Vector3 = (flowers[i] as Vector3) - f.global_position
		near(f.global_position.y, 0.15, "FlowerPatch%d keeps y 0.15" % (i + 1), 0.001)
		fe.y = 0.0
		ck(fe.length() <= POS_TOL, "FlowerPatch%d sits on its cell %s (got %s)" % [i + 1, str(flowers[i]), str(f.global_position)])
	# the check can fail: it reports an object one cell away
	ck(((_cell_xz(2.0, 3.0) - (p["Centrifuge"] as Node3D).global_position) * Vector3(1, 0, 1)).length() > POS_TOL, "self-check: the cell below the centrifuge is not where it stands")
	_fin()
