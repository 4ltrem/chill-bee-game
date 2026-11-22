# Implements 0.3 item 2 (Habitat Health pill) and GDD 9 / UI_DESIGN.md rule 9: number, wildflower icon, then "+" (opens the Shop).
# Attach to the HabitatPill node in TopInfo. Children by name: HabitatCountLabel (Label), HabitatPlusButton (Button).
class_name HabitatPill
extends Control

var _label: Label
var _plus: Button


func _ready() -> void:
	_label = find_child("HabitatCountLabel", true, false) as Label
	_plus = find_child("HabitatPlusButton", true, false) as Button
	if _plus != null:
		_plus.pressed.connect(_on_plus)
	Economy.habitat_changed.connect(func(_h: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	if _label != null:
		_label.text = str(Economy.habitat_health)


func _on_plus() -> void:
	var shop: ShopUI = get_tree().root.find_child("ShopPanel", true, false) as ShopUI
	if shop != null:
		shop.set_sheet_open(true)
