extends "res://tests/test_welcome.gd"

# Quinn: 0.3 item 2 (Habitat Health), written from game/specs/0.3-course-build.md item 2.
# Numbers come from the config: habitat_health_start, habitat_health_max, habitat_thriving.


## Drives Economy through its own API; counts `thriving` emissions.
# goal T2.1
func t_habitat_start_cap_thriving_once() -> void:
	var e: Node = _eco()
	var fired: Array = [0]
	var cb: Callable = func() -> void: fired[0] += 1
	e.call("reset")
	e.connect("thriving", cb)
	var start: int = int(cv("habitat_health_start"))
	var hmax: int = int(cv("habitat_health_max"))
	var thr: int = int(cv("habitat_thriving"))
	eq(int(e.get("habitat_health")), start, "step start: Health begins at habitat_health_start")
	e.call("add_habitat", 1)
	eq(int(e.get("habitat_health")), start + 1, "step add: one point raises Health by one")
	e.call("add_habitat", 0)
	e.call("add_habitat", -5)
	eq(int(e.get("habitat_health")), start + 1, "step lower: nothing lowers Health (0 and negative adds)")
	eq(fired[0], 0, "step early: no thriving below the threshold")
	e.call("add_habitat", hmax * 3)
	eq(int(e.get("habitat_health")), hmax, "step cap: Health stops at habitat_health_max")
	eq(fired[0], 1 if hmax >= thr else 0, "step thriving: emitted once when the threshold is reached")
	e.call("add_habitat", 5)
	e.call("add_habitat", hmax)
	eq(fired[0], 1, "step again: no second thriving in the same farm")
	e.call("reset")
	eq(int(e.get("habitat_health")), start, "step reset: Health back to start")
	e.call("add_habitat", hmax)
	eq(fired[0], 2, "step twice: a new farm emits thriving again, once")
	e.disconnect("thriving", cb)
	e.call("reset")
	_fin()


## The pill sits in TopInfo: number, wildflower icon, then +; + opens the Shop (real tap); clear of the action anchors.
# goal T2.1
func t_habitat_pill_order_plus_opens_shop_twice() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var e: Node = _eco()
	e.call("reset")
	await _frames(3)
	var pill: Control = m.find_child("HabitatPill", true, false) as Control
	ck(pill != null, "HabitatPill exists")
	var top: Control = m.find_child("TopInfo", true, false) as Control
	ck(pill != null and top != null and top.is_ancestor_of(pill), "the pill is in TopInfo")
	if pill == null:
		_fin()
		return
	ck(pill.is_visible_in_tree(), "the pill shows in the farm view")
	var lab: Label = pill.find_child("HabitatCountLabel", true, false) as Label
	var plus: Button = pill.find_child("HabitatPlusButton", true, false) as Button
	var icons: Array = pill.find_children("HabitatIcon", "Control", true, false)   # a flat Panel, no texture (designer 2026-11-22, V4)
	ck(lab != null and plus != null and not icons.is_empty(), "number label, icon and + button all exist")
	if lab == null or plus == null or icons.is_empty():
		_fin()
		return
	eq(lab.text, str(int(cv("habitat_health_start"))), "step start: the number is Health")
	e.call("add_habitat", 5)
	await _frames(2)
	eq(lab.text, str(int(e.get("habitat_health"))), "step add: the number follows Health")
	var ic: Control = icons[0] as Control
	var xl: float = lab.get_global_rect().position.x
	var xi: float = ic.get_global_rect().position.x
	var xp: float = plus.get_global_rect().position.x
	ck(xl < xi and xi < xp, "order: number, icon, then + (x %.0f, %.0f, %.0f)" % [xl, xi, xp])
	ck(plus.text.contains("+"), "the + button reads '+'")
	var pr: Rect2 = pill.get_global_rect()
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon"]:
		var c: Control = m.find_child(nm, true, false) as Control
		if c != null and c.is_visible_in_tree():
			ck(not pr.intersects(c.get_global_rect()), "the pill clears %s; diag: pill %s, %s %s" % [nm, pr, nm, c.get_global_rect()])
	var panel: Control = m.find_child("ShopPanel", true, false) as Control
	for run in 2:
		if panel != null and panel.has_method("set_sheet_open"):
			panel.call("set_sheet_open", false)
		await _frames(3)
		ck(panel != null and not panel.visible, "run %d: the Shop is closed before the tap" % (run + 1))
		await fi.tap_at(plus.get_global_rect().get_center())
		await _frames(3)
		ck(panel != null and panel.visible, "run %d: a real tap on + opens the Shop; diag: panel %s, plus rect %s, plus disabled %s, plus visible %s" % [run + 1, panel, plus.get_global_rect(), plus.disabled, plus.is_visible_in_tree()])
	if panel != null and panel.has_method("set_sheet_open"):
		panel.call("set_sheet_open", false)
	_fin()


## 0.3 item 4: the Journal button is hidden below habitat_thriving; at thriving the toast shows the toast_bumble_visitor text and a real
## tap on Journal opens the Bumble Bees entry; a farm reset hides the button again; the second farm does the same.
# goal T4.1
func t_bumble_visitor_toast_journal_unlock_twice() -> void:
	var d: Dictionary = _journal_read()
	var old: String = TranslationServer.get_locale()
	if d.is_empty():
		ck(false, "journal.csv opens")
		_fin()
		return
	var rows: Dictionary = d["rows"]
	TranslationServer.set_locale("en")
	var e: Node = _eco()
	var m: Node = await _mk_main()   # not quiet: a disabled Main takes no real taps (the Shop and Journal taps below)
	if m == null:
		TranslationServer.set_locale(old)
		_fin()
		return
	var thr: int = int(cv("habitat_thriving"))
	var btn: Button = m.find_child("JournalButton", true, false) as Button
	var panel: Control = m.find_child("JournalPanel", true, false) as Control
	var title: Label = m.find_child("JournalTitle", true, false) as Label
	var close: Button = m.find_child("JournalCloseButton", true, false) as Button
	var toast: Control = m.find_child("PhaseToast", true, false) as Control
	var toast_label: Label = m.find_child("ToastLabel", true, false) as Label
	if btn == null or panel == null or title == null or close == null or toast == null or toast_label == null:
		ck(false, "Journal nodes and the toast exist; diag: btn %s, panel %s, title %s, close %s, toast %s, label %s" % [btn, panel, title, close, toast, toast_label])
		TranslationServer.set_locale(old)
		_fin()
		return
	var want: String = str(rows["toast_bumble_visitor"]["en"])
	for run in [1, 2]:
		e.call("reset")
		await _frames(3)
		ck(not btn.visible, "run %d step start: the Journal button is hidden in a new farm" % run)
		e.call("add_habitat", thr - 1 - int(e.get("habitat_health")))
		await _frames(3)
		ck(not btn.visible, "run %d step below: still hidden one point under habitat_thriving; diag: health %d, thr %d" % [run, int(e.get("habitat_health")), thr])
		ck(not (toast.visible and toast_label.text == want), "run %d step below: no bumble toast yet" % run)
		e.call("add_habitat", 1)
		await _frames(3)
		ck(toast.visible, "run %d step thriving: the toast shows" % run)
		eq(toast_label.text, want, "run %d step thriving: the toast text is toast_bumble_visitor" % run)
		ck(btn.visible, "run %d step thriving: the Journal button shows" % run)
		await _shop_open(m, true)
		var pn: Control = m.find_child("ShopPanel", true, false) as Control
		var sx: String = "sheet_open %s; " % [pn.call("is_sheet_open") if pn != null and pn.has_method("is_sheet_open") else "n/a"]
		var shp: Control = m.find_child("ShopPanel", true, false) as Control
		var sbn: Control = m.find_child("ShopButton", true, false) as Control
		var anc: Array = []
		var an: Node = btn
		while an != null:
			anc.append("%s:%s" % [an.name, an.get("visible")])
			an = an.get_parent()
		var dg: String = sx + "shop panel visible %s, in tree %s, shop_layout %s; ShopButton in tree %s rect %s; toast rect %s filter %s; Journal visible %s rect %s; ancestors %s" % [
			shp.visible if shp != null else "none", shp.is_visible_in_tree() if shp != null else "none", str(m.get("shop_layout")),
			sbn.is_visible_in_tree() if sbn != null else "none", sbn.get_global_rect() if sbn != null else "none",
			toast.get_global_rect(), toast.mouse_filter, btn.visible, btn.get_global_rect(), anc]
		ck(btn.is_visible_in_tree(), "run %d step open: the Journal button is on screen in the Shop; diag: %s" % [run, dg])
		await fi.tap_at(btn.get_global_rect().get_center())
		await _frames(2)
		ck(panel.is_visible_in_tree(), "run %d step tap: a real tap on Journal opens the entry" % run)
		eq(title.text, str(rows["JOURNAL_BUMBLE_BEES_TITLE"]["en"]), "run %d step tap: the Bumble Bees title" % run)
		await fi.tap_at(close.get_global_rect().get_center())
		await _frames(2)
		ck(not panel.visible, "run %d step close: Close hides the entry" % run)
		var shop: Control = m.find_child("ShopPanel", true, false) as Control
		if shop != null and shop.has_method("set_sheet_open"):
			shop.call("set_sheet_open", false)
		e.call("reset")
		await _frames(3)
		ck(not btn.visible, "run %d step reset: a farm reset hides the Journal button again" % run)
	TranslationServer.set_locale(old)
	_fin()


## 0.3 item 3: planting. Buying walks the PatchSlots in child order; each purchase joins group flower_patch and adds
## habitat_health_per_patch to Health; cost grows per the config; a farm reset hides them again (twice).
# goal T3.1
func t_patch_plant_steps_group_health_twice() -> void:
	var e: Node = _eco()
	var m: Node = await _mk_main(true)
	if m == null:
		_fin()
		return
	var slots: Node = m.find_child("PatchSlots", true, false)
	ck(slots != null, "main.tscn has a PatchSlots node")
	if slots == null:
		_fin()
		return
	var n: int = int(cv("patch_slots"))
	var per: int = int(cv("habitat_health_per_patch"))
	var base: float = float(cv("patch_base_cost"))
	var growth: float = float(cv("patch_cost_growth"))
	for run in 2:
		e.call("reset")
		await _frames(2)
		var deco: int = root.get_tree().get_nodes_in_group("flower_patch").size()
		eq(int(slots.call("slot_count")), n, "run %d: PatchSlots holds patch_slots children" % run)
		eq(int(slots.call("planted_count")), 0, "run %d: nothing planted at start" % run)
		var h0: int = int(e.get("habitat_health"))
		for i in n:
			e.set("money", 1000000)
			eq(int(e.call("cost", "plant_patch")), floori(base * pow(growth, i)), "run %d step %d: cost is base x growth^planted" % [run, i])
			ck(bool(e.call("buy", "plant_patch")), "run %d step %d: the buy succeeds with no gate" % [run, i])
			eq(int(slots.call("planted_count")), i + 1, "run %d step %d: one more slot shown" % [run, i])
			eq(root.get_tree().get_nodes_in_group("flower_patch").size(), deco + i + 1, "run %d step %d: group flower_patch gains the planted slot; diag: before %d" % [run, i, deco])
			eq(int(e.get("habitat_health")), mini(h0 + per * (i + 1), int(cv("habitat_health_max"))), "run %d step %d: Health rises by habitat_health_per_patch" % [run, i])
		e.set("money", 1000000)
		ck(not bool(e.call("buy", "plant_patch")), "run %d: a buy at max is refused" % run)
		eq(int(slots.call("planted_count")), n, "run %d: still patch_slots planted" % run)
	e.call("reset")
	_fin()


func _sk_shown(o: Node) -> bool:
	return o != null and o.has_method("is_showing") and bool(o.call("is_showing"))


## 0.3 item 6: a real tap on SkipIcon (farm view) plants every patch for free: Health reaches habitat_thriving, money is unchanged, the victory
## follows after victory_delay_seconds on the idle farm view, and the icon hides; a reset brings it back and the second farm does the same.
# goal 0.3 T6.1
func t_skip_icon_reaches_thriving_free_twice() -> void:
	_portrait()
	var e: Node = _eco()
	var m: Node = await _mk_main()   # not quiet: a disabled Main takes no real taps
	if m == null:
		_fin()
		return
	var icon: Button = m.find_child("SkipIcon", true, false) as Button
	var slots: Node = m.find_child("PatchSlots", true, false)
	var o: Node = m.find_child("VictoryOverlay", true, false)
	if icon == null or slots == null or o == null:
		ck(false, "SkipIcon, PatchSlots and VictoryOverlay exist; diag: icon %s, slots %s, overlay %s" % [icon, slots, o])
		_fin()
		return
	var thr: int = int(cv("habitat_thriving"))
	var n: int = int(cv("patch_slots"))
	var delay: float = float(cv("victory_delay_seconds"))
	for run in [1, 2]:
		e.call("reset")
		await _frames(3)
		ck(icon.is_visible_in_tree(), "run %d step start: the skip icon shows on the idle farm view" % run)
		ck(int(e.get("habitat_health")) < thr, "run %d step start: Health is below habitat_thriving" % run)
		eq(int(slots.call("planted_count")), 0, "run %d step start: nothing planted" % run)
		eq(_sk_shown(o), false, "run %d step start: no victory yet" % run)
		var money0: Variant = e.get("money")
		await fi.tap_at(icon.get_global_rect().get_center())
		await _frames(3)
		ck(int(e.get("habitat_health")) >= thr, "run %d step tap: a real tap raises Health to habitat_thriving; diag: health %s, thr %d, icon rect %s" % [run, str(e.get("habitat_health")), thr, icon.get_global_rect()])
		eq(e.get("money"), money0, "run %d step tap: money unchanged (free)" % run)
		eq(int(slots.call("planted_count")), n, "run %d step tap: all patch_slots patches shown" % run)
		ck(not icon.visible, "run %d step tap: the icon hides once thriving" % run)
		eq(_sk_shown(o), false, "run %d step delay: the victory is not shown at once; diag: delay %s" % [run, delay])
		var ok: bool = await _until(func() -> bool: return _sk_shown(o), delay * 3.0 + 2.0)
		ck(ok, "run %d step victory: the overlay shows after victory_delay_seconds" % run)
		if o.has_method("close"):
			o.call("close")
		await _frames(2)
	e.call("reset")
	_fin()


## 0.3 item 6: the icon is a farm-view control: hidden on the welcome screen (and a press does nothing there), hidden in the first zoom and
## at the second stop, shown on the idle farm view.
# goal 0.3 T6.1
func t_skip_icon_farm_view_only() -> void:
	_portrait()
	var e: Node = _eco()
	_set_cfg("show_welcome", true)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var icon: Button = m.find_child("SkipIcon", true, false) as Button
	var slots: Node = m.find_child("PatchSlots", true, false)
	if icon == null or slots == null:
		ck(false, "SkipIcon and PatchSlots exist; diag: icon %s, slots %s" % [icon, slots])
		_fin()
		return
	ck(not icon.is_visible_in_tree(), "welcome: the skip icon is hidden while the welcome screen is up")
	icon.pressed.emit()
	await _frames(3)
	eq(int(slots.call("planted_count")), 0, "welcome: a press does nothing while the welcome screen is up")
	_cleanup_main(m)
	_set_cfg("show_welcome", false)
	var z: Dictionary = await _first_zoom_setup()
	if z.is_empty():
		_fin()
		return
	var zi: Control = (z["m"] as Node).find_child("SkipIcon", true, false) as Control
	ck(zi != null and not zi.is_visible_in_tree(), "first zoom: the skip icon is hidden")
	_cleanup_main(z["m"])
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		_fin()
		return
	var si: Control = (s["m"] as Node).find_child("SkipIcon", true, false) as Control
	ck(si != null and not si.is_visible_in_tree(), "second stop: the skip icon is hidden")
	_cleanup_main(s["m"])
	e.call("reset")
	var m2: Node = await _mk_main()
	if m2 != null:
		await _frames(3)
		var ic2: Control = m2.find_child("SkipIcon", true, false) as Control
		ck(ic2 != null and ic2.is_visible_in_tree(), "idle farm view: the skip icon shows")
	_fin()
