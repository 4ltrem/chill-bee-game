# Quinn: snapshot test of the comb pop (game/CONTEXT.md Process 7: whatever the designer marks "do not change" gets reference frames
# recorded once from the last approved build and compared on every build). Designer, 2026-11-04: "DO NOT change the comb animations".
#
#   record (once, from the revision 3 build, commit 7d04bc6, in a git worktree outside the project):
#     CB_MODE=record CB_TAG=r3 CB_OUT=<abs dir> Godot --path <worktree>/game --resolution 720x1280 --position 0,0 -s <abs path of this file>
#   check (every build):
#     Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/snapshot_pop.gd        (CB_MODE defaults to check)
#
# Self-contained (revision 3 has no tests/farm_input.gd). Both builds are driven the same way: hive full, the farm's fork icon (clicked
# where it is drawn in the check build; the revision 3 close-up opens through its signal), then ONE cell in the middle of the frame is scraped
# by a real mouse press pushed into the viewport in window pixels. Engine.time_scale is set to SCALE just before the press, so the 0.18 s
# pop lasts 0.18 / SCALE real seconds and a frame can be captured at each fixed pop time T (the sample times below).
#
# What is compared (the revision 3 close-up is flat and top-down, revision 4 is upright at the isometric angle, so raw pixels cannot match):
#   1. PROJECTED SIZE: the on-screen width of the scraped cell's hexagonal face (flat side to flat side, its two +-X extremes projected
#      through the build's own camera), at each T, divided by the width at the settled end of the pop (T >= 0.30 s). That is the pop's scale
#      curve as the camera renders it. Tolerance: 0.02 (the curve is geometry, not pixels; a different tween changes it by 0.05 to 0.3).
#   2. (0.1.2: REPORT-ONLY, no pass/fail; spec 0.1.2 change 4 drops the pixel-area half) RENDERED PIXELS: the visible bright-yellow (uncapped colour) area of that cell in the captured frame (flood fill from the cell's centre
#      pixel, mask R > 230, G > 230, B < 130), as sqrt(area at T / area at T = 0.165 s), a linear size, for T up to 0.165 s (from 0.18 s the cell
#      has left its slot in the 0.1 build, a flying copy replaces it). The cell is partly hidden by its raised Capped
#      neighbours while it is big, differently in the two views, so this is a sanity check with a wide tolerance, 0.12, not a match.
#   3. The settled ratio is exactly 1 and the first sample (T = 0) is 1.3 (the pop starts at scale 1.3), in both.
# Outputs: crops of the cell (PNG, 96 x 96 px around it) per sample, and a CSV of the curves, in CB_OUT (default res://reports/_runs/snapshots/<tag>/).
# Exit code 0 only if every check holds AND the final "COMPLETED" line printed.
extends SceneTree

const SCALE: float = 0.05
const TIMES: Array[float] = [0.0, 0.015, 0.03, 0.045, 0.06, 0.075, 0.09, 0.105, 0.12, 0.135, 0.15, 0.165, 0.18, 0.21, 0.30]
const IDX_LAST_IN_POP: int = 11             # TIMES[11] = 0.165 s
const CELL: int = 17                       # row 2, column 3 of the 7 x 5 frame: the middle, all eight neighbours Capped
const REF_CSV := "res://tests/snapshots/pop-r3-reference.csv"
const TOL_PROJECTED: float = 0.02
const TOL_PIXELS: float = 0.12

var main: Node
var fails: int = 0
var checks: int = 0
var risen: int = -1
var _tag: String = "r4"
var _out: String = ""


func _initialize() -> void:
	_run()


func ck(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
	print("PASS  " if c else "FAIL  ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < sec * 1000.0:
		await process_frame


func _w() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func _press(vp: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp * _w()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(ev)


## The face width of the cell's Mesh (flat side to flat side, local X through the +Y face centre), in viewport pixels.
func _face_width(mi: MeshInstance3D, cam: Camera3D) -> float:
	var aabb: AABB = mi.mesh.get_aabb()
	var c: Vector3 = aabb.position + aabb.size * 0.5
	c.y = aabb.end.y
	var hx: Vector3 = Vector3(aabb.size.x * 0.5, 0.0, 0.0)
	var gt: Transform3D = mi.global_transform
	return cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx)))


## Visible bright-yellow area around the centre pixel: flood fill, returns {area, w, h} in image pixels.
func _blob(img: Image, centre: Vector2i) -> Dictionary:
	var lim: int = 90
	var seen: Dictionary = {}
	var stack: Array[Vector2i] = []
	# the centre pixel may sit on an edge: start from the nearest yellow pixel within 6 px
	var start: Vector2i = Vector2i(-1, -1)
	for r in range(0, 7):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var p: Vector2i = centre + Vector2i(dx, dy)
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and _yellow(img.get_pixelv(p)):
					start = p
					break
			if start.x >= 0:
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return {"area": 0, "w": 0, "h": 0}
	stack.append(start)
	seen[start] = true
	var minx: int = start.x
	var maxx: int = start.x
	var miny: int = start.y
	var maxy: int = start.y
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		minx = mini(minx, p.x)
		maxx = maxi(maxx, p.x)
		miny = mini(miny, p.y)
		maxy = maxi(maxy, p.y)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if seen.has(q) or absi(q.x - centre.x) > lim or absi(q.y - centre.y) > lim:
				continue
			if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
				continue
			if _yellow(img.get_pixelv(q)):
				seen[q] = true
				stack.append(q)
	return {"area": seen.size(), "w": maxx - minx + 1, "h": maxy - miny + 1}


func _yellow(c: Color) -> bool:
	return c.r8 > 230 and c.g8 > 230 and c.b8 < 130


func _save_crop(img: Image, centre: Vector2i, name: String) -> void:
	var half: int = 48
	var r := Rect2i(maxi(centre.x - half, 0), maxi(centre.y - half, 0), half * 2, half * 2)
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var crop: Image = img.get_region(r)
	crop.save_png(name)


func _read_csv(path: String) -> Array:
	var rows: Array = []
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return rows
	f.get_line()
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line == "":
			continue
		var p: PackedStringArray = line.split(",")
		rows.append({"t": float(p[0]), "proj": float(p[1]), "pix": float(p[2])})
	return rows


func _interp(rows: Array, t: float, key: String) -> float:
	if rows.is_empty():
		return NAN
	if t <= float(rows[0]["t"]):
		return float(rows[0][key])
	for i in range(1, rows.size()):
		var t1: float = float(rows[i]["t"])
		if t <= t1:
			var t0: float = float(rows[i - 1]["t"])
			var f: float = (t - t0) / maxf(t1 - t0, 1.0e-9)
			return lerpf(float(rows[i - 1][key]), float(rows[i][key]), f)
	return float(rows[rows.size() - 1][key])


func _run() -> void:
	var mode: String = OS.get_environment("CB_MODE") if OS.get_environment("CB_MODE") != "" else "check"
	_tag = OS.get_environment("CB_TAG") if OS.get_environment("CB_TAG") != "" else "r4"
	_out = OS.get_environment("CB_OUT") if OS.get_environment("CB_OUT") != "" else ProjectSettings.globalize_path("res://reports/_runs/snapshots/%s/" % _tag)
	DirAccess.make_dir_recursive_absolute(_out)
	# Reset to defaults equivalent (a stale user://dev_config.tres would override the default values)
	if FileAccess.file_exists("user://dev_config.tres"):
		print("a stale user://dev_config.tres was FOUND and removed")
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://dev_config.tres"))
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	ck(root.get_visible_rect().size == Vector2(720, 1280) and DisplayServer.window_get_size() == Vector2i(720, 1280), "window 720 x 1280 (%s)" % str(DisplayServer.window_get_size()))
	var hive: Node = main.find_child("Hive", true, false)
	var cfg: Object = root.get_node("Economy").get("config")
	var is_r4: bool = hive.has_method("raise_frame")
	print("build: ", "0.1 (zoom on the farm)" if is_r4 else "revision 3 (close-up scene)", ", mode ", mode, ", tag ", _tag)
	if hive.has_method("fill_now"):
		hive.call("fill_now")
	else:
		hive.call("advance", float(cfg.get("frame_jars")) * float(cfg.get("base_seconds_per_jar")), 1.0)   # revision 3: the Dev action's way, 10 jars' time
	cfg.set("base_seconds_per_jar", 1.0e9)   # nothing arrives behind the measurement
	await _frames(6)
	var fork: Control = main.find_child("ForkIcon", true, false) as Control
	if is_r4:
		hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
		var cam0: Camera3D = root.get_viewport().get_camera_3d()
		var anchor: Node3D = fork.get_node(fork.get("anchor_path")) as Node3D
		var projected: Vector2 = cam0.unproject_position(anchor.global_position) + (fork.get("screen_offset") as Vector2)
		var rect: Rect2 = fork.get_global_rect()
		var inside := Vector2(clampf(projected.x, rect.position.x + 6.0, rect.end.x - 6.0), clampf(projected.y, rect.position.y + 6.0, rect.end.y - 6.0))
		_press(inside, true)
		await process_frame
		_press(inside, false)
		var t0: int = Time.get_ticks_msec()
		while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
			await process_frame
		ck(risen >= 0, "the zoom opened with a risen frame")
		await _wait(float(cfg.get("zoom_seconds")) + _lid_t(cfg) + float(cfg.get("slide_seconds")) + 0.8)
	else:
		fork.emit_signal("pressed")
		await _wait(1.6)
	cfg.set("cell_fly_seconds", 30.0)   # the check build: the cell must still sit at its slot when it is read (it leaves 0.18 s after the scrape)
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var body: Node3D = null
	for c in hc.find_children("*", "CollisionObject3D", true, false):
		if c.has_meta("cell_index") and int(c.get_meta("cell_index")) == CELL:
			body = c as Node3D
	ck(body != null, "cell %d of the frame has a collider with its cell_index" % CELL)
	if body == null:
		quit(1)
		return
	var mesh: MeshInstance3D = null
	for mi in body.find_children("*", "MeshInstance3D", true, false):   # revision 3: the Mesh is a child of the Body
		mesh = mi as MeshInstance3D
	if mesh == null:   # 0.1: Body and Mesh are siblings inside HoneyCell
		for mi in body.get_parent().find_children("*", "MeshInstance3D", true, false):
			mesh = mi as MeshInstance3D
	ck(mesh != null, "the cell's Mesh node was found")
	var centre_vp: Vector2 = cam.unproject_position(mesh.global_position)
	var k: Vector2 = _w()
	var centre_px := Vector2i(int(centre_vp.x * k.x), int(centre_vp.y * k.y))
	var width_before: float = _face_width(mesh, cam)
	print("cell ", CELL, " centre ", centre_vp, ", face width before the scrape ", width_before, " px, camera size ", cam.size)

	# scrape it with one real press, then step through the pop in slow motion
	# a clock node: its _process delta is the scaled frame time, exactly what the pop's tween is stepped with
	var gs := GDScript.new()
	gs.source_code = "extends Node
var sim: float = 0.0
func _process(d: float) -> void:
	sim += d
"
	gs.reload()
	var clock := Node.new()
	clock.set_script(gs)
	root.add_child(clock)
	Engine.time_scale = SCALE
	var samples: Array = []
	_press(centre_vp, true)
	await process_frame
	_press(centre_vp, false)
	var ti: int = 0
	var guard_end: int = Time.get_ticks_msec() + 60000
	while ti < TIMES.size() and Time.get_ticks_msec() < guard_end:
		var sim: float = float(clock.get("sim"))
		if sim >= TIMES[ti]:
			await RenderingServer.frame_post_draw
			var img: Image = root.get_texture().get_image()
			var blob: Dictionary = _blob(img, centre_px)
			var wv: float = _face_width(mesh, cam)
			samples.append({"t": sim, "want": TIMES[ti], "w": wv, "sc": mesh.scale.x, "area": int(blob["area"]), "bw": int(blob["w"]), "bh": int(blob["h"])})
			_save_crop(img, centre_px, "%spop-%s-t%03d.png" % [_out, _tag, int(round(TIMES[ti] * 1000.0))])
			ti += 1
			continue
		await process_frame
	Engine.time_scale = 1.0
	var sim_end: float = float(clock.get("sim"))
	clock.queue_free()
	ck(samples.size() == TIMES.size(), "all %d sample times were captured (%d)" % [TIMES.size(), samples.size()])
	if samples.size() != TIMES.size():
		quit(1)
		return
	var w_settled: float = float(samples[samples.size() - 1]["w"])
	# the pixel curve is normalised by the last sample INSIDE the pop (T = 0.165 s, scale 0.997): from T = 0.18 s the 0.1 build's cell has left
	# its slot (a flying copy takes its place), so a later frame no longer shows the slot's cell
	var a_settled: float = float(samples[IDX_LAST_IN_POP]["area"])
	var curve: Array = []
	for s in samples:
		curve.append({"t": float(s["t"]), "proj": float(s["w"]) / w_settled, "pix": sqrt(float(s["area"]) / maxf(a_settled, 1.0))})
	var csv: String = "t_sim_s,projected_width_ratio,pixel_size_ratio,mesh_scale_x,projected_width_px,yellow_area_px,blob_w_px,blob_h_px\n"
	for i in samples.size():
		var s: Dictionary = samples[i]
		csv += "%.4f,%.4f,%.4f,%.4f,%.2f,%d,%d,%d\n" % [float(s["t"]), float(curve[i]["proj"]), float(curve[i]["pix"]), float(s["sc"]), float(s["w"]), int(s["area"]), int(s["bw"]), int(s["bh"])]
	var f: FileAccess = FileAccess.open(_out + "pop-%s.csv" % _tag, FileAccess.WRITE)
	f.store_string(csv)
	f.close()
	print(csv)
	# facts about the pop itself
	# the pop's own parameters, read off the cell's Mesh at every sample: scale 1.3 -> 1 over 0.18 s with TRANS_BACK / EASE_OUT
	var worst_a: float = 0.0
	for s in samples:
		var x: float = clampf(float(s["t"]) / 0.18, 0.0, 1.0) - 1.0
		var back_out: float = x * x * ((1.70158 + 1.0) * x + 1.70158) + 1.0
		worst_a = maxf(worst_a, absf(float(s["sc"]) - (1.3 + (1.0 - 1.3) * back_out)))
	print("MEASURE pop scale against 1.3 -> 1 over 0.18 s, back-out: worst difference %.4f" % worst_a)
	ck(worst_a <= 0.012, "the Mesh scale follows 1.3 -> 1 over 0.18 s with a back-out ease at every sample (worst %.4f)" % worst_a)
	ck(float(curve[0]["proj"]) > 1.2 and float(samples[0]["t"]) < 0.02, "the first sample (T = %.4f s) shows the cell still enlarged (%.3f of its settled width)" % [float(samples[0]["t"]), float(curve[0]["proj"])])
	ck(float(curve[8]["proj"]) < 1.0, "the back-out undershoots 1 (T = %.3f s: %.3f)" % [float(samples[8]["t"]), float(curve[8]["proj"])])
	ck(absf(float(samples[samples.size() - 1]["sc"]) - 1.0) <= 0.001, "T = 0.30 s: the cell's Mesh scale is back at 1 (%.4f)" % float(samples[samples.size() - 1]["sc"]))
	print("MEASURE (report-only, 0.1.2) yellow face area at the end of the pop: %d px; at T = 0: %d px" % [int(samples[IDX_LAST_IN_POP]["area"]), int(samples[0]["area"])])
	var last_sim: float = float(samples[samples.size() - 1]["t"])
	print("sim clock at the end ", sim_end)
	ck(last_sim >= 0.30 and last_sim < 0.34, "sim time at the last sample is about 0.30 s (%.4f)" % last_sim)

	if mode == "check":
		var ref: Array = _read_csv(REF_CSV)
		ck(ref.size() == TIMES.size(), "the revision 3 reference curve is present (%d samples in %s)" % [ref.size(), REF_CSV])
		var worst_p: float = 0.0
		var worst_x: float = 0.0
		var wp_t: float = 0.0
		var wx_t: float = 0.0
		for i in curve.size():
			var t: float = float(curve[i]["t"])
			var dp: float = absf(float(curve[i]["proj"]) - _interp(ref, t, "proj"))
			var dx: float = absf(float(curve[i]["pix"]) - _interp(ref, t, "pix")) if i <= IDX_LAST_IN_POP else 0.0   # inside the pop only
			if dp > worst_p:
				worst_p = dp
				wp_t = t
			if dx > worst_x:
				worst_x = dx
				wx_t = t
		print("MEASURE pop curve against the revision 3 reference: worst projected-width difference %.4f at T = %.3f s (tolerance %.2f); worst rendered-pixel difference %.4f at T = %.3f s (tolerance %.2f)" % [worst_p, wp_t, TOL_PROJECTED, worst_x, wx_t, TOL_PIXELS])
		ck(worst_p <= TOL_PROJECTED, "the projected size curve matches revision 3 within %.2f (worst %.4f)" % [TOL_PROJECTED, worst_p])
		print("MEASURE (report-only, 0.1.2: no pass/fail) rendered-pixel size curve worst difference %.4f against %.2f" % [worst_x, TOL_PIXELS])
	print("---- %d checks, %d failed" % [checks, fails])
	print("COMPLETED")
	quit(1 if fails > 0 else 0)


## Lid time of 0.1.1: the lift then the fall (the revision 3 build has no lid_lift_seconds: counts as 0). Waits only, never the reference data.
func _lid_t(c: Object) -> float:
	var lift: Variant = c.get("lid_lift_seconds")
	return float(c.get("lid_drop_seconds")) + (float(lift) if lift != null else 0.0)
