# Implements GDD 9 (UI & Screens: floating call-to-action icons) and 8 (one-handed play: touch area of at least 120 x 120).
# A Button that follows a 3D anchor: each frame it places itself at camera.unproject_position(anchor) plus an offset,
# and hides when the anchor is behind the camera. main.gd decides when it is wanted (set_wanted); use the
# Button's own `pressed` signal.
class_name FloatingIcon
extends Button

const MIN_TOUCH: Vector2 = Vector2(120.0, 120.0)   # GDD 8 / spec Accessibility

## The anchor node to follow. Resolved relative to this button, then relative to the scene owner, then by name.
@export var anchor_path: NodePath
@export var screen_offset: Vector2 = Vector2.ZERO

var _anchor: Node3D
var _wanted: bool = true   # follows its anchor until main.gd says otherwise


func _ready() -> void:
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, MIN_TOUCH.x), maxf(custom_minimum_size.y, MIN_TOUCH.y))


## main.gd shows the icon only when the state table says so.
func set_wanted(value: bool) -> void:
	_wanted = value
	if not value:
		visible = false


func is_wanted() -> bool:
	return _wanted


## Screen position of the anchor's projection, or false when the anchor is missing or behind the camera.
func place() -> bool:
	if _anchor == null or not is_instance_valid(_anchor):
		_anchor = _resolve_anchor()
		if _anchor == null:
			return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(_anchor.global_position):
		return false
	var screen: Vector2 = camera.unproject_position(_anchor.global_position)
	global_position = screen - size * 0.5 + screen_offset
	return true


func _resolve_anchor() -> Node3D:
	if anchor_path.is_empty():
		return null
	var found: Node = get_node_or_null(anchor_path)
	if found == null and owner != null:
		found = owner.get_node_or_null(anchor_path)
	if found == null:
		found = get_tree().root.find_child(String(anchor_path.get_name(anchor_path.get_name_count() - 1)), true, false)
	return found as Node3D


func _process(_delta: float) -> void:
	if not _wanted:
		return
	visible = place()
