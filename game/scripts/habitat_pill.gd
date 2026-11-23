# Implements 0.3 item 2 as changed by 0.3.1 item 1 (Habitat Health pill) and UI_DESIGN.md rule 9: number and wildflower icon only; no + (the ShopButton is the only way into the Shop).
# Attach to the HabitatPill node in TopInfo. Child by name: HabitatCountLabel (Label). main.gd hides the pill in the first zoom and at the second stop.
class_name HabitatPill
extends Control

var _label: Label


func _ready() -> void:
	_label = find_child("HabitatCountLabel", true, false) as Label
	Economy.habitat_changed.connect(func(_h: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	if _label != null:
		_label.text = str(Economy.habitat_health)
