# Implements GDD 2 (Phase 1 uncapping close-up, stage 1 only) and 9 (UI & Screens) for Prototype 0.
# The close-up shows a hint and a BackButton. Extraction, bottling and the summary now play on the farm.
# Finds its child controls by name (see "Node paths for Bob" in game/specs/prototype-0.md); holds no layout.
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
	show_stage1()


## Uncapping in progress: the drag hint and the Back button.
func show_stage1() -> void:
	if _hint != null:
		_hint.text = _hint_text
	if _back_button != null:
		_back_button.visible = true


## Every cell is uncapped: the hint changes and Back goes away (the frame has left the hive).
func show_stage1_done() -> void:
	if _hint != null:
		_hint.text = "All cells uncapped!"
	if _back_button != null:
		_back_button.visible = false
