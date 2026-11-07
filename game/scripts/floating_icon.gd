# Implements GDD 9 (UI & Screens: floating call-to-action icons) and 8 (one-handed play: touch area of at least 120 x 120).
# A Button that follows a 3D anchor: each frame it places itself at camera.unproject_position(anchor) plus an offset,
# and hides when the anchor is behind the camera. main.gd decides when it is wanted (set_wanted); use the
# Button's own `pressed` signal.
# 0.1 Harvest (game/specs/0.1-harvest.md, Accessibility): the VISIBLE shape is drawn smaller (each dimension is the Button's size minus
# 120 - config.icon_visual_px) by a child Control behind the Button's text, from the Button's own styleboxes, which the script then
# empties. The Button's rect, and so its touch area, stays at least 120 x 120 (GDD 8).
class_name FloatingIcon
extends Button

const MIN_TOUCH: Vector2 = Vector2(120.0, 120.0)   # GDD 8 / spec Accessibility

## The anchor node to follow. Resolved relative to this button, then relative to the scene owner, then by name.
@export var anchor_path: NodePath
@export var screen_offset: Vector2 = Vector2.ZERO
@export var config: GameConfig = GameConfig.live()

const STYLE_NAMES: Array[String] = ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]
const GROUP: StringName = &"anchored_buttons"
const OFFSET_KEYS: Dictionary = {"ForkIcon": "harvest_anchor_offset", "CentrifugeIcon": "spin_anchor_offset", "SellIcon": "sell_anchor_offset"}
const AVOID_NAMES: Array[String] = ["TopInfo", "BackButton"]   # other controls an anchored button is nudged clear of

var _anchor: Node3D
var _avoid_cache: Dictionary = {}
var _wanted: bool = true   # follows its anchor until main.gd says otherwise
var _styles: Dictionary = {}
var _shape: Control
var _last_mode: int = -1
var _last_px: int = -1
var _anchor_screen: Vector2 = Vector2.ZERO
var _anchor_ok: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, MIN_TOUCH.x), maxf(custom_minimum_size.y, MIN_TOUCH.y))
	for style_name in STYLE_NAMES:
		_styles[style_name] = get_theme_stylebox(style_name)
		add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	_shape = Control.new()
	_shape.name = "VisibleShape"
	_shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shape.show_behind_parent = true
	_shape.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shape.draw.connect(_draw_shape)
	add_child(_shape)
	move_child(_shape, 0)   # 0.1.4: the shape draws first, so a show_behind_parent child (ForkIcon/HarvestFill) draws over it, under the text


## The visible shape's size: the Button's size minus (120 - icon_visual_px) in each dimension, never below 1.
func visible_size() -> Vector2:
	var shrink: float = maxf(MIN_TOUCH.x - float(config.icon_visual_px), 0.0)
	return Vector2(maxf(size.x - shrink, 1.0), maxf(size.y - shrink, 1.0))


func _draw_shape() -> void:
	var style_name: String = "normal"
	match get_draw_mode():
		DRAW_PRESSED:
			style_name = "pressed"
		DRAW_HOVER:
			style_name = "hover"
		DRAW_DISABLED:
			style_name = "disabled"
		DRAW_HOVER_PRESSED:
			style_name = "hover_pressed"
	var style: StyleBox = _styles.get(style_name) as StyleBox
	if style == null:
		return
	var shape_size: Vector2 = visible_size()
	_shape.draw_style_box(style, Rect2((size - shape_size) * 0.5, shape_size))


## Where the anchor projects on screen (valid only after place() succeeded this frame).
func anchor_screen_point() -> Vector2:
	return _anchor_screen


func has_anchor_point() -> bool:
	return _anchor_ok


## main.gd shows the icon only when the state table says so.
func set_wanted(value: bool) -> void:
	_wanted = value
	if not value:
		visible = false


func is_wanted() -> bool:
	return _wanted


## Screen position of the anchor's projection, or false when the anchor is missing or behind the camera.
func place() -> bool:
	_anchor_ok = false
	if _anchor == null or not is_instance_valid(_anchor):
		_anchor = _resolve_anchor()
		if _anchor == null:
			return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(_anchor.global_position):
		return false
	var screen: Vector2 = camera.unproject_position(_anchor.global_position)
	_anchor_screen = screen
	_anchor_ok = true
	var want: Vector2 = screen - size * 0.5 + screen_offset + Vector2(0.0, _config_offset())
	global_position = _clamp_and_nudge(want)
	return true


## 0.1.4: the one px offset this button's config key gives (the same in every view), by node name.
func _config_offset() -> float:
	var key: String = OFFSET_KEYS.get(String(name), "")
	if key == "":
		return 0.0
	return float(config.get(key))


## 0.1.4: inside the screen with button_screen_margin, then moved the shortest way (up or down) off any other visible
## anchored button or avoided control; clamped again. No per-view branches.
func _clamp_and_nudge(pos: Vector2) -> Vector2:
	var view: Vector2 = get_viewport_rect().size
	var m: float = config.button_screen_margin
	var lo := Vector2(m, m)
	var hi := Vector2(maxf(view.x - m - size.x, m), maxf(view.y - m - size.y, m))
	pos = pos.clamp(lo, hi)
	for other in _blockers():
		var box := Rect2(pos, size)
		if not box.intersects(other):
			continue
		var up: float = other.position.y - size.y
		var down: float = other.end.y
		pos.y = up if absf(up - pos.y) <= absf(down - pos.y) else down
		if pos.y < lo.y or pos.y > hi.y:
			pos.y = down if pos.y < lo.y else up
		pos = pos.clamp(lo, hi)
	return pos


func _blockers() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in get_tree().get_nodes_in_group(GROUP):
		var c := node as FloatingIcon
		if c != null and c != self and c.is_visible_in_tree() and c._wanted:
			rects.append(c.get_global_rect())
	for avoid_name in AVOID_NAMES:
		var c: Control = _avoid_cache.get(avoid_name) as Control
		if c == null or not is_instance_valid(c):
			c = get_tree().root.find_child(avoid_name, true, false) as Control
			_avoid_cache[avoid_name] = c
		if c != null and c.is_visible_in_tree():
			rects.append(c.get_global_rect())
	return rects


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
	if _shape != null and (get_draw_mode() != _last_mode or config.icon_visual_px != _last_px):
		_last_mode = get_draw_mode()
		_last_px = config.icon_visual_px
		_shape.queue_redraw()
