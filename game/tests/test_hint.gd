extends "res://tests/test_helpers_4.gd"

# Quinn: 0.3.1 item 4 (the first-time hint), written from game/specs/0.3.1-playtest-fixes.md before the code.
# Every tap is a real mouse event in window pixels (farm_input.gd); texts come from content/first-time-hint.md; waits are game seconds.
# The steps follow the game's state, so each test drives the game and reads the line on the HintBubble (see test_helpers_4.gd).


## Every hint key (the eight steps and hint_skip) has the approved EN and FR text in the exported translations, and tr() returns it.
# goal T4.3
func t_hint_texts_match_content() -> void:
	var want: Dictionary = _hi_content()
	var rows: Dictionary = _hi_csv_rows()
	ck(want.size() == HINT_KEYS.size() + 1, "content/first-time-hint.md holds the eight steps and hint_skip (got %d)" % want.size())
	var old: String = TranslationServer.get_locale()
	for k in want.keys():
		for loc in ["en", "fr"]:
			eq(str((rows.get(k, {}) as Dictionary).get(loc, "<no row>")), want[k][loc], "translations CSV: %s (%s) is William's approved text" % [k, loc])
			TranslationServer.set_locale(loc)
			eq(TranslationServer.translate(k), want[k][loc], "tr(%s) in %s is William's approved text" % [k, loc])
	TranslationServer.set_locale(old)
	_fin()


## Never under the welcome overlay; a real tap on Play starts it at hint_wait (the hive is filling, no ForkIcon yet). A second launch does the same.
# goal T4.3
func t_hint_waits_for_play_then_starts_twice() -> void:
	var first: Array = []
	for run in [1, 2]:
		var m: Node = await _hi_launch(true)
		if m == null:
			_fin()
			return
		var ov: Node = _wl_overlay(m)
		ck(ov != null, "run %d: the welcome overlay is up (show_welcome true)" % run)
		await _wait(_wl_wait_s())
		eq(_hi_key(), "", "run %d step welcome: no bubble under the welcome overlay" % run)
		var bs: Array = _wl_buttons(ov) if ov != null else []
		if bs.size() != 1:
			ck(false, "run %d: exactly one Play button to tap" % run)
			_fin()
			return
		await fi.tap_at((bs[0] as Control).get_global_rect().get_center())
		ck(await _hi_wait_key("hint_wait", 3.0), "run %d step play: after Play the bubble is hint_wait (got '%s')" % [run, _hi_key()])
		eq(_hi_problems(), [], "run %d step play: the hint_wait bubble is on screen, clear of its target, 28 px, Skip 120 px" % run)
		first.append(_hi_key())
		_cleanup_main(m)
	eq(first[0], first[1], "twice: the second launch starts the same way")
	_fin()


## A real tap on Skip ends the hint for good (no hint_harvest with the fork showing, no hint_plant in the Shop); the Dev button "Replay hint"
## restarts it at the step that fits (hint_harvest); the second launch (a new farm) shows it again and ends the same way.
# goal T4.3
func t_hint_skip_ends_for_good_twice() -> void:
	_set_dev_mode(true)
	var traces: Array = []
	for run in [1, 2]:
		var m: Node = await _hi_launch()
		if m == null:
			_fin()
			return
		var trace: Array = []
		ck(await _hi_wait_key("hint_wait", 3.0), "run %d step start: the hint shows on a new farm" % run)
		var sk: Button = _hi_skip_btn()
		eq(_hi_covers(sk.get_global_rect().get_center()), [], "run %d step start: nothing draws over the Skip button" % run)
		await _hi_tap(sk)
		await _frames(3)
		trace.append(_hi_key())
		eq(_hi_key(), "", "run %d step skip: a real tap on Skip hides the bubble" % run)
		_full_hive_frozen(_nn(m, "Hive"))
		var fork: Control = _nn(m, "ForkIcon") as Control
		ck(await _until(func() -> bool: return fork.is_visible_in_tree(), 5.0), "run %d: the fork shows on the full hive" % run)
		await _frames(5)
		trace.append(_hi_key())
		eq(_hi_key(), "", "run %d step ended: the fork shows and no hint_harvest follows Skip" % run)
		await _shop_open(m, true)
		await _frames(3)
		trace.append(_hi_key())
		eq(_hi_key(), "", "run %d step ended: no hint_plant in the Shop after Skip" % run)
		await _hi_tap(_hi_n("ShopCloseButton") as Control)
		await _frames(3)
		var dev: Button = root.find_child("DevButton", true, false) as Button
		ck(dev != null, "run %d: the Dev button exists (Dev mode on)" % run)
		if dev != null:
			await _hi_tap(dev)
			var rb: Button = _button_with(_find_dev_panel(m), "replay hint") if _find_dev_panel(m) != null else null
			ck(rb != null, "run %d: the Dev panel has a 'Replay hint' button" % run)
			if rb != null:
				await _hi_tap(rb)
				ck(await _hi_wait_key("hint_harvest", 3.0), "run %d step replay: restarts at the step that fits (fork showing: hint_harvest), got '%s'" % [run, _hi_key()])
				trace.append(_hi_key())
		traces.append(trace)
		_cleanup_main(m)
	eq(traces[0], traces[1], "twice: the second farm shows, skips and replays the same way")
	_fin()


## One whole farm through real input: the steps show in the spec's order (out-of-order ones skipped), each on screen and clear of its
## target, no bubble while bottling runs with no step due, and it is over once the first patch is planted. The second farm matches the first.
# goal T4.3
func t_hint_steps_follow_state_in_order_twice() -> void:
	var runs: Array = []
	for run in [1, 2]:
		var r: Dictionary = await _hi_walk()
		ck(bool(r["ok"]), "run %d: the walk reached the second stop" % run)
		var keys: Array = (r["keys"] as Array).duplicate()
		if not keys.is_empty() and keys[0] == "hint_wait":
			keys.pop_front()   # the hive was frozen full a few frames in: hint_wait is optional here (the Play test covers it)
		var order: Array = []
		order.append_array(HINT_KEYS.slice(1))   # an untyped copy: the spec's order, hint_wait aside
		eq(keys, order, "run %d: the steps shown, in order" % run)
		eq(r["problems"], [], "run %d: no off-screen, covered, mis-sized or mis-pointed bubble, none while bottling with no step due" % run)
		runs.append(keys)
		if r.has("m"):
			_cleanup_main(r["m"])
	eq(runs[0], runs[1], "twice: the second farm shows the same steps")
	_fin()


## While the Shop sheet is open only hint_plant shows and it draws above the sheet and its dim, at TabHabitat then at the plant row; any other
## step waits until the Shop closes (twice); planting the first patch ends it for good.
# goal T4.3
func t_hint_shop_only_plant_above_sheet_ends_on_patch() -> void:
	var m: Node = await _hi_launch()
	if m == null:
		_fin()
		return
	_full_hive_frozen(_nn(m, "Hive"))
	ck(await _hi_wait_key("hint_harvest", 5.0), "start: the full hive shows hint_harvest (got '%s')" % _hi_key())
	var rule: Callable = func() -> String:
		var k: String = _hi_key()
		if _hi_sheet_open() and k != "" and k != "hint_plant":
			return "%s showed while the Shop sheet was open (only hint_plant may)" % k
		return ""
	var w: Dictionary = _hi_watch([rule])
	for cycle in [1, 2]:
		await _shop_open(m, true)
		ck(_hi_sheet_open(), "cycle %d: a real tap on ShopButton opens the sheet" % cycle)
		ck(await _hi_wait_key("hint_plant", 3.0), "cycle %d step open: only hint_plant shows over the sheet (got '%s')" % [cycle, _hi_key()])
		var bub: Control = _hi_n("HintBubble") as Control
		eq(_hi_covers(bub.get_global_rect().get_center()), [], "cycle %d step above: nothing draws over the bubble (the sheet and its dim are below)" % cycle)
		eq(_hi_covers(_hi_skip_btn().get_global_rect().get_center()), [], "cycle %d step above: nothing draws over the Skip button" % cycle)
		var tab: Control = _hi_n("TabHabitat") as Control
		ck(tab != null, "cycle %d: TabHabitat exists" % cycle)
		if tab != null and not (tab is BaseButton and (tab as BaseButton).button_pressed):
			var t0: Array = _hi_targets("hint_plant")
			ck(t0.size() == 1 and t0[0] == tab.get_global_rect(), "cycle %d step tab: until it is selected the target is TabHabitat" % cycle)
			ck(_hi_dist(_hi_tip(), tab.get_global_rect()) <= bub.size.y, "cycle %d step tab: the tail points at TabHabitat" % cycle)
		ck(await _hi_select_habitat(), "cycle %d: with the tab selected the plant row shows" % cycle)
		var row: Control = _hi_n("Row_plant_patch") as Control
		eq(_hi_key(), "hint_plant", "cycle %d step row: still hint_plant after the tab is selected" % cycle)
		if row != null and tab != null:
			ck(_hi_dist(_hi_tip(), row.get_global_rect()) < _hi_dist(_hi_tip(), tab.get_global_rect()), "cycle %d step row: the tail now points at the plant row, not the tab" % cycle)
			ck(not bub.get_global_rect().intersects(row.get_global_rect()), "cycle %d step row: the bubble does not cover the row" % cycle)
		await _hi_tap(_hi_n("ShopCloseButton") as Control)
		await _frames(3)
		ck(not _hi_sheet_open(), "cycle %d: a real tap on Close closes the sheet" % cycle)
		ck(await _hi_wait_key("hint_harvest", 3.0), "cycle %d step close: the waiting step is back (got '%s')" % [cycle, _hi_key()])
	await _shop_open(m, true)
	ck(await _hi_select_habitat(), "plant: the row shows")
	_eco().call("earn", int(_eco().call("cost", "plant_patch")) * 2)
	await _frames(3)
	var buy: Button = (_hi_n("Row_plant_patch")).find_child("UpgradeButton", true, false) as Button
	ck(buy != null, "plant: the row has its button")
	if buy != null:
		await _hi_tap(buy)
	await _frames(4)
	eq(int(_eco().call("level", "plant_patch")), 1, "plant: a real tap on the row planted the first patch")
	eq(_hi_key(), "", "step planted: the hint ends")
	await _hi_tap(_hi_n("ShopCloseButton") as Control)
	await _frames(5)
	ck((_hi_n("ForkIcon") as Control).is_visible_in_tree(), "the fork still shows")
	eq(_hi_key(), "", "step planted: for good (no hint_harvest although the fork shows)")
	_hi_unwatch(w)
	eq(w["problems"], [], "no bubble problem and no other step over the sheet in the whole run")
	_fin()


## The victory overlay and the Journal panel hide the bubble while they are up; it comes back after (Journal twice).
# goal T4.3
func t_hint_hidden_under_journal_and_victory_twice() -> void:
	var m: Node = await _hi_launch()
	if m == null:
		_fin()
		return
	_full_hive_frozen(_nn(m, "Hive"))
	ck(await _hi_wait_key("hint_harvest", 5.0), "start: the full hive shows hint_harvest (got '%s')" % _hi_key())
	var panel: Control = _nn(m, "JournalPanel") as Control
	var o: Node = _vic_overlay(m)
	var rule: Callable = func() -> String:
		var k: String = _hi_key()
		if k != "" and (panel.is_visible_in_tree() or _vic_shown(o)):
			return "%s showed while the Journal panel or the victory overlay was up" % k
		return ""
	var w: Dictionary = _hi_watch([rule])
	_eco().call("add_habitat", int(cv("habitat_health_max")) * 3)   # thriving on this farm: Journal button, then the victory (no reset: the hive stays full)
	var ok: bool = await _until(func() -> bool: return _vic_shown(o), float(cv("toast_seconds")) + float(cv("victory_delay_seconds")) * 3.0 + 10.0)
	ck(ok, "the victory shows on the farm view")
	if ok:
		await _frames(3)
		eq(_hi_key(), "", "step victory: the bubble is hidden under the victory overlay")
		await _hi_tap(o.find_child("VictoryButton", true, false) as Control)
		await _frames(3)
		ck(await _hi_wait_key("hint_harvest", 3.0), "step victory closed: the bubble is back (got '%s')" % _hi_key())
	var btn: Control = _nn(m, "JournalButton") as Control
	var close: Control = _nn(m, "JournalCloseButton") as Control
	for run in [1, 2]:
		ck(btn.is_visible_in_tree(), "run %d: the Journal button shows (thriving)" % run)
		await _hi_tap(btn)
		await _frames(3)
		ck(panel.is_visible_in_tree(), "run %d: a real tap on Journal opens the panel" % run)
		eq(_hi_key(), "", "run %d step journal: the bubble is hidden while the Journal panel is up" % run)
		await _hi_tap(close)
		await _frames(3)
		ck(await _hi_wait_key("hint_harvest", 3.0), "run %d step closed: the bubble is back (got '%s')" % [run, _hi_key()])
	_hi_unwatch(w)
	eq(w["problems"], [], "no bubble problem (toast overlap included) and none under the overlays")
	_fin()


## Leaving mid-way shows the step that fits where the player now is, and coming back shows the step again, twice: Back from the first zoom
## (hint_uncap -> hint_harvest), Back from the second stop before the crank turned (no hint_crank on the farm view, hint_crank again on Spin),
## and a turned crank is not asked for again.
# goal T4.3
func t_hint_leaving_shows_step_that_fits_twice() -> void:
	_hi_setup()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	for run in [1, 2, 3]:
		ck(await _hi_wait_key("hint_uncap", 4.0), "run %d: in the first zoom with capped cells left: hint_uncap (got '%s')" % [run, _hi_key()])
		eq(_hi_problems(), [], "run %d: the hint_uncap bubble is clear of the comb and on screen" % run)
		await _hi_tap(p["BackButton"] as Control)
		ck(await _until(func() -> bool: return _zoom_closed(m), float(cv("zoom_seconds")) + _zoom_settle() + 8.0), "run %d: Back ends the zoom" % run)
		await _wait(_zoom_settle())
		ck(await _hi_wait_key("hint_harvest", 4.0), "run %d step back: on the farm view with the fork showing: hint_harvest (got '%s')" % [run, _hi_key()])
		if run < 3:
			ck(await _open_zoom(m, p, tr), "run %d: the fork opens the zoom again" % run)
	_cleanup_main(m)
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var m2: Node = s["m"]
	var p2: Dictionary = s["p"]
	for run in [1, 2]:
		ck(await _hi_wait_key("hint_crank", 4.0), "run %d: at the second stop, crank not turned: hint_crank (got '%s')" % [run, _hi_key()])
		eq(_hi_problems(), [], "run %d: the hint_crank bubble is clear of the crank and on screen" % run)
		await _hi_tap(p2["BackButton"] as Control)
		ck(await _until(func() -> bool: return not bool(m2.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0), "run %d: Back leaves the second stop" % run)
		await _wait(_zoom_settle())
		var k: String = _hi_key()
		ck(k != "hint_crank", "run %d step back: no hint_crank on the farm view (got '%s')" % [run, k])
		ck(["", "hint_spin", "hint_harvest"].has(k), "run %d step back: a step that fits the farm view (got '%s')" % [run, k])
		var spin: Control = p2["CentrifugeIcon"] as Control
		ck(spin.is_visible_in_tree(), "run %d: Spin shows on the farm view" % run)
		await fi.click_icon(spin)
		ck(await _until(func() -> bool: return bool(m2.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0), "run %d step again: Spin goes back to the second stop" % run)
		await _wait(0.4)
	ck(await _hi_wait_key("hint_crank", 4.0), "back at the second stop: hint_crank again (got '%s')" % _hi_key())
	await fi.tap_at(fi.free_spot(m2))
	await _frames(4)
	ck(_hi_key() != "hint_crank", "step turned: once the crank has turned it is not asked for again (got '%s')" % _hi_key())
	_fin()
