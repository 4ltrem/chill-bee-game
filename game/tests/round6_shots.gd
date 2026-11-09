# Bob: round 6 first-zoom comparison, four options (overrides only, no scene/script/config file changed). Based on shots_0_1_3.gd.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/round6_shots.gd
# Shots to game/reports/round6-shots/: <option>-1-first-zoom.png, <option>-2-second-stop.png and checks.json.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const OUT := "res://reports/round6-shots/"
const CELL: float = 2.0
const ASPECT: float = 720.0 / 1280.0
const OFFSET: float = 1.25                     # the round-5 hive shift up-right (world -z)
const LID_SPOT := Vector3(0.0, 0.075, 3.125)
const FIT_MARGIN: float = 0.005                # per side, on the smallest fitting zoom
const OPTS := [
	{"name": "A-hive-on-cell", "off": 0.0, "scale": 1.4, "mode": "fixed", "zoom": 6.966},
	{"name": "B-smaller-cells", "off": OFFSET, "scale": 1.4, "mode": "fit", "zoom": 0.0},
	{"name": "C-smaller-hive", "off": OFFSET, "scale": 1.4, "mode": "scale", "zoom": 7.6},
	{"name": "D-hive-cropped", "off": OFFSET, "scale": 1.4, "mode": "crop", "zoom": 6.966},
]

var fi: RefCounted
var main: Node
var risen: int = -1
var grid: Array = []
var checks: Dictionary = {}
var truck_off := Vector3(0.8, 0.0, 1.2)
var hive_off := Vector3.ZERO


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < sec * 1000.0:
		await process_frame


func _cfg() -> Object:
	return root.get_node("Economy").get("config")


func _cells_of(code: int) -> Array:
	var out: Array = []
	for r in 5:
		for c in 5:
			if int(grid[r][c]) == code:
				out.append(Vector2(c, r))
	return out


func _centre(cells: Array, cell: float) -> Vector3:
	var s := Vector2.ZERO
	for v in cells:
		s += v as Vector2
	s /= float(cells.size())
	return Vector3((s.x - 2.0) * cell, 0.0, (s.y - 2.0) * cell)

func _build(off: float, hscale: float, zoom: float) -> void:
	FarmInput.reset_dev_config()
	_cfg().set("hive_scale", hscale)
	root.get_node("Economy").call("reset")
	hive_off = Vector3(0.0, 0.0, -off)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var fw: Node3D = main.get_node("FarmWorld")
	var hive3: Node3D = fw.get_node("Hive")
	hive3.position = _centre(_cells_of(1), CELL) + hive_off
	hive3.scale = Vector3.ONE * hscale
	var cen: Node3D = fw.get_node("Centrifuge")
	cen.position = _centre(_cells_of(3), CELL)
	cen.scale = Vector3.ONE * 0.64
	(fw.get_node("Pile") as Node3D).position = _centre(_cells_of(6), CELL)
	(fw.get_node("JarCrate") as Node3D).position = _centre(_cells_of(4), CELL)
	var truck: Node3D = fw.get_node("Truck")
	truck.position = _centre(_cells_of(5), CELL) + truck_off
	truck.scale = Vector3.ONE * 0.93
	var fl: Array = _cells_of(2)
	for i in 3:
		var p: Vector3 = _centre([fl[i]], CELL)
		p.y = 0.15
		(fw.get_node("Flowers/FlowerPatch%d" % (i + 1)) as Node3D).position = p
	(cen.find_child("CentrifugeLidSpot", true, false) as Node3D).position = LID_SPOT
	var g: MeshInstance3D = fw.get_node("Ground")
	var pm: PlaneMesh = (g.mesh as PlaneMesh).duplicate()
	pm.size = Vector2(5.0 * CELL, 5.0 * CELL)
	g.mesh = pm
	(main.get_node("Camera3D") as Camera3D).size = 20.0
	root.add_child(main)
	await _frames(10)
	var hive: Node = main.find_child("Hive", true, false)
	risen = -1
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	hive.call("fill_now")
	var cfg: Object = _cfg()
	cfg.set("zoom_size", zoom)
	cfg.set("base_seconds_per_jar", 1.0e9)
	await _frames(5)


func _open_zoom() -> void:
	await fi.click_icon(main.find_child("ForkIcon", true, false) as Control)
	var t0: int = Time.get_ticks_msec()
	while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	var cfg: Object = _cfg()
	var lift: Variant = cfg.get("lid_lift_seconds")
	await _wait(float(cfg.get("zoom_seconds")) + float(cfg.get("lid_drop_seconds")) + (float(lift) if lift != null else 0.0) + float(cfg.get("slide_seconds")) + 0.8)


func _free_main() -> void:
	root.remove_child(main)
	main.queue_free()
	await _frames(3)


## Projected (u, v) rect of the visible meshes under `nodes`, in camera right/up units.
func _rect(nodes: Array, cam: Camera3D, skip: Node = null) -> Rect2:
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	var lo := Vector2(1.0e9, 1.0e9)
	var hi := Vector2(-1.0e9, -1.0e9)
	for n in nodes:
		for mi in (n as Node).find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi as MeshInstance3D
			if m.mesh == null or not m.is_visible_in_tree() or (skip != null and skip.is_ancestor_of(m)):
				continue
			var a: AABB = m.mesh.get_aabb()
			for k in 8:
				var p: Vector3 = m.global_transform * a.get_endpoint(k)
				var uv := Vector2(p.dot(right), p.dot(up))
				lo = Vector2(minf(lo.x, uv.x), minf(lo.y, uv.y))
				hi = Vector2(maxf(hi.x, uv.x), maxf(hi.y, uv.y))
	return Rect2(lo, hi - lo)


## Area-weighted sample points of a node's visible meshes: [uv, weight (projected area), world point].
func _samples(node: Node, cam: Camera3D) -> Array:
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	var out: Array = []
	var n: int = 3
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree():
			continue
		var f: PackedVector3Array = m.mesh.get_faces()
		var gt: Transform3D = m.global_transform
		for t in range(0, f.size() - 2, 3):
			var a: Vector3 = gt * f[t]
			var b: Vector3 = gt * f[t + 1]
			var c: Vector3 = gt * f[t + 2]
			var ua := Vector2(a.dot(right), a.dot(up))
			var ub := Vector2(b.dot(right), b.dot(up))
			var uc := Vector2(c.dot(right), c.dot(up))
			var area: float = absf((ub - ua).cross(uc - ua)) * 0.5
			if area < 1.0e-9:
				continue
			var w: float = area / float(n * n)
			for i in n:
				for j in n - i:
					var s1: float = (float(i) + 1.0 / 3.0) / float(n)
					var s2: float = (float(j) + 1.0 / 3.0) / float(n)
					var p: Vector3 = a + (b - a) * s1 + (c - a) * s2
					out.append([Vector2(p.dot(right), p.dot(up)), w, p])
					if i + j < n - 1:
						s1 = (float(i) + 2.0 / 3.0) / float(n)
						s2 = (float(j) + 2.0 / 3.0) / float(n)
						p = a + (b - a) * s1 + (c - a) * s2
						out.append([Vector2(p.dot(right), p.dot(up)), w, p])
	return out


## The node's silhouette: the 0.08-unit (u, v) cells covered by its projected triangles (overlaps count once), as [cell centre, 1.0].
func _silhouette(node: Node, cam: Camera3D) -> Array:
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	var cs: float = 0.08
	var seen: Dictionary = {}
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree():
			continue
		var f: PackedVector3Array = m.mesh.get_faces()
		var gt: Transform3D = m.global_transform
		for t in range(0, f.size() - 2, 3):
			var pa: Vector3 = gt * f[t]
			var pb: Vector3 = gt * f[t + 1]
			var pc: Vector3 = gt * f[t + 2]
			var a := Vector2(pa.dot(right), pa.dot(up))
			var b := Vector2(pb.dot(right), pb.dot(up))
			var c := Vector2(pc.dot(right), pc.dot(up))
			var den: float = (b - a).cross(c - a)
			var lo := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.y, minf(b.y, c.y)))
			var hi := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.y, maxf(b.y, c.y)))
			var i0: int = int(floor(lo.x / cs))
			var i1: int = int(floor(hi.x / cs))
			var j0: int = int(floor(lo.y / cs))
			var j1: int = int(floor(hi.y / cs))
			if absf(den) < 1.0e-9 or (i1 - i0) * (j1 - j0) <= 1:
				seen[Vector2i(int(floor((a.x + b.x + c.x) / 3.0 / cs)), int(floor((a.y + b.y + c.y) / 3.0 / cs)))] = true
				continue
			for i in range(i0, i1 + 1):
				for j in range(j0, j1 + 1):
					var q := (Vector2(float(i), float(j)) + Vector2(0.5, 0.5)) * cs
					var w1: float = (q - a).cross(c - a) / den
					var w2: float = (b - a).cross(q - a) / den
					if w1 >= 0.0 and w2 >= 0.0 and w1 + w2 <= 1.0:
						seen[Vector2i(i, j)] = true
	var out: Array = []
	for k in seen:
		out.append([(Vector2(k) + Vector2(0.5, 0.5)) * cs, 1.0])
	return out


func _visible_fraction(samples: Array, v: Rect2) -> float:
	var tot: float = 0.0
	var inside: float = 0.0
	for s in samples:
		tot += float(s[1])
		if v.has_point(s[0] as Vector2):
			inside += float(s[1])
	return inside / maxf(tot, 1.0e-9)


func _min_cell_px(cam: Camera3D) -> float:
	var min_w: float = 1.0e9
	for mi in main.find_child("Honeycomb", true, false).find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var aabb: AABB = m.mesh.get_aabb()
		var c: Vector3 = aabb.position + aabb.size * 0.5
		c.y = aabb.end.y
		var hx := Vector3(aabb.size.x * 0.5, 0.0, 0.0)
		var gt: Transform3D = m.global_transform
		min_w = minf(min_w, cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx))))
	return min_w


func _shot(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	print("shot ", name, " ", img.get_size(), " err=", img.save_png(ProjectSettings.globalize_path(OUT + name + ".png")))

func _whole(r: Rect2, v: Rect2) -> bool:
	var e: float = 0.002
	return r.position.x >= v.position.x - e and r.end.x <= v.end.x + e and r.position.y >= v.position.y - e and r.end.y <= v.end.y + e


func _view(cam: Camera3D) -> Rect2:
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	return _view_of(cam.global_position.dot(right), cam.global_position.dot(up), cam.size)


func _view_of(cx: float, cy: float, size: float) -> Rect2:
	return Rect2(cx - size * ASPECT * 0.5, cy - size * 0.5, size * ASPECT, size)


## Rects of the hive, its silhouette, the centrifuge body (no lid), the whole centrifuge and the hive frames, after the zoom has opened.
func _probe(off: float, hscale: float) -> Dictionary:
	await _build(off, hscale, 0.0)
	await _open_zoom()
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var out: Dictionary = _first_rects(cam)
	await _free_main()
	return out


func _first_rects(cam: Camera3D) -> Dictionary:
	var fw: Node = main.get_node("FarmWorld")
	var hive: Node = fw.get_node("Hive")
	var cen: Node = fw.get_node("Centrifuge")
	var fnodes: Array = [main.find_child("Honeycomb", true, false)]
	var bars: Node = hive.find_child("FrameBars", true, false)
	if bars != null:
		fnodes.append(bars)
	return {"hr": _rect([hive], cam), "hs": _silhouette(hive, cam), "cb": _rect([cen], cam, cen.find_child("Lid", true, false)),
			"cf": _rect([cen], cam), "fr": _rect(fnodes, cam)}


func _need(rc: Rect2) -> float:
	return maxf(rc.size.x / ASPECT, rc.size.y) * (1.0 + 2.0 * FIT_MARGIN)


func _plan(o: Dictionary) -> Dictionary:
	var hscale: float = float(o["scale"])
	var off: float = float(o["off"])
	var size: float = float(o["zoom"])
	var mode: String = o["mode"]
	if mode == "scale":
		var lo: float = 0.5
		var hi: float = hscale
		for i in 8:
			var mid: float = (lo + hi) * 0.5
			var pr: Dictionary = await _probe(off, mid)
			if _need((pr["hr"] as Rect2).merge(pr["cf"] as Rect2)) <= size:
				lo = mid
			else:
				hi = mid
		hscale = floorf(lo * 100.0) / 100.0
	var p: Dictionary = await _probe(off, hscale)
	var rc: Rect2 = (p["hr"] as Rect2).merge(p["cf"] as Rect2)
	var ctr: Vector2 = rc.position + rc.size * 0.5
	if mode == "fit":
		size = _need(rc)
	elif mode == "crop":
		var cf: Rect2 = p["cf"]
		var fr: Rect2 = p["fr"]
		var w: float = size * ASPECT
		var both: Rect2 = cf.merge(fr)
		print("  D: centrifuge + frames need zoom ", snappedf(maxf(both.size.x / ASPECT, both.size.y), 0.001), " (have ", size, ")")
		# the centrifuge stays whole; among those views the one showing most of the frames (then most of the hive)
		var x_lo: float = cf.end.x - w
		var x_hi: float = cf.position.x
		var y_lo: float = cf.end.y - size
		var y_hi: float = cf.position.y
		if x_lo > x_hi or y_lo > y_hi:
			print("  D: centrifuge alone does not fit")
			x_lo = (x_lo + x_hi) * 0.5
			x_hi = x_lo
			y_lo = (y_lo + y_hi) * 0.5
			y_hi = y_lo
		var best: float = -1.0
		for xi in 41:
			for yi in 41:
				var x0: float = lerpf(x_lo, x_hi, float(xi) / 40.0)
				var y0: float = lerpf(y_lo, y_hi, float(yi) / 40.0)
				var v := Rect2(x0, y0, w, size)
				var fa: float = v.intersection(fr).get_area() / maxf(fr.get_area(), 1.0e-9)
				var score: float = fa + 0.01 * _visible_fraction(p["hs"] as Array, v)
				if score > best + 1.0e-7:
					best = score
					ctr = Vector2(x0 + w * 0.5, y0 + size * 0.5)
	return {"scale": hscale, "size": size, "ctr": ctr}


func _first_zoom(o: Dictionary, plan: Dictionary) -> void:
	var file: String = "%s-1-first-zoom.png" % o["name"]
	await _build(float(o["off"]), float(plan["scale"]), float(plan["size"]))
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var zf: Node3D = main.find_child("ZoomFraming", true, false) as Node3D
	var ctr: Vector2 = plan["ctr"]
	zf.global_position = cam.global_transform.basis.x * ctr.x + cam.global_transform.basis.y * ctr.y
	await _open_zoom()
	await _shot(file.get_basename())
	var r: Dictionary = _first_rects(cam)
	var v: Rect2 = _view(cam)
	var hive_whole: bool = _whole(r["hr"], v)
	var cen_whole: bool = _whole(r["cf"], v)
	var body_whole: bool = _whole(r["cb"], v)
	var fr_vis: float = v.intersection(r["fr"] as Rect2).get_area() / maxf((r["fr"] as Rect2).get_area(), 1.0e-9) * 100.0
	var frames_whole: bool = _whole(r["fr"], v)
	var crop: float = (1.0 - _visible_fraction(r["hs"] as Array, v)) * 100.0
	var mp: float = _min_cell_px(cam)
	var min_px: float = float(_cfg().get("min_cell_px"))
	var ok: bool = mp >= min_px and hive_whole and cen_whole
	var sm: String = "hive_scale %.2f, hive offset %.2f, zoom_size %.3f (cam %.3f); smallest cell %.1f px (min %.0f); hive whole %s (%.1f%% cropped); frames whole %s (%.0f%% of the frames visible); centrifuge whole %s (body without lid %s)" % [
			float(plan["scale"]), float(o["off"]), float(plan["size"]), cam.size, mp, min_px, "y" if hive_whole else "n", crop,
			"y" if frames_whole else "n", fr_vis, "y" if cen_whole else "n", "y" if body_whole else "n"]
	print("  ", file, " ", sm)
	checks[file] = {"pass": ok, "summary": sm}
	await _free_main()


func _second_stop(o: Dictionary, plan: Dictionary) -> void:
	var file: String = "%s-2-second-stop.png" % o["name"]
	await _build(float(o["off"]), float(plan["scale"]), float(plan["size"]))
	var fw: Node = main.get_node("FarmWorld")
	var cen: Centrifuge = fw.get_node("Centrifuge") as Centrifuge
	var n: int = cen.capacity_cells()
	cen.add_cells(n, 1.0, 0.0)
	cen.land_cells(n)
	await _wait(2.0)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var pose: Dictionary = main.call("second_stop_pose")
	var pan0: float = float(_cfg().get("pan_zoom_size"))
	while not bool(pose["fits"]) and float(_cfg().get("pan_zoom_size")) < 14.0:
		_cfg().set("pan_zoom_size", float(_cfg().get("pan_zoom_size")) + 0.01)
		pose = main.call("second_stop_pose")
	cam.global_position = pose["position"]
	cam.size = float(pose["size"])
	main.call("_enter_second_stop_hud")
	await _frames(5)
	await _shot(file.get_basename())
	var v: Rect2 = _view_of(float(pose["plane_x"]), float(pose["plane_y"]), float(pose["size"]))
	var hs: Array = _silhouette(fw.get_node("Hive"), cam)
	var vis: float = _visible_fraction(hs, v)
	var tot: float = 0.0
	var ur: float = 0.0
	var sx: float = 0.0
	var sy: float = 0.0
	for s in hs:
		var q: Vector2 = s[0]
		if v.has_point(q):
			tot += 1.0
			sx += q.x
			sy += q.y
			if q.x > v.get_center().x and q.y > v.get_center().y:
				ur += 1.0
	var urf: float = ur / maxf(tot, 1.0)
	var quad: String = "none visible"
	if tot > 0.0:
		quad = ("upper" if sy / tot > v.get_center().y else "lower") + "-" + ("right" if sx / tot > v.get_center().x else "left")
	var cw: bool = _whole(_rect([cen], cam), v)
	var kw: bool = _whole(_rect([fw.get_node("JarCrate")], cam), v)
	var tw: bool = _whole(_rect([fw.get_node("Truck")], cam), v)
	var ok: bool = bool(pose["fits"]) and cw and kw and tw and vis >= 0.15 and vis <= 0.35 and urf >= 0.95
	var sm: String = "hive_scale %.2f, hive offset %.2f, pan_zoom_size %.3f (config %.3f raised to the smallest that fits: %s); hive share %.1f%%, centroid quadrant %s (%.0f%% of the visible part in upper-right); centrifuge whole %s, crate whole %s, truck whole %s" % [
			float(plan["scale"]), float(o["off"]), float(pose["size"]), pan0, "y" if bool(pose["fits"]) else "n (none)", vis * 100.0, quad, urf * 100.0,
			"y" if cw else "n", "y" if kw else "n", "y" if tw else "n"]
	print("  ", file, " ", sm)
	checks[file] = {"pass": ok, "summary": sm}
	await _free_main()


func _run() -> void:
	grid = (JSON.parse_string(FileAccess.get_file_as_string("res://data/farm_layout_c.json")) as Dictionary)["grid"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	fi = FarmInput.new(self)
	for o in OPTS:
		var plan: Dictionary = await _plan(o)
		print(o["name"], " plan: scale ", plan["scale"], " size ", plan["size"], " ctr ", plan["ctr"])
		await _first_zoom(o, plan)
		await _second_stop(o, plan)
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "checks.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(checks, "\t"))
	f.close()
	print("COMPLETED")
	quit(0)
