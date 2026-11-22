# Implements 0.3 item 6 (game/specs/0.3-course-build.md): the small skip icon at the farm view's edge.
# Node "SkipIcon" (Button, this script). Pressing it plants every remaining patch for free through the same path as a shop buy
# (Economy.set_level "plant_patch"; patch_slots.gd grows them in and adds the Health), so thriving, the Journal and the victory follow.
# It hides once Health is thriving. The label (tooltip) is the translation key skip_icon_label.
class_name SkipIcon
extends Button

const LABEL_KEY: String = "skip_icon_label"


func _ready() -> void:
	tooltip_text = tr(LABEL_KEY)
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	Economy.habitat_changed.connect(func(_h: int) -> void: _sync())
	_sync()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		tooltip_text = tr(LABEL_KEY)


func _on_pressed() -> void:
	if is_thriving():
		return
	Economy.set_level("plant_patch", Economy.max_level("plant_patch"))   # free: no money taken


func is_thriving() -> bool:
	return Economy.habitat_health >= Economy.config.habitat_thriving


func _sync() -> void:
	visible = not is_thriving()
