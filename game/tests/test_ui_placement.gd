extends "res://tests/test_replay.gd"

# Quinn: 0.1.4 item 2 tests, written from game/specs/0.1.4-ui-placement.md (item 2) and game/specs/0.1.4-node-handoff.md, not from the code.
# T2.1: no two HUD controls overlap and none is cut off by the screen edge, in the farm view, the first zoom and the second stop.
# T2.2: Harvest (ForkIcon), Spin (CentrifugeIcon) and Sell (SellIcon) sit within button_screen_margin of their anchor's projected point,
# or are clamped inside the screen; the same offset in every view; Harvest is hidden at the second stop. Spin is placed by the scene.

const _ICON_NAMES: Array[String] = ["ForkIcon", "CentrifugeIcon", "SellIcon"]


## The HUD controls on screen now: visible anchored buttons, BackButton, TopInfo, ShopPanel, HiveCountLabel, HintLabel (DevSpeedTag is a child of TopInfo, so TopInfo's rect covers it).
## Returns [[name, Rect2], ...] (a control with no size, or a label with no text, is not a HUD control).
func _hud_rects(m: Node) -> Array:
	var out: Array = []
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon", "BackButton", "TopInfo", "ShopPanel", "HiveCountLabel", "HintLabel"]:
		var c: Control = m.find_child(nm, true, false) as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if c is Label and (c as Label).text.strip_edges() == "":
			continue
		var r: Rect2 = c.get_global_rect()
		if r.size.x > 0.0 and r.size.y > 0.0:
			out.append([nm, r])
	return out


## Pairs allowed to touch or overlap. The count label sits on the Harvest button by design: the designer kept the 4 px gap
## (Design Votes round 8, C1 count gap: "these are all the same"; ref chosen), so this pair is not an overlap failure.
const _ALLOWED_PAIRS: Array = [["HiveCountLabel", "ForkIcon"]]


func _pair_allowed(a: String, b: String) -> bool:
	for pr in _ALLOWED_PAIRS:
		if (pr[0] == a and pr[1] == b) or (pr[0] == b and pr[1] == a):
			return true
	return false


## Strings naming each overlapping pair and each rect not wholly inside the viewport `view`.
func _hud_violations(rects: Array, view: Rect2) -> Array:
	var bad: Array = []
	for i in rects.size():
		var ra: Rect2 = rects[i][1]
		if not view.encloses(ra):
			bad.append("%s is cut off by the screen edge %s" % [rects[i][0], str(ra)])
		for j in range(i + 1, rects.size()):
			var rb: Rect2 = rects[j][1]
			if ra.intersects(rb) and not _pair_allowed(rects[i][0], rects[j][0]):
				bad.append("%s %s overlaps %s %s" % [rects[i][0], str(ra), rects[j][0], str(rb)])
	return bad


## Run `visit(m, p, label)` in the farm view (full hive), the first zoom and the second stop (as t_icons_never_overlap travels).
func _walk_views(visit: Callable) -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		return
	var tr: Dictionary = _track(p["Hive"])
	_full_hive_frozen(p["Hive"])
	await _frames(6)
	await visit.call(m, p, "farm view")
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "the zoom opened with a risen frame")
	if not raised:
		return
	await _wait(_zoom_settle())
	await visit.call(m, p, "first zoom")
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
		await visit.call(m, p, "second stop")


## T2.1: in each view no two HUD controls overlap and none is cut off by the screen edge.
func t_hud_no_overlap_no_cutoff() -> void:
	# self-checks: the helper reports an overlap and an edge cut-off (it can fail)
	var view := Rect2(Vector2.ZERO, Vector2(1080.0, 1920.0))
	ck(_hud_violations([["A", Rect2(0, 0, 100, 100)], ["B", Rect2(50, 50, 100, 100)]], view).size() == 1, "self-check: two overlapping rects are reported")
	ck(_hud_violations([["A", Rect2(1000, 0, 100, 100)]], view).size() == 1, "self-check: a rect past the screen edge is reported")
	ck(_hud_violations([["A", Rect2(0, 0, 100, 100)], ["B", Rect2(100, 0, 100, 100)]], view).is_empty(), "self-check: touching, clear rects are not reported")
	ck(_hud_violations([["HiveCountLabel", Rect2(0, 0, 100, 100)], ["ForkIcon", Rect2(50, 50, 100, 100)]], view).is_empty(), "self-check: the allowed count/Harvest pair is not reported")
	ck(_hud_violations([["HiveCountLabel", Rect2(0, 0, 100, 100)], ["SellIcon", Rect2(50, 50, 100, 100)]], view).size() == 1, "self-check: the count label over another button is still reported")
	var seen: Array = [0]
	await _walk_views(func(m: Node, _p: Dictionary, label: String) -> void:
		await _frames(3)
		var rects: Array = _hud_rects(m)
		seen[0] += rects.size()
		ck(rects.size() >= 2, "%s: at least two HUD controls are on screen (%d)" % [label, rects.size()])
		eq(_hud_violations(rects, _vp()), [], "%s: no HUD controls overlap and none is cut off" % label))
	ck(int(seen[0]) >= 6, "HUD controls were measured in every view (%d)" % int(seen[0]))
	_fin()


## Px between an icon's rect centre and its target (the anchor's projection plus its config offset).
func _centre_gap(ic: FloatingIcon) -> float:
	return (ic.get_global_rect().get_center() - _icon_target(ic)).length()


## True when the rect lies inside the viewport shrunk by button_screen_margin (1 px tolerance).
func _inside_margin(r: Rect2) -> bool:
	var mg: float = float(cv("button_screen_margin")) - 1.0
	return _vp().grow(-mg).encloses(r)


## T2.2: each visible button is within button_screen_margin of its anchor's projection, or clamped inside the screen (nudged clear of
## another control only when the wanted spot meets one); Spin keeps the same offset from its anchor in every view (no per-view offsets).
func t_buttons_at_anchor_or_clamped() -> void:
	var deltas: Dictionary = {}   # icon name -> {label: Vector2 centre - projection} for the buttons sitting at their wanted spot
	var shown: Array = [0]
	await _walk_views(func(m: Node, p: Dictionary, label: String) -> void:
		await _frames(3)
		for nm in _ICON_NAMES:
			var ic: FloatingIcon = p[nm]
			if not ic.is_visible_in_tree():
				continue
			shown[0] += 1
			var r: Rect2 = ic.get_global_rect()
			var proj: Vector2 = _icon_target(ic)
			var gap: float = _centre_gap(ic)
			var mg: float = float(cv("button_screen_margin"))
			if gap <= mg:
				if not deltas.has(nm):
					deltas[nm] = {}
				deltas[nm][label] = r.get_center() - proj
				ck(true, "%s: %s is %.0f px from its anchor's projected point" % [label, nm, gap])
			else:
				var want: Vector2 = (proj - r.size * 0.5).clamp(Vector2(mg, mg), Vector2(maxf(_vp().size.x - mg - r.size.x, mg), maxf(_vp().size.y - mg - r.size.y, mg)))
				var clamped_here: bool = (r.position - want).length() <= mg
				var nudged: bool = false
				for other in _hud_rects(m):
					if other[0] != nm and Rect2(want, r.size).intersects(other[1] as Rect2):
						nudged = true
				ck(clamped_here or nudged, "%s: %s is %.0f px from its anchor but neither clamped inside the screen nor nudged clear (rect %s, wanted %s)" % [label, nm, gap, str(r), str(want)])
				ck(_inside_margin(r), "%s: %s keeps the screen margin when moved (%s)" % [label, nm, str(r)]))
	ck(int(shown[0]) >= 2, "buttons were measured (%d)" % int(shown[0]))
	# no per-view offsets: a button at its wanted spot keeps the same centre-to-projection vector in every view it shows in
	for nm in deltas:
		var labels: Array = (deltas[nm] as Dictionary).keys()
		for i in range(1, labels.size()):
			var d0: Vector2 = deltas[nm][labels[0]]
			var di: Vector2 = deltas[nm][labels[i]]
			ck((d0 - di).length() <= 1.5, "%s: the same offset from its anchor in %s and %s (%s, %s)" % [nm, labels[0], labels[i], str(d0), str(di)])
	_fin()


## T2.2: whatever the camera does, a button whose anchor projects off screen is clamped inside the screen with button_screen_margin.
func t_buttons_clamped_when_anchor_off_screen() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	_full_hive_frozen(p["Hive"])
	await _frames(6)
	var cam: Camera3D = _cam()
	var dirs: Array = [["right", cam.global_transform.basis.x], ["left", -cam.global_transform.basis.x], ["up", cam.global_transform.basis.y], ["down", -cam.global_transform.basis.y]]
	# self-check: the helper rejects a rect on the screen edge
	ck(not _inside_margin(Rect2(0, 0, 100, 100)), "self-check: a rect at the screen edge is outside the margin")
	for nm in _ICON_NAMES:
		var ic: FloatingIcon = p[nm]
		var a: Node3D = ic.get_node(ic.anchor_path) as Node3D
		var home: Vector3 = a.global_position
		for d in dirs:
			a.global_position = home + (d[1] as Vector3) * 60.0
			var placed: bool = ic.place()
			if placed:
				var r: Rect2 = ic.get_global_rect()
				ck(_inside_margin(r), "%s: anchor 60 units %s of the view: the button is clamped inside the screen with the margin (%s)" % [nm, d[0], str(r)])
				ck(_vp().encloses(r), "%s: anchor %s: the button is not cut off (%s)" % [nm, d[0], str(r)])
			else:
				ck(false, "%s: anchor %s of the view but in front of the camera: place() returned false" % [nm, d[0]])
		a.global_position = home
	_fin()


## T2.2: Harvest is hidden at the second stop (Capped frames remain), shown on the farm view after Back, and hidden again there.
func t_harvest_hidden_at_second_stop() -> void:
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var fork: Control = p["ForkIcon"]
	eq(bool(m.call("at_second_stop")), true, "precondition: at the second stop")
	eq(bool(m.call("fork_available")), true, "precondition: Capped frames remain, so Harvest would show elsewhere")
	for i in 5:
		await _frames(4)
		ck(not fork.is_visible_in_tree(), "Harvest stays hidden at the second stop (check %d)" % (i + 1))
	ck((p["CentrifugeIcon"] as Control).is_visible_in_tree(), "self-check: Spin still shows at the second stop, so only Harvest is hidden")
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	await _until(func() -> bool: return not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	ck(fork.is_visible_in_tree(), "Harvest shows on the farm view after Back")
	_fin()


## Spin is placed by the scene (spec: "today's runtime move of Spin out of FarmUI by main.gd goes away, because the scene places it"):
## in main.tscn CentrifugeIcon is a child of FarmUIRoot, not FarmUI; ForkIcon and SellIcon stay under FarmUI; none has a screen offset.
func t_spin_placed_by_scene() -> void:
	var ps: PackedScene = load("res://scenes/main.tscn") as PackedScene
	ck(ps != null, "main.tscn loads")
	if ps == null:
		_fin()
		return
	var st: SceneState = ps.get_state()
	var parents: Dictionary = {}
	var offs: Dictionary = {}
	for i in st.get_node_count():
		var nm: String = String(st.get_node_name(i))
		if _ICON_NAMES.has(nm):
			parents[nm] = str(st.get_node_path(i)).trim_prefix("./")
			for k in st.get_node_property_count(i):
				if st.get_node_property_name(i, k) == "screen_offset":
					offs[nm] = st.get_node_property_value(i, k)
	eq(parents.get("CentrifugeIcon", ""), "FarmUIRoot/CentrifugeIcon", "Spin is declared as a child of FarmUIRoot in main.tscn")
	eq(parents.get("ForkIcon", ""), "FarmUIRoot/FarmUI/ForkIcon", "Harvest stays under FarmUI in main.tscn")
	eq(parents.get("SellIcon", ""), "FarmUIRoot/FarmUI/SellIcon", "Sell stays under FarmUI in main.tscn")
	for nm in _ICON_NAMES:
		eq(offs.get(nm, Vector2.ZERO), Vector2.ZERO, "%s: no per-view screen offset in main.tscn" % nm)
	# live: the instance has Spin under FarmUIRoot from the first frame the scene is ready
	var m: Node = await _mk_main()
	if m != null:
		var spin: Node = m.find_child("CentrifugeIcon", true, false)
		ck(spin != null and spin.get_parent().name == "FarmUIRoot", "live: Spin's parent is FarmUIRoot")
	_fin()


# ---- 0.1.4 items 3, 4, 8 (written from game/specs/0.1.4-ui-placement.md and 0.1.4-node-handoff.md, not from the code) ----
# T.1: Back has the same screen rect in the first zoom and at the second stop. T.2: Back is in the top-right quadrant; the speed tag sits
# below the money and bees labels without touching them. T8.1: HintLabel lies wholly below Back and does not touch it, in both views.

## Back's and HintLabel's global rects in the first zoom and at the second stop: {view: {"back": Rect2, "hint": Rect2}}.
func _back_hint_rects() -> Dictionary:
	var got: Dictionary = {}
	await _walk_views(func(m: Node, _p: Dictionary, label: String) -> void:
		if label == "farm view":
			return
		await _frames(3)
		var b: Control = m.find_child("BackButton", true, false) as Control
		var h: Label = m.find_child("HintLabel", true, false) as Label
		ck(b != null and b.is_visible_in_tree(), "%s: Back is visible" % label)
		if label == "first zoom":
			ck(h != null and h.is_visible_in_tree() and h.text.strip_edges() != "", "%s: the instruction text is visible and has text" % label)
		# at the second stop harvest_ui.gd may hide HintLabel; its rect must still lie below Back (the spec names both views), so it is measured anyway
		if b != null and h != null:
			got[label] = {"back": b.get_global_rect(), "hint": h.get_global_rect()})
	return got


## True when `a` ends above `b` with a gap (no touching): a.bottom < b.top.
func _wholly_above(a: Rect2, b: Rect2) -> bool:
	return a.end.y < b.position.y


func t_back_fixed_top_right() -> void:
	ck(not _wholly_above(Rect2(0, 0, 10, 10), Rect2(0, 10, 10, 10)), "self-check: touching rects are not 'wholly above'")
	ck(_wholly_above(Rect2(0, 0, 10, 10), Rect2(0, 11, 10, 10)), "self-check: a gap counts as wholly above")
	var got: Dictionary = await _back_hint_rects()
	ck(got.has("first zoom") and got.has("second stop"), "Back was measured in both views (%s)" % str(got.keys()))
	if not (got.has("first zoom") and got.has("second stop")):
		_fin()
		return
	var r1: Rect2 = got["first zoom"]["back"]
	var r2: Rect2 = got["second stop"]["back"]
	ck(r1.position.distance_to(r2.position) <= 0.5 and r1.size.distance_to(r2.size) <= 0.5, "T.1: Back's rect is the same in the first zoom %s and at the second stop %s" % [str(r1), str(r2)])
	var vp: Rect2 = _vp()
	for k in ["first zoom", "second stop"]:
		var r: Rect2 = got[k]["back"]
		var c: Vector2 = r.get_center()
		ck(c.x > vp.size.x * 0.5 and c.y < vp.size.y * 0.5, "T.2: %s: Back's centre %s is in the top-right quadrant of %s" % [k, str(c), str(vp.size)])
		ck(vp.encloses(r), "T.2: %s: Back is wholly on screen %s" % [k, str(r)])
		var h: Rect2 = got[k]["hint"]
		ck(_wholly_above(r, h), "T8.1: %s: the instruction text %s lies wholly below Back %s and does not touch it" % [k, str(h), str(r)])
	_fin()


## T.2: the speed tag (shown by the Dev speed row) sits under the money and bees labels, not touching them.
func t_speed_tag_below_labels() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	await _frames(6)
	var tag: Label = m.find_child("DevSpeedTag", true, false) as Label
	var money: Control = m.find_child("MoneyLabel", true, false) as Control
	var bees: Control = m.find_child("BeeCountLabel", true, false) as Control
	ck(tag != null and money != null and bees != null, "the tag, money and bees labels exist")
	if tag == null or money == null or bees == null:
		_fin()
		return
	tag.text = "x5"
	tag.visible = true
	await _frames(6)
	ck(tag.is_visible_in_tree(), "the tag is visible once shown")
	var rt: Rect2 = tag.get_global_rect()
	for nm in [money, bees]:
		var r: Rect2 = (nm as Control).get_global_rect()
		ck(rt.position.y >= r.end.y, "T.2: the speed tag %s is below %s %s" % [str(rt), nm.name, str(r)])
		ck(not rt.intersects(r), "T.2: the speed tag does not touch %s" % nm.name)
	ck(rt.size.x > 0.0 and rt.size.y > 0.0, "the tag has a size %s" % str(rt.size))
	_fin()
