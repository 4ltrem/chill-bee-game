# Implements 0.3.1 item 7 (game/specs/0.3.1-playtest-fixes.md): the shared base of the sheets that open over the farm view
# (Settings, Journal; the Shop, welcome and victory move onto it when a later item touches them).
# Attach to a hidden panel named <Name>Panel. It finds <Name>CloseButton under itself (and wires it), joins the group "modal_panels"
# (main.gd any_panel_open() asks that group), sits above the Shop sheet (z 51) and its dim (z 50), and with `with_dim` a tap outside closes it.
# Its owner script sets the texts when `refresh_requested` fires (on open and on a locale change while open).
class_name ModalPanel
extends Control

signal refresh_requested

const PANEL_Z: int = 60   # above the Shop sheet (z 51) and its dim (z 50), so Close takes the press
const DIM_Z: int = 59
const GROUP: StringName = &"modal_panels"
const DIM_COLOR: Color = Color(0.0, 0.0, 0.0, 0.35)   # same dim as the Shop sheet (ShopDim)

## A dim behind the panel that closes it on a tap; built at the first open, named <Name>Dim.
@export var with_dim: bool = false

var _dim: ColorRect


func _ready() -> void:
	add_to_group(GROUP)
	visible = false
	var close_button: Button = find_child(_prefix() + "CloseButton", true, false) as Button
	if close_button != null:
		close_button.pressed.connect(close)


func _prefix() -> String:
	return String(name).trim_suffix("Panel")


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		refresh_requested.emit()
		return
	z_index = PANEL_Z
	top_level = true   # GUI root sorted by z, like ShopPanel: tree order does not decide picking
	if with_dim:
		_show_dim(true)
	refresh_requested.emit()
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	_show_dim(false)


func _show_dim(on: bool) -> void:
	if on and _dim == null:
		_dim = ColorRect.new()
		_dim.name = _prefix() + "Dim"
		_dim.color = DIM_COLOR
		_dim.z_index = DIM_Z
		_dim.top_level = true
		_dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_dim.gui_input.connect(func(e: InputEvent) -> void:
			if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
				close())
		var holder: Node = get_parent()
		if holder != null:
			holder.add_child(_dim)
			holder.move_child(_dim, get_index())   # a sibling before the panel: a child would draw over its parent's panel
	if _dim != null and is_instance_valid(_dim):
		_dim.position = Vector2.ZERO
		_dim.size = get_viewport_rect().size
		_dim.visible = on


func _exit_tree() -> void:
	if _dim != null and is_instance_valid(_dim) and _dim.get_parent() != null:
		_dim.queue_free()
	_dim = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and visible:
		refresh_requested.emit()
