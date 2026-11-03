# Implements GDD 2 (Extraction minigame UI, batch summary) and 8 (No-Rapid-Tap Mode toggle) for Prototype 0.
# Finds its child controls by name (see "Node paths for Bob" in game/specs/prototype-0.md); holds no layout.
class_name HarvestUI
extends Control

signal continue_pressed
signal extract_pressed

var _extract_button: Button
var _stage1_hint: Label
var _stage1_hint_text: String = ""

var _centrifuge: Centrifuge
var _stage1: Control
var _stage2: Control
var _summary: Control
var _jar_counter: Label
var _tap_bar: ProgressBar
var _crank_button: Button
var _hold_check: BaseButton
var _summary_jars: Label
var _summary_value: Label
var _summary_total: Label
var _continue_button: Button


func _ready() -> void:
	_stage1 = find_child("Stage1Panel", true, false) as Control
	_stage2 = find_child("Stage2Panel", true, false) as Control
	_summary = find_child("SummaryModal", true, false) as Control
	_jar_counter = find_child("JarCounterLabel", true, false) as Label
	_tap_bar = find_child("TapProgressBar", true, false) as ProgressBar
	_crank_button = find_child("CrankButton", true, false) as Button
	_hold_check = find_child("NoRapidTapCheck", true, false) as BaseButton
	_summary_jars = find_child("SummaryJarsLabel", true, false) as Label
	_summary_value = find_child("SummaryValueLabel", true, false) as Label
	_summary_total = find_child("SummaryTotalLabel", true, false) as Label
	_continue_button = find_child("ContinueButton", true, false) as Button
	if _crank_button != null:
		_crank_button.button_down.connect(_on_crank_down)
		_crank_button.button_up.connect(_on_crank_up)
	if _hold_check != null:
		_hold_check.button_pressed = Economy.no_rapid_tap_mode
		_hold_check.toggled.connect(_on_hold_toggled)
	if _continue_button != null:
		_continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	_extract_button = find_child("ExtractButton", true, false) as Button
	if _extract_button != null:
		_extract_button.pressed.connect(func() -> void: extract_pressed.emit())
	# The hint is the first Label directly or indirectly under Stage1Panel.
	if _stage1 is Label:
		_stage1_hint = _stage1 as Label
		_stage1_hint_text = _stage1_hint.text
	elif _stage1 != null:
		for child in _stage1.find_children("*", "Label", true, false):
			_stage1_hint = child as Label
			_stage1_hint_text = _stage1_hint.text
			break
	show_stage1()


## Called by main.gd once the centrifuge node is known.
func setup(centrifuge: Centrifuge) -> void:
	_centrifuge = centrifuge
	_centrifuge.hold_mode = Economy.no_rapid_tap_mode
	_centrifuge.jar_filled.connect(_on_jar_filled)


func show_stage1() -> void:
	_set_panels(true, false, false)
	if _stage1_hint != null:
		_stage1_hint.text = _stage1_hint_text


## Every cell is uncapped: hint "All cells uncapped!" and the large ExtractButton; stage 2 waits for extract_pressed.
func show_stage1_done() -> void:
	_set_panels(true, false, false)
	if _stage1_hint != null:
		_stage1_hint.text = "All cells uncapped!"
	if _extract_button != null:
		_extract_button.visible = true


func show_stage2(jars: int) -> void:
	_set_panels(false, true, false)
	_update_counter(0, jars)


func show_summary(jars: int, per_jar: int, total: int) -> void:
	_set_panels(false, false, true)
	if _summary_jars != null:
		_summary_jars.text = "Jars: %d" % jars
	if _summary_value != null:
		_summary_value.text = "Value per jar: $%d" % per_jar
	if _summary_total != null:
		_summary_total.text = "Batch total: $%d" % total


func _set_panels(one: bool, two: bool, three: bool) -> void:
	if _stage1 != null:
		_stage1.visible = one
	if _extract_button != null:
		_extract_button.visible = false
	if _stage2 != null:
		_stage2.visible = two
	if _summary != null:
		_summary.visible = three


func _update_counter(filled: int, total: int) -> void:
	if _jar_counter != null:
		_jar_counter.text = "Jars: %d / %d" % [filled, total]
	if _tap_bar != null:
		_tap_bar.max_value = maxf(total, 1)
		_tap_bar.value = filled


func _on_jar_filled(count: int) -> void:
	_update_counter(count, _centrifuge.jars_total)


func _on_crank_down() -> void:
	if _centrifuge == null:
		return
	if _centrifuge.hold_mode:
		_centrifuge.set_holding(true)
	else:
		_centrifuge.crank()


func _on_crank_up() -> void:
	if _centrifuge != null:
		_centrifuge.set_holding(false)


func _on_hold_toggled(pressed: bool) -> void:
	Economy.no_rapid_tap_mode = pressed
	if _centrifuge != null:
		_centrifuge.hold_mode = pressed
