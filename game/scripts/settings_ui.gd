# Implements 0.3.1 item 7 (game/specs/0.3.1-playtest-fixes.md): the Settings icon, its sheet and the language switch.
# Attach to FarmUI (farm_ui.gd adds it if the scene has none); nodes are found by name: SettingsButton (farm view corner),
# SettingsPanel (a ModalPanel) with SettingsTitle, SettingsLanguageLabel, LangEnglishButton, LangFrenchButton, SettingsCloseButton.
# Texts come from game/translations/journal.csv (content/ui-labels.md). The language names are never translated.
class_name SettingsUI
extends Node

const LOCALES: Dictionary = {"LangEnglishButton": "en", "LangFrenchButton": "fr"}
const LANG_KEYS: Dictionary = {"LangEnglishButton": "settings_lang_en", "LangFrenchButton": "settings_lang_fr"}

static var _device_locale_set: bool = false   # once per launch: the farm reset reloads the scene and must not undo the player's pick

var _panel: ModalPanel
var _open_button: Button
var _title: Label
var _row_label: Label
var _close_button: Button
var _lang_buttons: Dictionary = {}   # node name -> Button


func _ready() -> void:
	add_to_group("settings_ui")
	apply_device_locale()
	_panel = get_parent().find_child("SettingsPanel", true, false) as ModalPanel
	_open_button = get_parent().find_child("SettingsButton", true, false) as Button
	if _open_button != null:
		_open_button.focus_mode = Control.FOCUS_NONE
		_open_button.pressed.connect(open)
	if _panel != null:
		_panel.with_dim = true   # a tap on the dim closes the sheet
		_title = _panel.find_child("SettingsTitle", true, false) as Label
		_row_label = _panel.find_child("SettingsLanguageLabel", true, false) as Label
		_close_button = _panel.find_child("SettingsCloseButton", true, false) as Button
		for button_name: String in LOCALES:
			var b: Button = _panel.find_child(button_name, true, false) as Button
			if b != null:
				_lang_buttons[button_name] = b
				b.toggle_mode = true
				b.focus_mode = Control.FOCUS_NONE
				b.pressed.connect(set_language.bind(String(LOCALES[button_name])))
		_panel.refresh_requested.connect(_refresh_text)
	_refresh_text()


## The device's language: French when it begins with "fr", else English. Applied once per launch (no save system yet).
static func apply_device_locale() -> void:
	if _device_locale_set:
		return
	_device_locale_set = true
	TranslationServer.set_locale("fr" if OS.get_locale().begins_with("fr") else "en")


func open() -> void:
	if _panel != null:
		_panel.open()


func close() -> void:
	if _panel != null:
		_panel.close()


func is_open() -> bool:
	return _panel != null and _panel.is_open()


## The toggle: every visible label updates at once (NOTIFICATION_TRANSLATION_CHANGED), the open sheet's included.
func set_language(code: String) -> void:
	TranslationServer.set_locale(code)
	_refresh_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_text()


func _refresh_text() -> void:
	if _open_button != null:
		_open_button.tooltip_text = tr("settings_title")
		if "accessibility_name" in _open_button:
			_open_button.set("accessibility_name", tr("settings_title"))
	if _title != null:
		_title.text = tr("settings_title")
	if _row_label != null:
		_row_label.text = tr("settings_language")
	if _close_button != null:
		_close_button.text = tr("settings_close")
	var current: String = TranslationServer.get_locale().substr(0, 2)
	for button_name: String in _lang_buttons:
		var b: Button = _lang_buttons[button_name]
		b.text = tr(String(LANG_KEYS[button_name]))
		b.set_pressed_no_signal(String(LOCALES[button_name]) == current)
