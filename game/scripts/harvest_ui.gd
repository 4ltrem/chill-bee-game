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
