# Implements 0.2 item 8 (game/specs/0.2-first-automation.md): the Bee Journal panel, EN/FR through tr().
# Attach to FarmUI (or any ancestor of JournalButton/JournalPanel); nodes are found by name (0.2-node-handoff.md).
# Text keys come from game/translations/journal.csv (exported by _tools/journal_csv.py).
class_name JournalUI
extends Node

const ENTRY_ID: String = "BUMBLE_BEES"

var _panel: Control
var _title: Label
var _body: Label
var _open_button: Button
var _forced: bool = false   # Dev "Unlock Journal"


func _ready() -> void:
	add_to_group("journal_ui")
	_panel = get_parent().find_child("JournalPanel", true, false) as Control
	_title = get_parent().find_child("JournalTitle", true, false) as Label
	_body = get_parent().find_child("JournalBody", true, false) as Label
	var open_button: Button = get_parent().find_child("JournalButton", true, false) as Button
	var close_button: Button = get_parent().find_child("JournalCloseButton", true, false) as Button
	if _panel != null:
		_panel.visible = false
	if open_button != null:
		open_button.pressed.connect(open)
		# 0.3 item 4: hidden until Habitat Health is thriving; habitat_changed also covers Reset.
		_open_button = open_button
		_open_button.text = tr("journal_icon")   # 0.3.1 item 1: farm-view icon under FarmUI, labelled through tr()
		Economy.habitat_changed.connect(func(h: int) -> void:
			if h <= Economy.config.habitat_health_start:   # a reset ends a Dev unlock
				_forced = false
			_refresh_button())
		_refresh_button()
	if close_button != null:
		close_button.pressed.connect(close)


## 0.3.1 item 5 (Dev "Unlock Journal"): shows the Journal icon without thriving, until Health next drops under thriving (a reset).
func unlock() -> void:
	_forced = true
	_refresh_button()


func _refresh_button() -> void:
	if _open_button == null:
		return
	var thriving: bool = Economy.habitat_health >= Economy.config.habitat_thriving
	var unlocked: bool = thriving or _forced
	_open_button.visible = unlocked
	if not unlocked:
		close()


func open() -> void:
	_refresh_text()
	if _panel != null:
		_panel.z_index = 60   # opens over the farm, above the shop sheet (z 51) and its dim (z 50) so Close takes the press
		_panel.top_level = true   # GUI root sorted by z, like ShopPanel: tree order does not decide picking
		_panel.visible = true


func close() -> void:
	if _panel != null:
		_panel.visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if _open_button != null:
			_open_button.text = tr("journal_icon")
		if _panel != null and _panel.visible:
			_refresh_text()


func _refresh_text() -> void:
	if _title != null:
		_title.text = tr("JOURNAL_%s_TITLE" % ENTRY_ID)
	if _body != null:
		_body.text = tr("JOURNAL_%s_BODY" % ENTRY_ID)
