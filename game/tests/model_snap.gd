# Quinn: model snap, one or more single-scene shots, each in its own SubViewport (own World3D), no ground, no grid.
#   Godot --path game --rendering-method gl_compatibility -s res://tests/model_snap.gd -- --jobs=<ABSOLUTE path to json>
# The json is an array of jobs, each: scene (res://), out (absolute png), px (int), fit (node path or ""), hide ([paths]),
#   set ([[path, prop, value]]), call ([[path, method, [args]]]), bg ("transparent" or [r,g,b] 0-1). Paths are relative to the
#   scene root, "." = the root. Staging copied from model_shots.gd: the farm's Environment, Sun and camera angle, read from
#   res://scenes/main.tscn (never edited), camera-space fit with a 1.15 margin, camera 20 units back, aspect 1.0.
# Prints "shot <out> <w>x<h> coverage=<0.0000> err=<n>" per job; "COMPLETED" and exit 0 only when every job saved.
extends SceneTree

var jobs_path: String = ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--jobs="):
			jobs_path = a.substr(7)
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


func _node(scene_root: Node, path: String) -> Node:
	if path == "" or path == ".":
		return scene_root
	return scene_root.get_node_or_null(NodePath(path))


func _run() -> void:
	if jobs_path == "":
		_fail("usage: -- --jobs=<ABSOLUTE path to json>")
		return
	if not FileAccess.file_exists(jobs_path):
		_fail("no jobs file " + jobs_path)
		return
	var jobs = JSON.parse_string(FileAccess.get_file_as_string(jobs_path))
	if not (jobs is Array) or (jobs as Array).is_empty():
		_fail("jobs json must be a non-empty array")
		return
	# the farm's light, environment and camera angle (read from the scene, never edited)
	var farm: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var env: Environment = (farm.get_node("WorldEnvironment") as WorldEnvironment).environment
	var farm_sun := farm.get_node("Sun") as DirectionalLight3D
	var farm_cam := farm.get_node("Camera3D") as Camera3D
	var cam_basis: Basis = farm_cam.transform.basis
	var cam_proj: int = farm_cam.projection
	var sun_t: Transform3D = farm_sun.transform
	var sun_color: Color = farm_sun.light_color
	farm.free()
	var written: int = 0
	for job in jobs:
		if await _shoot(job, env, sun_t, sun_color, cam_basis, cam_proj):
			written += 1
		else:
			return   # _fail already printed and quit
	if written != (jobs as Array).size():
		_fail("%d of %d shots written" % [written, (jobs as Array).size()])
		return
	print("COMPLETED")
	quit(0)


func _shoot(job: Dictionary, env: Environment, sun_t: Transform3D, sun_color: Color, cam_basis: Basis, cam_proj: int) -> bool:
	var scene_path: String = str(job.get("scene", ""))
	var out: String = str(job.get("out", ""))
	var px: int = int(job.get("px", 0))
	var fit: String = str(job.get("fit", ""))
	var bg = job.get("bg", "transparent")
	var transparent: bool = (bg is String and bg == "transparent")
	var bgc := Color(0, 0, 0, 0)
	if not transparent:
		if not (bg is Array) or (bg as Array).size() < 3:
			_fail("bad bg for " + out)
			return false
		bgc = Color(float(bg[0]), float(bg[1]), float(bg[2]), 1.0)
	if px <= 0 or out == "":
		_fail("bad px or out in job for " + scene_path)
		return false
	if not ResourceLoader.exists(scene_path):
		_fail("no scene " + scene_path)
		return false
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())

	var vp := SubViewport.new()
	vp.size = Vector2i(px, px)
	vp.own_world_3d = true
	vp.transparent_bg = transparent
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var e: Environment = env.duplicate() as Environment
	if transparent:
		e.background_mode = Environment.BG_CLEAR_COLOR
	else:
		e.background_mode = Environment.BG_COLOR
		e.background_color = bgc
	var we := WorldEnvironment.new()
	we.environment = e
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.transform = sun_t
	sun.light_color = sun_color
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = cam_proj
	cam.current = true
	vp.add_child(cam)
	var inst := (load(scene_path) as PackedScene).instantiate()
	vp.add_child(inst)
	root.add_child(vp)
	await process_frame
	for f in 3:   # a live prop's script may rescale it on _ready: apply and fit after it settles
		await process_frame

	for h in job.get("hide", []):
		var hn: Node = _node(inst, str(h))
		if hn == null:
			_fail("no node " + str(h))
			return false
		if hn is Node3D:
			(hn as Node3D).visible = false
		elif hn is CanvasItem:
			(hn as CanvasItem).visible = false
	for s in job.get("set", []):
		var sn: Node = _node(inst, str(s[0]))
		if sn == null:
			_fail("no node " + str(s[0]))
			return false
		if not (str(s[1]) in sn):
			_fail("no property %s on %s" % [str(s[1]), str(s[0])])
			return false
		sn.set(str(s[1]), s[2])
	for c in job.get("call", []):
		var cn: Node = _node(inst, str(c[0]))
		if cn == null:
			_fail("no node " + str(c[0]))
			return false
		if not cn.has_method(str(c[1])):
			_fail("no method %s on %s" % [str(c[1]), str(c[0])])
			return false
		var cargs: Array = c[2] if c.size() > 2 and c[2] is Array else []
		cn.callv(str(c[1]), cargs)
	for f in 2:
		await process_frame

	var target: Node = _node(inst, fit)
	if target == null:
		_fail("no fit node " + fit)
		return false
	var wbox: AABB
	if target is Node3D:
		wbox = _bounds(target, (target as Node3D).global_transform)
	else:
		wbox = _bounds(target, Transform3D.IDENTITY)
	var ctr: Vector3 = wbox.get_center()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for k in 8:
		var p: Vector3 = cam_basis.inverse() * (wbox.get_endpoint(k) - ctr)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var mid: Vector3 = cam_basis * Vector3((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, 0.0)
	cam.size = maxf(0.5, 1.15 * maxf(hi.y - lo.y, hi.x - lo.x))   # aspect 1.0
	cam.transform = Transform3D(cam_basis, ctr + mid + cam_basis * Vector3(0, 0, 20.0))
	for f in 5:
		await process_frame
	await RenderingServer.frame_post_draw

	var img: Image = vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var hgt: int = img.get_height()
	var diff: int = 0
	for y in hgt:
		for x in w:
			var px_c: Color = img.get_pixel(x, y)
			if transparent:
				if px_c.a > 0.1:
					diff += 1
			else:
				var d: float = sqrt(pow(px_c.r - bgc.r, 2) + pow(px_c.g - bgc.g, 2) + pow(px_c.b - bgc.b, 2))
				if d > 0.02:
					diff += 1
	var coverage: float = float(diff) / float(maxi(1, w * hgt))
	var err: int = img.save_png(out)
	print("shot %s %dx%d coverage=%.4f err=%d" % [out, w, hgt, coverage, err])
	root.remove_child(vp)
	vp.free()
	await process_frame
	if err != OK:
		_fail("save failed for " + out)
		return false
	return true
