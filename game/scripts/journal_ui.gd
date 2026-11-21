# Implements 0.2 item 8 (game/specs/0.2-first-automation.md): the Bee Journal panel, EN/FR through tr().
# Attach to FarmUI (or any ancestor of JournalButton/JournalPanel); nodes are found by name (0.2-node-handoff.md).
# Text keys come from game/translations/journal.csv (exported by _tools/journal_csv.py).
class_name JournalUI
extends Node

const ENTRY_ID: String = "BUMBLE_BEES"

var _panel: Control
var _title: Label
var _body: Label


func _ready() -> void:
	_panel = get_parent().find_child("JournalPanel", true, false) as Control
	_title = get_parent().find_child("JournalTitle", true, false) as Label
	_body = get_parent().find_child("JournalBody", true, false) as Label
	var open_button: Button = get_parent().find_child("JournalButton", true, false) as Button
	var close_button: Button = get_parent().find_child("JournalCloseButton", true, false) as Button
	if _panel != null:
		_panel.visible = false
	if open_button != null:
		open_button.pressed.connect(open)
	if close_button != null:
		close_button.pressed.connect(close)


func open() -> void:
	_refresh_text()
	if _panel != null:
		_panel.z_index = 60   # above the shop sheet (z 51) and its dim (z 50) so Close takes the press
		_panel.top_level = true   # GUI root sorted by z, like ShopPanel: tree order does not decide picking
		_panel.visible = true


func close() -> void:
	if _panel != null:
		_panel.visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _panel != null and _panel.visible:
		_refresh_text()


func _refresh_text() -> void:
	if _title != null:
		_title.text = tr("JOURNAL_%s_TITLE" % ENTRY_ID)
	if _body != null:
		_body.text = tr("JOURNAL_%s_BODY" % ENTRY_ID)
