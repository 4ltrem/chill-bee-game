# Implements GDD 9 (UI & Screens: the uncapping zoom on the hive and the centrifuge) for 0.1 Harvest (game/specs/0.1-harvest.md).
# Lives in main.tscn (HarvestUIRoot/HarvestUI): shows a hint and a BackButton during the zoom, hidden otherwise.
# Finds its child controls by name (see "Node paths for Bob"); holds no layout.
class_name HarvestUI
extends Control

signal back_pressed

var _hint: Label
var _hint_text: String = ""
var _back_button: Button


func _ready() -> void:
	_hint = find_child("HintLabel", true, false) as Label
	_back_button = find_child("BackButton", true, false) as Button
	if _hint != null:
		_hint_text = _hint.text
	if _back_button != null:
		_back_button.pressed.connect(func() -> void: back_pressed.emit())
	visible = false


## The zoom opens: the drag hint and the Back button.
func show_zoom() -> void:
	visible = true
	if _hint != null:
		_hint.visible = true
		_hint.text = _hint_text
	if _back_button != null:
		_back_button.visible = true
	_keep_hint_clear_of_back()


## 0.1.4: the hint's right edge stops 16 px left of Back (parent-relative maths, so it needs no layout pass).
func _keep_hint_clear_of_back() -> void:
	if _hint == null or _back_button == null:
		return
	var parent_w: float = _hint.get_parent_area_size().x
	var back_left: float = parent_w * _back_button.anchor_left + _back_button.offset_left
	var max_right: float = back_left - 16.0 - parent_w * _hint.anchor_right
	if _hint.offset_right > max_right:
		_hint.offset_right = max_right


## The second camera stop (0.1.3c): only the Back button shows, fixed top-right like the first zoom.
func show_pan() -> void:
	visible = true
	if _hint != null:
		_hint.visible = false
	if _back_button != null:
		_back_button.visible = true


## No frame is left to uncap: the hint changes and Back goes away while the zoom closes.
func show_done() -> void:
	if _hint != null:
		_hint.text = "All cells uncapped!"
	if _back_button != null:
		_back_button.visible = false


## The zoom has ended: everything hides.
func hide_zoom() -> void:
	visible = false
