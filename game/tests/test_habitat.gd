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
	var icons: Array = pill.find_children("*", "TextureRect", true, false)
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
			ck(not pr.intersects(c.get_global_rect()), "the pill clears %s" % nm)
	var panel: Control = m.find_child("ShopPanel", true, false) as Control
	for run in 2:
		if panel != null and panel.has_method("set_sheet_open"):
			panel.call("set_sheet_open", false)
		await _frames(3)
		ck(panel != null and not panel.visible, "run %d: the Shop is closed before the tap" % (run + 1))
		await fi.tap_at(plus.get_global_rect().get_center())
		await _frames(3)
		ck(panel != null and panel.visible, "run %d: a real tap on + opens the Shop" % (run + 1))
	if panel != null and panel.has_method("set_sheet_open"):
		panel.call("set_sheet_open", false)
	_fin()
