extends "res://tests/test_zoom_end.gd"

# Quinn: 0.2 item 15 (Shop stays available in both zooms), written from game/specs/0.2-first-automation.md before the code.
# Every tap is a real mouse event in window pixels (farm_input.gd); every price and name comes from the config / the scene.
# Shared steps live here once: _zs_buy (open, buy, close), _zs_clear (Shop clear of the other controls), _zs_leave (an exit with the sheet open).


func _zs_btn(m: Node) -> Control:
	return m.find_child("ShopButton", true, false) as Control


func _zs_panel(m: Node) -> Control:
	return m.find_child("ShopPanel", true, false) as Control


func _zs_open(m: Node) -> bool:
	var panel: Control = _zs_panel(m)
	return panel != null and panel.is_visible_in_tree()


func _zs_zoom_val(m: Node, nm: String) -> int:
	var d: Dictionary = (m.get_script() as Script).get_script_constant_map()
	return int((d["Zoom"] as Dictionary).get(nm, -1))


## What the zoom looks like: the state a closed sheet must leave untouched.
func _zs_state(m: Node, p: Dictionary) -> Dictionary:
	var cen: Node = p["Centrifuge"]
	return {"zoom": int(m.get("zoom")), "size": _cam().size, "second": bool(m.call("at_second_stop")), "cen": cen.get("state"), "cx": int(cen.get("turns_counted"))}


## Waits (up to 4 s) until the camera size stops changing, so a "before" state is not taken mid-pan (run 2 of the
## Tools second-stop test caught the pan into the second stop: 15.05 -> 12.83 -> 9.54).
func _zs_settle() -> void:
	var last: float = -1.0
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 4000:
		await _frames(2)
		var now: float = _cam().size
		if absf(now - last) < 0.001:
			return
		last = now


func _zs_same_state(m: Node, p: Dictionary, before: Dictionary, label: String) -> void:
	var now: Dictionary = _zs_state(m, p)
	eq(now["zoom"], before["zoom"], "%s: the zoom state is unchanged" % label)
	near(float(now["size"]), float(before["size"]), 0.02, "%s: the camera is where it was (diag: zoom=%s second=%s before_second=%s)" % [label, str(now["zoom"]), str(now["second"]), str(before["second"])])
	eq(now["second"], before["second"], "%s: at_second_stop is unchanged" % label)
	eq(now["cen"], before["cen"], "%s: the centrifuge state is unchanged" % label)


## Shop shows and clears Back, the hint, Spin and the hive count (any that is on screen).
func _zs_clear(m: Node, p: Dictionary, label: String) -> Rect2:
	var sb: Control = _zs_btn(m)
	ck(sb != null and sb.is_visible_in_tree(), "%s: the Shop button shows" % label)
	if sb == null or not sb.is_visible_in_tree():
		return Rect2()
	var r: Rect2 = sb.get_global_rect()
	ck(_vp().encloses(r), "%s: the Shop button is whole on screen" % label)
	ck(r.get_center().x > _vp().size.x * 0.5 and r.get_center().y > _vp().size.y * 0.5, "%s: the Shop button sits bottom-right" % label)
	var seen: int = 0
	for nm in ["BackButton", "HintLabel", "CentrifugeIcon", "HiveCountLabel"]:
		var c: Control = _node(m, nm) as Control
		if c != null and c.is_visible_in_tree() and c.get_global_rect().size.x > 0.0:
			seen += 1
			ck(not r.intersects(c.get_global_rect()), "%s: Shop clears %s" % [label, nm])
	ck(seen >= 1, "%s: at least Back was on screen to be cleared" % label)
	return r


## Open the sheet with a real tap, buy `id` once with a real tap on its row, close by Close (via_dim false) or a tap on the dim. Returns the Shop rect.
## tools = true: the sheet is opened from the ToolsButton (0.3.1 item 8, which took the zoom purchases over from the Shop) and the row is found by its name.
func _zs_buy(m: Node, p: Dictionary, id: String, via_dim: bool, label: String, tools: bool = false) -> void:
	var e: Node = _eco()
	var lvl: int = int(e.call("level", id))
	var cost: int = _shop_expect_cost(id, lvl)
	e.set("money", cost + 3)
	e.emit_signal("money_changed", cost + 3)
	await _frames(2)
	await _zs_settle()
	var before: Dictionary = _zs_state(m, p)
	if not tools:
		await _zs_clear(m, p, label)
	var sb: Control = (m.find_child("ToolsButton", true, false) as Control) if tools else _zs_btn(m)
	if sb == null or not sb.is_visible_in_tree():
		ck(false, "%s: the opening button shows" % label)
		return
	await fi.tap_at(sb.get_global_rect().get_center())
	await _frames(3)
	ck(_zs_open(m), "%s: a real tap on the button opens the sheet over the zoom" % label)
	var row: Control = m.find_child("Row_%s" % id, true, false) as Control
	if row == null or not row.is_visible_in_tree() or _row_buy(row) == null:
		ck(false, "%s: the %s row shows and has a buy button" % [label, id])
		return
	await fi.tap_at(_row_buy(row).get_global_rect().get_center())
	await _frames(2)
	eq(int(e.call("level", id)), lvl + 1, "%s: %s level after the buy" % [label, id])
	eq(int(e.get("money")), 3, "%s: the price (config) was taken, 3 left" % label)
	if via_dim:
		var at: Vector2 = Vector2(_vp().size.x * 0.5, _vp().size.y * 0.1)
		ck(not _zs_panel(m).get_global_rect().has_point(at), "%s: the dim tap point is outside the sheet" % label)
		await fi.tap_at(at)
	else:
		var cb: Control = m.find_child("ShopCloseButton", true, false) as Control
		ck(cb != null and cb.is_visible_in_tree(), "%s: Close shows on the open sheet" % label)
		if cb != null:
			await fi.tap_at(cb.get_global_rect().get_center())
	await _frames(3)
	ck(not _zs_open(m), "%s: the sheet is closed again (%s)" % [label, "dim tap" if via_dim else "Close"])
	await _zs_same_state(m, p, before, label)
	ck(sb.is_visible_in_tree(), "%s: the opening button shows again after closing" % label)


## With the sheet open: a real drag over the frame scrapes nothing and a real tap turns no crank. Reopens the sheet if the press closed it.
func _zs_blocked(m: Node, p: Dictionary, label: String, tools: bool = false) -> void:
	var sb: Control = (m.find_child("ToolsButton", true, false) as Control) if tools else _zs_btn(m)
	await fi.tap_at(sb.get_global_rect().get_center())
	await _frames(3)
	ck(_zs_open(m), "%s: the sheet is open for the input check" % label)
	var hive: Node = p["Hive"]
	var cen: Node = p["Centrifuge"]
	var caps: int = fi.capped_total(hive, _frames_n())
	var turns: int = int(cen.get("turns_counted"))
	var hc: Node = m.find_child("Honeycomb", true, false)
	if bool(m.call("at_second_stop")):
		await fi.tap_at(fi.free_spot(m))
		await _wait(_tap_gap())
	elif hc != null:
		# one row only: the press lands on the dim, which closes the sheet (spec: "a tap on the dim returns to the zoom"); a second row would scrape with the sheet closed
		var rws: Array = fi.rows(hc, _cam())
		if not rws.is_empty():
			await fi.drag_row(rws[0])
	await _wait(0.3)
	eq(fi.capped_total(hive, _frames_n()), caps, "%s: with the sheet open the fork scraped no cell" % label)
	eq(int(cen.get("turns_counted")), turns, "%s: with the sheet open the crank counted no turn (diag: sheet_open=%s cen_state=%s tap=%s cam=%s)" % [label, str(_zs_open(m)), str(cen.get("state")), str(fi.free_spot(m)), str(_cam().size)])
	if _zs_open(m):
		await fi.tap_at(Vector2(_vp().size.x * 0.5, _vp().size.y * 0.1))
		await _frames(3)
	ck(not _zs_open(m), "%s: a tap on the dim closed the sheet" % label)


## Leave by Back with the sheet open (a second tap if the dim took the first): the sheet closes and the zoom or second stop ends.
func _zs_back_with_sheet(m: Node, p: Dictionary, label: String, tools: bool = false) -> void:
	await fi.tap_at(((m.find_child("ToolsButton", true, false) as Control) if tools else _zs_btn(m)).get_global_rect().get_center())
	await _frames(3)
	ck(_zs_open(m), "%s: sheet open before Back" % label)
	await _tap_back({"p": p})
	await _frames(3)
	ck(not _zs_open(m), "%s: Back with the sheet open leaves it closed" % label)
	await _wait(0.3)
	if absf(_cam().size - float(cv("zoom_size"))) < 0.02 or bool(m.call("at_second_stop")):
		await _tap_back({"p": p})   # the first tap only closed the sheet: Back itself
		await _wait(0.2)
	ck(not _zs_open(m), "%s: the sheet is still closed after Back" % label)
	await _until(func() -> bool: return int(m.get("zoom")) == 0 and not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("zoom_seconds")) + float(cv("camera_pan_seconds")) + _zoom_settle() + 6.0)
	await _wait(_zoom_settle())
	ck(int(m.get("zoom")) == 0 and not bool(m.call("at_second_stop")), "%s: Back left the zoom (farm view)" % label)


## First zoom, sheet open: in each zoom, three times in a row open the Shop, buy, close; the sheet blocks fork input; Back and the zoom ending on its own close it; then again.
# goal T15.1
func t_shop_in_first_zoom_buy_blocks_input_closes_on_exit() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var hive: Node = p["Hive"]
	var hc: Node = m.find_child("Honeycomb", true, false)
	# positive control: with the sheet closed a real drag scrapes (the blocked check can fail)
	var caps0: int = fi.capped_total(hive, _frames_n())
	var rows: Array = fi.rows(hc, _cam())
	if not rows.is_empty():
		await fi.drag_row(rows[0])
	await _wait(0.3)
	ck(fi.capped_total(hive, _frames_n()) < caps0, "positive control: a real drag scrapes with the sheet closed")
	# spec 0.3.1 item 3: "The Shop opens from the farm view only: this supersedes 0.2 item 15 ... The `ShopButton` hides in the first zoom and at the second stop"
	# (replaces: the Shop button shows in the zoom, a purchase works there, Back and the zoom ending close the sheet)
	var zb: Control = _zs_btn(m)
	ck(zb == null or not zb.is_visible_in_tree(), "first zoom: the ShopButton is hidden (0.3.1 item 3)")
	ck(not _zs_open(m), "first zoom: the Shop sheet is closed")
	# exit: Back to the farm view; the ShopButton is back and a real tap opens the sheet (the farm view is where the Shop opens)
	await _tap_back({"p": p})
	await _until(func() -> bool: return int(m.get("zoom")) == 0 and not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("zoom_seconds")) + float(cv("camera_pan_seconds")) + _zoom_settle() + 6.0)
	await _wait(_zoom_settle())
	for run in 2:
		var farm_btn: Control = _zs_btn(m)
		ck(farm_btn != null and farm_btn.is_visible_in_tree(), "farm view run %d: the ShopButton shows" % (run + 1))
		if farm_btn == null or not farm_btn.is_visible_in_tree():
			break
		await fi.tap_at(farm_btn.get_global_rect().get_center())
		await _frames(3)
		ck(_zs_open(m), "farm view run %d: a real tap on the ShopButton opens the sheet" % (run + 1))
		await fi.tap_at(m.find_child("ShopCloseButton", true, false).get_global_rect().get_center())
		await _frames(3)
		ck(not _zs_open(m), "farm view run %d: Close returns to the farm" % (run + 1))
	# come back to the zoom: the ShopButton hides again
	tr["risen"] = -1
	ck(await _open_zoom(m, p, tr), "run 2: Harvest again opens the zoom")
	zb = _zs_btn(m)
	ck(zb == null or not zb.is_visible_in_tree(), "run 2 first zoom: the ShopButton is hidden again")
	_fin()


## Scrape every frame with real drags until the last Capped cell goes; then, while the zoom finishes (LOWERING or CLOSE_DELAY), open the sheet. Returns whether it opened before CLOSING.
# goal T15.1
func _zs_finish_with_sheet(m: Node, p: Dictionary, tr: Dictionary, tools: bool = false) -> bool:
	var hive: Node = p["Hive"]
	var t0: int = _gms()
	# only the risen frame is scraped by hand: the others are emptied in the hive's data (main.gd _raise_next skips frames with no Capped cell), so the zoom ends after this frame (diag run 20261122-010936: 40 Capped cells left in other frames when the 120 game-second cap hit)
	var rf: int = int(tr["risen"])
	for f in int(hive.call("frame_count")):
		if f != rf:
			for c in (hive.call("frame_cells", f) as PackedByteArray).size():
				hive.call("scrape", f, c)
	_set_cfg("close_delay_seconds", 4.0)   # 0.5 s is ~5 frames at --time-scale 6: widen the window the player has to tap Shop in (restored after the test)
	var delay: int = _zs_zoom_val(m, "CLOSE_DELAY")
	var working: int = _zs_zoom_val(m, "WORKING")
	# only CLOSE_DELAY means the zoom is ending on its own (main.gd back()); after LOWERING a refilled frame can rise again, so keep scraping until then
	while int(m.get("zoom")) != delay and float(_gms() - t0) < 120000.0:
		if int(tr["risen"]) >= 0 and int(m.get("zoom")) == working and fi.capped_total(hive, _frames_n()) > 0:
			await _scrape_risen(m, hive, tr, 1)
		else:
			await process_frame
		if int(m.get("zoom")) == _zs_zoom_val(m, "CLOSING") or int(m.get("zoom")) == 0:
			break
	var lowering: int = _zs_zoom_val(m, "LOWERING")
	var z: int = int(m.get("zoom"))
	if z != delay:
		# diagnosis: the hive's Capped count vs the risen honeycomb's own cell states (frame_done needs every cell EXTRACTED)
		var hcd: Node = m.find_child("Honeycomb", true, false)
		var st: Array = [0, 0, 0]
		if hcd != null:
			for c in hcd.get("cells"):
				st[clampi(int(c), 0, 2)] += 1
		ck(false, "diag: zoom %d, risen %d, hive capped %d, honeycomb capped/uncapped/extracted %s, departures %d" % [z, int(tr["risen"]), fi.capped_total(hive, _frames_n()), str(st), (hcd.get("_departures") as Array).size() if hcd != null else -1])
		return false   # CLOSING or NONE already (or timed out): too late, the check fails honestly
	# The Shop button sits under FarmUIRoot and stays in the zoom (shop_layout 1): tap it for real when visible, else ask the panel directly.
	var btn: Control = (m.find_child("ToolsButton", true, false) as Control) if tools else _zs_btn(m)
	if btn != null and btn.is_visible_in_tree():
		await fi.tap_at(btn.get_global_rect().get_center())
		await _frames(2)
	if not tools and not _zs_open(m) and int(m.get("zoom")) in [lowering, delay]:
		_zs_panel(m).call("set_sheet_open", true)
		await process_frame
	return _zs_open(m)


## When the zoom reaches CLOSING (whatever started it) the sheet must be closed within two frames, not only at the very end.
func _zs_expect_closed_at_closing(m: Node, label: String) -> void:
	var closing: int = _zs_zoom_val(m, "CLOSING")
	ck(closing >= 0, "%s: main.gd names Zoom.CLOSING" % label)
	var hit: bool = await _until(func() -> bool: return int(m.get("zoom")) == closing, float(cv("slide_seconds")) + float(cv("zoom_seconds")) + 10.0)
	ck(hit, "%s: the zoom reached CLOSING (zoom is %s)" % [label, str(m.get("zoom"))])
	await _frames(2)
	ck(not _zs_open(m), "%s: the sheet is closed as the zoom starts closing" % label)


## Second stop: Shop shows; in the open crank a purchase applies (Gearing: fewer turns left), the sheet takes no crank tap, Back closes it, Spin comes back, again.
# goal T15.1
func t_shop_at_second_stop_buy_blocks_crank_closes_on_back() -> void:
	var s: Dictionary = await _cranking_at_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var cen: Node = s["cen"]
	ck(bool(m.call("at_second_stop")), "step start: at the second stop")
	# positive control: with the sheet closed a real tap counts a turn
	var t0: int = int(cen.get("turns_counted"))
	await _tap_free(m)
	ck(int(cen.get("turns_counted")) > t0, "positive control: a real tap at the second stop counts a turn with the sheet closed")
	# spec 0.3.1 item 3: "The Shop opens from the farm view only ... The `ShopButton` hides in the first zoom and at the second stop, where item 8's Tools icon holds the machine's upgrades"
	# (replaces: the Shop shows at the second stop and a purchase works there)
	var zb: Control = _zs_btn(m)
	ck(zb == null or not zb.is_visible_in_tree(), "second stop: the ShopButton is hidden (0.3.1 item 3)")
	ck(not _zs_open(m), "second stop: the Shop sheet is closed")
	# leave by Back, come back with Spin: hidden again
	var kept: int = int(cen.get("turns_counted"))
	await _tap_back({"p": p})
	await _wait(0.3)
	eq(int(cen.get("turns_counted")), kept, "Back counted no turn and kept the progress")
	eq(cen.get("state"), _st(cen, "CRANKING"), "the paused crank is still the same crank")
	var spin: Control = p["CentrifugeIcon"]
	await fi.tap_at(spin.get_global_rect().get_center())
	var back: bool = await _until(func() -> bool: return bool(m.call("at_second_stop")) and absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01, float(cv("camera_pan_seconds")) + _zoom_settle() + 6.0)
	await _wait(0.4)
	ck(back, "run 2: Spin returns to the second stop")
	zb = _zs_btn(m)
	ck(zb == null or not zb.is_visible_in_tree(), "run 2 second stop: the ShopButton is hidden again")
	_fin()


## shop_layout = 0 (compact panel): the panel stays farm-only, no Shop button shows in the first zoom.
# goal T15.1
func t_shop_compact_layout_nothing_in_zoom() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()   # opened with the default layout: the compact panel would sit over the Harvest icon and block its tap
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	_set_cfg("shop_layout", 0)   # then switch to the compact panel inside the zoom (spec: "With shop_layout = 0 nothing changes: the panel stays farm-only")
	await _frames(4)
	var sb: Control = _zs_btn(m)
	ck(sb == null or not sb.is_visible_in_tree(), "shop_layout 0: no Shop button shows in the zoom")
	ck(not _zs_open(m), "shop_layout 0: the compact panel is not shown in the zoom (farm-only)")
	var panel: Node = _zs_panel(m)
	if panel != null and panel.has_method("set_sheet_open"):
		panel.call("set_sheet_open", true)
		await _frames(3)
		ck(not _zs_open(m), "shop_layout 0: asking for the sheet shows nothing in the zoom")
	_fin()
