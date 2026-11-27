extends "res://tests/test_helpers_7.gd"

# Quinn: 0.3.2 item 3 (the 0.3.1 test lines that never got a test), part A: T1.1 the pill and the Journal icon, T2.1 the toast queue.
# Written from game/specs/0.3.2-tests-and-quick-buy.md item 3 and the 0.3.1 spec's lines, before the code. Taps are real mouse events;
# numbers come from the config, the scene, the translation table and ProjectSettings.


## The pill holds no Button; it shows on the farm view only; the money still shows at the second stop; nothing but ShopButton opens the Shop. Twice.
# goal T3.1
func t_pill_no_button_farm_view_only_money_stays_only_shop_button_opens_shop_twice() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var pill: Control = _nn(m, "HabitatPill") as Control
	var money: Control = _nn(m, "MoneyLabel") as Control
	if pill == null or money == null:
		_fin()
		return
	eq(pill.find_children("*", "BaseButton", true, false).size(), 0, "the pill has no Button child (the + is gone)")
	ck(_shown(pill), "farm view: the pill shows")
	var pr: Rect2 = pill.get_global_rect()
	var spots: Array = [pr.get_center(), pr.end - Vector2(12.0, 12.0)]   # the middle, and the right end where the + sat
	for run in [1, 2]:
		var L: String = "run %d" % run
		ck(not _tl_sheet_open(), "%s step start: the Shop is closed" % L)
		for at in spots:
			await fi.tap_at(at)
			await _frames(3)
			ck(not _tl_sheet_open(), "%s step pill: a real tap at %s on the pill opens no Shop" % [L, str(at)])
		await _pt_tap(money)
		ck(not _tl_sheet_open(), "%s step money: a real tap on the money opens no Shop" % L)
		ck(await _pt_open_shop(m), "%s step ShopButton: a real tap on ShopButton opens the Shop" % L)
		await _pt_close_shop(m)
		ck(not _tl_sheet_open(), "%s step Close: the Shop closes" % L)
	_pt_drop(m)
	var z: Dictionary = await _zoom_open_main()
	if not z.is_empty():
		var zp: Control = _nn(z["m"], "HabitatPill") as Control
		ck(int(z["m"].get("zoom")) != 0 and zp != null and not _shown(zp), "first zoom: the pill is hidden")
		_pt_drop(z["m"])
	var s: Dictionary = await _second_stop_with_capped()
	if not s.is_empty():
		var sp: Control = _nn(s["m"], "HabitatPill") as Control
		var sm: Control = _nn(s["m"], "MoneyLabel") as Control
		ck(bool(s["m"].call("at_second_stop")), "second stop: the camera is at the second stop")
		ck(sp != null and not _shown(sp), "second stop: the pill is hidden")
		ck(sm != null and _shown(sm), "second stop: the money still shows")
	_fin()


## Before thriving the Journal icon is hidden; at thriving it shows on the farm view and a real tap opens the Bumble Bees entry, not the Shop;
## it is hidden in both zooms. Twice: open and close again.
# goal T3.1
func t_journal_icon_hidden_before_thriving_opens_entry_not_shop_hidden_in_zooms_twice() -> void:
	var d: Dictionary = _journal_read()
	ck(not d.is_empty(), "journal.csv opens")
	var m: Node = await _pt_farm()
	if m == null or d.is_empty():
		_fin()
		return
	var rows: Dictionary = d["rows"]
	var e: Node = _eco()
	e.call("reset")
	await _frames(3)
	var btn: Control = _nn(m, "JournalButton") as Control
	var panel: Control = _nn(m, "JournalPanel") as Control
	var title: Label = _nn(m, "JournalTitle") as Label
	var close: Control = _nn(m, "JournalCloseButton") as Control
	if btn == null or panel == null or title == null or close == null:
		_fin()
		return
	var thr: int = int(cv("habitat_thriving"))
	ck(not _shown(btn), "step start: the Journal icon is hidden in a new farm")
	e.call("add_habitat", thr - 1 - int(e.get("habitat_health")))
	await _frames(3)
	ck(not _shown(btn), "step below: still hidden one point under habitat_thriving")
	e.call("add_habitat", 1)
	await _frames(3)
	for run in [1, 2]:
		var L: String = "run %d" % run
		ck(_shown(btn), "%s step thriving: the icon shows on the farm view" % L)
		ck(not _tl_sheet_open(), "%s step thriving: the Shop is closed before the tap" % L)
		await _pt_tap(btn)
		ck(panel.is_visible_in_tree(), "%s step tap: a real tap on the icon opens the Journal" % L)
		eq(title.text, str(rows["JOURNAL_BUMBLE_BEES_TITLE"]["en"]), "%s step tap: it opens the Bumble Bees entry" % L)
		ck(not _tl_sheet_open(), "%s step tap: the Shop did not open" % L)
		await _pt_tap(close)
		ck(not panel.is_visible_in_tree(), "%s step close: Close returns to the farm" % L)
	_pt_drop(m)
	var z: Dictionary = await _zoom_open_main()
	if not z.is_empty():
		e.call("add_habitat", thr)
		await _frames(3)
		var zj: Control = _nn(z["m"], "JournalButton") as Control
		ck(int(z["m"].get("zoom")) != 0 and zj != null and not _shown(zj), "first zoom: the Journal icon is hidden at thriving")
		_pt_drop(z["m"])
	var s: Dictionary = await _second_stop_with_capped()
	if not s.is_empty():
		e.call("add_habitat", thr)
		await _frames(3)
		var sj: Control = _nn(s["m"], "JournalButton") as Control
		ck(bool(s["m"].call("at_second_stop")) and sj != null and not _shown(sj), "second stop: the Journal icon is hidden at thriving")
	e.call("reset")
	_fin()


## At thriving with every anchor showing (Harvest, Spin, Sell), the Journal icon clears ShopButton, SkipIcon, the hive count and the three anchors.
# goal T3.1
func t_journal_icon_clears_shop_button_skip_icon_hive_count_and_anchors() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var e: Node = _eco()
	e.call("reset")
	e.call("add_habitat", int(cv("habitat_thriving")))
	_full_hive_frozen(p["Hive"])
	_pt_full_bucket(p)
	for i in int(cv("truck_capacity_jars")):
		(p["Truck"] as Node).call("receive_jar")
	await _frames(8)
	var j: Control = _nn(m, "JournalButton") as Control
	if j == null:
		_fin()
		return
	ck(_shown(j), "the Journal icon shows at thriving")
	var jr: Rect2 = j.get_global_rect()
	ck(jr.size.x >= FloatingIcon.MIN_TOUCH.x and jr.size.y >= FloatingIcon.MIN_TOUCH.y, "the icon's touch rect %s is at least the minimum %s" % [str(jr.size), str(FloatingIcon.MIN_TOUCH)])
	ck(_cb_viewport().encloses(jr), "the icon %s is whole on screen" % str(jr))
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon"]:
		ck(_shown(p[nm]), "%s shows, so its place is measured" % nm)
	for nm in ["ShopButton", "SkipIcon", "HiveCountLabel", "ForkIcon", "CentrifugeIcon", "SellIcon"]:
		var c: Control = _nn(m, nm) as Control
		if c != null:
			ck(not jr.intersects(c.get_global_rect()), "the Journal icon %s clears %s %s" % [str(jr), nm, str(c.get_global_rect())])
	e.call("reset")
	_fin()


## Buying a patch with the Shop open shows no toast until Close, then toast_patch_planted for toast_seconds (+-0.2 s), seen. Twice.
# goal T3.2
func t_patch_toast_waits_for_shop_close_then_shows_toast_seconds_twice() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var e: Node = _eco()
	var slots: Node = _nn(m, "PatchSlots")
	if slots == null:
		_fin()
		return
	var want: String = TranslationServer.translate("toast_patch_planted")
	var secs: float = float(cv("toast_seconds"))
	for run in [1, 2]:
		var L: String = "run %d" % run
		e.call("reset")
		await _frames(3)
		_cb_rich()
		var before: int = int(slots.call("planted_count"))
		ck(await _pt_open_shop(m), "%s step open: the Shop opens" % L)
		var w: Dictionary = _cb_watch(m)
		ck(await _cb_buy_patch_in_shop(m), "%s step buy: a real tap on the plant row's Buy" % L)
		eq(int(slots.call("planted_count")), before + 1, "%s step buy: one more patch planted" % L)
		await _wait(secs * 0.6)
		eq(_cb_texts(w), [], "%s step open: no toast shows while the Shop is open" % L)
		await _pt_close_shop(m)
		ck(await _until(func() -> bool: return _cb_toast_text(m) == want, 2.0), "%s step Close: toast_patch_planted shows after Close (got '%s')" % [L, _cb_toast_text(m)])
		eq(_cb_toast_unseen(m), [], "%s step Close: the toast is seen" % L)
		ck(await _until(func() -> bool: return _cb_toast_text(m) == "", secs + 2.0), "%s step end: the toast goes" % L)
		_cb_unwatch(w)
		var span: Array = _cb_span(w, want)
		ck(span.size() == 2, "%s step span: the toast was logged" % L)
		if span.size() == 2:
			near(float(span[1]) - float(span[0]), secs, 0.2 + float(w["step"]), "%s step span: it shows toast_seconds (+-0.2 s, plus one frame of sampling)" % L)
		eq(_cb_texts(w), [want], "%s step only: nothing but the patch toast showed" % L)
	e.call("reset")
	_fin()


## The planting that reaches thriving shows only toast_bumble_visitor after Close (never the patch toast), and the victory only after it.
# goal T3.2
func t_last_patch_shows_only_bumble_toast_after_close_victory_after_it() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var e: Node = _eco()
	var o: Node = _vic_overlay(m)
	if o == null:
		_fin()
		return
	var secs: float = float(cv("toast_seconds"))
	var delay: float = float(cv("victory_delay_seconds"))
	var want: String = TranslationServer.translate("toast_bumble_visitor")
	e.call("reset")
	await _frames(3)
	_cb_rich()
	e.call("add_habitat", int(cv("habitat_thriving")) - int(cv("habitat_health_per_patch")) - int(e.get("habitat_health")))   # one patch short
	await _frames(3)
	var vic: Dictionary = {"t": -1.0}
	var vcb: Callable = func() -> void:
		if float(vic["t"]) < 0.0 and _vic_shown(o):
			vic["t"] = _cb_secs()
	process_frame.connect(vcb)
	ck(await _pt_open_shop(m), "step open: the Shop opens")
	var w: Dictionary = _cb_watch(m)
	ck(await _cb_buy_patch_in_shop(m), "step buy: a real tap buys the last patch")
	ck(int(e.get("habitat_health")) >= int(cv("habitat_thriving")), "step buy: Health reached habitat_thriving")
	await _wait(secs * 0.6)
	eq(_cb_texts(w), [], "step open: no toast while the Shop is open")
	eq(_vic_shown(o), false, "step open: no victory while the Shop is open")
	await _pt_close_shop(m)
	var ok: bool = await _until(func() -> bool: return float(vic["t"]) >= 0.0, secs + delay + 4.0)
	ck(ok, "step victory: the victory shows after Close")
	_cb_unwatch(w)
	process_frame.disconnect(vcb)
	eq(_cb_texts(w), [want], "step toast: only toast_bumble_visitor showed, never the patch toast")
	var span: Array = _cb_span(w, want)
	ck(span.size() == 2, "step toast: the bumble toast was logged")
	if span.size() == 2 and ok:
		ck(float(vic["t"]) >= float(span[1]) - float(w["step"]), "step order: the victory (%.2f) came after the toast ended (%.2f)" % [float(vic["t"]), float(span[1])])
		ck(float(vic["t"]) - float(span[1]) >= delay - 0.2 - float(w["step"]), "step delay: victory_delay_seconds passed between them (%.2f s)" % (float(vic["t"]) - float(span[1])))
	if o.has_method("close"):
		o.call("close")
	e.call("reset")
	_fin()


## The Phase 2 toast still shows (after the Shop closes, seen, its text); "Reset habitat" (the Dev button) empties the queue of waiting toasts.
# goal T3.2
func t_phase2_toast_shows_and_reset_habitat_empties_queue() -> void:
	_set_dev_mode(true)
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var e: Node = _eco()
	var secs: float = float(cv("toast_seconds"))
	e.call("reset")
	await _frames(3)
	e.call("set_level", "faster_delivery", _shop_unlock_level())
	_cb_rich()
	var phase2: String = TranslationServer.translate("toast_phase2")
	ck(await _pt_open_shop(m), "phase 2 step open: the Shop opens")
	var w: Dictionary = _cb_watch(m)
	await _pt_tab(m, "Hive")
	var row: Control = m.find_child("Row_auto_sell", true, false) as Control
	var buy: Button = _row_buy(row) if row != null else null
	ck(buy != null and not buy.disabled, "phase 2 step buy: Auto-Sell can be bought")
	if buy != null:
		await _pt_tap(buy)
	eq(int(e.call("level", "auto_sell")), 1, "phase 2 step buy: Auto-Sell is owned")
	await _wait(secs * 0.5)
	eq(_cb_texts(w), [], "phase 2 step open: the toast waits for the Shop")
	await _pt_close_shop(m)
	ck(await _until(func() -> bool: return _cb_toast_text(m) == phase2, 2.0), "phase 2 step Close: the Phase 2 toast shows (got '%s')" % _cb_toast_text(m))
	eq(_cb_toast_unseen(m), [], "phase 2 step Close: the toast is seen")
	ck(await _until(func() -> bool: return _cb_toast_text(m) == "", secs + 2.0), "phase 2 step end: the toast goes")
	_cb_unwatch(w)
	# the queue: two patch toasts wait under the open Shop, "Reset habitat" empties them
	e.call("reset")
	await _frames(3)
	_cb_rich()
	var reset: Button = _cb_dev_button(m, "Reset habitat")
	ck(reset != null, "queue step: the Dev panel has a Reset habitat button")
	ck(await _pt_open_shop(m), "queue step open: the Shop opens")
	var w2: Dictionary = _cb_watch(m)
	ck(await _cb_buy_patch_in_shop(m), "queue step buy: the first patch")
	if m.find_child("Row_plant_patch", true, false) != null and _row_buy(m.find_child("Row_plant_patch", true, false)) != null:
		await _pt_tap(_row_buy(m.find_child("Row_plant_patch", true, false)))
	if reset != null:
		reset.pressed.emit()
	await _frames(3)
	await _pt_close_shop(m)
	await _wait(secs * 2.5)
	_cb_unwatch(w2)
	eq(_cb_texts(w2), [], "queue step reset: no waiting toast shows after Reset habitat and Close")
	e.call("reset")
	_fin()
