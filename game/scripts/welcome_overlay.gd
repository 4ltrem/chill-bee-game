# Implements 0.3 item 1 (game/specs/0.3-course-build.md): the welcome overlay. A CanvasLayer in main.tscn (Bob builds the nodes):
# the title label (not translated) and one Play button "PlayButton" whose text goes through tr("welcome_play"). Emits play_pressed
# and frees itself; main.gd holds the world idle until then.
class_name WelcomeOverlay
extends CanvasLayer

signal play_pressed

var _button: BaseButton


func _ready() -> void:
	_button = find_child("PlayButton", true, false) as BaseButton
	if _button == null:
		push_error("welcome_overlay.gd: no PlayButton node under the overlay (see the 0.3 handoff).")
		return
	if _button is Button:
		(_button as Button).text = tr("welcome_play")
	_button.pressed.connect(press)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _button is Button:
		(_button as Button).text = tr("welcome_play")


## Play: tell main.gd, then remove the overlay. Public so a test can call it.
func press() -> void:
	play_pressed.emit()
	queue_free()
