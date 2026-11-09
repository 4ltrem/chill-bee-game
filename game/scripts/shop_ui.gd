# Implements GDD 3 (Tree A: Worker Swarm Count) and 9 (Upgrade Shop panel) for Prototype 0.
# One item. The button shows the next cost and is disabled when unaffordable or at max level.
class_name ShopUI
extends Control

var _button: Button
var _level_label: Label


func _ready() -> void:
	_button = find_child("UpgradeButton", true, false) as Button
	_level_label = find_child("LevelLabel", true, false) as Label
	if _button != null:
		_button.pressed.connect(func() -> void: Economy.buy_swarm())
	Economy.money_changed.connect(func(_m: int) -> void: _refresh())
	Economy.swarm_level_changed.connect(func(_l: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var maxed: bool = Economy.is_swarm_maxed()
	if _level_label != null:
		_level_label.text = "Worker Swarm Count  Lv %d / %d" % [Economy.swarm_level, Economy.config.swarm_max_level]
	if _button != null:
		_button.disabled = not Economy.can_buy_swarm()
		if maxed:
			_button.text = "Max level"
		else:
			_button.text = "Upgrade  $%d" % Economy.swarm_cost()
