# Bob: Layout C grid mock-up shots (3 cell sizes x 3 zooms). Mock-up only: everything is placed at runtime, main.tscn is not touched.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/ab_grid_shots.gd
# Objects go to their cell centres (x = (col-2)*cell, z = (row-2)*cell) from res://data/farm_layout_c.json. The probe pass raises the rack,
# measures the projected bounds, then each zoom gets a fresh scene whose ZoomFraming (position + zoom_size) is set before the zoom.
# Output: game/reports/grid-shots/c{cell}-z{1|2|3}.png and grid-shots.json.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const OUT := "res://reports/grid-shots/"
const CELLS: Array = [1.5, 2.0, 2.4]
const MARGIN: float = 0.07
const ASPECT: float = 720.0 / 1280.0

var fi: RefCounted
var main: Node
var risen: int = -1
var grid: Array = []
var results: Array = []


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


## Builds main, places everything on its cells, adds it to the tree (so every _ready caches the new positions).
func _build(cell: float, farm_size: float) -> void:
	FarmInput.reset_dev_config()
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var fw: Node3D = main.get_node("FarmWorld")
	(fw.get_node("Hive") as Node3D).position = _centre(_cells_of(1), cell)
	var cen: Node3D = fw.get_node("Centrifuge")
	cen.position = _centre(_cells_of(3), cell)
	cen.scale = Vector3.ONE * 0.64
	(fw.get_node("Pile") as Node3D).position = _centre(_cells_of(6), cell)
	(fw.get_node("JarCrate") as Node3D).position = _centre(_cells_of(4), cell)
	var truck: Node3D = fw.get_node("Truck")
	truck.position = _centre(_cells_of(5), cell)
	truck.scale = Vector3.ONE * 0.93
	var fl: Array = _cells_of(2)
	for i in 3:
		var p: Vector3 = _centre([fl[i]], cell)
		p.y = 0.15
		(fw.get_node("Flowers/FlowerPatch%d" % (i + 1)) as Node3D).position = p
	var g: MeshInstance3D = fw.get_node("Ground")
	var pm: PlaneMesh = (g.mesh as PlaneMesh).duplicate()
	pm.size = Vector2(5.0 * cell, 5.0 * cell)
	g.mesh = pm
	if farm_size > 0.0:
		(main.get_node("Camera3D") as Camera3D).size = farm_size
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
func _rect(nodes: Array, cam: Camera3D) -> Rect2:
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	var lo := Vector2(1.0e9, 1.0e9)
	var hi := Vector2(-1.0e9, -1.0e9)
	for n in nodes:
		for mi in (n as Node).find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi as MeshInstance3D
			if m.mesh == null or not m.is_visible_in_tree():
				continue
			var a: AABB = m.mesh.get_aabb()
			for k in 8:
				var p: Vector3 = m.global_transform * a.get_endpoint(k)
				var uv := Vector2(p.dot(right), p.dot(up))
				lo = Vector2(minf(lo.x, uv.x), minf(lo.y, uv.y))
				hi = Vector2(maxf(hi.x, uv.x), maxf(hi.y, uv.y))
	return Rect2(lo, hi - lo)


func _frame_for(rc: Rect2) -> Dictionary:
	var size: float = maxf(rc.size.x / ASPECT, rc.size.y) * (1.0 + MARGIN)
	return {"size": size, "uc": rc.position.x + rc.size.x * 0.5, "vc": rc.position.y + rc.size.y * 0.5}


## Rack = the risen frame's cells and its bars (the FrameBar node standing highest).
func _rack_nodes() -> Array:
	var hc: Node = main.find_child("Honeycomb", true, false)
	var best: Node3D = null
	for b in main.find_child("Hive", true, false).find_child("FrameBars", true, false).get_children():
		if b is Node3D and (best == null or (b as Node3D).global_position.y > best.global_position.y):
			best = b
	return [hc, best]


func _probe(cell: float) -> Dictionary:
	await _build(cell, 0.0)
	await _open_zoom()
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var fw: Node = main.get_node("FarmWorld")
	var hive: Node = fw.get_node("Hive")
	var cen: Node = fw.get_node("Centrifuge")
	var crate: Node = fw.get_node("JarCrate")
	var rack: Rect2 = _rect(_rack_nodes(), cam)
	var hr: Rect2 = _rect([hive], cam)
	var cr: Rect2 = _rect([cen], cam)
	var kr: Rect2 = _rect([crate], cam)
	var everything: Rect2 = _rect([hive, cen, crate, fw.get_node("Truck"), fw.get_node("Flowers"), fw.get_node("Pile")], cam)
	# the grid diamond: the ground's four corners, at y = 0
	var right: Vector3 = cam.global_transform.basis.x
	var ext: float = 2.5 * cell
	var du: float = 0.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			du = maxf(du, absf(Vector3(sx * ext, 0.0, sz * ext).dot(right)))
	var half_w: float = maxf(du, maxf(absf(everything.position.x), absf(everything.end.x)))
	var out := {
		"farm_size": half_w * 2.0 / ASPECT * 1.03,
		"z1": _frame_for(rack),
		"z2": _frame_for(hr.merge(cr)),
		"z3": _frame_for(hr.merge(cr).merge(kr)),
	}
	await _free_main()
	return out


func _min_cell_px(cam: Camera3D) -> float:
	var min_w: float = 1.0e9
	var n: int = 0
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
		n += 1
	print("  measured ", n, " rack cells")
	return min_w


func _run() -> void:
	grid = (JSON.parse_string(FileAccess.get_file_as_string("res://data/farm_layout_c.json")) as Dictionary)["grid"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	fi = FarmInput.new(self)
	for cell in CELLS:
		var pr: Dictionary = await _probe(cell)
		if OS.get_cmdline_user_args().has("farm"):   # diagnostics: the whole farm, not part of the 9 shots
			await _build(cell, float(pr["farm_size"]))
			await _frames(3)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("C:/Users/mtrem/AppData/Local/Temp/claude/ee30cc009e26b737/e0d1da16-c10b-4153-9084-bbcd654fdb0b/scratchpad/farm-%.1f.png" % cell)
			await _free_main()
		for z in [1, 2, 3]:
			var fr: Dictionary = pr["z%d" % z]
			await _build(cell, float(pr["farm_size"]))
			var cam: Camera3D = root.get_viewport().get_camera_3d()
			var zf: Node3D = main.find_child("ZoomFraming", true, false) as Node3D
			zf.global_position = cam.global_transform.basis.x * float(fr["uc"]) + cam.global_transform.basis.y * float(fr["vc"])
			zf.set_meta("zoom_size", float(fr["size"]))
			await _open_zoom()
			await _frames(3)
			await RenderingServer.frame_post_draw
			var name: String = "c%.1f-z%d" % [cell, z]
			var img: Image = root.get_texture().get_image()
			var err: int = img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
			var mp: float = _min_cell_px(cam)
			print("shot ", name, " ", img.get_size(), " err=", err, " zoom_size=", snappedf(cam.size, 0.001), " min_cell_px=", snappedf(mp, 0.1))
			results.append({"file": name + ".png", "cell_size": cell, "zoom": z, "zoom_size": snappedf(float(fr["size"]), 0.001),
				"farm_camera_size": snappedf(float(pr["farm_size"]), 0.001), "min_cell_px": snappedf(mp, 0.1)})
			await _free_main()
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "grid-shots.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "\t"))
	f.close()
	print("COMPLETED")
	quit(0)
