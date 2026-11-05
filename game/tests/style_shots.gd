# Quinn: the style loop's fixed shot set (M2 spec item 4), WINDOWED at 720 x 1280, on the current farm.
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/style_shots.gd -- --out=<ABSOLUTE dir>
# Writes 01-farm-start, 02-farm-hive-full, 03-zoom-uncapping, 04-bucket-full, 05-pile, 06-truck-away (PNG) and measure.json
# {"viewport", "cell_px_min", "cell_px_max", "shots"} into --out (default res://reports/style/_manual/). Zoom, scrape, Back and Sell are
# real input (tests/farm_input.gd); the bucket, the pile and the truck load are set with the cheats of play_loop.gd.
# Cell width is measured exactly like r4_measure.gd (_face_size over the risen frame, before the scrape). Exit 0 only after "COMPLETED".
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")

var out_dir: String = "res://reports/style/_manual/"
var fi: RefCounted
var main: Node
var P: Dictionary = {}
var risen: int = -1
var names: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	if not out_dir.ends_with("/"):
		out_dir += "/"
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < sec * 1000.0:
		await process_frame


func _path(f: String) -> String:
	return ProjectSettings.globalize_path(out_dir + f)


func _shot(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err: int = img.save_png(_path(name + ".png"))
	print("shot ", name, " ", img.get_size(), " err=", err)
	if err == OK and img.get_size() == Vector2i(720, 1280):
		names.append(name + ".png")


func _cfg() -> Object:
	return root.get_node("Economy").get("config")


func _lid_t(c: Object) -> float:
	var lift: Variant = c.get("lid_lift_seconds")
	return float(c.get("lid_drop_seconds")) + (float(lift) if lift != null else 0.0)


func _settle() -> float:
	var c: Object = _cfg()
	return float(c.get("zoom_seconds")) + _lid_t(c) + float(c.get("slide_seconds")) + 0.6


func _face_size(mi: MeshInstance3D, cam: Camera3D) -> Vector2:
	var aabb: AABB = mi.mesh.get_aabb()
	var c: Vector3 = aabb.position + aabb.size * 0.5
	c.y = aabb.end.y
	var hx: Vector3 = Vector3(aabb.size.x * 0.5, 0.0, 0.0)
	var hz: Vector3 = Vector3(0.0, 0.0, aabb.size.z * 0.5)
	var gt: Transform3D = mi.global_transform
	return Vector2(cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx))), cam.unproject_position(gt * (c + hz)).distance_to(cam.unproject_position(gt * (c - hz))))


func _fail(msg: String) -> void:
	print("FAILED: ", msg)
	quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_path(""))
	fi = FarmInput.new(self)
	FarmInput.reset_dev_config()
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	for nm in ["Hive", "Centrifuge", "Pile", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon"]:
		P[nm] = main.find_child(nm, true, false)
	var hive: Node = P["Hive"]
	var cen: Node = P["Centrifuge"]
	var pile: Node = P["Pile"]
	var truck: Node = P["Truck"]
	var cfg: Object = _cfg()
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	if root.get_visible_rect().size != Vector2(720, 1280):
		_fail("viewport is not 720 x 1280")
		return
	await _shot("01-farm-start")
	hive.call("fill_now")
	cfg.set("base_seconds_per_jar", 1.0e9)   # CHEAT: nothing arrives behind the shots
	cfg.set("cell_fly_seconds", 0.5)
	await _frames(5)
	await _shot("02-farm-hive-full")
	# zoom (real tap on the fork icon), measure the cells, one real scrape, shot
	await fi.click_icon(P["ForkIcon"] as Control)
	var t0: int = Time.get_ticks_msec()
	while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	await _wait(_settle())
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	if risen < 0 or hc == null:
		_fail("the zoom did not open")
		return
	var min_w: float = 1.0e9
	var max_w: float = 0.0
	var n_cells: int = 0
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var sz: Vector2 = _face_size(m, cam)
		if sz.x > 0.0:
			min_w = minf(min_w, sz.x)
			max_w = maxf(max_w, sz.x)
			n_cells += 1
	print("MEASURE cells=%d min=%.1f max=%.1f" % [n_cells, min_w, max_w])
	if n_cells == 0:
		_fail("no cell measured")
		return
	var rws: Array = fi.rows(hc, cam)
	await fi.drag_row(rws[0])
	await _wait(float(cfg.get("cell_fly_seconds")) + 0.5)
	await _shot("03-zoom-uncapping")
	# Back, then the bucket full (cheat: the cells the scrape did not bring)
	await fi.click_ctl(main.find_child("BackButton", true, false) as Control)
	await _wait(_settle() + 0.5)
	var room: int = int(cen.call("room_cells"))
	cen.call("add_cells", room, float(room) / 35.0)
	cen.call("land_cells", int(cen.call("capacity_cells")))
	await _wait(_lid_t(cfg) + 1.0)
	await _shot("04-bucket-full")
	# pile: cells piled by the centrifuge while it cranks
	cen.call("begin_crank")
	pile.call("add", 30, 30.0 / 35.0)
	pile.call("land", 30)
	await _wait(0.8)
	await _shot("05-pile")
	# truck away after a real Sell
	for i in int(truck.get("capacity")):
		truck.call("receive_jar")
	await _wait(2.5)
	if not (P["SellIcon"] as CanvasItem).is_visible_in_tree():
		_fail("the Sell icon is not showing on the full truck")
		return
	await fi.click_icon(P["SellIcon"] as Control)
	await _wait(1.0)
	var ok: Node = main.find_child("SummaryOkButton", true, false)
	if ok != null and (ok as CanvasItem).is_visible_in_tree():
		await fi.click_ctl(ok as Control)
	await _wait(0.8)
	if not bool(truck.get("away")):
		_fail("the truck is not away")
		return
	await _shot("06-truck-away")
	var j := {"viewport": [720, 1280], "cell_px_min": snappedf(min_w, 0.1), "cell_px_max": snappedf(max_w, 0.1), "shots": names}
	var f := FileAccess.open(_path("measure.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(j))
	f.close()
	if names.size() != 6:
		_fail("only %d shots written" % names.size())
		return
	print("COMPLETED")
	quit(0)
