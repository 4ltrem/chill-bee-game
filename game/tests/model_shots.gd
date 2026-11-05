# Quinn: model variant shots (M2 spec item 11), WINDOWED at 720 x 1280.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/model_shots.gd -- --prop=<name> --out=<ABSOLUTE dir> [--size=<ortho>]
# For each res://scenes/variants/<prop>/<prop>-*.tscn (sorted): a test scene with a 5 x 5 ground grid (cell 2.0, faint lines on the farm's
# meadow colour), the farm's Sun and Environment, and the camera of the farm's uncapping zoom (the farm camera's angle and projection, ortho size
# = config zoom_size, or the ZoomFraming metadata if that is 0; --size= overrides it for wider views), looking at the grid centre where the
# variant stands. Saves <prop>-a.png etc. (the file name's suffix). Exit 0 only after "COMPLETED"; nothing found or a failed save exits 1.
extends SceneTree

var prop: String = ""
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
	_run()


func _fail(msg: String) -> void:
	print("FAILED: ", msg)
	quit(1)


func _lines(parent: Node3D) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 6:
		var t: float = -5.0 + 2.0 * float(i)
		im.surface_add_vertex(Vector3(t, 0.01, -5.0))
		im.surface_add_vertex(Vector3(t, 0.01, 5.0))
		im.surface_add_vertex(Vector3(-5.0, 0.01, t))
		im.surface_add_vertex(Vector3(5.0, 0.01, t))
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
	if prop == "" or out_dir == "":
		_fail("usage: -- --prop=<name> --out=<ABSOLUTE dir> [--size=<ortho>]")
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	var dir := "res://scenes/variants/%s/" % prop
	var files: Array = []
	for f in DirAccess.get_files_at(dir):
		var fn: String = f.trim_suffix(".remap")
		if fn.begins_with(prop + "-") and fn.ends_with(".tscn") and not files.has(fn):
			files.append(fn)
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
	var written: int = 0
	for fn in files:
		var scene := Node3D.new()
		var we := WorldEnvironment.new()
		we.environment = env
		scene.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.transform = sun_t
		sun.light_color = sun_color
		scene.add_child(sun)
		var ground := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(10, 10)
		pm.material = meadow
		ground.mesh = pm
		scene.add_child(ground)
		_lines(scene)
		var cam := Camera3D.new()
		cam.projection = cam_proj
		cam.size = zoom_size
		cam.transform = Transform3D(cam_basis, cam_basis * Vector3(0, 0, 20.0))   # 20 units back along the view direction from the grid centre
		cam.current = true
		scene.add_child(cam)
		var variant: Node = (load(dir + fn) as PackedScene).instantiate()
		scene.add_child(variant)
		root.add_child(scene)
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var suffix: String = fn.trim_suffix(".tscn").trim_prefix(prop + "-")
		var path: String = out_dir.path_join("%s-%s.png" % [prop, suffix])
		var err: int = img.save_png(path)
		print("shot ", path, " ", img.get_size(), " err=", err)
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
