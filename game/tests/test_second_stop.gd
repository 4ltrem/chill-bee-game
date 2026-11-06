extends "res://tests/test_camera.gd"

# Quinn: second-stop input tests (0.1.3c), written from game/specs/0.1.3-next-revision.md (Clarifications 0.1.3c) and
# game/specs/0.1.3c-node-handoff.md. Every tap is a real mouse event pushed into the viewport in window pixels (farm_input.gd tap_at):
# Back (HarvestUIRoot/HarvestUI/BackButton) at the second stop, and the moved Harvest (ForkIcon) and Spin (CentrifugeIcon) icons.
# A route to the second stop with Capped cells left (so Harvest shows): fill the bucket (2 frames), the camera stays on the first zoom
# (designer: finish, then pan), tap Back; the zoom closes to the second stop because the bucket filled in it.


## Other visible controls that would take a press at `pt` before `target` does: they stop the mouse, cover the point, and are not target's ancestors.
func _stealers(m: Node, target: Control, pt: Vector2) -> Array:
	var out: Array = []
	for n in m.find_children("*", "Control", true, false):
		var c: Control = n as Control
		if c == target or not c.is_visible_in_tree() or c.mouse_filter != Control.MOUSE_FILTER_STOP or c.is_ancestor_of(target):
			continue
		if c.get_global_rect().has_point(pt):
			out.append("%s %s" % [c.name, str(c.get_global_rect())])
	return out


## The bucket filled in a zoom with frames still Capped: Back, and the zoom closes to the second stop. {m, p, tr} or {}.
func _second_stop_with_capped() -> Dictionary:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		return {}
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var cen: Node = p["Centrifuge"]
	var frames: int = int(ceil(float(_bucket_cells()) / float(_cpf())))
	for k in frames:
		var f: int = await _scrape_risen(m, p["Hive"], tr)
		ck(await _next_frame(tr, f), "frame %d done: the next frame rose" % f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	eq(cen.get("state"), _st(cen, "FULL"), "the bucket is full with Capped frames left")
	near(_cam().size, float(cv("zoom_size")), 0.05, "the camera stays on the first zoom while frames remain (finish, then pan)")
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	var reached: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(0.4)
	ck(reached, "Back with the bucket full pans to the second stop (size %s)" % str(_cam().size))
	if not reached:
		return {}
	return {"m": m, "p": p, "tr": tr}


## Back at the second stop (after every frame was finished and the camera panned): a real tap on BackButton, which nothing else covers.
func t_second_stop_back_tap() -> void:
	var s: Dictionary = await _go_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var back: Control = (s["p"] as Dictionary)["BackButton"]
	ck(_shown(back), "BackButton shows at the second stop")
	var r: Rect2 = back.get_global_rect()
	ck(_vp().encloses(r) and r.size.y >= 120.0, "BackButton is on screen and at least 120 px high (%s)" % str(r))
	eq(_stealers(m, back, r.get_center()), [], "no other control takes a press at BackButton's centre")
	var probe := Button.new()
	probe.name = "ProbeCover"
	probe.size = Vector2(40.0, 40.0)
	probe.position = r.get_center() - Vector2(20.0, 20.0)
	(m.find_child("HarvestUI", true, false) as Node).add_child(probe)
	ck(_stealers(m, back, r.get_center()).size() >= 1, "self-check: a control over BackButton is reported")
	probe.queue_free()
	await _frames(2)
	eq(bool(m.call("at_second_stop")), true, "at_second_stop is true before the tap")
	await fi.tap_at(r.get_center())
	await _wait(_zoom_settle() + float(cv("zoom_seconds")) + float(cv("camera_pan_seconds")))
	eq(bool(m.call("at_second_stop")), false, "a real tap on Back leaves the second stop")
	ck(_cam().size > float(cv("pan_zoom_size")) + 0.5, "the camera is back on the farm view (size %.3f)" % _cam().size)
	ck(not _shown(back), "BackButton hides again")
	_fin()


## Spin at the second stop: left of the centrifuge, on screen, untouched by other controls; a real tap starts the crank.
func t_second_stop_spin_icon_tap() -> void:
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var spin: Control = p["CentrifugeIcon"]
	var cen: Node = p["Centrifuge"]
	ck(_shown(spin), "Spin shows at the second stop (bucket FULL)")
	var r: Rect2 = spin.get_global_rect()
	ck(_vp().encloses(r), "Spin is wholly on screen (%s)" % str(r))
	var cen_rect: Rect2 = _screen_of(_obbs(cen), _cam())
	ck(r.get_center().x < cen_rect.position.x, "Spin sits left of the centrifuge (icon x %.0f, centrifuge from x %.0f)" % [r.get_center().x, cen_rect.position.x])
	eq(_overlap_area(r, cen_rect) < 1.0, true, "Spin does not cover the centrifuge")
	eq(_stealers(m, spin, r.get_center()), [], "no other control takes a press at Spin's centre")
	await fi.tap_at(r.get_center())
	await _frames(3)
	eq(cen.get("state"), _st(cen, "CRANKING"), "a real tap on Spin at the second stop starts the crank")
	_fin()


## Harvest (ForkIcon) at the second stop: below the hive, on screen, untouched; a real tap opens the zoom again from there.
func t_second_stop_fork_icon_tap() -> void:
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var tr: Dictionary = s["tr"]
	var fork: Control = p["ForkIcon"]
	ck(_shown(fork), "Harvest shows at the second stop (Capped frames remain)")
	var r: Rect2 = fork.get_global_rect()
	ck(_vp().encloses(r), "Harvest is wholly on screen (%s)" % str(r))
	var hive_rect: Rect2 = _screen_of(_obbs(p["Hive"] as Node), _cam()).intersection(_vp())
	var cen_rect: Rect2 = _screen_of(_obbs(p["Centrifuge"] as Node), _cam())
	ck(r.get_center().y > hive_rect.end.y, "Harvest sits below the hive (icon y %.0f, hive bottom %.0f)" % [r.get_center().y, hive_rect.end.y])
	eq(_overlap_area(r, hive_rect) < 1.0 and _overlap_area(r, cen_rect) < 1.0, true, "Harvest covers neither the hive nor the centrifuge")
	eq(_stealers(m, fork, r.get_center()), [], "no other control takes a press at Harvest's centre")
	tr["risen"] = -1
	await fi.tap_at(r.get_center())
	var raised: bool = await _until(func() -> bool: return int(tr["risen"]) >= 0, 3.0)
	ck(raised, "a real tap on Harvest at the second stop opens the zoom (a frame rises)")
	await _wait(_zoom_settle())
	near(_cam().size, float(cv("zoom_size")), 0.05, "the camera went back to the first zoom")
	eq(bool(m.call("at_second_stop")), false, "the second stop is left")
	_fin()


# ---------------------------------------------------------------- icons never overlap (0.1.3c, "Icons anchored in the game world")

## Every FloatingIcon of the scene (Fork, Spin, Sell), visible or not.
func _icon_nodes(m: Node) -> Array:
	var out: Array = []
	for n in m.find_children("*", "Button", true, false):
		if n is FloatingIcon:
			out.append(n)
	return out


## One camera state: visible icons >= 120 x 120, no two touch rects intersect, none meets TopInfo or ShopPanel; at the second stop
## none meets the hive's or the centrifuge's screen rect. Returns the visible icon count.
func _icons_state(m: Node, p: Dictionary, label: String, second: bool) -> int:
	await _frames(3)
	var vis: Array = []
	for ic in _icon_nodes(m):
		if (ic as Control).is_visible_in_tree():
			vis.append(ic)
	var hud: Array = []
	for nm in ["TopInfo", "ShopPanel"]:
		var c: Control = m.find_child(nm, true, false) as Control
		ck(c != null, "%s: %s exists" % [label, nm])
		if c != null and c.is_visible_in_tree():
			hud.append(c)
	var world: Array = []
	if second:
		world.append(["hive", _screen_of(_obbs(p["Hive"] as Node), _cam()).intersection(_vp())])
		world.append(["centrifuge", _screen_of(_obbs(p["Centrifuge"] as Node), _cam())])
	for i in vis.size():
		var a: Control = vis[i]
		var ra: Rect2 = a.get_global_rect()
		ck(ra.size.x >= 120.0 and ra.size.y >= 120.0, "%s: %s touch rect is at least 120 x 120 (%s)" % [label, a.name, str(ra.size)])
		for j in range(i + 1, vis.size()):
			var b: Control = vis[j]
			eq(ra.intersects(b.get_global_rect()), false, "%s: %s and %s touch rects do not intersect (%s, %s)" % [label, a.name, b.name, str(ra), str(b.get_global_rect())])
		for h in hud:
			eq(ra.intersects((h as Control).get_global_rect()), false, "%s: %s does not meet %s (%s, %s)" % [label, a.name, h.name, str(ra), str((h as Control).get_global_rect())])
		for w in world:
			eq(ra.intersects(w[1] as Rect2), false, "%s: %s does not meet the %s (%s, %s)" % [label, a.name, w[0], str(ra), str(w[1])])
	# every icon, shown or not: place each on its anchor and compare all pairs (an icon hidden by the state table still must not share a spot)
	var all_icons: Array = _icon_nodes(m)
	var rects: Array = []
	for ic in all_icons:
		var fic: FloatingIcon = ic
		var placed: bool = fic.place()
		rects.append(fic.get_global_rect() if placed else Rect2())
		ck(placed or fic.use_fixed_center == false, "%s: %s placed (anchor in front of the camera)" % [label, fic.name])
	for i in all_icons.size():
		for j in range(i + 1, all_icons.size()):
			if (rects[i] as Rect2).size != Vector2.ZERO and (rects[j] as Rect2).size != Vector2.ZERO:
				eq((rects[i] as Rect2).intersects(rects[j] as Rect2), false, "%s: all icons: %s and %s anchored apart (%s, %s)" % [label, all_icons[i].name, all_icons[j].name, str(rects[i]), str(rects[j])])
	return vis.size()


## Icons are placed only by their 3D anchors: every FloatingIcon has screen_offset (0, 0); in each camera state the visible icons
## stay clear of one another, of TopInfo and ShopPanel, and at the second stop of the hive and the centrifuge.
func t_icons_never_overlap() -> void:
	# self-check: the intersection test reports an overlap
	ck(Rect2(0, 0, 120, 120).intersects(Rect2(60, 60, 120, 120)), "self-check: overlapping rects are reported")
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var icons: Array = _icon_nodes(m)
	eq(icons.size(), 3, "the scene has three FloatingIcons (Fork, Spin, Sell)")
	for ic in icons:
		eq((ic as FloatingIcon).screen_offset, Vector2.ZERO, "%s: screen_offset is (0, 0)" % ic.name)
	var tr: Dictionary = _track(p["Hive"])
	_full_hive_frozen(p["Hive"])
	await _frames(4)
	var n_farm: int = await _icons_state(m, p, "farm view", false)
	ck(n_farm >= 1, "farm view: at least one icon shows with the hive full (%d)" % n_farm)
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "the zoom opened with a risen frame")
	if not raised:
		_fin()
		return
	await _wait(_zoom_settle())
	var n_zoom: int = await _icons_state(m, p, "first zoom", false)
	# on to the second stop: finish every frame, then Back (as _second_stop_with_capped does)
	var frames: int = int(ceil(float(_bucket_cells()) / float(_cpf())))
	for k in frames:
		var f: int = await _scrape_risen(m, p["Hive"], tr)
		ck(await _next_frame(tr, f), "frame %d done: the next frame rose" % f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	var reached: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(0.4)
	ck(reached, "the second stop was reached (size %s)" % str(_cam().size))
	if reached:
		var n_second: int = await _icons_state(m, p, "second stop", true)
		ck(n_second >= 1, "second stop: at least one icon shows (%d)" % n_second)
	ck(n_zoom >= 0, "first zoom measured")
	_fin()
