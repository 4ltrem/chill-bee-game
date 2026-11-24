extends "res://tests/test_helpers_5.gd"

# Quinn: 0.3.1 item 8 (the Tools icon in both zooms, in place of the Shop), written from game/specs/0.3.1-playtest-fixes.md before the code.
# Every tap is a real mouse event in window pixels (farm_input.gd); prices, levels and names come from the config; the viewport from ProjectSettings.
# Shared steps: test_helpers_5.gd (_tl_*) and, for buy / blocked input / Back with the sheet open, test_shop_zoom.gd (_zs_*, with tools = true).
# Stale and replaced by item 8: test_shop_zoom.gd's two zoom-purchase tests already assert the hidden ShopButton (item 3); the purchases are here.


## First zoom: the icon is whole, at least 120 px, bottom-right, clear of Back, the text and the comb, with its label under it; the ShopButton is
## hidden; on the farm view the icon never shows and the ShopButton does. Twice (Back, then the fork opens the zoom again).
# goal T8.1
func t_tools_icon_first_zoom_place_and_farm_view_twice() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	for run in [1, 2]:
		await _wait(_zoom_settle())
		eq(_tl_place_problems(false), [], "run %d step first zoom: the icon is placed as the spec says" % run)
		await _tl_to_farm(m, p, "run %d" % run)
		ck(not _tl_on(), "run %d step farm view: the Tools icon never shows on the farm view" % run)
		ck(_tl_shop_btn_on(), "run %d step farm view: the ShopButton shows again" % run)
		if run == 1:
			tr["risen"] = -1
			ck(await _open_zoom(m, p, tr), "run 2: the fork opens the zoom again")
	_fin()


## Second stop: the same placement (clear of the crank this time); the ShopButton is hidden; Back to the farm view hides the icon, Spin brings both back. Twice.
# goal T8.1
func t_tools_icon_second_stop_place_and_farm_view_twice() -> void:
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	for run in [1, 2]:
		await _wait(_zoom_settle())
		ck(bool(m.call("at_second_stop")), "run %d: at the second stop" % run)
		eq(_tl_place_problems(true), [], "run %d step second stop: the icon is placed as the spec says" % run)
		await _tl_to_farm(m, p, "run %d" % run)
		ck(not _tl_on(), "run %d step farm view: the Tools icon never shows on the farm view" % run)
		ck(_tl_shop_btn_on(), "run %d step farm view: the ShopButton shows again" % run)
		if run == 1:
			await fi.click_icon(p["CentrifugeIcon"] as Control)
			ck(await _until(func() -> bool: return bool(m.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + 6.0), "run 2 step Spin: back at the second stop")
			await _wait(0.4)
	_fin()


## First zoom, sheet: Heated Fork only, no tabs, title Tools; a buy takes the config price and raises the level (Close, then the dim); fork input is blocked
## while it is open; Back closes it. Twice. (Leave by Back is the exit mid-way; the zoom ending on its own and app pause are in their own tests / open questions.)
# goal T8.1
func t_tools_first_zoom_sheet_fork_only_buy_blocks_exits_twice() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	# positive control: with the sheet closed a real drag scrapes (the blocked check below can fail)
	var hive: Node = p["Hive"]
	var caps0: int = fi.capped_total(hive, _frames_n())
	var rws: Array = fi.rows(m.find_child("Honeycomb", true, false), _cam())
	if not rws.is_empty():
		await fi.drag_row(rws[0])
	await _wait(0.3)
	ck(fi.capped_total(hive, _frames_n()) < caps0, "positive control: a real drag scrapes with the sheet closed")
	for run in [1, 2]:
		var lab: String = "run %d" % run
		await _tl_open_check(m, false, lab)
		await _tl_close_check(m, p, lab)
		await _zs_buy(m, p, "heated_fork", run == 2, lab + " step buy (%s)" % ("dim" if run == 2 else "Close"), true)
		await _zs_blocked(m, p, lab + " step blocked", true)
		await _zs_back_with_sheet(m, p, lab + " step Back", true)
		ck(not _tl_on(), "%s step Back: the farm view shows no Tools icon" % lab)
		if run == 1:
			tr["risen"] = -1
			ck(await _open_zoom(m, p, tr), "run 2: the fork opens the zoom again")
	_fin()


## Second stop, sheet: Centrifuge Gearing and Spigot Flow only, no tabs; a buy of each takes the config price; the crank counts no turn while it is open;
## Back closes it. Twice (Spin returns to the second stop).
# goal T8.1
func t_tools_second_stop_sheet_gearing_spigot_buy_blocks_exits_twice() -> void:
	var s: Dictionary = await _cranking_at_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var cen: Node = s["cen"]
	var t0: int = int(cen.get("turns_counted"))
	await _tap_free(m)
	ck(int(cen.get("turns_counted")) > t0, "positive control: a real tap at the second stop counts a turn with the sheet closed")
	for run in [1, 2]:
		var lab: String = "run %d" % run
		await _tl_open_check(m, true, lab)
		await _tl_close_check(m, p, lab)
		await _zs_buy(m, p, "gearing", false, lab + " step buy gearing (Close)", true)
		await _zs_buy(m, p, "spigot_flow", run == 2, lab + " step buy spigot (%s)" % ("dim" if run == 2 else "Close"), true)
		await _zs_blocked(m, p, lab + " step blocked", true)
		await _zs_back_with_sheet(m, p, lab + " step Back", true)
		ck(not _tl_on(), "%s step Back: the farm view shows no Tools icon" % lab)
		if run == 1:
			await fi.click_icon(p["CentrifugeIcon"] as Control)
			ck(await _until(func() -> bool: return bool(m.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + 6.0), "run 2 step Spin: back at the second stop")
			await _wait(0.4)
	_fin()


## The zoom ending on its own (every frame done) with the Tools sheet open closes the sheet as the zoom starts closing; twice, on a fresh farm each time.
# goal T8.1
func t_tools_sheet_closes_when_zoom_ends_on_its_own_twice() -> void:
	_portrait()
	for run in [1, 2]:
		var z: Dictionary = await _zoom_open_main()
		if z.is_empty():
			_fin()
			return
		var m: Node = z["m"]
		var opened: bool = await _zs_finish_with_sheet(m, z["p"], z["tr"], true)
		ck(opened, "run %d step open: the Tools sheet opened while the zoom was finishing" % run)
		if opened:
			ck(not _tl_on(), "run %d step open: the Tools icon is hidden under its open sheet" % run)
			await _zs_expect_closed_at_closing(m, "run %d step zoom ended" % run)
		await _until(func() -> bool: return int(m.get("zoom")) == 0, float(cv("zoom_seconds")) + _zoom_settle() + 8.0)
		await _wait(_zoom_settle())
		ck(not _tl_sheet_open(), "run %d step farm view: the sheet is still closed" % run)
		ck(not _tl_on(), "run %d step farm view: no Tools icon" % run)
		_cleanup_main(m)
	_fin()


## Tools never changes the Shop's remembered tab: select Habitat in the Shop, open and close Tools in the zoom, and the Shop opens on Habitat. Twice.
# goal T8.1
func t_tools_leaves_shop_tab_alone_twice() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	await _tl_to_farm(m, p, "start")
	for run in [1, 2]:
		var lab: String = "run %d" % run
		await _shop_open(m, true)
		ck(await _shop_tab(m, "Habitat"), "%s step tab: the Shop has a Habitat tab to select" % lab)
		await fi.tap_at((root.find_child("ShopCloseButton", true, false) as Control).get_global_rect().get_center())
		await _frames(3)
		tr["risen"] = -1
		ck(await _open_zoom(m, p, tr), "%s: the fork opens the zoom" % lab)
		await _tl_open_check(m, false, lab)
		await _tl_close_check(m, p, lab)
		await _tl_to_farm(m, p, lab)
		await _shop_open(m, true)
		var tab: Button = root.find_child("TabHabitat", true, false) as Button
		ck(tab != null and tab.button_pressed, "%s step Shop: the Shop opens on its last tab, Habitat (Tools left it alone)" % lab)
		var row: Control = root.find_child("Row_plant_patch", true, false) as Control
		ck(row != null and row.is_visible_in_tree(), "%s step Shop: the Habitat row shows, not Tools' Heated Fork" % lab)
		await fi.tap_at((root.find_child("ShopCloseButton", true, false) as Control).get_global_rect().get_center())
		await _frames(3)
	_fin()


## shop_layout = 0 (compact panel): the Tools icon never shows in a zoom and asking for its sheet shows nothing; back on 1 it shows again.
# goal T8.1
func t_tools_shop_layout_zero_never_shows() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	await _wait(_zoom_settle())
	ck(_tl_on(), "positive control: with shop_layout 1 the icon shows in the zoom")
	_set_cfg("shop_layout", 0)
	await _frames(4)
	ck(not _tl_on(), "shop_layout 0: no Tools icon in the first zoom")
	var panel: Node = root.find_child("ShopPanel", true, false)
	if panel != null and panel.has_method("set_tools_open"):
		panel.call("set_tools_open", true)
		await _frames(3)
		ck(not _tl_sheet_open(), "shop_layout 0: asking for the Tools sheet shows nothing")
	_set_cfg("shop_layout", 1)
	await _frames(4)
	ck(_tl_on(), "shop_layout back to 1: the icon shows again")
	_fin()


## Labels: "Outils" in French and "Tools" in English (content/ui-labels.md), on the label under the icon and on the sheet's title.
# goal T8.1
func t_tools_label_and_title_read_outils_in_french() -> void:
	var want: Dictionary = {}
	var f: FileAccess = FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../content/ui-labels.md").simplify_path(), FileAccess.READ)
	if f != null:
		while not f.eof_reached():
			var line: String = f.get_line().strip_edges()
			if line.begins_with("tools_icon,\""):
				var cols: PackedStringArray = line.substr("tools_icon,".length()).trim_prefix("\"").trim_suffix("\"").split("\",\"")
				if cols.size() == 2:
					want = {"en": cols[0], "fr": cols[1]}
	ck(not want.is_empty(), "content/ui-labels.md holds the approved tools_icon row")
	if want.is_empty():
		_fin()
		return
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var old: String = TranslationServer.get_locale()
	await _wait(_zoom_settle())
	for loc in ["fr", "en", "fr"]:
		TranslationServer.set_locale(loc)
		await _frames(3)
		var l: Label = _tl_label()
		ck(l != null and l.text == want[loc], "%s: the label under the icon reads '%s' (got '%s'; diag: locale=%s translate=%s tools_btn_on=%s)" % [loc, want[loc], l.text if l != null else "<none>", TranslationServer.get_locale(), TranslationServer.translate("tools_icon"), str(_tl_on())])
		await _tl_open_check(m, false, loc)
		var title: Label = root.find_child("ShopTitle", true, false) as Label
		eq(title.text if title != null else "<none>", want[loc], "%s: the sheet title reads the same word" % loc)
		await _tl_close_check(m, p, loc)
	TranslationServer.set_locale(old)
	_fin()
