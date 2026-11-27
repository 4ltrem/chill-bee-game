extends "res://tests/test_helpers_6.gd"

# Quinn: 0.3.2 item 2 (tests for what the 0.3.1 play-test found), written from game/specs/0.3.2-tests-and-quick-buy.md before the code.
# Part A: Settings, Coming soon, tab text, fork fill, smooth circles, the gear under sheets and its placement.
# Every tap is a real mouse event; every expected number comes from the config, the scene or the translation table.


## A real tap on the gear opens the Settings sheet (a ModalPanel); English / Français switch its labels; Close and the dim close it.
## Twice: the second round is the first again (the dim must come back, the gear must still work).
# goal T2.1
func t_settings_gear_opens_panel_languages_close_dim_twice() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var gear: Control = _nn(m, "SettingsButton") as Control
	var panel: Control = _nn(m, "SettingsPanel") as Control
	var en_btn: Control = _nn(m, "LangEnglishButton") as Control
	var fr_btn: Control = _nn(m, "LangFrenchButton") as Control
	var title: Label = _nn(m, "SettingsTitle") as Label
	var close: Button = _nn(m, "SettingsCloseButton") as Button
	if gear == null or panel == null or en_btn == null or fr_btn == null or title == null or close == null:
		_fin()
		return
	ck(panel is ModalPanel, "SettingsPanel carries the ModalPanel script (without it the gear did nothing)")
	_pt_lang("en")
	var en_title: String = TranslationServer.translate("settings_title")
	var en_close: String = TranslationServer.translate("settings_close")
	_pt_lang("fr")
	var fr_title: String = TranslationServer.translate("settings_title")
	var fr_close: String = TranslationServer.translate("settings_close")
	_pt_lang("en")
	await _frames(2)
	ck(en_title != fr_title and en_close != fr_close, "self-check: the two languages read differently (%s / %s)" % [en_title, fr_title])
	for run in [1, 2]:
		var L: String = "run %d" % run
		ck(not panel.is_visible_in_tree(), "%s step start: the sheet is closed" % L)
		ck(_shown(gear), "%s step start: the gear shows in the farm view" % L)
		await _pt_tap(gear)
		ck(panel.is_visible_in_tree(), "%s step gear: a real tap on SettingsButton opens SettingsPanel" % L)
		ck(_vp().encloses(panel.get_global_rect()), "%s step gear: the sheet is whole on screen" % L)
		var dim: Control = m.find_child("SettingsDim", true, false) as Control
		ck(dim != null and dim.is_visible_in_tree(), "%s step gear: a dim stands behind the sheet" % L)
		eq(title.text, en_title, "%s step gear: the title reads English" % L)
		eq(close.text, en_close, "%s step gear: Close reads English" % L)
		await _pt_tap(fr_btn)
		eq(title.text, fr_title, "%s step Français: the title switches" % L)
		eq(close.text, fr_close, "%s step Français: Close switches" % L)
		ck(TranslationServer.get_locale().begins_with("fr"), "%s step Français: the locale is French" % L)
		await _pt_tap(en_btn)
		eq(title.text, en_title, "%s step English: the title switches back" % L)
		eq(close.text, en_close, "%s step English: Close switches back" % L)
		await _pt_tap(close)
		ck(not panel.is_visible_in_tree(), "%s step Close: a real tap on Close closes the sheet" % L)
		await _pt_tap(gear)
		ck(panel.is_visible_in_tree(), "%s step reopen: the gear opens it again" % L)
		dim = m.find_child("SettingsDim", true, false) as Control
		var outside: Vector2 = _vp().position + Vector2(8.0, 8.0)
		ck(dim != null and dim.is_visible_in_tree() and not panel.get_global_rect().has_point(outside), "%s step dim: the dim shows and the tap point is outside the sheet" % L)
		await fi.tap_at(outside)
		await _frames(3)
		ck(not panel.is_visible_in_tree(), "%s step dim: a real tap on the dim closes the sheet" % L)
	_fin()


## On Research and Refinery the Shop sheet shows ComingSoonLabel: visible, seen, tr("shop_coming_soon"), ink on the cream sheet (not white).
# goal T2.2
func t_coming_soon_label_visible_translated_contrasts_with_sheet() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	ck(await _pt_open_shop(m), "the Shop sheet opens with a real tap on ShopButton")
	var sheet: Control = _nn(m, "ShopPanel") as Control
	if sheet == null:
		_fin()
		return
	var box: StyleBoxFlat = sheet.get_theme_stylebox("panel") as StyleBoxFlat
	ck(box != null, "the sheet has a flat background to compare the text with")
	if box == null:
		_fin()
		return
	for lang in ["en", "fr"]:
		_pt_lang(lang)
		await _frames(2)
		for key in ["Research", "Refinery"]:
			var L: String = "%s tab %s" % [lang, key]
			await _pt_tab(m, key)
			var lab: Label = m.find_child("ComingSoonLabel", true, false) as Label
			ck(lab != null and lab.is_visible_in_tree(), "%s: ComingSoonLabel is visible" % L)
			if lab == null:
				continue
			eq(lab.text, TranslationServer.translate("shop_coming_soon"), "%s: it reads tr(\"shop_coming_soon\")" % L)
			var ink: Color = lab.get_theme_color("font_color")
			ck(ink != Color.WHITE and _pt_contrast(ink, box.bg_color) >= PT_MIN_CONTRAST, "%s: font colour %s contrasts with the sheet %s (ratio %.2f, needs %.1f)" % [L, str(ink), str(box.bg_color), _pt_contrast(ink, box.bg_color), PT_MIN_CONTRAST])
			ck(lab.modulate.a > 0.0 and sheet.get_global_rect().encloses(lab.get_global_rect()), "%s: it lies inside the sheet" % L)
			eq(_pt_covers(lab, lab.get_global_rect().get_center()), [], "%s: nothing drawn over it" % L)
	_pt_lang("en")
	_fin()


## Each of the five tabs' text fits its button at 28 px, in English and in French (no clipping), and the tabs stay on the sheet.
# goal T2.3
func t_tab_text_fits_its_button_english_and_french() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	ck(await _pt_open_shop(m), "the Shop sheet opens with a real tap on ShopButton")
	var sheet: Control = _nn(m, "ShopPanel") as Control
	for lang in ["en", "fr"]:
		_pt_lang(lang)
		await _frames(4)
		for key in PT_TAB_KEYS:
			var b: Button = _nn(m, "Tab" + key) as Button
			if b == null:
				continue
			var L: String = "%s tab %s" % [lang, key]
			ck(b.is_visible_in_tree(), "%s: the tab shows" % L)
			eq(b.get_theme_font_size("font_size"), PT_TAB_FONT, "%s: the text is %d px" % [L, PT_TAB_FONT])
			eq(b.text, TranslationServer.translate("shop_tab_" + key.to_lower()), "%s: the tab reads its translation" % L)
			ck(_pt_need_px(b) <= b.size.x + 0.5, "%s: '%s' needs %.1f px, the button is %.1f px wide (clipped)" % [L, b.text, _pt_need_px(b), b.size.x])
			ck(sheet != null and sheet.get_global_rect().grow(1.0).encloses(b.get_global_rect()), "%s: the tab lies on the sheet (%s)" % [L, str(b.get_global_rect())])
	_pt_lang("en")
	_fin()


## At a full hive the honey fill (HarvestFill) shows and covers the whole drawn circle of Harvest, not a white circle.
# goal T2.4
func t_fork_fill_covers_whole_circle_at_full_hive() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var fork: FloatingIcon = p["ForkIcon"] as FloatingIcon
	var fill: Control = _nn(m, "HarvestFill") as Control
	if fill == null:
		_fin()
		return
	_full_hive_frozen(hive)
	await _frames(6)
	ck(bool(hive.call("is_full")), "the hive is full")
	ck(_shown(fork), "Harvest shows in the farm view")
	ck(_shown(fill), "HarvestFill shows at a full hive (it hid at full and left the white circle)")
	var circle: Rect2 = fork.visible_global_rect()
	var r: Rect2 = fill.get_global_rect()
	ck(r.grow(1.0).encloses(circle), "the fill %s covers the whole drawn circle %s" % [str(r), str(circle)])
	var shape: Control = fill.find_child("FillShape", true, false) as Control
	ck(shape != null and _shown(shape), "the fill's honey shape is drawn")
	if shape != null:
		ck(shape.get_global_rect().grow(1.0).encloses(circle), "the honey shape %s covers the circle %s" % [str(shape.get_global_rect()), str(circle)])
	_fin()


## Every FloatingIcon's circle styles are smooth: corner_detail >= 24 and anti-aliasing on (the default 8 segments drew a jagged circle).
# goal T2.5
func t_floating_icon_circles_are_smooth() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	var icons: Array = m.find_children("*", "Button", true, false).filter(func(n: Node) -> bool: return n is FloatingIcon)
	for want in ["ForkIcon", "CentrifugeIcon", "SellIcon"]:
		ck(not p.is_empty() and icons.has(p[want]), "%s is among the FloatingIcons found" % want)
	for n in icons:
		var ic: FloatingIcon = n as FloatingIcon
		var flat: int = 0
		for sn in FloatingIcon.STYLE_NAMES:
			var st: StyleBoxFlat = ic.shape_style(sn) as StyleBoxFlat
			if st == null:
				continue
			flat += 1
			ck(st.corner_detail >= PT_CIRCLE_DETAIL, "%s style %s: corner_detail %d, needs >= %d" % [ic.name, sn, st.corner_detail, PT_CIRCLE_DETAIL])
			ck(st.anti_aliasing, "%s style %s: anti-aliasing is on" % [ic.name, sn])
		ck(flat > 0, "%s has a circle style to check" % ic.name)
	_fin()


## With any sheet or panel open (the Shop sheet, every ModalPanel) the gear is hidden; it comes back when each closes. Twice.
# goal T2.8
func t_gear_hidden_under_every_sheet_and_panel_twice() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var gear: Control = _nn(m, "SettingsButton") as Control
	if gear == null:
		_fin()
		return
	for run in [1, 2]:
		var L: String = "run %d" % run
		ck(_shown(gear), "%s step start: the gear shows with nothing open" % L)
		ck(await _pt_open_shop(m), "%s step Shop: a real tap on ShopButton opens the sheet" % L)
		ck(not _shown(gear), "%s step Shop: the gear is hidden under the Shop sheet (its Close sat on the gear)" % L)
		await _pt_close_shop(m)
		ck(not _tl_sheet_open(), "%s step Shop: a real tap on Close closes the sheet" % L)
		ck(_shown(gear), "%s step Shop: the gear is back after Close" % L)
		await _pt_tap(gear)
		ck(not _shown(gear), "%s step Settings: opened by the gear, the gear hides" % L)
		(_nn(m, "SettingsPanel") as ModalPanel).close()
		await _frames(3)
		ck(_shown(gear), "%s step Settings: the gear is back after the sheet closes" % L)
		var seen: Array = []
		for node in get_nodes_in_group(ModalPanel.GROUP):
			var mp: ModalPanel = node as ModalPanel
			seen.append(String(mp.name))
			mp.open()
			await _frames(3)
			ck(not _shown(gear), "%s step %s: open, the gear is hidden" % [L, mp.name])
			mp.close()
			await _frames(3)
			ck(_shown(gear), "%s step %s: closed, the gear is back" % [L, mp.name])
		ck(seen.has("SettingsPanel"), "%s step panels: the modal panels found include SettingsPanel (%s)" % [L, str(seen)])
	_fin()


## The gear clears HabitatPill and SkipIcon on the farm view and is hidden in the first zoom and at the second stop (Back holds that corner).
# goal T2.9
func t_gear_clears_pill_and_skip_hidden_in_both_zooms() -> void:
	var m: Node = await _pt_farm()
	if m == null:
		_fin()
		return
	var gear: Control = _nn(m, "SettingsButton") as Control
	var pill: Control = _nn(m, "HabitatPill") as Control
	var skip: Control = _nn(m, "SkipIcon") as Control
	if gear == null or pill == null or skip == null:
		_fin()
		return
	ck(_shown(gear) and _shown(pill) and _shown(skip), "farm view: the gear, HabitatPill and SkipIcon all show")
	var g: Rect2 = gear.get_global_rect()
	ck(not g.intersects(pill.get_global_rect()), "farm view: the gear %s clears HabitatPill %s" % [str(g), str(pill.get_global_rect())])
	ck(not g.intersects(skip.get_global_rect()), "farm view: the gear %s clears SkipIcon %s" % [str(g), str(skip.get_global_rect())])
	ck(_vp().encloses(g), "farm view: the gear is whole on screen")
	_pt_drop(m)
	var z: Dictionary = await _zoom_open_main()
	if not z.is_empty():
		var zg: Control = _nn(z["m"], "SettingsButton") as Control
		ck(int(z["m"].get("zoom")) != 0 and zg != null and not _shown(zg), "first zoom: the gear is hidden")
		_pt_drop(z["m"])
	var s: Dictionary = await _second_stop_with_capped()
	if not s.is_empty():
		var sg: Control = _nn(s["m"], "SettingsButton") as Control
		ck(bool(s["m"].call("at_second_stop")) and sg != null and not _shown(sg), "second stop: the gear is hidden")
	_fin()
