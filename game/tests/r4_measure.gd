# Quinn: milestone 0.1 (Harvest) measurements, WINDOWED at the full portrait size, written from game/specs/0.1-harvest.md.
#   Godot --path game --resolution 720x1280 --position 0,0 -s tests/r4_measure.gd
# Measures, and prints one "MEASURE" line each (the report copies them):
#   1. the smallest cell's on-screen width at the zoom (projected mesh AABB, viewport px) against config min_cell_px;
#   2. the pixel colour of a Capped cell and of an Uncapped one (5 x 5 mean at the cell's projected centre) against revision 3's
#      numbers, capped (229, 177, 45) and uncapped (255, 255, 57), +-2 per channel (spec: "Models as reusable scenes");
#   3. frame time on the farm and in the zoom with cells flying (60 FPS = 16.7 ms), desktop.
# Capture timing: an Uncapped cell leaves its slot 0.18 s after the scrape (pop), so the screenshot is taken 0.20-0.24 s after
# the scrape and cell_fly_seconds is raised (CHEAT, restored) so the cell has barely moved from its slot at that moment.
# Exit code 0 only if every measured limit holds AND the final "COMPLETED" line printed.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const SHOT_DIR := "res://reports/2026-11-04-0.1-harvest/"
const CAPPED_R3 := Color8(229, 177, 45)
const UNCAPPED_R3 := Color8(255, 255, 57)

var fi: RefCounted
var main: Node
var fails: int = 0
var checks: int = 0
var _cfg_saved: Dictionary = {}
var risen: int = -1


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


func _cfg() -> Variant:
	return root.get_node("Economy").get("config")


func _cv(name: String) -> Variant:
	var v: Variant = _cfg().get(name)
	if v == null:
		print("FAIL  ABORT config value missing: ", name)
		quit(1)
		return 0
	return v


func _set_cfg(name: String, value: Variant) -> void:
	if not _cfg_saved.has(name):
		_cfg_saved[name] = _cfg().get(name)
	_cfg().set(name, value)


func _img(name: String) -> Image:
	await _frames(2)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(SHOT_DIR + name + ".png"))
	return img


func _mean5(img: Image, vp: Vector2) -> Color:
	var k: Vector2 = Vector2(img.get_size()) / root.get_visible_rect().size
	var cx: int = int(vp.x * k.x)
	var cy: int = int(vp.y * k.y)
	var sum := Vector3.ZERO
	var n: int = 0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var c: Color = img.get_pixel(clampi(cx + dx, 0, img.get_width() - 1), clampi(cy + dy, 0, img.get_height() - 1))
			sum += Vector3(c.r8, c.g8, c.b8)
			n += 1
	sum /= float(n)
	return Color8(int(round(sum.x)), int(round(sum.y)), int(round(sum.z)))


func _within(a: Color, b: Color, tol: int) -> bool:
	return absi(a.r8 - b.r8) <= tol and absi(a.g8 - b.g8) <= tol and absi(a.b8 - b.b8) <= tol


func _fps(tag: String, seconds: float) -> float:
	var t_end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	var last: int = Time.get_ticks_usec()
	var dts: Array[float] = []
	while Time.get_ticks_msec() < t_end:
		await process_frame
		var now: int = Time.get_ticks_usec()
		dts.append(float(now - last) / 1000.0)
		last = now
	dts.sort()
	var sum: float = 0.0
	for d in dts:
		sum += d
	var avg: float = sum / float(maxi(dts.size(), 1))
	var p95: float = dts[int(float(dts.size()) * 0.95)] if dts.size() > 0 else 0.0
	var over: int = 0
	for d in dts:
		if d > 16.7 + 1.0:
			over += 1
	print("MEASURE fps %s: %d frames, avg %.2f ms (%.1f FPS), p95 %.2f ms, max %.2f ms, %d frames over 17.7 ms" % [tag, dts.size(), avg, 1000.0 / maxf(avg, 0.001), p95, dts[dts.size() - 1] if dts.size() > 0 else 0.0, over])
	return avg


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	fi = FarmInput.new(self)
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	print("window ", DisplayServer.window_get_size(), " viewport ", root.get_visible_rect().size, " (the pixel numbers need 720 x 1280)")
	var hive: Node = main.find_child("Hive", true, false)
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	hive.call("fill_now")
	_set_cfg("base_seconds_per_jar", 1.0e9)       # CHEAT: nothing arrives behind the measurement
	_set_cfg("cell_fly_seconds", 5.0)             # CHEAT: a scraped cell is still near its slot when the screenshot is taken
	await _frames(5)
	await _fps("farm, full hive, fork icon showing", 5.0)
	await _img("r4-m0-farm")
	await fi.click_icon(main.find_child("ForkIcon", true, false) as Control)
	var t0: int = Time.get_ticks_msec()
	while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	await _wait(float(_cv("zoom_seconds")) + float(_cv("lid_drop_seconds")) + float(_cv("slide_seconds")) + 0.6)
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	ck(risen >= 0 and hc != null, "the zoom is open with a risen frame")
	var vp: Vector2 = root.get_visible_rect().size

	# ---- 1. smallest cell width on screen
	var min_w: float = 1.0e9
	var max_w: float = 0.0
	var n_cells: int = 0
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var r: Rect2 = fi.screen_rect(m, cam)
		if r.size.x > 0.0:
			min_w = minf(min_w, r.size.x)
			max_w = maxf(max_w, r.size.x)
			n_cells += 1
	var min_px: float = float(_cv("min_cell_px"))
	print("MEASURE cell width at the zoom: %d cells, smallest %.1f px, largest %.1f px, min_cell_px %s, zoom_size %s, viewport %s" % [n_cells, min_w, max_w, str(min_px), str(_cv("zoom_size")), str(vp)])
	ck(n_cells >= int(_cv("grid_cols")) * int(_cv("grid_rows")) - 1, "the whole frame (35 cells) was measured (%d)" % n_cells)
	ck(min_w >= min_px, "the smallest cell is at least min_cell_px wide on screen (%.1f >= %s)" % [min_w, str(min_px)])
	await _img("r4-m1-zoom-risen-frame")

	# ---- 2. capped vs uncapped colour: scrape one cell by a real press, capture inside 0.20-0.24 s
	var cells: Array[Node3D] = fi.cells(hc)
	var target: Node3D = cells[0]
	var other: Node3D = cells[cells.size() - 1]
	var rec: Dictionary = {"t0": -1, "wp": Vector3.ZERO}
	hc.connect("cell_scraped", func(_c: Variant, _v: Variant, wp: Variant) -> void:
		if int(rec["t0"]) < 0:
			rec["t0"] = Time.get_ticks_usec()
			rec["wp"] = wp)
	var press: Vector2 = cam.unproject_position(target.global_position)
	var capped_at: Vector2 = cam.unproject_position(other.global_position)
	fi.mouse_button(press, true)
	while int(rec["t0"]) < 0:
		await process_frame
	while float(Time.get_ticks_usec() - int(rec["t0"])) < 200000.0:
		await process_frame
	var img: Image = await _img("r4-m2-capped-vs-uncapped")
	var age: float = float(Time.get_ticks_usec() - int(rec["t0"])) / 1.0e6
	fi.mouse_button(press, false)
	# the scraped cell's mesh: nearest to the scrape position
	var best: float = 1.0e9
	var node: Node3D = null
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		var d: float = (mi as Node3D).global_position.distance_to(rec["wp"] as Vector3)
		if d < best:
			best = d
			node = mi as Node3D
	var uncapped_px: Color = _mean5(img, cam.unproject_position(node.global_position))
	var capped_px: Color = _mean5(img, capped_at)
	print("MEASURE colours (capture %.3f s after the scrape): capped %s, uncapped %s; revision 3: capped %s, uncapped %s" % [age, str(capped_px.to_html(false)), str(uncapped_px.to_html(false)), str(CAPPED_R3.to_html(false)), str(UNCAPPED_R3.to_html(false))])
	print("MEASURE colours as RGB: capped (%d, %d, %d), uncapped (%d, %d, %d)" % [capped_px.r8, capped_px.g8, capped_px.b8, uncapped_px.r8, uncapped_px.g8, uncapped_px.b8])
	ck(age >= 0.18 and age <= 0.30, "the capture was taken inside the settled pop, before the cell left (%.3f s)" % age)
	ck(_within(capped_px, CAPPED_R3, 2), "Capped cell pixel equals revision 3's (229, 177, 45) +-2 per channel")
	ck(_within(uncapped_px, UNCAPPED_R3, 2), "Uncapped cell pixel equals revision 3's (255, 255, 57) +-2 per channel")
	ck(not _within(capped_px, uncapped_px, 20), "capped and uncapped still differ visibly")

	# ---- 3. frame time in the zoom with cells flying
	var rws: Array = fi.rows(hc, cam)
	if rws.size() > 1:
		await fi.drag_row(rws[1])
	var avg: float = await _fps("zoom, cells flying (cell_fly_seconds raised)", 4.0)
	ck(avg <= 1000.0 / 60.0 + 0.5, "the zoom with cells flying holds 60 FPS (avg %.2f ms)" % avg)

	for k in _cfg_saved:
		_cfg().set(k, _cfg_saved[k])
	print("---- %d checks, %d failed" % [checks, fails])
	print("COMPLETED")
	quit(1 if fails > 0 else 0)
