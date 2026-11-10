# Implements GDD 3 (Tree A: Worker Swarm Count) and 9 (Upgrade Shop panel) for Prototype 0.
# 0.2 item 1: one row per upgrade in Economy's table, duplicated from RowTemplate (names in game/specs/0.2-node-handoff.md).
# Each buy button shows the next cost and is disabled when unaffordable, maxed or locked.
class_name ShopUI
extends Control

var _rows: Dictionary = {}   # id -> {"buy": Button, "level": Label, "gate": Label}


func _ready() -> void:
	var template: Control = find_child("RowTemplate", true, false) as Control
	if template != null:
		var holder: Node = template.get_parent()
		for id: String in Economy.UPGRADE_IDS:
			var row: Control = template.duplicate() as Control
			row.name = "Row_" + id
			row.visible = true
			holder.add_child(row)
			var buy: Button = row.find_child("BuyButton", true, false) as Button
			(row.find_child("NameLabel", true, false) as Label).text = Economy.upgrade_name(id)
			if id == "swarm" and buy != null:
				buy.name = "UpgradeButton"   # play_loop.gd looks the first row's button up by this name
			if buy != null:
				buy.pressed.connect(func() -> void: Economy.buy(id))
			_rows[id] = {
				"buy": buy,
				"level": row.find_child("LevelLabel", true, false) as Label,
				"gate": row.find_child("GateLabel", true, false) as Label,
			}
	Economy.money_changed.connect(func(_m: int) -> void: _refresh())
	Economy.upgrade_changed.connect(func(_id: String, _l: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	for id: String in _rows:
		var r: Dictionary = _rows[id]
		var lv: int = Economy.level(id)
		var maxed: bool = Economy.is_maxed(id)
		var gate: String = Economy.gate_text(id)
		var level_label: Label = r["level"]
		var gate_label: Label = r["gate"]
		var buy: Button = r["buy"]
		if level_label != null:
			if Economy.is_one_time(id):
				level_label.text = "Owned" if lv >= 1 else "Not owned"
			else:
				level_label.text = "Lv %d / %d" % [lv, Economy.max_level(id)]
		if gate_label != null:
			gate_label.text = gate
			gate_label.visible = gate != ""
		if buy != null:
			buy.disabled = not Economy.can_buy(id)
			buy.text = "Max" if maxed else "$%d" % Economy.cost(id)
