# Implements 0.3.2 item 9 (Habitat Health bar) on 0.3.1 item 1: "health/thriving" label and a fill share; no + (the ShopButton is the only way into the Shop).
# Attach to the HabitatPill node in TopInfo. Children by name: HabitatCountLabel (Label), HabitatTrack (Control) holding HabitatFill (Control, left-anchored, width set here). main.gd hides the pill in the first zoom and at the second stop.
class_name HabitatPill
extends Control

var _label: Label
var _track: Control
var _fill: Control


func _ready() -> void:
	_label = find_child("HabitatCountLabel", true, false) as Label
	_track = find_child("HabitatTrack", true, false) as Control
	_fill = find_child("HabitatFill", true, false) as Control
	if _fill != null:
		_fill.anchor_right = _fill.anchor_left   # equal opposite anchors: the width is set by size.x below, no size-override warning
	Economy.habitat_changed.connect(func(_h: int) -> void: _refresh())
	if _track != null:
		_track.resized.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var thriving: int = maxi(Economy.config.habitat_thriving, 1)
	if _label != null:
		_label.text = "%d/%d" % [Economy.habitat_health, thriving]
	if _track != null and _fill != null:
		var share: float = clampf(float(Economy.habitat_health) / float(thriving), 0.0, 1.0)
		_fill.position.x = 0.0
		_fill.size.x = _track.size.x * share
