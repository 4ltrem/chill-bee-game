# Implements 0.3 item 5 (game/specs/0.3-course-build.md): the victory screen. A CanvasLayer "VictoryOverlay" in main.tscn (Bob builds
# the nodes, hidden at start): "VictoryTitle" and "VictoryBody" labels, one "VictoryButton". After Economy.thriving it is queued; it shows
# once victory_delay_seconds have passed AND the player is on the farm view (main.farm_view_idle(): no zoom, second stop, Shop sheet or
# drag). The button closes it; it never shows again for this farm (Economy.reset() re-arms it). No summary, timer or record.
class_name VictoryOverlay
extends CanvasLayer

signal shown
signal closed

var _title: Label
var _body: Label
var _button: BaseButton
var _queued: bool = false
var _wait: float = 0.0
var _done: bool = false   # shown once for this farm
var _main: Node


func _ready() -> void:
	_title = find_child("VictoryTitle", true, false) as Label
	_body = find_child("VictoryBody", true, false) as Label
	_button = find_child("VictoryButton", true, false) as BaseButton
	if _button == null:
		push_error("victory_overlay.gd: no VictoryButton node under the overlay (see the 0.3 handoff).")
	else:
		_button.pressed.connect(close)
	visible = false
	_apply_text()
	Economy.thriving.connect(_on_thriving)
	Economy.habitat_changed.connect(func(health: int) -> void:
		if health < Economy.config.habitat_thriving:   # Reset lowered Health: a new farm
			_rearm())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_apply_text()


func _apply_text() -> void:
	if _title != null:
		_title.text = tr("victory_title")
	if _body != null:
		_body.text = tr("victory_body")
	if _button is Button:
		(_button as Button).text = tr("victory_button")


func _on_thriving() -> void:
	if _done or _queued:
		return
	_queued = true
	_wait = Economy.config.victory_delay_seconds   # read when used


func is_queued() -> bool:
	return _queued


func is_showing() -> bool:
	return visible


## Re-arm for a new farm (Reset).
func _rearm() -> void:
	_queued = false
	_done = false
	visible = false


func _process(delta: float) -> void:
	if not _queued or visible:
		return
	if _bumble_toast_pending():   # 0.3.1 item 2: the delay starts once the bumble toast has finished
		return
	_wait = maxf(_wait - delta, 0.0)
	if _wait > 0.0:
		return
	if _farm_view_idle():
		_show()


func _bumble_toast_pending() -> bool:
	for node: Node in get_tree().get_nodes_in_group("farm_ui"):
		if node.has_method("bumble_toast_pending") and bool(node.call("bumble_toast_pending")):
			return true
	return false


func _farm_view_idle() -> bool:
	if _main == null or not is_instance_valid(_main):
		_main = get_parent()   # the overlay lives under Main; current_scene is not Main when a test instances it
		if _main == null or not _main.has_method("farm_view_idle"):
			_main = get_tree().current_scene
	if _main != null and _main.has_method("farm_view_idle"):
		return _main.call("farm_view_idle")
	return true


func _show() -> void:
	_queued = false
	_done = true
	visible = true
	shown.emit()


## 0.3.1 item 5 (Dev "Show victory"): shows it now, skipping the delay and the farm-view wait.
func show_now() -> void:
	if not visible:
		_show()


## The button. Public so a test can call it. Play continues unchanged.
func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
