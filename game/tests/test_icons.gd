extends "res://tests/test_zoom2.gd"

# Quinn: icons tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

# Accessibility: icons keep a touch area of at least 120 x 120 whatever their visible size; the visible size is smaller.
func t_icon_touch_area_in_scene() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	ck(float(cv("icon_visual_px")) < 120.0, "icon_visual_px (%s) is below the 120 px touch area" % str(cv("icon_visual_px")))
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon"]:
		var c: Node = _nn(m, nm)
		if c != null and c is Control:
			var s: Vector2 = (c as Control).size
			ck(s.x >= 120.0 and s.y >= 120.0, "%s touch area at least 120 x 120 (%s)" % [nm, str(s)])
	_fin()


# L127: the icon places itself at camera.unproject_position(anchor.global_position) + screen_offset.
# Relative checks (the spec does not say whether that point is the icon's corner or its centre).
func t_icon_follows_anchor() -> void:
	var rig: Dictionary = await _mk_icon_rig(Vector3(0.0, 0.0, 0.0), true)
	var icon: Object = rig["icon"]
	var cam: Camera3D = rig["cam"]
	var marker: Marker3D = rig["marker"]
	if icon == null:
		_fin()
		return
	var p0: Vector2 = (icon as Control).global_position
	var s0: Vector2 = cam.unproject_position(marker.global_position)
	marker.position = Vector3(2.0, 0.0, -1.5)
	await _frames(3)
	var s1: Vector2 = cam.unproject_position(marker.global_position)
	var p1: Vector2 = (icon as Control).global_position
	ck(s1.distance_to(s0) > 20.0, "rig: the anchor moved on screen (%s)" % str(s1 - s0))
	near(p1.x - p0.x, s1.x - s0.x, "icon moved with the anchor in x", 1.5)
	near(p1.y - p0.y, s1.y - s0.y, "icon moved with the anchor in y", 1.5)
	icon.set("screen_offset", Vector2(0.0, -80.0))
	await _frames(3)
	var p2: Vector2 = (icon as Control).global_position
	near(p2.x - p1.x, 0.0, "screen_offset x applied", 1.5)
	near(p2.y - p1.y, -80.0, "screen_offset y applied", 1.5)
	_fin()


# L127: hides when the anchor is behind the camera.
func t_icon_hidden_behind_camera() -> void:
	var rig: Dictionary = await _mk_icon_rig(Vector3(0.0, 0.0, 0.0), false)
	var icon: Object = rig["icon"]
	var marker: Marker3D = rig["marker"]
	if icon == null:
		_fin()
		return
	ck((icon as Control).is_visible_in_tree(), "icon visible with the anchor in front of the camera")
	marker.position = Vector3(0.0, 30.0, 0.0)   # the camera sits at y = 10 looking down: this is behind it
	await _frames(3)
	ck(not (icon as Control).is_visible_in_tree(), "icon hidden with the anchor behind the camera")
	marker.position = Vector3(0.0, 0.0, 0.0)
	await _frames(3)
	ck((icon as Control).is_visible_in_tree(), "icon visible again once the anchor is back in front")
	_fin()


# ---------------------------------------------------------------- config and dev mode
