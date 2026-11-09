# Quinn: where the truck drives while it is away (r3 layout check, kept for 0.1: it uses only the truck's own API). Windowed, prints numbers, saves one screenshot.
#   Godot --path game --resolution 720x1280 --position 0,0 --script res://tests/r3_trip.gd
# Loads 10 jars onto the truck (receive_jar, a Dev-mode style shortcut), sells, then samples the truck's projected
# box against the ShopPanel and the screen every frame of the trip; saves the frame where the overlap is largest.
extends SceneTree


func _initialize() -> void:
	_run()


func _prop_rect(node: Node, cam: Camera3D) -> Rect2:
	var out := Rect2()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var bb: AABB = mi.get_aabb()
		for k in 8:
			var corner: Vector3 = bb.position + Vector3(bb.size.x * float(k & 1), bb.size.y * float((k >> 1) & 1), bb.size.z * float((k >> 2) & 1))
			var p: Vector2 = cam.unproject_position(mi.global_transform * corner)
			if first:
				out = Rect2(p, Vector2.ZERO)
				first = false
			else:
				out = out.expand(p)
	return out


func _run() -> void:
	await process_frame
	print("Dev config reset: stale file ", "FOUND and removed" if load("res://tests/farm_input.gd").call("reset_dev_config") else "not present")
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 10:
		await process_frame
	var truck: Node = main.find_child("Truck", true, false)
	var shop: Control = main.find_child("ShopPanel", true, false) as Control
	var cfg: Object = root.get_node("Economy").get("config")
	for i in int(cfg.get("truck_capacity_jars")):
		truck.call("receive_jar")
	truck.call("sell")
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var worst: float = 0.0
	var worst_t: float = -1.0
	var on_screen_frames: int = 0
	var t0: int = Time.get_ticks_msec()
	var saved := false
	var best_img: Image = null
	var panel: Rect2 = shop.get_global_rect()
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var frames: int = 0
	while float(Time.get_ticks_msec() - t0) < float(cfg.get("truck_trip_seconds")) * 1000.0 * 0.6:
		await process_frame
		frames += 1
		var r: Rect2 = _prop_rect(truck, cam)
		var inter: Rect2 = r.intersection(panel)
		var area: float = maxf(inter.size.x, 0.0) * maxf(inter.size.y, 0.0) if r.intersects(panel) else 0.0
		if r.intersects(screen):
			on_screen_frames += 1
		if area > worst:
			worst = area
			worst_t = float(Time.get_ticks_msec() - t0) / 1000.0
			await RenderingServer.frame_post_draw
			best_img = root.get_texture().get_image()
	print("TRIP: %d frames sampled; truck box on screen in %d of them; largest overlap of the truck's projected box with ShopPanel %.0f px2 at t=%.2f s (panel %s)" % [frames, on_screen_frames, worst, worst_t, str(panel)])
	if best_img != null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/_runs/shots/r3_trip/"))
		best_img.save_png(ProjectSettings.globalize_path("res://reports/_runs/shots/r3_trip/r4-m4-truck-trip-max-overlap.png"))
	quit()
