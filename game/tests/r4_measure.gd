# Quinn: milestone 0.1 (Harvest) measurements, WINDOWED at the full portrait size, written from game/specs/0.1-harvest.md.
#   Godot --path game --resolution 720x1280 --position 0,0 -s tests/r4_measure.gd
# Measures, and prints one "MEASURE" line each (the report copies them):
#   1. the smallest cell's on-screen width at the zoom (projected mesh AABB, viewport px) against config min_cell_px;
#   2. the pixel colour of a Capped cell and of an Uncapped one (5 x 5 mean at the cell's projected centre) against revision 3's
#      numbers, capped (229, 177, 45) and uncapped (255, 255, 57), +-2 per channel (spec: "Models as reusable scenes");
#   3. frame time on the farm and in the zoom with cells flying (60 FPS = 16.7 ms), desktop.
# Capture timing: an Uncapped cell leaves its slot 0.18 s after the scrape (pop), so the frame is read 0.20-0.30 s after the
# scrape (the check below fails outside that window) and cell_fly_seconds is raised (CHEAT, restored) so the cell has barely moved.
# 'Width' of a cell = the screen distance between the two flat sides of its hexagonal face (mesh AABB x extent, through the cell
# centre along the frame's width axis); the on-screen height (vertex to vertex) is printed too but the spec's limit is on width.
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


## Reads the frame as it is drawn (no file write: saving takes tens of ms, which would age the capture); save with _save().
## Reads the frame as it is drawn (no file write: saving takes tens of ms, which would age the capture); save with _save().
func _img() -> Image:
	await _frames(2)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(SHOT_DIR + name + ".png"))


func _shot(name: String) -> Image:
	var img: Image = await _img()
	_save(img, name)
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


## Screen width of one cell's hexagonal face: its two flat sides, through the cell centre along the mesh's local X (the frame's
## width axis). Also returns the height (vertex to vertex, local Z). Both in viewport pixels.
func _face_size(mi: MeshInstance3D, cam: Camera3D) -> Vector2:
	var aabb: AABB = mi.mesh.get_aabb()
	var c: Vector3 = aabb.position + aabb.size * 0.5
	c.y = aabb.end.y   # the +Y face (the side that shows)
	var hx: Vector3 = Vector3(aabb.size.x * 0.5, 0.0, 0.0)
	var hz: Vector3 = Vector3(0.0, 0.0, aabb.size.z * 0.5)
	var gt: Transform3D = mi.global_transform
	var w: float = cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx)))
	var h: float = cam.unproject_position(gt * (c + hz)).distance_to(cam.unproject_position(gt * (c - hz)))
	return Vector2(w, h)


func _hold_os(vp: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp * fi.to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func eq(a: Variant, b: Variant, what: String) -> void:
	ck(a == b, "%s (expected %s, got %s)" % [what, str(b), str(a)])


## Frame time for up to `seconds` while `cond` holds. Returns the average ms.
func _fps_while(tag: String, cond: Callable, seconds: float) -> float:
	var t_end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	var last: int = Time.get_ticks_usec()
	var dts: Array[float] = []
	while Time.get_ticks_msec() < t_end and cond.call():
		await process_frame
		var now: int = Time.get_ticks_usec()
		dts.append(float(now - last) / 1000.0)
		last = now
	dts.sort()
	var sum: float = 0.0
	for d in dts:
		sum += d
	var avg: float = sum / float(maxi(dts.size(), 1))
	var over: int = 0
	for d in dts:
		if d > 17.7:
			over += 1
	print("MEASURE fps %s: %d frames, avg %.2f ms (%.1f FPS), p95 %.2f ms, max %.2f ms, %d frames over 17.7 ms" % [tag, dts.size(), avg, 1000.0 / maxf(avg, 0.001), dts[int(float(dts.size()) * 0.95)] if dts.size() > 0 else 0.0, dts[dts.size() - 1] if dts.size() > 0 else 0.0, over])
	ck(dts.size() >= 60, "%s: at least 60 frames were measured (%d)" % [tag, dts.size()])
	return avg


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	fi = FarmInput.new(self)
	var stale: bool = FarmInput.reset_dev_config()
	print("Dev config reset (equivalent of Reset to defaults): a stale user://dev_config.tres was ", "FOUND and removed" if stale else "not present")
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	print("window ", DisplayServer.window_get_size(), " viewport ", root.get_visible_rect().size, " (the pixel numbers need 720 x 1280)")
	ck(root.get_visible_rect().size == Vector2(720, 1280), "the viewport is 720 x 1280")
	var hive: Node = main.find_child("Hive", true, false)
	var cen: Node = main.find_child("Centrifuge", true, false)
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	hive.call("fill_now")
	_set_cfg("base_seconds_per_jar", 1.0e9)       # CHEAT: nothing arrives behind the measurement
	_set_cfg("cell_fly_seconds", 5.0)             # CHEAT: a scraped cell is still near its slot when the frame is read
	await _frames(5)
	await _fps("farm, full hive, fork icon showing", 5.0)
	await _shot("r4-m0-farm")
	await fi.click_icon(main.find_child("ForkIcon", true, false) as Control)
	var t0: int = Time.get_ticks_msec()
	while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	await _wait(float(_cv("zoom_seconds")) + float(_cv("lid_drop_seconds")) + float(_cv("slide_seconds")) + 0.6)
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	ck(risen >= 0 and hc != null, "the zoom is open with a risen frame")
	var vp: Vector2 = root.get_visible_rect().size

	# ---- 1. smallest cell width on screen (a vacuous pass is impossible: all 35 cells must be measured)
	var min_w: float = 1.0e9
	var max_w: float = 0.0
	var min_h: float = 1.0e9
	var n_cells: int = 0
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var sz: Vector2 = _face_size(m, cam)
		if sz.x > 0.0:
			min_w = minf(min_w, sz.x)
			max_w = maxf(max_w, sz.x)
			min_h = minf(min_h, sz.y)
			n_cells += 1
	var min_px: float = float(_cv("min_cell_px"))
	print("MEASURE cell width at the zoom: %d cells, smallest width %.1f px, largest %.1f px, smallest height (vertex to vertex) %.1f px, min_cell_px %s, zoom_size %s, camera size %.2f, viewport %s" % [n_cells, min_w, max_w, min_h, str(min_px), str(_cv("zoom_size")), cam.size, str(vp)])
	eq(n_cells, int(_cv("grid_cols")) * int(_cv("grid_rows")), "all 35 cells of the risen frame were measured")
	ck(n_cells > 0 and min_w >= min_px, "the smallest cell is at least min_cell_px wide on screen (%.1f >= %s)" % [min_w, str(min_px)])
	await _shot("r4-m1-zoom-risen-frame")

	# ---- 2. capped vs uncapped colour: scrape one cell by a real press, read the frame 0.20-0.30 s later
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
	var img: Image = await _img()
	var age: float = float(Time.get_ticks_usec() - int(rec["t0"])) / 1.0e6
	fi.mouse_button(press, false)
	_save(img, "r4-m2-capped-vs-uncapped")
	var best: float = 1.0e9
	var node: Node3D = null
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		var d: float = (mi as Node3D).global_position.distance_to(rec["wp"] as Vector3)
		if d < best:
			best = d
			node = mi as Node3D
	var uncapped_px: Color = _mean5(img, cam.unproject_position(node.global_position))
	var capped_px: Color = _mean5(img, capped_at)
	print("MEASURE colours (frame read %.3f s after the scrape): capped %s, uncapped %s; revision 3: capped %s, uncapped %s" % [age, str(capped_px.to_html(false)), str(uncapped_px.to_html(false)), str(CAPPED_R3.to_html(false)), str(UNCAPPED_R3.to_html(false))])
	print("MEASURE colours as RGB: capped (%d, %d, %d), uncapped (%d, %d, %d)" % [capped_px.r8, capped_px.g8, capped_px.b8, uncapped_px.r8, uncapped_px.g8, uncapped_px.b8])
	ck(age >= 0.18 and age <= 0.30, "the frame was read inside the settled pop, before the cell left (%.3f s)" % age)
	ck(_within(capped_px, CAPPED_R3, 2), "Capped cell pixel equals revision 3's (229, 177, 45) +-2 per channel")
	ck(_within(uncapped_px, UNCAPPED_R3, 2), "Uncapped cell pixel equals revision 3's (255, 255, 57) +-2 per channel")
	ck(not _within(capped_px, uncapped_px, 20), "capped and uncapped still differ visibly")

	# ---- 3. frame time in the zoom with cells flying
	var rws: Array = fi.rows(hc, cam)
	if rws.size() > 1:
		await fi.drag_row(rws[1])
	var avg: float = await _fps("zoom, cells flying (cell_fly_seconds raised)", 4.0)
	ck(avg <= 1000.0 / 60.0 + 0.5, "the zoom with cells flying holds 60 FPS (avg %.2f ms)" % avg)
	_set_cfg("cell_fly_seconds", 0.5)
	var cap_cells: int = int(_cv("centrifuge_capacity_frames")) * int(_cv("grid_cols")) * int(_cv("grid_rows"))
	var guard: int = 0
	while int(cen.get("cells")) < cap_cells and guard < 4 and risen >= 0:
		# rows() also lists slots that already left (their collider nodes stay visible), so drag each row once, in order
		for rw in fi.rows(hc, cam):
			if int(cen.get("cells")) >= cap_cells or risen < 0 or FarmInput.capped(hive, risen) == 0:
				break
			await fi.drag_row(rw)
			await _wait(0.25)
		await _wait(float(_cv("slide_seconds")) * 2.0 + 0.6)   # the next frame rises
		guard += 1
	await _wait(float(_cv("cell_fly_seconds")) + 0.5)
	eq(int(cen.get("cells")), cap_cells, "the bucket was filled to its capacity by real drags (%d cells)" % cap_cells)
	if risen >= 0:
		for rw in fi.rows(hc, cam):
			if FarmInput.capped(hive, risen) == 0:
				break
			await fi.drag_row(rw)   # the bucket is full: these cells fly to the pile
			await _wait(0.25)
			break
	await _fps("zoom, cells flying to the pile, bucket lid on", 1.5)

	# ---- 4. cranking, then bottling (farm view), desktop
	await fi.click_ctl(main.find_child("BackButton", true, false) as Control)
	await _wait(float(_cv("zoom_seconds")) + float(_cv("lid_drop_seconds")) + float(_cv("slide_seconds")) + 0.8)
	var cicon: Control = main.find_child("CentrifugeIcon", true, false) as Control
	ck(cicon.is_visible_in_tree(), "Spin shows after Back (bucket full, lid on)")
	await fi.click_icon(cicon)
	await _frames(3)
	var spot: Vector2 = fi.free_spot(main)
	var rate: float = float(_cv("max_tap_rate"))
	var cranking: int = int(cen.get("state"))
	var need_turns: int = int(ceil(float(cap_cells * int(_cv("frame_jars"))) / float(int(_cv("grid_cols")) * int(_cv("grid_rows"))) * float(_cv("taps_per_jar"))))
	_hold_os(spot, true)   # a real hold: one turn on press, then max_tap_rate per second
	var crank_avg: float = await _fps_while("farm, cranking (real hold, melt and spin)", func() -> bool: return int(cen.get("state")) == cranking, (float(need_turns) / rate) + 3.0)
	_hold_os(spot, false)
	ck(crank_avg <= 1000.0 / 60.0 + 0.5, "the farm holds 60 FPS while cranking (avg %.2f ms)" % crank_avg)
	await _frames(5)
	await _shot("r4-m3-farm-done")
	_set_cfg("bottling_seconds_per_jar", 3.0)
	await fi.click_ctl(main.find_child("ContinueButton", true, false) as Control)
	await _frames(3)
	var bottling: int = int(cen.get("state"))
	var bot_avg: float = await _fps_while("farm, bottling (honey level dropping, jars filling)", func() -> bool: return int(cen.get("state")) == bottling, 6.0)
	ck(bot_avg <= 1000.0 / 60.0 + 0.5, "the farm holds 60 FPS while bottling (avg %.2f ms)" % bot_avg)

	for k in _cfg_saved:
		_cfg().set(k, _cfg_saved[k])
	print("---- %d checks, %d failed" % [checks, fails])
	print("COMPLETED")
	quit(1 if fails > 0 else 0)
