# Quinn: measurements for the Prototype 0 r3 report (spec "Done when": uncapping pop RGB, layout, contrast, FPS).
#   Godot --path game --resolution 720x1280 --position 0,0 --script res://tests/r3_measure.gd
# Windowed. Not a pass/fail suite: it prints numbers and saves screenshots to reports/2026-11-04-prototype-0-r3/.
# Drives the farm through the real scene nodes (pressed signals), not through input: input is play_loop.gd's job.
# The uncapping close-up is reached through the fork icon (instanced under Main, so the Sun lights it) and sampled
# MID-DRAG: the mouse button is still down (Input.parse_input_event, as the OS sends it) when the pixels are read.
extends SceneTree

const SHOT_DIR := "res://reports/2026-11-04-prototype-0-r3/"
var main: Node


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < sec * 1000.0:
		await process_frame


func _n(name: String) -> Node:
	return main.find_child(name, true, false)


func _vis(n: Node) -> bool:
	return n != null and (n as CanvasItem).is_visible_in_tree()


func _img() -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _shot(name: String) -> Image:
	var img: Image = await _img()
	img.save_png(ProjectSettings.globalize_path(SHOT_DIR + name + ".png"))
	print("SHOT ", name, " image ", img.get_size(), " viewport ", root.get_visible_rect().size)
	return img


func _rect_str(r: Rect2) -> String:
	return "x %.0f..%.0f y %.0f..%.0f" % [r.position.x, r.end.x, r.position.y, r.end.y]


## Gap between two rects in px: an overlap size if they intersect, else the distance between their edges.
func _gap(a: Rect2, b: Rect2) -> String:
	var i: Rect2 = a.intersection(b)
	if a.intersects(b) and i.size.x > 0.0 and i.size.y > 0.0:
		return "OVERLAP %.0f x %.0f px" % [i.size.x, i.size.y]
	var dx: float = maxf(maxf(b.position.x - a.end.x, a.position.x - b.end.x), 0.0)
	var dy: float = maxf(maxf(b.position.y - a.end.y, a.position.y - b.end.y), 0.0)
	return "clear by %.0f px (dx %.0f, dy %.0f)" % [sqrt(dx * dx + dy * dy), dx, dy]


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


func _layout(tag: String) -> void:
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var shop: Control = _n("ShopPanel") as Control
	var tops: Dictionary = {}
	for nm in ["MoneyLabel", "FillBar", "FillLabel", "BeeCountLabel", "PausedLabel", "CentrifugeLabel"]:
		var c: Control = _n(nm) as Control
		if _vis(c):
			tops[nm] = c.get_global_rect()
	var icons: Dictionary = {}
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon", "ContinueButton", "SummaryModal"]:
		var c: Control = _n(nm) as Control
		if _vis(c):
			icons[nm] = c.get_global_rect()
	print("LAYOUT ", tag, ": ShopPanel ", _rect_str(shop.get_global_rect()), "; top info ", tops.keys())
	for nm in icons:
		var line: String = "  %s %s | ShopPanel: %s" % [nm, _rect_str(icons[nm]), _gap(icons[nm], shop.get_global_rect())]
		for t in tops:
			line += " | %s: %s" % [t, _gap(icons[nm], tops[t])]
		print(line)
	for nm in ["Hive", "Flowers", "Centrifuge", "JarCrate", "Truck"]:
		var node: Node = _n(nm)
		if node == null:
			continue
		var r: Rect2 = _prop_rect(node, cam)
		var line2: String = "  prop %s %s | ShopPanel: %s" % [nm, _rect_str(r), _gap(r, shop.get_global_rect())]
		for t in tops:
			line2 += " | %s: %s" % [t, _gap(r, tops[t])]
		for ic in icons:
			if ic != "SummaryModal":
				line2 += " | under %s: %s" % [ic, _gap(r, icons[ic])]
		print(line2)
	if icons.has("SellIcon"):
		var hive_r: Rect2 = _prop_rect(_n("Hive"), cam)
		print("  SellIcon vs hive box: icon top y %.0f, hive bottom y %.0f, %s" % [icons["SellIcon"].position.y, hive_r.end.y, _gap(icons["SellIcon"], hive_r)])
	if icons.has("ForkIcon") and tops.has("PausedLabel"):
		print("  ForkIcon top y %.0f vs PausedLabel bottom y %.0f: %s" % [icons["ForkIcon"].position.y, tops["PausedLabel"].end.y, _gap(icons["ForkIcon"], tops["PausedLabel"])])


# ---- FPS
func _fps(tag: String, seconds: float) -> void:
	var dts: Array[float] = []
	var last: int = Time.get_ticks_usec()
	var t0: int = last
	while float(Time.get_ticks_usec() - t0) < seconds * 1.0e6:
		await process_frame
		var now: int = Time.get_ticks_usec()
		dts.append(float(now - last) / 1000.0)
		last = now
	dts.sort()
	var total: float = 0.0
	var over: int = 0
	for d in dts:
		total += d
		if d > 16.7:
			over += 1
	var n: int = dts.size()
	var avg_ms: float = total / float(maxi(n, 1))
	var p99: float = dts[mini(int(float(n) * 0.99), n - 1)]
	print("FPS %s: %d frames in %.1f s, avg %.1f fps (%.2f ms), worst %.1f ms, p99 %.1f ms, frames over 16.7 ms: %d, vsync=%d, draw_calls=%d" % [
		tag, n, total / 1000.0, 1000.0 / avg_ms, avg_ms, dts[n - 1], p99, over, DisplayServer.window_get_vsync_mode(),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])


# ---- colour / contrast
func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)


func _lum(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


func _ratio(a: Color, b: Color) -> float:
	var la: float = _lum(a)
	var lb: float = _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _rgb8(c: Color) -> String:
	return "(%d, %d, %d)" % [roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0)]


func _contrast(img: Image, btn: Button, tag: String) -> void:
	var sc: Vector2 = Vector2(img.get_size()) / root.get_visible_rect().size
	var r: Rect2 = btn.get_global_rect()
	var counts: Dictionary = {}
	var px: Array[Color] = []
	for y in range(int(r.position.y * sc.y), int(r.end.y * sc.y)):
		for x in range(int(r.position.x * sc.x), int(r.end.x * sc.x)):
			var c: Color = img.get_pixel(x, y)
			px.append(c)
			var key: int = c.to_rgba32()
			counts[key] = int(counts.get(key, 0)) + 1
	var bg_key: int = 0
	var best: int = -1
	for k in counts:
		if int(counts[k]) > best:
			best = int(counts[k])
			bg_key = k
	var bg := Color.hex(bg_key)
	var ink: Color = bg
	var far: float = -1.0
	for c in px:
		var d: float = absf(_lum(c) - _lum(bg))
		if d > far:
			far = d
			ink = c
	print("CONTRAST %s: button '%s' disabled=%s rect %s; image px %d; background (most common) %s; text ink (farthest from bg) %s; ratio %.2f:1" % [tag, btn.text, str(btn.disabled), _rect_str(r), px.size(), _rgb8(bg), _rgb8(ink), _ratio(ink, bg)])
	var fc: Color = btn.get_theme_color("font_disabled_color")
	var sb: StyleBox = btn.get_theme_stylebox("disabled")
	var sbc: Color = (sb as StyleBoxFlat).bg_color if sb is StyleBoxFlat else Color(0, 0, 0, 0)
	print("  from the theme: font_disabled_color %s, disabled stylebox bg %s (%s) -> ratio %.2f:1 (alpha ignored)" % [_rgb8(fc), _rgb8(sbc), sb.get_class(), _ratio(fc, sbc)])


# ---- mouse as the OS sends it
func _w() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func _mb(vp: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp * _w()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _mm(vp: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = vp * _w()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _sample(img: Image, p: Vector2) -> Array:
	var sc: Vector2 = Vector2(img.get_size()) / root.get_visible_rect().size
	var c := Vector2i(int(p.x * sc.x), int(p.y * sc.y))
	var sum := Vector3.ZERO
	var k: int = 0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var q := img.get_pixel(c.x + dx, c.y + dy)
			sum += Vector3(q.r, q.g, q.b)
			k += 1
	var mean := Color(sum.x / k, sum.y / k, sum.z / k)
	return [img.get_pixel(c.x, c.y), mean, c]


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var eco: Node = root.get_node("Economy")
	if eco.has_method("reset"):
		eco.call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	print("window ", DisplayServer.window_get_size(), " viewport ", root.get_visible_rect().size, " root.size ", root.size)
	var cfg: Object = eco.get("config")
	var hive: Node = _n("Hive")
	var cen: Node = _n("Centrifuge")
	var truck: Node = _n("Truck")
	var fork: Button = _n("ForkIcon") as Button
	var cicon: Button = _n("CentrifugeIcon") as Button
	var cont: Button = _n("ContinueButton") as Button
	var sell: Button = _n("SellIcon") as Button
	var okb: Button = _n("SummaryOkButton") as Button
	var upg: Button = _n("UpgradeButton") as Button
	var J: int = int(cfg.get("frame_jars"))
	var CRANK: int = 2
	await _fps("farm idle (bees flying, hive filling)", 3.0)
	var img0: Image = await _shot("00-farm-start")
	_contrast(img0, upg, "disabled UpgradeButton at $0")
	hive.call("advance", float(J) * float(cfg.get("base_seconds_per_jar")), 1.0)
	await _frames(5)
	await _shot("01-farm-empty-fork")
	_layout("1 EMPTY, hive full (fork icon)")
	hive.call("advance", 100000.0, 1.0)
	await _frames(5)
	await _shot("01b-farm-paused-fork")
	_layout("1b EMPTY, hive and overflow full (PausedLabel + fork)")
	fork.pressed.emit()
	await _wait(1.2)
	var hc: Node = main.find_child("Honeycomb", true, false)
	var ccam: Camera3D = root.get_viewport().get_camera_3d()
	var cols: int = int(cfg.get("grid_cols"))
	var rows_n: int = int(cfg.get("grid_rows"))
	var cells: Array[Node3D] = []
	for c in hc.find_children("*", "CollisionObject3D", true, false):
		cells.append(c as Node3D)
	var pts: Array[Vector2] = []
	for c in cells:
		pts.append(ccam.unproject_position(c.global_position))
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	var rowsets: Array = []
	for r in rows_n:
		var row: Array[Vector2] = []
		for k in cols:
			row.append(pts[r * cols + k])
		row.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		rowsets.append(row)
	print("CLOSEUP: %d cells found, ortho=%s, camera size %.1f" % [cells.size(), str(ccam.projection == Camera3D.PROJECTION_ORTHOGONAL), ccam.size])
	await _fps("close-up before the drag (35 capped cells)", 3.0)
	var first: Vector2 = rowsets[0][0]
	_mb(first, true)
	await process_frame
	var r0: Array = rowsets[0]
	var r1: Array = rowsets[1]
	for s in range(1, r0.size() * 4 + 1):
		_mm(first.lerp(r0[r0.size() - 1], float(s) / float(r0.size() * 4)))
		await process_frame
	for s in range(1, 9):
		_mm((r0[r0.size() - 1] as Vector2).lerp(r1[r1.size() - 1], float(s) / 8.0))
		await process_frame
	for s in range(1, r1.size() * 4 + 1):
		_mm((r1[r1.size() - 1] as Vector2).lerp(r1[0], float(s) / float(r1.size() * 4)))
		await process_frame
	await _wait(1.0)
	print("MID-DRAG: Input.is_mouse_button_pressed(LEFT) = ", Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	var n_unc: int = 0
	var n_cap: int = 0
	for i in cols * rows_n:
		var st: int = int(hc.call("get_state", i))
		if st == 1:
			n_unc += 1
		elif st == 0:
			n_cap += 1
	print("MID-DRAG cell states: %d uncapped, %d capped" % [n_unc, n_cap])
	var img1: Image = await _shot("02-closeup-mid-drag")
	var unc_p: Vector2 = rowsets[0][cols / 2]
	var cap_p: Vector2 = rowsets[rows_n - 1][cols / 2]
	var su: Array = _sample(img1, unc_p)
	var sc: Array = _sample(img1, cap_p)
	print("RGB uncapped cell at %s (image px %s): centre pixel %s, 5x5 mean %s" % [str(unc_p), str(su[2]), _rgb8(su[0]), _rgb8(su[1])])
	print("RGB capped   cell at %s (image px %s): centre pixel %s, 5x5 mean %s" % [str(cap_p), str(sc[2]), _rgb8(sc[0]), _rgb8(sc[1])])
	var cu: Color = su[0]
	var cc: Color = sc[0]
	print("RGB difference (uncapped - capped), centre pixel: dR %d dG %d dB %d; Euclid distance %.1f of 441.7; luminance ratio %.2f:1" % [roundi((cu.r - cc.r) * 255.0), roundi((cu.g - cc.g) * 255.0), roundi((cu.b - cc.b) * 255.0), Vector3(cu.r - cc.r, cu.g - cc.g, cu.b - cc.b).length() * 255.0, _ratio(cu, cc)])
	await _fps("close-up mid-drag, button held", 3.0)
	_mb(r1[0], false)
	await process_frame
	for i in cols * rows_n:
		hc.call("uncap_at", i)
	await _wait(2.0)
	print("STATE after the close-up: centrifuge state ", cen.get("state"), " (1 = FULL)")
	await _shot("03-farm-full-centrifuge-icon")
	_layout("2 FULL (centrifuge icon)")
	cicon.pressed.emit()
	await _frames(5)
	await _shot("04-farm-cranking")
	_layout("3 CRANKING")
	cen.call("tap")
	cen.call("set_holding", true)
	await _fps("farm cranking (hold)", 3.0)
	var guard: int = 0
	while int(cen.get("state")) == CRANK and guard < 3000:
		await process_frame
		guard += 1
	await _frames(5)
	await _shot("05-farm-done-continue")
	_layout("4 DONE (Continue)")
	cont.pressed.emit()
	await _wait(2.0)
	await _shot("06-farm-bottling")
	_layout("5 BOTTLING")
	await _fps("farm bottling (jar growing at the spigot, truck loading)", 6.0)
	guard = 0
	while int(cen.get("state")) != 0 and guard < 10000:
		await process_frame
		guard += 1
	await _frames(5)
	await _shot("07-farm-summary")
	_layout("5b summary modal after the last jar")
	okb.pressed.emit()
	await _frames(5)
	await _shot("08-farm-sell-icon")
	_layout("6 EMPTY, truck full at home (Sell icon)")
	var sell_text: String = sell.text
	sell.pressed.emit()
	await _frames(4)
	print("SELL: icon text was '", sell_text, "', money now $", eco.get("money"), ", truck away=", truck.get("away"))
	await _fps("farm with the truck driving off", 3.0)
	await _shot("09-farm-truck-away")
	_layout("7 truck away")
	await _fps("farm, truck away, later in the trip", 3.0)
	print("DONE")
	quit()
