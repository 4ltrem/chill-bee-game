# Bob: round 5 camera mock-up (option C, rack c-1: whole hive scaled 1.4x, 7 x 5 cells, layout C at cell 2.0). Copy of ab_round4_shots.gd.
# Mock-up only: everything is placed at runtime, main.tscn is not touched.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/shots_0_1_3.gd [-- truck=0.8,1.2 pan_margin=0.04]
# Shots to game/reports/0.1.3-shots/: z1-tight|mid|loose (hive + centrifuge, margins 3/6/10%), pan-quarter|third|half (second stop:
# centrifuge, crate, truck, hive partly in the upper-right corner) and round5.json.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const OUT := "res://reports/0.1.3-shots/"
const CELL: float = 2.0
const ASPECT: float = 720.0 / 1280.0
const HIVE_SCALE: float = 1.4
const LID_SPOT := Vector3(0.0, 0.075, 3.125)   # centrifuge-local: world (0, 0.05, 2.0) = the free cell 7 (col 2, row 3), clear of the crate
const SHOP_FRACTION: float = 0.17              # the shop panel covers the bottom of the screen at the second stop

var fi: RefCounted
var main: Node
var risen: int = -1
var grid: Array = []
var results: Array = []
var truck_off := Vector3(0.8, 0.0, 1.2)        # mock-up nudge of the truck down-screen so it clears the crate's front
var pan_margin: float = 0.04
var z1_margins: Array = [0.03, 0.06, 0.10]
var _farm_size: float = 20.0
var hive_off := Vector3.ZERO                   # mock-up shift of the hive up-right on screen (world -z), pan shots only


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"truck":
				var p: PackedStringArray = kv[1].split(",")
				truck_off = Vector3(float(p[0]), 0.0, float(p[1]))
			"pan_margin":
				pan_margin = float(kv[1])
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


func _build() -> void:
	FarmInput.reset_dev_config()
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var fw: Node3D = main.get_node("FarmWorld")
	var hive3: Node3D = fw.get_node("Hive")
	hive3.position = _centre(_cells_of(1), CELL) + hive_off
	hive3.scale = Vector3.ONE * HIVE_SCALE
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
	(main.get_node("Camera3D") as Camera3D).size = _farm_size
	root.add_child(main)
	await _frames(10)
	var hive: Node = main.find_child("Hive", true, false)
	risen = -1
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	hive.call("fill_now")
	var cfg: Object = _cfg()
	cfg.set("zoom_size", 0.0)
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


## One probe: the farm camera size for the whole diamond, and the z1 rect (hive + centrifuge incl. lid, frame raised).
func _probe() -> Dictionary:
	_farm_size = 20.0
	await _build()
	await _open_zoom()
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var fw: Node = main.get_node("FarmWorld")
	var hr: Rect2 = _rect([fw.get_node("Hive")], cam)
	var cr: Rect2 = _rect([fw.get_node("Centrifuge")], cam, fw.get_node("Centrifuge").find_child("Lid", true, false))
	var everything: Rect2 = _rect([fw.get_node("Hive"), fw.get_node("Centrifuge"), fw.get_node("JarCrate"), fw.get_node("Truck"), fw.get_node("Flowers"), fw.get_node("Pile")], cam)
	var right: Vector3 = cam.global_transform.basis.x
	var du: float = 0.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			du = maxf(du, absf(Vector3(sx * 2.5 * CELL, 0.0, sz * 2.5 * CELL).dot(right)))
	var half_w: float = maxf(du, maxf(absf(everything.position.x), absf(everything.end.x)))
	var out := {"farm_size": half_w * 2.0 / ASPECT * 1.03, "z1": hr.merge(cr)}
	await _free_main()
	return out


func _z1_shot(file: String, label: String, margin: float, rc: Rect2) -> void:
	await _build()
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var size: float = maxf(rc.size.x / ASPECT, rc.size.y) * (1.0 + 2.0 * margin)
	var zf: Node3D = main.find_child("ZoomFraming", true, false) as Node3D
	zf.global_position = cam.global_transform.basis.x * (rc.position.x + rc.size.x * 0.5) + cam.global_transform.basis.y * (rc.position.y + rc.size.y * 0.5)
	zf.set_meta("zoom_size", size)
	await _open_zoom()
	await _shot(file.get_basename())
	var mp: float = _min_cell_px(cam)
	print("  ", file, " zoom_size=", snappedf(cam.size, 0.001), " min_cell_px=", snappedf(mp, 0.1))
	results.append({"file": file, "label": label,
		"change": "hive + centrifuge (lid on its own cell) framed with a %d%% margin on each side; hive 1.4x, 7 x 5 cells; the crate and truck are out of frame" % int(round(margin * 100.0)),
		"zoom_size": snappedf(cam.size, 0.001), "min_cell_px": snappedf(mp, 0.1)})
	await _free_main()


## Searches the second-stop framing: the camera view that holds centrifuge + crate + truck (margin, above the shop panel) and shows
## `frac` of the hive (its drawn faces) in the upper-right corner, with the hive shifted up-right by the smallest dh that makes it possible.
func _pan_plan(frac: float) -> Dictionary:
	hive_off = Vector3.ZERO
	await _build()
	var fw: Node = main.get_node("FarmWorld")
	var cen: Centrifuge = fw.get_node("Centrifuge") as Centrifuge
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	var rc: Rect2 = _rect([cen, fw.get_node("JarCrate"), fw.get_node("Truck")], cam)
	var hr0: Rect2 = _rect([fw.get_node("Hive")], cam)
	var hs: Array = _silhouette(fw.get_node("Hive"), cam)
	await _free_main()
	var infl: float = maxf(rc.size.x / ASPECT, rc.size.y) * pan_margin
	var rm := Rect2(rc.position - Vector2(infl * ASPECT, infl), rc.size + Vector2(2.0 * infl * ASPECT, 2.0 * infl))
	var s_min: float = maxf(rm.size.x / ASPECT, rm.size.y / (1.0 - SHOP_FRACTION))
	var best: Dictionary = {}
	var best_err: float = 1.0e9
	for di in 15:
		var dh: float = 0.25 * float(di)
		var shift := Vector2(Vector3(0.0, 0.0, -dh).dot(right), Vector3(0.0, 0.0, -dh).dot(up))
		var hr := Rect2(hr0.position + shift, hr0.size)
		var hsh: Array = []
		for sm in hs:
			hsh.append([(sm[0] as Vector2) + shift, sm[1]])
		for si in 11:
			var s: float = s_min * (1.0 + 0.04 * float(si))
			var w: float = s * ASPECT
			var x_lo: float = rm.end.x - w
			var x_hi: float = rm.position.x
			var y_lo: float = rm.end.y - s
			var y_hi: float = rm.position.y - SHOP_FRACTION * s
			if x_lo > x_hi or y_lo > y_hi:
				continue
			for xi in 11:
				for yi in 11:
					var x0: float = lerpf(x_lo, x_hi, float(xi) / 10.0)
					var y0: float = lerpf(y_lo, y_hi, float(yi) / 10.0)
					var v := Rect2(x0, y0, w, s)
					if hr.end.x < v.end.x or hr.end.y < v.end.y:
						continue   # the hive must run off the top and the right edge: it sits in the corner
					var vis: float = _visible_fraction(hsh, v)
					var err: float = absf(vis - frac) + 0.004 * float(si) + 0.01 * dh
					if err < best_err:
						best_err = err
						best = {"size": s, "x0": x0, "y0": y0, "dh": dh, "vis": vis}
	return best


func _pan_shot(file: String, label: String, frac: float) -> void:
	var plan: Dictionary = await _pan_plan(frac)
	if plan.is_empty():
		print("  NO SOLUTION for ", file)
		results.append({"file": file, "label": label, "change": "no framing found", "zoom_size": null, "min_cell_px": null})
		return
	hive_off = Vector3(0.0, 0.0, -float(plan["dh"]))
	await _build()
	var fw: Node = main.get_node("FarmWorld")
	var cen: Centrifuge = fw.get_node("Centrifuge") as Centrifuge
	var n: int = cen.capacity_cells()
	cen.add_cells(n, 1.0, 0.0)
	cen.land_cells(n)
	await _wait(2.0)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	var s2: float = float(plan["size"])
	var cx: float = float(plan["x0"]) + s2 * ASPECT * 0.5
	var cy: float = float(plan["y0"]) + s2 * 0.5
	cam.global_position += right * (cx - cam.global_position.dot(right)) + up * (cy - cam.global_position.dot(up))
	cam.size = s2
	await _frames(3)
	var hs: Array = _samples(fw.get_node("Hive"), cam)
	var v := Rect2(float(plan["x0"]), float(plan["y0"]), s2 * ASPECT, s2)
	var vis: float = _visible_fraction(_silhouette(fw.get_node("Hive"), cam), v)
	var lo := Vector2(1.0e9, 1.0e9)
	var hi := Vector2(-1.0e9, -1.0e9)
	for sm in hs:
		var px: Vector2 = cam.unproject_position(sm[2] as Vector3)
		if px.x >= 0.0 and px.x <= 720.0 and px.y >= 0.0 and px.y <= 1280.0:
			lo = Vector2(minf(lo.x, px.x), minf(lo.y, px.y))
			hi = Vector2(maxf(hi.x, px.x), maxf(hi.y, px.y))
	var hive_px := Rect2(lo, hi - lo)
	_arrange_hud(cam, hive_px)
	await _frames(4)
	await _shot(file.get_basename())
	var dh: float = float(plan["dh"])
	print("  ", file, " zoom_size=", snappedf(s2, 0.001), " hive visible=", snappedf(vis, 0.01), " hive shifted ", dh, " hive px=", hive_px)
	var note: String = "hive kept on its layout cell"
	if dh > 0.0:
		note = "hive shifted %.2f world units up-right on screen (-z) from its layout cell, because at the layout position the full centrifuge + crate + truck already leave more of it showing" % dh
	results.append({"file": file, "label": label,
		"change": "camera panned to the full centrifuge + crate + truck (margin %d%%, above the shop panel), hive %d%% showing in the upper-right corner (share of its on-screen silhouette); %s; centrifuge lid on its own cell 7; truck nudged (%.1f, %.1f) so it clears the crate; HUD kept off the hive" % [int(round(pan_margin * 100.0)), int(round(vis * 100.0)), note, truck_off.x, truck_off.z],
		"zoom_size": snappedf(s2, 0.001), "min_cell_px": null, "hive_visible": snappedf(vis, 0.01), "hive_shift_world": dh})
	hive_off = Vector3.ZERO
	await _free_main()


func _arrange_hud(cam: Camera3D, hive_px: Rect2) -> void:
	var fork: FloatingIcon = main.find_child("ForkIcon", true, false) as FloatingIcon
	var spin: FloatingIcon = main.find_child("CentrifugeIcon", true, false) as FloatingIcon
	var bar: Control = main.find_child("FillBar", true, false) as Control
	var cen_node: Node3D = main.find_child("Centrifuge", true, false) as Node3D
	var cl: float = 1.0e9   # the centrifuge body's left edge on screen
	for mi in cen_node.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree() or m.name == "Lid":
			continue
		var a: AABB = m.mesh.get_aabb()
		for k in 8:
			cl = minf(cl, cam.unproject_position(m.global_transform * a.get_endpoint(k)).x)
	# the Hive bar stops short of the hive and of the centrifuge
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.custom_minimum_size.x = maxf(minf(hive_px.position.x, cl) - 16.0 - 24.0, 120.0)
	var fa: Vector2 = cam.unproject_position((main.find_child("ForkAnchor", true, false) as Node3D).global_position)
	var sa: Vector2 = cam.unproject_position((main.find_child("CentrifugeAnchor", true, false) as Node3D).global_position)
	# Harvest: just under the hive's visible part. Spin: left of the centrifuge, below the HUD block
	var fork_c := Vector2(clampf(hive_px.get_center().x, 120.0, 650.0), hive_px.end.y + 24.0 + 90.0)
	fork.screen_offset = fork_c - fa
	var spin_c := Vector2(maxf(cl - 16.0 - 80.0, 100.0), 340.0)
	spin.screen_offset = spin_c - sa
	print("  hud: bar w ", bar.custom_minimum_size.x, " fork ", fork_c, " spin ", spin_c, " cen left ", cl)


func _run() -> void:
	grid = (JSON.parse_string(FileAccess.get_file_as_string("res://data/farm_layout_c.json")) as Dictionary)["grid"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	fi = FarmInput.new(self)
	var base: Dictionary = await _probe()
	_farm_size = float(base["farm_size"])
	var rc: Rect2 = base["z1"]
	var names: Array = ["tight", "mid", "loose"]
	for i in 3:
		await _z1_shot("z1-%s.png" % names[i], "First zoom, %s: hive + centrifuge" % names[i], float(z1_margins[i]), rc)
	var fr: Array = [["quarter", 0.25], ["third", 1.0 / 3.0], ["half", 0.5]]
	for p in fr:
		await _pan_shot("pan-%s.png" % p[0], "Second stop, hive about %s showing" % p[0], float(p[1]))
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "round5.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "	"))
	f.close()
	print("COMPLETED")
	quit(0)
