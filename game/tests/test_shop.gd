extends "res://tests/test_lid_clip.gd"

# Quinn: 0.2 item 1 (upgrade shop rows), written from game/specs/0.2-first-automation.md (item 1) and game/specs/0.2-node-handoff.md.
# Every expected number is read from the config: floori(base * growth^level), the max level, the Auto-Sell gate level.

const _SHOP_ORDER: Array[String] = ["Worker Swarm Count", "Flight Endurance", "Heated Uncapping Fork", "Centrifuge Gearing", "Faster Delivery", "Auto-Sell"]
# id -> [base key, growth key, max key]; Auto-Sell is a one-time buy (max 1, price auto_sell_cost, no growth)
const _SHOP_KEYS: Dictionary = {
	"swarm": ["swarm_base_cost", "swarm_cost_growth", "swarm_max_level"],
	"flight": ["flight_base_cost", "flight_cost_growth", "flight_max_level"],
	"heated_fork": ["heated_fork_base_cost", "heated_fork_cost_growth", "heated_fork_max_level"],
	"gearing": ["gearing_base_cost", "gearing_cost_growth", "gearing_max_level"],
	"faster_delivery": ["faster_delivery_base_cost", "faster_delivery_cost_growth", "faster_delivery_max_level"],
}
const _SHOP_IDS: Array[String] = ["swarm", "flight", "heated_fork", "gearing", "faster_delivery", "auto_sell"]


func _shop_expect_cost(id: String, lvl: int) -> int:
	if id == "auto_sell":
		return floori(float(cv("auto_sell_cost")))
	var k: Array = _SHOP_KEYS[id]
	return floori(float(cv(k[0])) * pow(float(cv(k[1])), float(lvl)))


func _shop_max(id: String) -> int:
	return 1 if id == "auto_sell" else int(cv(_SHOP_KEYS[id][2]))


func _shop_unlock_level() -> int:
	return int(cv("auto_sell_unlock_delivery_level"))


## Every upgrade to 0 and money to 0 (Economy.reset), through the economy's own API.
func _shop_zero() -> Node:
	var e: Node = _eco()
	e.call("reset")
	return e


## The visible rows of the shop list, in order (RowTemplate is hidden; handoff: ShopRows holds the rows).
func _shop_rows(m: Node) -> Array:
	var out: Array = []
	var holder: Node = m.find_child("ShopRows", true, false)
	ck(holder != null, "ShopRows exists (handoff item 1)")
	if holder == null:
		return out
	for c in holder.get_children():
		if c is Control and (c as Control).visible and c.name != &"RowTemplate":
			out.append(c)
	return out


func _row_name(row: Node) -> String:
	var l: Label = row.find_child("NameLabel", true, false) as Label
	return l.text if l != null else ""


func _row_buy(row: Node) -> Button:
	var bs: Array = row.find_children("*", "Button", true, false)
	return bs[0] as Button if bs.size() > 0 else null


func _row_text(row: Node, label: String) -> Label:
	return row.find_child(label, true, false) as Label


## Costs: base x growth^level, floored, for levels 0..max (a one-time buy: its one price).
# goal T1.1
func t_shop_costs_floor_base_growth() -> void:
	var e: Node = _eco()
	for id in _SHOP_IDS:
		for lvl in _shop_max(id) + 1:
			if id == "auto_sell" and lvl > 0:
				break
			e.call("set_level", id, lvl)
			eq(int(e.call("cost", id)), _shop_expect_cost(id, lvl), "%s: cost at level %d is floor(base x growth^level)" % [id, lvl])
	_fin()


## A buy subtracts the cost and raises the level by one; every row, from level 0 up to its max.
# goal T1.1
func t_shop_buy_deducts_and_levels() -> void:
	var e: Node = _eco()
	e.call("set_level", "faster_delivery", _shop_unlock_level())   # opens the Auto-Sell gate
	for id in _SHOP_IDS:
		e.call("set_level", id, 0 if id != "faster_delivery" else _shop_unlock_level())
		var start: int = int(e.call("level", id))
		for step in _shop_max(id) - start:
			var cost: int = _shop_expect_cost(id, start + step)
			e.set("money", cost + 7)
			ck(bool(e.call("buy", id)), "%s: buy %d succeeds with cost + 7" % [id, step])
			eq(int(e.get("money")), 7, "%s: money after buy %d is what was left over" % [id, step])
			eq(int(e.call("level", id)), start + step + 1, "%s: level after buy %d" % [id, step])
	_fin()


## Buttons are disabled when unaffordable, maxed or locked, and enabled otherwise; the button shows "$cost" (rounded down).
# goal T1.1
func t_shop_buttons_disabled_unaffordable_maxed_locked() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var e: Node = _shop_zero()
	e.call("set_level", "faster_delivery", _shop_unlock_level())
	await _frames(2)
	var rows: Array = _shop_rows(m)
	eq(rows.size(), _SHOP_IDS.size(), "one row per upgrade")
	if rows.size() != _SHOP_IDS.size():
		_fin()
		return
	for i in rows.size():
		var id: String = _SHOP_IDS[i]
		var btn: Button = _row_buy(rows[i])
		ck(btn != null, "%s: the row has a buy button" % id)
		if btn == null:
			continue
		var lvl: int = int(e.call("level", id))
		var cost: int = _shop_expect_cost(id, lvl)
		e.set("money", cost - 1)
		e.call("earn", 0)
		e.emit_signal("money_changed", cost - 1)
		await _frames(2)
		ck(btn.disabled, "%s: disabled with cost - 1 (unaffordable)" % id)
		ck(btn.text.contains("$%d" % cost), "%s: the button shows the next cost $%d (text '%s')" % [id, cost, btn.text])
		e.set("money", cost)
		e.emit_signal("money_changed", cost)
		await _frames(2)
		ck(not btn.disabled, "%s: enabled with exactly the cost (not locked, not maxed)" % id)
		# maxed
		e.call("set_level", id, _shop_max(id))
		e.set("money", 100000000)
		e.emit_signal("money_changed", 100000000)
		await _frames(2)
		ck(btn.disabled, "%s: disabled when maxed, even with a fortune" % id)
		e.call("set_level", id, 0 if id != "faster_delivery" else _shop_unlock_level())
		e.set("money", 0)
	# locked: Auto-Sell with Faster Delivery 0 and a fortune
	e.call("set_level", "faster_delivery", 0)
	e.call("set_level", "auto_sell", 0)
	e.set("money", 100000000)
	e.emit_signal("money_changed", 100000000)
	await _frames(2)
	ck(_row_buy(rows[5]).disabled, "Auto-Sell: disabled while locked, even with a fortune")
	_fin()


## Rows in the spec's order; level text "Lv n / max" (or "Owned" once a one-time buy is bought).
# goal T1.1
func t_shop_rows_order_and_level_text() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var e: Node = _shop_zero()
	e.call("set_level", "faster_delivery", _shop_unlock_level())
	await _frames(2)
	var rows: Array = _shop_rows(m)
	eq(rows.size(), _SHOP_ORDER.size(), "six rows")
	for i in mini(rows.size(), _SHOP_ORDER.size()):
		eq(_row_name(rows[i]), _SHOP_ORDER[i], "row %d name" % i)
		var lab: Label = _row_text(rows[i], "LevelLabel")
		ck(lab != null, "row %d has a LevelLabel" % i)
		if lab == null:
			continue
		var id: String = _SHOP_IDS[i]
		if id != "auto_sell":
			e.call("set_level", id, 1)
			await _frames(2)
			var want_max: int = _shop_max(id)
			eq(lab.text, "Lv %d / %d" % [int(e.call("level", id)), want_max], "%s: level text" % id)
		else:
			e.call("set_level", id, 1)
			await _frames(2)
			eq(lab.text, "Owned", "Auto-Sell: level text once bought")
	_fin()


## Auto-Sell is locked until Faster Delivery 1: the gate text shows, nothing can buy it; at Faster Delivery 1 the gate goes.
# goal T1.1
func t_shop_auto_sell_locked_until_delivery_1() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var e: Node = _shop_zero()
	e.set("money", 100000000)
	e.emit_signal("money_changed", 100000000)
	await _frames(2)
	var rows: Array = _shop_rows(m)
	if rows.size() != _SHOP_IDS.size():
		ck(false, "six rows expected, got %d" % rows.size())
		_fin()
		return
	var row: Node = rows[5]
	var gate: Label = _row_text(row, "GateLabel")
	ck(gate != null and gate.is_visible_in_tree(), "step locked: the Auto-Sell gate label shows")
	if gate != null:
		eq(gate.text, "Needs Faster Delivery %d" % _shop_unlock_level(), "step locked: gate text")
	ck(_row_buy(row).disabled, "step locked: the Auto-Sell button is disabled with a fortune")
	ck(not bool(e.call("buy", "auto_sell")), "step locked: buy('auto_sell') refused")
	eq(int(e.get("money")), 100000000, "step locked: money untouched by the refused buy")
	eq(int(e.call("level", "auto_sell")), 0, "step locked: Auto-Sell still not owned")
	for i in 5:
		var g: Label = _row_text(rows[i], "GateLabel")
		ck(g == null or not g.is_visible_in_tree(), "%s has no gate" % _SHOP_IDS[i])
	# one level short of the gate (when the gate is above 1), then the gate level
	var unlock: int = _shop_unlock_level()
	if unlock > 1:
		e.call("set_level", "faster_delivery", unlock - 1)
		await _frames(2)
		ck(_row_buy(row).disabled, "step one short: still disabled")
	e.call("set_level", "faster_delivery", unlock)
	await _frames(2)
	ck(gate == null or not gate.is_visible_in_tree(), "step unlocked: the gate label is gone")
	ck(not _row_buy(row).disabled, "step unlocked: the Auto-Sell button is enabled")
	ck(bool(e.call("buy", "auto_sell")), "step unlocked: buy succeeds")
	eq(int(e.get("money")), 100000000 - floori(float(cv("auto_sell_cost"))), "step unlocked: the price was taken")
	_fin()


## The real mouse press on the first row's buy button buys; twice in a row, the second buy costs the next level's price.
# goal T1.1
func t_shop_buy_button_real_click_twice() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var e: Node = _shop_zero()
	var c0: int = _shop_expect_cost("swarm", 0)
	var c1: int = _shop_expect_cost("swarm", 1)
	e.set("money", c0 + c1 + 5)
	e.emit_signal("money_changed", c0 + c1 + 5)
	await _frames(3)
	var rows: Array = _shop_rows(m)
	if rows.is_empty():
		ck(false, "no rows")
		_fin()
		return
	var btn: Button = _row_buy(rows[0])
	ck(btn != null and btn.is_visible_in_tree(), "the first row's buy button is on screen")
	if btn == null:
		_fin()
		return
	await fi.tap_at(btn.get_global_rect().get_center())
	await _frames(2)
	eq(int(e.call("level", "swarm")), 1, "run 1: one real press buys one level")
	eq(int(e.get("money")), c1 + 5, "run 1: money after the press")
	await fi.tap_at(btn.get_global_rect().get_center())
	await _frames(2)
	eq(int(e.call("level", "swarm")), 2, "run 2: the second press buys the next level")
	eq(int(e.get("money")), 5, "run 2: the second price is the next level's, not the first's")
	await fi.tap_at(btn.get_global_rect().get_center())
	await _frames(2)
	eq(int(e.call("level", "swarm")), 2, "run 3: unaffordable, the press buys nothing")
	_fin()


## No shop row overlaps another control at 720 x 1280, and the list scrolls to its last row when the rows do not fit.
# goal T1.1
func t_shop_no_row_overlaps_other_controls() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	await _frames(2)
	var scroll: ScrollContainer = m.find_child("ShopScroll", true, false) as ScrollContainer
	ck(scroll != null, "ShopScroll exists (handoff item 1)")
	if scroll == null:
		_fin()
		return
	var e: Node = _shop_zero()
	e.call("set_level", "faster_delivery", _shop_unlock_level())
	await _frames(3)
	var sr: Rect2 = scroll.get_global_rect()
	var view: Rect2 = _vp()
	ck(view.encloses(sr), "the shop list sits inside the 720 x 1280 screen %s" % str(sr))
	var panel: Control = m.find_child("ShopPanel", true, false) as Control
	var others: Array = []
	for nm in ["TopInfo", "SellIcon", "ForkIcon", "CentrifugeIcon", "BackButton", "HiveCountLabel", "HintLabel"]:
		var c: Control = m.find_child(nm, true, false) as Control
		if c != null and c.is_visible_in_tree() and c.get_global_rect().size.x > 0.0:
			if panel != null and panel.is_ancestor_of(c):
				continue
			others.append([nm, c.get_global_rect()])
	var jb: Control = m.find_child("JournalButton", true, false) as Control
	if jb != null and jb.is_visible_in_tree():
		others.append(["JournalButton", jb.get_global_rect()])
	var rows: Array = _shop_rows(m)
	eq(rows.size(), _SHOP_IDS.size(), "six rows")
	# at the top, then scrolled to the bottom: every row's on-screen part (clipped to the list) is clear of the other controls and of its neighbours
	for pos in [0, 100000]:
		scroll.scroll_vertical = pos
		await _frames(3)
		var shown: Array = []
		for i in rows.size():
			var rr: Rect2 = (rows[i] as Control).get_global_rect().intersection(sr)
			if rr.size.y > 0.0:
				shown.append([_row_name(rows[i]), rr])
		for a in shown:
			for o in others:
				ck(not (a[1] as Rect2).intersects(o[1] as Rect2), "scroll %d: row '%s' %s overlaps %s %s" % [pos, a[0], str(a[1]), o[0], str(o[1])])
		for i in shown.size():
			for j in range(i + 1, shown.size()):
				ck(not (shown[i][1] as Rect2).intersects(shown[j][1] as Rect2), "scroll %d: rows '%s' and '%s' overlap" % [pos, shown[i][0], shown[j][0]])
		if pos > 0 and rows.size() > 0:
			var last: Rect2 = (rows[rows.size() - 1] as Control).get_global_rect()
			ck(sr.encloses(last), "scrolled to the end: the last row %s is whole inside the list %s (the list scrolls)" % [str(last), str(sr)])
	_fin()
