# Implements GDD 9 (UI & Screens: farm view HUD) for Prototype 0: money, fill bar, bee counter, paused label,
# the centrifuge progress label and the sale summary modal (0.1.2: shown after Sell, three lines; no Continue).
# Finds its child controls by name (see "Node paths for Bob" in game/specs/prototype-0.md); holds no layout.
# The three floating icons are driven by main.gd, which owns the state table.
class_name FarmUI
extends Control

signal summary_closed

const HINT_TEXT := "Tap or hold to spin"

var _hive: Hive
var _centrifuge: Centrifuge
var _truck: Truck
var _money_label: Label
var _fill_bar: ProgressBar
var _fill_label: Label
var _paused_label: Label
var _bee_label: Label
var _centrifuge_label: Label
var _summary: Control
var _summary_jars: Label
var _summary_value: Label
var _summary_total: Label
var _summary_ok: Button
var _top_saved: bool = false
var _top_flags: int = 0
var _bar_flags: int = 0
var _bar_min_x: float = 0.0


func _ready() -> void:
	_money_label = find_child("MoneyLabel", true, false) as Label
	_fill_bar = find_child("FillBar", true, false) as ProgressBar
	_fill_label = find_child("FillLabel", true, false) as Label
	_paused_label = find_child("PausedLabel", true, false) as Label
	_bee_label = find_child("BeeCountLabel", true, false) as Label
	_centrifuge_label = find_child("CentrifugeLabel", true, false) as Label
	_summary = find_child("SummaryModal", true, false) as Control
	_summary_jars = find_child("SummaryJarsLabel", true, false) as Label
	_summary_value = find_child("SummaryValueLabel", true, false) as Label
	_summary_total = find_child("SummaryTotalLabel", true, false) as Label
	_summary_ok = find_child("SummaryOkButton", true, false) as Button
	if _summary_ok != null:
		_summary_ok.pressed.connect(_on_summary_ok)
	if _summary != null:
		_summary.visible = false
	if _centrifuge_label != null:
		_centrifuge_label.visible = false
	Economy.swarm_level_changed.connect(func(_l: int) -> void: _refresh_bees())
	Economy.money_changed.connect(func(_m: int) -> void: _refresh_money())
	_refresh_bees()
	_refresh_money()
	_refresh_hive()


## Called by main.gd once the farm nodes are known.
func setup(hive: Hive, centrifuge: Centrifuge, truck: Truck) -> void:
	_hive = hive
	_hive.storage_changed.connect(func(_s: float, _o: float) -> void: _refresh_hive())
	_hive.became_full.connect(_refresh_hive)
	_refresh_hive()
	_centrifuge = centrifuge
	if _centrifuge != null:
		_centrifuge.state_changed.connect(func(_s: int) -> void: _refresh_centrifuge())
		_centrifuge.extraction_progress.connect(func(_d: float, _t: float) -> void: _refresh_centrifuge())
		_centrifuge.turn_counted.connect(func(_t: int) -> void: _refresh_centrifuge())
		_refresh_centrifuge()
	# The truck's load is shown on the truck itself; the farm UI keeps no jar counter.
	_truck = truck


## 0.1.3c, second camera stop: the top info column shrinks to its content and the Hive bar stops `gap` px left of every obstacle rect (the hive,
## the centrifuge) that sits level with the column.
func fit_top_info(obstacles: Array[Rect2], gap: float) -> void:
	var info: Control = find_child("TopInfo", true, false) as Control
	if info == null:
		return
	if not _top_saved:
		_top_saved = true
		_top_flags = info.size_flags_horizontal
		if _fill_bar != null:
			_bar_flags = _fill_bar.size_flags_horizontal
			_bar_min_x = _fill_bar.custom_minimum_size.x
	info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if _fill_bar != null:
		_fill_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var max_right: float = INF
		var column: Rect2 = info.get_global_rect()
		for r in obstacles:
			if r.position.y < column.end.y and r.end.y > column.position.y:
				max_right = minf(max_right, r.position.x - gap)
		_fill_bar.custom_minimum_size.x = maxf(max_right - info.global_position.x, 1.0) if max_right < INF else _bar_min_x


## Back to the full-width Hive bar.
func restore_top_info() -> void:
	if not _top_saved:
		return
	_top_saved = false
	var info: Control = find_child("TopInfo", true, false) as Control
	if info != null:
		info.size_flags_horizontal = _top_flags
	if _fill_bar != null:
		_fill_bar.size_flags_horizontal = _bar_flags
		_fill_bar.custom_minimum_size.x = _bar_min_x


func show_summary(jars: int, per_jar: int, total: int) -> void:
	if _summary_jars != null:
		_summary_jars.text = "Jars sold: %d" % jars
	if _summary_value != null:
		_summary_value.text = "Price per jar: $%d" % per_jar
	if _summary_total != null:
		_summary_total.text = "Total: $%d" % total
	if _summary != null:
		_summary.visible = true


func _on_summary_ok() -> void:
	if _summary != null:
		_summary.visible = false
	summary_closed.emit()


func _refresh_centrifuge() -> void:
	if _centrifuge_label == null or _centrifuge == null:
		return
	var cranking: bool = _centrifuge.state == Centrifuge.State.CRANKING
	_centrifuge_label.visible = cranking
	if cranking:
		var text: String = "Honey: %d / %d" % [floori(_centrifuge.jars_extracted + 1.0e-6), floori(_centrifuge.jars_total + 1.0e-6)]
		if _centrifuge.turns_counted == 0:
			text += "\n" + HINT_TEXT
		_centrifuge_label.text = text


func _refresh_money() -> void:
	if _money_label != null:
		_money_label.text = "$%d" % Economy.money


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
	if _paused_label != null:
		_paused_label.visible = _hive.is_paused()
