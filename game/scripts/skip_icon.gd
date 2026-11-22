# Implements 0.3 item 6 (game/specs/0.3-course-build.md): the small skip icon at the farm view's edge.
# Node "SkipIcon" (Button, this script). Pressing it plants every remaining patch for free through the same path as a shop buy
# (Economy.set_level "plant_patch"; patch_slots.gd grows them in and adds the Health), so thriving, the Journal and the victory follow.
# It hides once Health is thriving. The label (tooltip) is the translation key skip_icon_label.
class_name SkipIcon
extends Button

const LABEL_KEY: String = "skip_icon_label"

var _on_farm_view: bool = true


func _ready() -> void:
	tooltip_text = tr(LABEL_KEY)
	if "accessibility_name" in self:
		set("accessibility_name", tr(LABEL_KEY))
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	Economy.habitat_changed.connect(func(_h: int) -> void: _sync())
	_sync()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		tooltip_text = tr(LABEL_KEY)


func _on_pressed() -> void:
	if is_thriving() or _welcome_up():
		return
	Economy.set_level("plant_patch", Economy.max_level("plant_patch"))   # free: no money taken


func is_thriving() -> bool:
	return Economy.habitat_health >= Economy.config.habitat_thriving


func _welcome_up() -> bool:
	var m: Node = get_parent()   # walk up to Main: current_scene is not Main when a test instances it (as victory_overlay.gd)
	while m != null and not m.has_method("welcome_active"):
		m = m.get_parent()
	return m != null and m.welcome_active()


## Main calls this on every state change: the icon is a farm-view control only.
func set_on_farm_view(on: bool) -> void:
	_on_farm_view = on
	_sync()


func _sync() -> void:
	visible = _on_farm_view and not is_thriving()
