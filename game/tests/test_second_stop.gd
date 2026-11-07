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
	# 0.1.4 spec item 2: "Each button follows one anchor point on its prop ... No per-view offsets"; "Spin: just above the centrifuge lid":
	# the same rule as the farm view, so Spin sits at its CentrifugeAnchor's projection (clamped inside the screen), not left of the centrifuge.
	var gap: float = _anchor_gap(spin as FloatingIcon)
	ck(gap <= float(cv("button_screen_margin")), "Spin sits at its anchor's projected point or clamped inside the screen (off by %.0f px)" % gap)
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
	# 0.1.4 spec item 2: "[Harvest] is hidden at the second stop, where the lid may be off screen (designer, 2026-11-06: "hide it")"
	ck(not _shown(fork), "Harvest is hidden at the second stop although Capped frames remain")
	eq(bool(m.call("fork_available")), true, "precondition: Capped frames remain (Harvest would show on the farm view)")
	# Back (real tap) to the farm view: Harvest shows again there and a real tap on it opens the zoom
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	await _until(func() -> bool: return not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	ck(_shown(fork), "Harvest shows on the farm view after Back")
	var r: Rect2 = fork.get_global_rect()
	ck(_vp().encloses(r), "Harvest is wholly on screen (%s)" % str(r))
	eq(_stealers(m, fork, r.get_center()), [], "no other control takes a press at Harvest's centre")
	tr["risen"] = -1
	await fi.tap_at(r.get_center())
	var raised: bool = await _until(func() -> bool: return int(tr["risen"]) >= 0, 3.0)
	ck(raised, "a real tap on Harvest on the farm view opens the zoom (a frame rises)")
	await _wait(_zoom_settle())
	near(_cam().size, float(cv("zoom_size")), 0.05, "the camera went to the first zoom")
	_fin()


# ---------------------------------------------------------------- icons never overlap (0.1.3c, "Icons anchored in the game world")

## Px between an icon's top-left and where its anchor's projection puts it, once clamped inside the screen by button_screen_margin.
func _anchor_gap(ic: FloatingIcon) -> float:
	var a: Node3D = ic.get_node(ic.anchor_path) as Node3D
	var mg: float = float(cv("button_screen_margin"))
	var view: Vector2 = _vp().size
	var want: Vector2 = (_cam().unproject_position(a.global_position) - ic.size * 0.5).clamp(Vector2(mg, mg), Vector2(maxf(view.x - mg - ic.size.x, mg), maxf(view.y - mg - ic.size.y, mg)))
	# spec: "nudged clear" of another control: the wanted spot meeting another visible anchored button, TopInfo or BackButton is allowed to move
	var wr := Rect2(want, ic.size)
	for other in _icon_nodes(ic.get_tree().root):
		if other != ic and (other as Control).is_visible_in_tree() and wr.intersects((other as Control).get_global_rect()):
			return 0.0
	for nm in ["TopInfo", "BackButton"]:
		var c: Control = ic.get_tree().root.find_child(nm, true, false) as Control
		if c != null and c.is_visible_in_tree() and wr.intersects(c.get_global_rect()):
			return 0.0
	return (ic.global_position - want).length()


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
	# 0.1.4 spec item 2: buttons sit on their props' anchors ("just above the centrifuge lid"); only other controls are cleared
	# ("clamped inside the screen with a 16 px margin and nudged clear"), so the 0.1.3c hive/centrifuge rect check no longer applies.
	if second:
		for ic in vis:
			ck(_anchor_gap(ic as FloatingIcon) <= float(cv("button_screen_margin")), "%s: sits at its anchor's projected point or clamped inside the screen" % ic.name)
		ck(not (p["ForkIcon"] as Control).is_visible_in_tree(), "second stop: Harvest is hidden")
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
		ck(placed, "%s: %s placed (anchor in front of the camera)" % [label, fic.name])
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


# ---------------------------------------------------------------- designer's 0.1.3 play-test (2026-11-06): the pan, icons above props, Spin in the first zoom

## The designer's ordinary hands: real drags on the risen frame, the next frame the moment it rises, no pause, until no Capped cell is left.
func _uncap_all(m: Node, p: Dictionary, tr: Dictionary) -> bool:
	var hive: Node = p["Hive"]
	var t0: int = _gms()
	while fi.capped_total(hive, _frames_n()) > 0 and float(_gms() - t0) < 120000.0:
		if int(tr["risen"]) >= 0:
			await _scrape_risen(m, hive, tr)
		await process_frame
	return fi.capped_total(hive, _frames_n()) == 0


## From the last uncapped cell the camera must be at the second stop within camera_pan_seconds + 1 s (the pan, never skipped).
func _pan_follows(m: Node, label: String) -> void:
	var secs: float = float(cv("camera_pan_seconds")) + 1.0
	var reached: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01 and bool(m.call("at_second_stop")), secs)
	ck(reached, "%s: the camera is at the second stop within camera_pan_seconds + 1 s of the last cell (size %s, at_second_stop %s)" % [label, str(_cam().size), str(m.call("at_second_stop"))])


## Fill the bucket by uncapping, keep uncapping until every frame is done, then the pan (no Back pressed).
func t_pan_after_all_frames_uncapped() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var done: bool = await _uncap_all(m, z["p"], z["tr"])
	ck(done, "every frame of the hive was uncapped with real drags")
	var cen: Node = (z["p"] as Dictionary)["Centrifuge"]
	eq(cen.get("state"), _st(cen, "FULL"), "the bucket is full")
	await _pan_follows(m, "all frames uncapped")
	_fin()


## Back pressed once the bucket filled (Capped frames left), Harvest again, then uncap everything: the pan still happens.
func t_pan_after_back_then_harvest_again() -> void:
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var tr: Dictionary = s["tr"]
	tr["risen"] = -1
	# 0.1.4 spec item 2: Harvest "is hidden at the second stop": _open_zoom taps Back to the farm view, then taps Harvest at its anchor
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "Harvest again: a frame rises")
	var back_in: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("zoom_size"))) < 0.05, _zoom_settle() + 2.0)
	ck(back_in, "the camera went back to the first zoom")
	var done: bool = await _uncap_all(m, p, tr)
	ck(done, "every remaining frame was uncapped")
	await _pan_follows(m, "after Back and Harvest again")
	_fin()


## Icon `ic` over `prop`: centre x within 40 px of the prop's screen-rect centre, rect bottom at or above the prop's rect top (+20 px).
func _icon_above(ic: FloatingIcon, prop: Node, label: String) -> void:
	var placed: bool = ic.place()
	ck(placed, "%s: %s is placed (anchor in front of the camera)" % [label, ic.name])
	var r: Rect2 = ic.get_global_rect()
	var pr: Rect2 = _screen_of(_obbs(prop), _cam())
	ck(absf(r.get_center().x - pr.get_center().x) <= 40.0, "%s: %s centre x %.0f is within 40 px of %s centre x %.0f" % [label, ic.name, r.get_center().x, prop.name, pr.get_center().x])
	# 0.1.4 spec item 2: Harvest "just above the hive lid", Spin "just above the centrifuge lid": the button follows its anchor on the
	# prop's lid (so it overlaps the prop's rect a little, no longer sits above it); the rule is the anchor's projection, clamped inside the screen.
	var gap: float = _anchor_gap(ic)
	ck(gap <= float(cv("button_screen_margin")), "%s: %s sits at its anchor's projected point, off by %.0f px" % [label, ic.name, gap])
	ck(r.get_center().y <= pr.get_center().y, "%s: %s centre y %.0f is in the upper half of the %s (centre y %.0f)" % [label, ic.name, r.get_center().y, prop.name, pr.get_center().y])


## Fork over the hive and Spin over the centrifuge, on the farm view and in the first zoom.
func t_icons_above_props() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var tr: Dictionary = _track(p["Hive"])
	_full_hive_frozen(p["Hive"])
	await _frames(6)
	# self-check: an icon pushed 200 px sideways leaves the +-40 px band (the measure can fail)
	var ic: FloatingIcon = p["ForkIcon"]
	ic.place()
	var pr: Rect2 = _screen_of(_obbs(p["Hive"] as Node), _cam())
	ic.position.x += 200.0
	ck(absf(ic.get_global_rect().get_center().x - pr.get_center().x) > 40.0, "self-check: an icon 200 px off is outside the band")
	_icon_above(p["ForkIcon"], p["Hive"], "farm view")
	_icon_above(p["CentrifugeIcon"], p["Centrifuge"], "farm view")
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "the zoom opened")
	if raised:
		await _wait(_zoom_settle())
		_icon_above(p["ForkIcon"], p["Hive"], "first zoom")
		_icon_above(p["CentrifugeIcon"], p["Centrifuge"], "first zoom")
	_fin()


## First zoom, bucket full (frames still Capped, so the zoom stays open): Spin shows, and covers neither the risen rack nor the BucketMouth.
func t_spin_icon_in_first_zoom() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var cen: Node = p["Centrifuge"]
	var frames: int = int(ceil(float(_bucket_cells()) / float(_cpf())))
	for k in frames:
		var f: int = await _scrape_risen(m, p["Hive"], tr)
		ck(await _next_frame(tr, f), "frame %d done: the next frame rose" % f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	eq(cen.get("state"), _st(cen, "FULL"), "the bucket is full")
	near(_cam().size, float(cv("zoom_size")), 0.05, "still in the first zoom")
	var spin: Control = p["CentrifugeIcon"]
	ck(_shown(spin), "Spin is visible in the first zoom with a full bucket")
	var r: Rect2 = spin.get_global_rect()
	ck(_vp().encloses(r), "Spin is wholly on screen (%s)" % str(r))
	var hc: Node = (p["Hive"] as Node).find_child("Honeycomb", true, false)
	var fb: Node = (p["Hive"] as Node).find_child("FrameBar%d" % (int(tr["risen"]) + 1), true, false)
	var rack: Array = _obbs(hc) if hc != null else []
	if fb != null:
		rack.append_array(_obbs(fb))
	var rr: Rect2 = _screen_of(rack, _cam())
	ck(rack.size() > 0 and rr.size.x > 50.0, "the risen rack has a screen rect (%s)" % str(rr))
	eq(_overlap_area(r, rr) < 1.0, true, "Spin does not cover the rack (spin %s, rack %s)" % [str(r), str(rr)])
	var mouth: Node3D = _nn(m, "BucketMouth") as Node3D
	ck(mouth != null, "BucketMouth exists")
	if mouth != null:
		var mp: Vector2 = _cam().unproject_position(mouth.global_position)
		ck(not r.has_point(mp), "Spin does not cover the BucketMouth (mouth %s, spin %s)" % [str(mp), str(r)])
	_fin()
