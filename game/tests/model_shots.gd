# Quinn: model variant shots (M2 spec item 11), WINDOWED at 720 x 1280.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/model_shots.gd -- --prop=<name> --out=<ABSOLUTE dir> [--size=<ortho>]
# All res://scenes/variants/<prop>/<prop>-*.tscn (sorted) are loaded ONCE into one test scene: side by side in a row on one shared ground
# grid (cell 2.0, faint lines on the farm's meadow colour, one empty cell between variants, each footprint aligned to the cells), with the
# farm's Sun and Environment and the farm camera's angle and projection. Then, per variant, the others are hidden and the camera zooms in
# close: centred on that variant and fitted to its bounds with a small margin (designer, 2026-11-05: same grid to save time, close shots).
# --size= > 0 sets a fixed ortho size instead of the fit. Saves <prop>-a.png etc. (the file name's suffix). Exit 0 only after "COMPLETED";
# nothing found or a failed save exits 1.
# --scenes=res://a.tscn,res://b.tscn instead of --prop: the same staging for any scenes, saved as <stem>.png (pick match,
# _tools/pick_match.py: the live prop beside the designer's picked variant, one load, one camera rule).
# --hide=Name,Name hides those nodes in the first --scenes entry only (a closed lid that would hide what's inside).
extends SceneTree

var prop: String = ""
var scenes_arg: String = ""
var hide_arg: String = ""
var out_dir: String = ""
var size_arg: float = 0.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prop="):
			prop = a.substr(7)
		elif a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--size="):
			size_arg = float(a.substr(7))
		elif a.begins_with("--scenes="):
			scenes_arg = a.substr(9)
		elif a.begins_with("--hide="):
			hide_arg = a.substr(7)
	_run()


func _fail(msg: String) -> void:
	print("FAILED: ", msg)
	quit(1)


func _bounds(node: Node, xf: Transform3D) -> AABB:
	# the merged AABB of every visual under node, in the space xf maps node into (works before the node is in the tree)
	var box := AABB()
	var first := true
	if node is VisualInstance3D:
		box = xf * (node as VisualInstance3D).get_aabb()
		first = false
	for ch in node.get_children():
		if ch is Node3D and (ch as Node3D).visible:   # hidden parts (a --hide lid, a script's off-screen helper) don't widen the fit
			var b: AABB = _bounds(ch, xf * (ch as Node3D).transform)
			if b.size != Vector3.ZERO or b.position != Vector3.ZERO:
				box = b if first else box.merge(b)
				first = false
	return box


func _lines(parent: Node3D, hx: float, hz: float) -> void:
	# grid lines on the odd coordinates (cell centres on the even ones, as on the 5 x 5 farm grid), covering x -hx..hx, z -hz..hz
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var t: float = -hx
	while t <= hx + 0.001:
		im.surface_add_vertex(Vector3(t, 0.01, -hz))
		im.surface_add_vertex(Vector3(t, 0.01, hz))
		t += 2.0
	t = -hz
	while t <= hz + 0.001:
		im.surface_add_vertex(Vector3(-hx, 0.01, t))
		im.surface_add_vertex(Vector3(hx, 0.01, t))
		t += 2.0
	im.surface_end()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.3, 0.45, 0.25, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = m
	parent.add_child(mi)


func _run() -> void:
	if (prop == "" and scenes_arg == "") or out_dir == "":
		_fail("usage: -- --prop=<name> | --scenes=<res://a.tscn,...> --out=<ABSOLUTE dir> [--size=<ortho>]")
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	var dir := "res://scenes/variants/%s/" % prop
	var files: Array = []   # full res:// paths
	if scenes_arg != "":
		for s in scenes_arg.split(",", false):
			files.append(s.strip_edges())
	else:
		for f in DirAccess.get_files_at(dir):
			var fn: String = f.trim_suffix(".remap")
			if fn.begins_with(prop + "-") and fn.ends_with(".tscn") and not files.has(dir + fn):
				files.append(dir + fn)
		files.sort()
	if files.is_empty():
		_fail("no %s-*.tscn in %s" % [prop, dir])
		return
	# the farm's light, environment, camera angle and zoom size (read from the scene, never edited)
	var farm: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var env: Environment = (farm.get_node("WorldEnvironment") as WorldEnvironment).environment
	var farm_sun := farm.get_node("Sun") as DirectionalLight3D
	var farm_cam := farm.get_node("Camera3D") as Camera3D
	var zoom_size: float = float(load("res://scripts/game_config.gd").new().get("zoom_size"))
	var framing: Node = farm.find_child("ZoomFraming", true, false)
	if zoom_size <= 0.0 and framing != null and framing.has_meta("zoom_size"):
		zoom_size = float(framing.get_meta("zoom_size"))
	if size_arg > 0.0:
		zoom_size = size_arg
	var meadow: Material = ((farm.get_node("FarmWorld/Ground") as MeshInstance3D).mesh as PlaneMesh).material
	var cam_basis: Basis = farm_cam.transform.basis
	var cam_proj: int = farm_cam.projection
	var sun_t: Transform3D = farm_sun.transform
	var sun_color: Color = farm_sun.light_color
	farm.free()
	print("camera: ortho size ", zoom_size, " basis ", cam_basis)
	# one scene, one shared grid: every variant in a row along x, footprints aligned to the cells, one empty cell between them
	var scene := Node3D.new()
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.transform = sun_t
	sun.light_color = sun_color
	scene.add_child(sun)
	var variants: Array = []   # [node, local AABB, cells wide]
	var row: float = 0.0
	var depth: int = 1
	for fn in files:
		var v := (load(fn) as PackedScene).instantiate() as Node3D
		var box: AABB = _bounds(v, Transform3D.IDENTITY)
		var w: int = maxi(1, int(ceil(maxf(box.size.x, 2.0 * maxf(absf(box.position.x), absf(box.end.x))) / 2.0 - 0.001)))
		depth = maxi(depth, int(ceil(maxf(absf(box.position.z), absf(box.end.z)) / 2.0 - 0.001)) * 2 + 1)
		variants.append([v, box, w])
		row += 2.0 * w
	row += 2.0 * (variants.size() - 1)
	var x: float = -1.0 - 2.0 * floorf(row / 4.0)   # left edge on a grid line (odd coordinate), row roughly centred
	for e in variants:
		e[0].position = Vector3(x + float(e[2]), 0, 0)   # footprint centre: a cell centre (odd width) or a grid line (even width)
		x += 2.0 * float(e[2]) + 2.0
		scene.add_child(e[0])
	var hx: float = maxf(absf(-1.0 - 2.0 * floorf(row / 4.0)), absf(x - 2.0)) + 6.0
	var hz: float = float(depth) + 6.0
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0 * hx, 2.0 * hz)
	pm.material = meadow
	ground.mesh = pm
	scene.add_child(ground)
	_lines(scene, hx, hz)
	var cam := Camera3D.new()
	cam.projection = cam_proj
	cam.current = true
	scene.add_child(cam)
	root.add_child(scene)
	for f in 3:   # a live prop's script may rescale it on _ready (hive.gd: hive_scale): fit after it settles
		await process_frame
	if scenes_arg != "" and hide_arg != "":   # --hide: nodes of the FIRST scene only (the live prop's lid, to show inside)
		for n in hide_arg.split(",", false):
			var h: Node = variants[0][0].find_child(n.strip_edges(), true, false)
			if h is Node3D:
				(h as Node3D).visible = false
				print("hidden ", n)
	var aspect: float = 1280.0 / 720.0   # ortho size is the visible height; the portrait width is size / aspect
	var written: int = 0
	for i in files.size():
		for j in variants.size():
			variants[j][0].visible = (j == i)
		var target: Node3D = variants[i][0]
		var wbox: AABB = _bounds(target, target.transform)
		var c: Vector3 = wbox.get_center()
		# the box's corners in camera space, to centre and fit it on screen
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for k in 8:
			var p: Vector3 = cam_basis.inverse() * (wbox.get_endpoint(k) - c)
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
		var mid: Vector3 = cam_basis * Vector3((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, 0.0)
		cam.size = size_arg if size_arg > 0.0 else maxf(0.5, 1.15 * maxf(hi.y - lo.y, (hi.x - lo.x) * aspect))
		cam.transform = Transform3D(cam_basis, c + mid + cam_basis * Vector3(0, 0, 20.0))   # 20 units back along the view direction
		for f in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path: String = out_dir.path_join((files[i] as String).get_file().trim_suffix(".tscn") + ".png")   # <prop>-a.png as before
		var err: int = img.save_png(path)
		print("shot ", path, " ", img.get_size(), " ortho ", cam.size, " err=", err)
		if err == OK and img.get_size() == Vector2i(720, 1280):
			written += 1
	root.remove_child(scene)
	scene.free()
	await process_frame
	if written != files.size():
		_fail("%d of %d shots written" % [written, files.size()])
		return
	print("COMPLETED")
	quit(0)
