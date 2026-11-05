# Implements the 0.1 Harvest Dev mode action "Show UI bounds" (game/specs/0.1-harvest.md, Contract: dev_panel.gd).
# A top CanvasLayer that outlines every visible Control's rect (buttons in one colour, labels in another, other controls dim), draws the
# touch rects of the floating icons dashed, and marks each icon's projected anchor point. It redraws every frame, so overlaps show while
# playing. Created by dev_panel.gd only in Dev mode.
class_name UiBoundsOverlay
extends CanvasLayer

const BUTTON_COLOR := Color(0.1, 0.9, 0.2, 0.9)
const LABEL_COLOR := Color(0.2, 0.6, 1.0, 0.9)
const OTHER_COLOR := Color(0.7, 0.7, 0.7, 0.35)
const TOUCH_COLOR := Color(1.0, 0.2, 0.9, 0.95)
const ANCHOR_COLOR := Color(1.0, 0.9, 0.1, 1.0)
const LINE_WIDTH: float = 2.0
const DASH: float = 8.0
const ANCHOR_RADIUS: float = 10.0

var _canvas: Control
var _controls: Array[Control] = []


func _init() -> void:
	layer = 99
	name = "UiBoundsOverlay"


func _ready() -> void:
	_canvas = Control.new()
	_canvas.name = "Canvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func _process(_delta: float) -> void:
	if visible and _canvas != null:
		_canvas.queue_redraw()


## Every visible Control in the tree (the Dev panel and this overlay excluded). 3D subtrees are walked too (the CanvasLayers sit under the Node3D scene root).
func collect_controls() -> Array[Control]:
	_controls.clear()
	_collect(get_tree().root)
	return _controls


func _collect(node: Node) -> void:
	for child in node.get_children():
		if child == self or child is DevPanel:
			continue
		if child is Control and (child as Control).is_visible_in_tree():
			_controls.append(child as Control)
		_collect(child)


func _on_draw() -> void:
	for control in collect_controls():
		var rect: Rect2 = control.get_global_rect()
		var color: Color = OTHER_COLOR
		if control is BaseButton:
			color = BUTTON_COLOR
		elif control is Label:
			color = LABEL_COLOR
		_canvas.draw_rect(rect, color, false, LINE_WIDTH)
		if control is FloatingIcon:
			_draw_dashed_rect(rect)
			var icon: FloatingIcon = control as FloatingIcon
			if icon.has_anchor_point():
				var point: Vector2 = icon.anchor_screen_point()
				_canvas.draw_circle(point, ANCHOR_RADIUS * 0.5, ANCHOR_COLOR)
				_canvas.draw_arc(point, ANCHOR_RADIUS, 0.0, TAU, 24, ANCHOR_COLOR, LINE_WIDTH)
				_canvas.draw_dashed_line(point, rect.get_center(), ANCHOR_COLOR, 1.0, DASH)


func _draw_dashed_rect(rect: Rect2) -> void:
	var a: Vector2 = rect.position
	var b: Vector2 = Vector2(rect.end.x, rect.position.y)
	var c: Vector2 = rect.end
	var d: Vector2 = Vector2(rect.position.x, rect.end.y)
	for pair in [[a, b], [b, c], [c, d], [d, a]]:
		_canvas.draw_dashed_line(pair[0], pair[1], TOUCH_COLOR, LINE_WIDTH + 1.0, DASH)
