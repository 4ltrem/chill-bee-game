extends "res://tests/test_autosell.gd"

# Quinn: 0.2 item 7 (Phase 2 flag), written from game/specs/0.2-first-automation.md before the code.
# Every expected number comes from the config. Buying goes through Economy.buy (the player-facing path).


func _rich_with_delivery(delivery_level: int) -> void:
	_eco().call("reset")
	_eco().set("money", 1000000000)
	_eco().call("set_level", "faster_delivery", delivery_level)


## Auto-Sell sets phase 2 exactly once (one phase_changed to 2), with the toast shown once; Faster Delivery alone leaves phase 1.
# goal T7.1
func t_phase2_auto_sell_sets_once_toast_once() -> void:
	var e: Node = _eco()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var toast: Control = _nn(m, "PhaseToast") as Control
	var lab: Label = _nn(m, "ToastLabel") as Label
	if toast == null or lab == null:
		_fin()
		return
	_eco().call("reset")
	_eco().set("money", 1000000000)
	await _frames(2)
	eq(e.get("phase"), 1, "start: phase is 1")
	ck(not toast.visible, "start: the toast is hidden")
	# Faster Delivery alone: every level, phase stays 1 and no toast
	var dmax: int = int(e.call("max_level", "faster_delivery"))
	for i in dmax:
		ck(bool(e.call("buy", "faster_delivery")), "Faster Delivery level %d bought" % (i + 1))
		eq(e.get("phase"), 1, "Faster Delivery %d alone: phase stays 1" % (i + 1))
		ck(not toast.visible, "Faster Delivery %d alone: no toast" % (i + 1))
	eq(e.call("level", "auto_sell"), 0, "Auto-Sell not owned yet")
	# buy Auto-Sell
	var count: Array = [0]
	e.connect("phase_changed", func(p: int) -> void:
		if p == 2:
			count[0] += 1)
	ck(bool(e.call("buy", "auto_sell")), "Auto-Sell bought")
	await _frames(2)
	eq(e.get("phase"), 2, "Auto-Sell bought: phase is 2")
	eq(count[0], 1, "Auto-Sell bought: phase 2 announced once")
	ck(toast.visible, "Auto-Sell bought: the toast shows")
	ck(lab.text.contains("Phase 2"), "the toast text names Phase 2")
	# second trigger: the toast must not show again
	toast.visible = false
	e.call("set_level", "auto_sell", 1)
	e.call("set_level", "faster_delivery", dmax)
	await _frames(2)
	eq(e.get("phase"), 2, "set again: phase still 2")
	eq(count[0], 1, "set again: phase 2 not announced a second time")
	ck(not toast.visible, "set again: the toast does not show a second time")
	# phase announced a second time (flag dropped by hand): the toast still shows only once
	e.set("phase", 1)
	e.call("set_level", "auto_sell", 0)
	e.call("set_level", "auto_sell", 1)
	await _frames(2)
	eq(e.get("phase"), 2, "re-announced: phase is 2 again")
	eq(count[0], 2, "re-announced: phase_changed(2) fired again")
	ck(not toast.visible, "re-announced: the toast does not show a second time")
	_eco().call("reset")
	_fin()


## A locked Auto-Sell cannot be bought, so phase stays 1 (no Faster Delivery owned).
# goal T7.1
func t_phase2_locked_auto_sell_keeps_phase_1() -> void:
	_rich_with_delivery(0)
	var e: Node = _eco()
	ck(not bool(e.call("buy", "auto_sell")), "locked Auto-Sell: buy refused")
	eq(e.get("phase"), 1, "locked Auto-Sell: phase stays 1")
	_eco().call("reset")
	_fin()
