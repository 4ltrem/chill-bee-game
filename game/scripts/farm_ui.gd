# Implements GDD 9 (UI & Screens: farm view HUD) for Prototype 0.
# Finds its child controls by name (see "Node paths for Bob" in game/specs/prototype-0.md); holds no layout.
class_name FarmUI
extends Control

signal harvest_requested

var _hive: Hive
var _money_label: Label
var _jars_label: Label
var _fill_bar: ProgressBar
var _fill_label: Label
var _paused_label: Label
var _harvest_button: Button
var _sell_button: Button
var _bee_label: Label


func _ready() -> void:
	_money_label = find_child("MoneyLabel", true, false) as Label
	_jars_label = find_child("JarsLabel", true, false) as Label
	_fill_bar = find_child("FillBar", true, false) as ProgressBar
	_fill_label = find_child("FillLabel", true, false) as Label
	_paused_label = find_child("PausedLabel", true, false) as Label
	_harvest_button = find_child("HarvestButton", true, false) as Button
	_sell_button = find_child("SellButton", true, false) as Button
	if _harvest_button != null:
		_harvest_button.pressed.connect(func() -> void: harvest_requested.emit())
	if _sell_button != null:
		_sell_button.pressed.connect(func() -> void: Economy.sell_jars())
	_bee_label = find_child("BeeCountLabel", true, false) as Label
	Economy.swarm_level_changed.connect(func(_l: int) -> void: _refresh_bees())
	_refresh_bees()
	Economy.money_changed.connect(func(_m: int) -> void: _refresh_money())
	Economy.jars_changed.connect(func(_j: int) -> void: _refresh_money())
	_refresh_money()
	_refresh_hive()


## Called by main.gd once the hive node is known.
func setup(hive: Hive) -> void:
	_hive = hive
	_hive.storage_changed.connect(func(_s: float, _o: float) -> void: _refresh_hive())
	_hive.became_full.connect(_refresh_hive)
	_refresh_hive()


func _refresh_money() -> void:
	if _money_label != null:
		_money_label.text = "$%d" % Economy.money
	if _jars_label != null:
		_jars_label.text = "Jars: %d" % Economy.jars
	if _sell_button != null:
		_sell_button.disabled = Economy.jars <= 0
		_sell_button.text = "Sell %d jars ($%d)" % [Economy.jars, Economy.jars * Economy.jar_value()]


func _refresh_bees() -> void:
	if _bee_label != null:
		_bee_label.text = "Bees: %d" % Economy.bee_count()


func _refresh_hive() -> void:
	if _hive == null:
		return
	if _fill_bar != null:
		_fill_bar.max_value = _hive.capacity
		_fill_bar.value = _hive.storage
	if _fill_label != null:
		_fill_label.text = "Hive: %d / %d" % [floori(_hive.storage), _hive.capacity]
	if _harvest_button != null:
		_harvest_button.visible = _hive.is_full()
	if _paused_label != null:
		_paused_label.visible = _hive.is_paused()
		if _hive.is_full() and not _hive.is_paused():
			_paused_label.visible = false
