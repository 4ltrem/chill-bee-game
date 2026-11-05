# Quinn: windowed check that "Show UI bounds" really DRAWS (0.1.1 test; the 0.1.0 toggle test passed while nothing was drawn).
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/ui_bounds_pixels.gd
# Two frames of the farm with a full hive (fork icon floating): overlay off, overlay on (pressed through the Dev panel's button).
# For the fork icon, UpgradeButton and MoneyLabel, the top edge of the control's rect is sampled (inset 0 px, the 2 px line straddles
# it) at 24 points: at least half must differ clearly (summed channel difference > 60) between the two frames, and the on-frame must
# hold a pixel near the button colour (green) on a button's edge or near the label colour (blue) on a label's. A frame that cannot
# be read (no renderer) FAILS. Exit code 0 only if every check holds AND the last line "COMPLETED" printed.
extends SceneTree

var fails: int = 0
var checks: int = 0


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


func _img() -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _px(img: Image, vp: Vector2) -> Color:
	var k: Vector2 = Vector2(img.get_size()) / root.get_visible_rect().size
	return img.get_pixel(clampi(int(vp.x * k.x), 0, img.get_width() - 1), clampi(int(vp.y * k.y), 0, img.get_height() - 1))


func _diff(a: Color, b: Color) -> int:
	return absi(a.r8 - b.r8) + absi(a.g8 - b.g8) + absi(a.b8 - b.b8)


func _run() -> void:
	root.get_node("Economy").call("reset")
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	main.find_child("Hive", true, false).call("fill_now")
	root.get_node("Economy").get("config").set("base_seconds_per_jar", 1.0e9)
	await _frames(6)
	var panel: Node = null
	for n in root.find_children("*", "", true, false):
		var s: Variant = n.get_script()
		if s != null and (s as Script).resource_path.ends_with("dev_panel.gd"):
			panel = n
			break
	ck(panel != null, "the Dev panel exists (project dev_mode true)")
	if panel == null:
		quit(1)
		return
	var btn: Button = null
	for b in panel.find_children("*", "Button", true, false):
		if (b as Button).text.to_lower().contains("bounds"):
			btn = b as Button
	ck(btn != null, "the Show UI bounds button exists")
	if btn == null:
		quit(1)
		return
	var off: Image = await _img()
	ck(off != null and off.get_width() > 0, "a frame can be read (windowed, real renderer)")
	btn.pressed.emit()
	var on: Image = await _img()
	var targets: Dictionary = {"ForkIcon": "btn", "UpgradeButton": "btn", "MoneyLabel": "label"}
	for nm in targets:
		var c: Control = main.find_child(nm, true, false) as Control
		ck(c != null and c.is_visible_in_tree(), "%s is visible" % nm)
		if c == null or not c.is_visible_in_tree():
			continue
		var r: Rect2 = c.get_global_rect()
		var changed: int = 0
		var near_col: int = 0
		var N: int = 24
		for i in N:
			var x: float = r.position.x + r.size.x * (float(i) + 0.5) / float(N)
			var best: int = 0
			var hit_col: bool = false
			for dy in [-1.0, 0.0, 1.0]:
				var p := Vector2(x, r.position.y + dy)
				best = maxi(best, _diff(_px(off, p), _px(on, p)))
				var col: Color = _px(on, p)
				if targets[nm] == "btn" and col.g8 > 180 and col.r8 < 90 and col.b8 < 120:
					hit_col = true
				if targets[nm] == "label" and col.b8 > 200 and col.r8 < 110:
					hit_col = true
			if best > 60:
				changed += 1
			if hit_col:
				near_col += 1
		print("MEASURE ", nm, " rect ", r, ": ", changed, " of ", N, " top-edge samples changed, ", near_col, " in the overlay colour")
		ck(changed >= N / 2, "%s: the overlay drew its rect's top edge (%d of %d samples changed)" % [nm, changed, N])
		ck(near_col >= 1, "%s: an edge pixel has the overlay colour for a %s" % [nm, targets[nm]])
	btn.pressed.emit()
	var gone: Image = await _img()
	var r2: Rect2 = (main.find_child("UpgradeButton", true, false) as Control).get_global_rect()
	var still: int = 0
	for i in 24:
		var p := Vector2(r2.position.x + r2.size.x * (float(i) + 0.5) / 24.0, r2.position.y)
		if _diff(_px(off, p), _px(gone, p)) > 60:
			still += 1
	ck(still <= 2, "toggled off: the outline is gone again (%d samples still differ)" % still)
	print("---- %d checks, %d failed" % [checks, fails])
	print("COMPLETED")
	quit(1 if fails > 0 else 0)
