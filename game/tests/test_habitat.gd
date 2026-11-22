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
