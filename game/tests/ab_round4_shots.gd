# Bob: round 4 shots (A vs C rack at cell 2.0, zoom Z2, plus the pan stop). Copy of ab_grid_shots.gd. Mock-up only: everything is placed at runtime, main.tscn is not touched.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/ab_grid_shots.gd
# Objects go to their cell centres (x = (col-2)*cell, z = (row-2)*cell) from res://data/farm_layout_c.json. The probe pass raises the rack,
# measures the projected bounds, then each zoom gets a fresh scene whose ZoomFraming (position + zoom_size) is set before the zoom.
# Output: game/reports/grid-shots/c{cell}-z{1|2|3}.png and grid-shots.json.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const OUT := "res://reports/round4-shots/"
const CELL: float = 2.0
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
func _build(cell: float, farm_size: float, opts: Dictionary = {}) -> void:
	FarmInput.reset_dev_config()
	root.get_node("Economy").call("reset")
	if opts.has("cols"):
		_cfg().set("grid_cols", int(opts["cols"]))
		_cfg().set("grid_rows", int(opts["rows"]))
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
	var hs: float = float(opts.get("hive_scale", 1.0))
	(fw.get_node("Hive") as Node3D).scale = Vector3.ONE * hs
	var pitch: float = float(opts.get("pitch", 1.0))
	if pitch != 1.0:
		var hc0: Honeycomb = main.find_child("Honeycomb", true, false) as Honeycomb
		hc0.cell_pitch = pitch
		hc0.cell_radius = 0.46 * pitch
	if opts.has("lid_spot"):
		(cen.find_child("CentrifugeLidSpot", true, false) as Node3D).position = opts["lid_spot"]
	var g: MeshInstance3D = fw.get_node("Ground")
	var pm: PlaneMesh = (g.mesh as PlaneMesh).duplicate()
	pm.size = Vector2(5.0 * cell, 5.0 * cell)
	g.mesh = pm
	if farm_size > 0.0:
		(main.get_node("Camera3D") as Camera3D).size = farm_size
	root.add_child(main)
	await _frames(10)
	if pitch != 1.0:
		for ch in main.find_child("Honeycomb", true, false).get_children():
			if ch.name.begins_with("Cell_"):
				(ch as Node3D).scale = Vector3.ONE * pitch
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


func _probe(cell: float, opts: Dictionary = {}) -> Dictionary:
	await _build(cell, 0.0, opts)
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


func _shot(name: String) -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	print("shot ", name, " ", img.get_size(), " err=", img.save_png(ProjectSettings.globalize_path(OUT + name + ".png")))
	return img


func _uncap_shot(file: String, option: String, label: String, change: String, opts: Dictionary, farm_size: float) -> void:
	var pr: Dictionary = await _probe(CELL, opts)
	var fr: Dictionary = pr["z2"]
	await _build(CELL, farm_size, opts)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var zf: Node3D = main.find_child("ZoomFraming", true, false) as Node3D
	zf.global_position = cam.global_transform.basis.x * float(fr["uc"]) + cam.global_transform.basis.y * float(fr["vc"])
	zf.set_meta("zoom_size", float(fr["size"]))
	await _open_zoom()
	await _shot(file.get_basename())
	var mp: float = _min_cell_px(cam)
	print("  ", file, " zoom_size=", snappedf(cam.size, 0.001), " min_cell_px=", snappedf(mp, 0.1))
	results.append({"file": file, "option": option, "label": label, "change": change,
		"zoom_size": snappedf(float(fr["size"]), 0.001), "min_cell_px": snappedf(mp, 0.1)})
	await _free_main()


func _pan_shot(farm_size: float) -> void:
	# lid spot beside the centrifuge, on empty cell (col 1, row 2): world (-2.0, 0, 0.5), centrifuge scale 0.64
	var spot := Vector3(-2.0 / 0.64, 0.075 / 0.64, 0.5 / 0.64) if false else Vector3(-3.1, 0.075, 0.8)
	await _build(CELL, farm_size, {"lid_spot": spot})
	var fw: Node = main.get_node("FarmWorld")
	var cen: Centrifuge = fw.get_node("Centrifuge") as Centrifuge
	var n: int = cen.capacity_cells()
	cen.add_cells(n, 1.0, 0.0)
	cen.land_cells(n)
	await _wait(2.0)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var rc: Rect2 = _rect([cen, fw.get_node("JarCrate"), fw.get_node("Truck")], cam)
	var fr: Dictionary = _frame_for(rc)
	var right: Vector3 = cam.global_transform.basis.x
	var up: Vector3 = cam.global_transform.basis.y
	cam.global_position += right * (float(fr["uc"]) - cam.global_position.dot(right)) + up * (float(fr["vc"]) - cam.global_position.dot(up))
	cam.size = float(fr["size"])
	await _shot("pan")
	print("  pan state=", cen.state, " zoom_size=", snappedf(cam.size, 0.001))
	results.append({"file": "pan.png", "option": "pan", "label": "second camera stop: centrifuge (full), crate, truck",
		"change": "camera framed on the three rects (margin 7%); centrifuge lid spot moved to local (-3.1, 0.075, 0.8) = world (-2.0, 0.05, 0.5), the empty cell west of the centrifuge",
		"zoom_size": snappedf(float(fr["size"]), 0.001), "min_cell_px": null})
	await _free_main()


func _run() -> void:
	grid = (JSON.parse_string(FileAccess.get_file_as_string("res://data/farm_layout_c.json")) as Dictionary)["grid"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	fi = FarmInput.new(self)
	var base: Dictionary = await _probe(CELL)
	var fs: float = float(base["farm_size"])
	await _uncap_shot("a-1-uncap.png", "A", "accept small cells", "none: today's 7 x 5 rack, hive 1.0x (frame 0.99 x 0.61 world)", {}, fs)
	await _pan_shot(fs)
	await _uncap_shot("c-1-uncap.png", "C", "bigger frames", "whole hive scaled 1.4x (body 1.82, lid 1.96 inside the 2.0 cell): frame 1.38 x 0.85 world, cells x1.4, 7 x 5 kept", {"hive_scale": 1.4}, fs)
	await _uncap_shot("c-2-uncap.png", "C", "fewer cells", "5 x 4 cells (20, was 35) on the same frame: cell pitch and size x1.25, hive 1.0x", {"cols": 5, "rows": 4, "pitch": 1.25}, fs)
	await _uncap_shot("c-3-uncap.png", "C", "both", "hive 1.4x and 5 x 4 cells at pitch 1.25: cells x1.75", {"hive_scale": 1.4, "cols": 5, "rows": 4, "pitch": 1.25}, fs)
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "round4.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "	"))
	f.close()
	print("COMPLETED")
	quit(0)
