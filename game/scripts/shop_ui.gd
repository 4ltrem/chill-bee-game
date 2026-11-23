# Implements GDD 3 (Tree A: Worker Swarm Count) and 9 (Upgrade Shop panel) for Prototype 0.
# 0.2 item 1: one row per upgrade in Economy's table, duplicated from RowTemplate (names in game/specs/0.2-node-handoff.md).
# 0.2 item 14: no scroll container; rows go into whatever parent RowTemplate has (all seven shown at once).
# Each buy button shows the next cost and is disabled when unaffordable, maxed or locked.
class_name ShopUI
extends Control

var _rows: Dictionary = {}   # id -> {"buy": Button, "level": Label, "gate": Label, "name": Label}
const NAME_KEYS: Dictionary = {   # 0.3.1 item 7: row name keys (content/ui-labels.md)
	"swarm": "shop_row_swarm", "flight": "shop_row_endurance", "heated_fork": "shop_row_fork", "gearing": "shop_row_gearing",
	"spigot_flow": "shop_row_spigot", "faster_delivery": "shop_row_delivery", "auto_sell": "shop_row_autosell", "plant_patch": "shop_row_patch",
}


func _ready() -> void:
	var template: Control = find_child("RowTemplate", true, false) as Control
	if template != null:
		var holder: Node = template.get_parent()
		for id: String in Economy.UPGRADE_IDS:
			var row: Control = template.duplicate() as Control
			row.name = "Row_" + id
			row.visible = true
			holder.add_child(row)
			var buy: Button = row.find_child("BuyButton", true, false) as Button
			(row.find_child("NameLabel", true, false) as Label).text = Economy.upgrade_name(id)
			if id == "swarm" and buy != null:
				buy.name = "UpgradeButton"   # play_loop.gd looks the first row's button up by this name
			if buy != null:
				buy.pressed.connect(func() -> void: Economy.buy(id))
			_row_nodes[id] = row
			_rows[id] = {
				"buy": buy,
				"level": row.find_child("LevelLabel", true, false) as Label,
				"gate": row.find_child("GateLabel", true, false) as Label,
			}
	var farm_ui: Node = get_parent()   # ShopPanel sits under FarmUI: walk up, so it also works when main is not the current scene (tests)
	while farm_ui != null and farm_ui.name != "FarmUI":
		farm_ui = farm_ui.get_parent()
	if farm_ui != null:
		var journal := JournalUI.new()   # item 8: wires JournalButton / JournalPanel (added at runtime)
		farm_ui.add_child.call_deferred(journal)
	Economy.money_changed.connect(func(_m: int) -> void: _refresh())
	Economy.upgrade_changed.connect(func(_id: String, _l: int) -> void: _refresh())
	_refresh()
	_farm_ui = farm_ui as Control
	_apply_layout()


# --- 0.2 item 14: layout options, all read from GameConfig (shop_layout, shop_row_height, shop_font_size) ---
# compact: the panel stays in the Column at the bottom, rows shrunk to shop_row_height, and the DevButton moves above it.
# sheet: the panel is hidden on the farm view and opens from a Shop button; it floats (top_level) over the farm with a
# dim backdrop that closes it on a tap, plus a Close button, and hands the crank input back when it closes.

const SHEET: int = 1
const DEV_BUTTON: String = "DevButton"
var _farm_ui: Control
var _cfg: GameConfig
var _applied: Vector3i = Vector3i(-1, -1, -1)
var _open: bool = false
var _shop_button: Button
var _close_button: Button
var _dim: ColorRect
var _dev_button: Button
var _dev_home: Vector2 = Vector2(-1.0, -1.0)
var _home: Node
var _home_index: int = 0

# 0.3.1 item 3: the sheet as drawn on Shop.dc.html: header, five tabs, the selected tab's rows. Tree map from GDD 3.
const TAB_IDS: Array[String] = ["bees", "hive", "habitat", "research", "refinery"]
const TAB_OF: Dictionary = {
	"swarm": "bees", "flight": "bees",
	"heated_fork": "hive", "gearing": "hive", "spigot_flow": "hive", "faster_delivery": "hive", "auto_sell": "hive",
	"plant_patch": "habitat",
}
const TAB_NODES: Dictionary = {"bees": "TabBees", "hive": "TabHive", "habitat": "TabHabitat", "research": "TabResearch", "refinery": "TabRefinery"}
const SHEET_TOP: float = 168.0   # px below the screen top (placeholder; designer confirms at play-test)
const TAB_HEIGHT: float = 120.0  # V11
const SHEET_FONT: int = 28       # V12
var _tab: String = "bees"        # remembered while this node lives (the farm reset reloads the scene)
var _tab_buttons: Dictionary = {}
var _money_label: Label
var _header: Control
var _tabs_row: Control
var _coming_soon: Label
var _row_nodes: Dictionary = {}   # id -> row Control
var _tools_mode: bool = false     # 0.3.1 item 8: the sheet shows the machine in view's rows, no tabs
var _tools_button: Button


func _process(_delta: float) -> void:
	if _cfg == null:
		_cfg = GameConfig.live()
	var key := Vector3i(clampi(_cfg.shop_layout, 0, 1), _cfg.shop_row_height, _cfg.shop_font_size)
	if key != _applied:
		_apply_layout()
	if _shop_button != null and _applied.x == SHEET:
		var show_btn: bool = not _open and _on_farm_view()
		if _shop_button.visible != show_btn:
			_shop_button.visible = show_btn
	if _open and _tools_mode and _on_farm_view():
		set_sheet_open(false)   # the zoom ended on its own: the Tools sheet closes with it
	_sync_tools_button()
	if _dev_button == null or not is_instance_valid(_dev_button):
		if GameConfig.dev_mode_enabled():
			_dev_button = get_tree().root.find_child(DEV_BUTTON, true, false) as Button   # built at runtime by dev_panel.gd
			if _dev_button != null:
				_place_dev_button()
	elif _applied.x != SHEET:
		_place_dev_button()   # compact: follow the panel's top edge once the container has laid it out


func is_sheet_open() -> bool:
	return _open


## Opens or closes the sheet (sheet layout only); in compact the panel is always shown.
func set_sheet_open(on: bool) -> void:
	_open = on and _applied.x == SHEET
	if not _open:
		_tools_mode = false
	_apply_mode()
	if _open:
		_select_tab(_tab)   # opens on the last selected tab (Bees the first time); Tools mode shows the machine's rows instead
	_sync_visibility()
	for dev_layer in get_tree().get_nodes_in_group("dev_button_layer") if is_inside_tree() else []:
		(dev_layer as CanvasLayer).visible = not _open   # Dev sits on CanvasLayer 50, above any z_index here; hidden it neither draws nor takes presses
	if _open:
		_place_sheet()
		_place_sheet.call_deferred()   # labels wrap at the final width, so re-measure once laid out


## 0.3.1 item 8: the sheet in Tools mode, over a zoom or the second stop only. Closing goes through set_sheet_open(false) (Close, dim, Back, zoom end).
func set_tools_open(on: bool) -> void:
	if on and (_applied.x != SHEET or _on_farm_view()):
		return
	_tools_mode = on
	set_sheet_open(on)


func is_tools_open() -> bool:
	return _open and _tools_mode


## Ids of the machine in view: Heated Fork in the first zoom; Gearing and Spigot Flow at the second stop.
func _tools_ids() -> Array[String]:
	var n: Node = _farm_ui
	while n != null and not n.has_method("at_second_stop"):
		n = n.get_parent()
	if n != null and n.at_second_stop() and int(n.get("zoom")) == 0:
		var second: Array[String] = ["gearing", "spigot_flow"]
		return second
	var first: Array[String] = ["heated_fork"]
	return first


## Title and tabs follow the mode; the Shop's remembered tab is never written here.
func _apply_mode() -> void:
	var title: Label = _header.find_child("ShopTitle", true, false) as Label if _header != null else null
	if title != null:
		title.text = tr("tools_icon") if _tools_mode else tr("shop_title")



## ToolsButton (Bob's node, under FarmUIRoot): shown in the zooms and at the second stop, sheet layout only, hidden while its sheet is open.
func _sync_tools_button() -> void:
	if _tools_button == null or not is_instance_valid(_tools_button):
		_tools_button = get_tree().root.find_child("ToolsButton", true, false) as Button
		if _tools_button == null:
			return
		_tools_button.pressed.connect(func() -> void: set_tools_open(true))
	var show_btn: bool = _applied.x == SHEET and not _open and not _on_farm_view()
	if _tools_button.visible != show_btn:
		_tools_button.visible = show_btn


## Sizes the sheet to its real minimum height and anchors it to the bottom of the view.
func _place_sheet() -> void:
	if not _open or not top_level:
		return
	_fit_sheet()


## The sheet runs from SHEET_TOP to the bottom of the view, full width.
func _fit_sheet() -> void:
	var view: Vector2 = get_viewport_rect().size
	position = Vector2(0.0, SHEET_TOP)
	size = Vector2(view.x, maxf(view.y - SHEET_TOP, 0.0))


func _apply_layout() -> void:
	if _cfg == null:
		_cfg = GameConfig.live()
	var layout: int = clampi(_cfg.shop_layout, 0, 1)
	_applied = Vector3i(layout, _cfg.shop_row_height, _cfg.shop_font_size)
	for id: String in _rows:
		var r: Dictionary = _rows[id]
		var buy: Button = r["buy"]
		if buy != null:
			buy.custom_minimum_size.y = float(_cfg.shop_row_height)
		for key: String in ["level", "gate"]:
			var lab: Label = r[key]
			if lab != null:
				lab.add_theme_font_size_override("font_size", _cfg.shop_font_size - (2 if key == "gate" else 0))
		var row: Node = buy.get_parent().get_parent() if buy != null else null
		var name_label: Label = row.find_child("NameLabel", true, false) as Label if row != null else null
		if name_label != null:
			name_label.add_theme_font_size_override("font_size", _cfg.shop_font_size)
	var journal: Control = find_child("JournalButton", true, false) as Control
	if journal != null:
		journal.custom_minimum_size.y = float(_cfg.shop_row_height)
	_move_parts.call_deferred(layout == SHEET)   # deferred: the scene's parents are still setting up children in _ready
	if layout == SHEET:
		_build_sheet_parts()
		top_level = true
		var view: Vector2 = get_viewport_rect().size
		_fit_sheet()
		_dim.top_level = true
		_dim.position = Vector2.ZERO
		_dim.size = view
	else:
		_open = false
		if top_level:
			top_level = false
			var p: Control = get_parent() as Control
			if p != null:
				p.queue_sort()
		if _dim != null:
			_dim.visible = false
	_sync_visibility()
	_select_tab(_tab)   # compact: every row shown, no header or tabs
	_place_dev_button()


func _build_sheet_parts() -> void:
	if _shop_button != null:
		return
	_shop_button = Button.new()   # the Shop icon: bottom-right of the farm HUD (placement is Bob's call; see the 0.2.1 handoff)
	_shop_button.name = "ShopButton"
	_shop_button.text = tr("shop_title")
	_shop_button.focus_mode = Control.FOCUS_NONE
	_shop_button.custom_minimum_size = Vector2(120.0, 96.0)
	_shop_button.add_theme_font_size_override("font_size", 32)
	var view: Vector2 = get_viewport_rect().size
	_shop_button.position = Vector2(view.x - 120.0 - 16.0, view.y - 96.0 - 16.0)
	_shop_button.size = _shop_button.custom_minimum_size
	_shop_button.pressed.connect(func() -> void: set_sheet_open(true))
	if _farm_ui != null:
		_sheet_root().add_child.call_deferred(_shop_button)   # 0.2 item 15: under FarmUIRoot, so it stays when main hides FarmUI in the zoom
	_dim = ColorRect.new()   # a tap outside the sheet closes it; show_behind_parent keeps it under the sheet
	_dim.name = "ShopDim"
	_dim.color = Color(0.0, 0.0, 0.0, 0.35)
	_dim.z_index = 50   # sheet z 51 above it; both above the HUD (Dev button) so only the farm is dimmed
	z_index = 51
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			set_sheet_open(false))
	_attach_dim.call_deferred()   # a sibling placed before the sheet: a child draws over its parent's panel
	var box: Node = find_child("ShopBox", true, false)
	if box != null:
		_build_header_and_tabs(box)
	_sheet_style()


## Rounded top corners on the sheet panel (placeholder colours from the palette's cream; the designer confirms at play-test).
func _sheet_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.96, 0.86, 1.0)
	sb.corner_radius_top_left = 32
	sb.corner_radius_top_right = 32
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 16.0
	sb.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", sb)


## ShopHeader (ShopTitle, ShopMoney, ShopCloseButton) and ShopTabs (five tab buttons) sit above ShopRows in ShopBox.
## Nodes Bob drew in the scene are used by name; any that are missing are made here.
func _build_header_and_tabs(box: Node) -> void:
	_header = find_child("ShopHeader", true, false) as Control
	if _header == null:
		_header = HBoxContainer.new()
		_header.name = "ShopHeader"
		box.add_child(_header)
		box.move_child(_header, 0)
	var title: Label = _header.find_child("ShopTitle", true, false) as Label
	if title == null:
		title = Label.new()
		title.name = "ShopTitle"
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_header.add_child(title)
	title.text = tr("shop_title")
	title.add_theme_font_size_override("font_size", SHEET_FONT)
	_money_label = _header.find_child("ShopMoney", true, false) as Label
	if _money_label == null:
		_money_label = Label.new()
		_money_label.name = "ShopMoney"
		_header.add_child(_money_label)
	_money_label.add_theme_font_size_override("font_size", SHEET_FONT)
	_close_button = _header.find_child("ShopCloseButton", true, false) as Button
	if _close_button == null:
		_close_button = Button.new()
		_close_button.name = "ShopCloseButton"
		_header.add_child(_close_button)
		var round_box := StyleBoxFlat.new()   # round: radius = half the 120 px target
		round_box.bg_color = Color(0.2, 0.12, 0.02, 0.12)
		round_box.set_corner_radius_all(60)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			_close_button.add_theme_stylebox_override(state, round_box)
	_close_button.text = "✕"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.custom_minimum_size = Vector2(120.0, 120.0)
	_close_button.add_theme_font_size_override("font_size", 36)
	_close_button.pressed.connect(func() -> void: set_sheet_open(false))
	_tabs_row = find_child("ShopTabs", true, false) as Control
	if _tabs_row == null:
		_tabs_row = HBoxContainer.new()
		_tabs_row.name = "ShopTabs"
		box.add_child(_tabs_row)
		box.move_child(_tabs_row, _header.get_index() + 1)
	for t: String in TAB_IDS:
		var node_name: String = TAB_NODES[t]
		var b: Button = _tabs_row.find_child(node_name, true, false) as Button
		if b == null:
			b = Button.new()
			b.name = node_name
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_tabs_row.add_child(b)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.custom_minimum_size.y = TAB_HEIGHT
		b.add_theme_font_size_override("font_size", SHEET_FONT)
		b.pressed.connect(_select_tab.bind(t))
		_tab_buttons[t] = b
	var rows_holder: Node = find_child("ShopRows", true, false)
	if rows_holder != null:
		_coming_soon = Label.new()
		_coming_soon.name = "ComingSoonLabel"
		_coming_soon.modulate = Color(1.0, 1.0, 1.0, 0.5)   # greyed
		_coming_soon.add_theme_font_size_override("font_size", SHEET_FONT)
		rows_holder.add_child(_coming_soon)
	_update_tab_texts()
	_select_tab(_tab)


func _update_tab_texts() -> void:
	for t: String in _tab_buttons:
		(_tab_buttons[t] as Button).text = tr("shop_tab_" + t)
	if _coming_soon != null:
		_coming_soon.text = tr("shop_coming_soon")
	if _money_label != null:
		_money_label.text = "$%d" % Economy.money


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_tab_texts()


## Shows one tab's rows (sheet layout); Research and Refinery show the greyed "Coming soon" line. Compact shows all rows, no tabs.
func _select_tab(t: String) -> void:
	if not TAB_IDS.has(t):
		return
	if not _tools_mode:
		_tab = t   # Tools mode never changes the remembered tab
	var sheet: bool = _applied.x == SHEET
	var tools: bool = sheet and _tools_mode
	var tool_ids: Array[String] = []
	if tools:
		tool_ids = _tools_ids()
	for id: String in _row_nodes:
		var show_row: bool = tool_ids.has(id) if tools else ((not sheet) or TAB_OF.get(id, "") == _tab)
		(_row_nodes[id] as Control).visible = show_row
	for k: String in _tab_buttons:
		(_tab_buttons[k] as Button).set_pressed_no_signal(k == _tab)
	if _coming_soon != null:
		_coming_soon.visible = sheet and not tools and not TAB_OF.values().has(_tab)
	if _header != null:
		_header.visible = sheet
	if _tabs_row != null:
		_tabs_row.visible = sheet and not tools


## 0.2 item 15: the node main.gd hides on zoom is FarmUI; the sheet, its dim, the Shop button and the Journal panel live under its parent
## (FarmUIRoot) while shop_layout = 1, so they stay visible. Compact puts the panel back in the Column (farm-only).
func _sheet_root() -> Node:
	return _farm_ui.get_parent() if _farm_ui != null and _farm_ui.get_parent() != null else self


func _move_parts(to_root: bool) -> void:
	if _farm_ui == null or _farm_ui.get_parent() == null:
		return
	var root: Node = _farm_ui.get_parent()
	var journal: Control = _farm_ui.find_child("JournalPanel", true, false) as Control
	if journal == null:
		journal = root.find_child("JournalPanel", true, false) as Control
	if to_root:
		if _home == null:
			_home = get_parent()
			_home_index = get_index()
		if get_parent() != root:
			reparent(root, false)
		if _dim != null and _dim.get_parent() != null and _dim.get_parent() != root:
			_dim.reparent(root, false)
		if _dim != null and _dim.get_parent() == root:
			root.move_child(_dim, get_index())
		if journal != null and journal.get_parent() != root:
			journal.reparent(root, false)
	else:
		if _home != null and is_instance_valid(_home) and get_parent() != _home:
			reparent(_home, false)
			_home.move_child(self, mini(_home_index, _home.get_child_count() - 1))
		if journal != null and journal.get_parent() == root:
			journal.reparent(_farm_ui, false)


func _attach_dim() -> void:
	var p: Node = get_parent()
	if p == null or _dim == null or _dim.get_parent() != null:
		return
	p.add_child(_dim)
	p.move_child(_dim, get_index())


func _exit_tree() -> void:
	if _dim != null and is_instance_valid(_dim) and _dim.get_parent() != null:
		_dim.queue_free()


func _sync_visibility() -> void:
	var sheet: bool = _applied.x == SHEET
	visible = _open if sheet else true
	if _dim != null:
		_dim.visible = sheet and _open
	if _shop_button != null:
		_shop_button.visible = sheet and not _open and _on_farm_view()   # 0.3.1 item 3: the Shop opens from the farm view only
	if _close_button != null:
		_close_button.visible = sheet


## True unless main is in a zoom or at the second stop (main.gd: zoom, at_second_stop()).
func _on_farm_view() -> bool:
	var n: Node = _farm_ui
	while n != null and not n.has_method("at_second_stop"):
		n = n.get_parent()
	if n == null:
		return true
	return int(n.get("zoom")) == 0 and not n.at_second_stop()


func _place_dev_button() -> void:
	if _dev_button == null or not is_instance_valid(_dev_button):
		return
	if _dev_home.x < 0.0:
		_dev_home = _dev_button.position
	if _applied.x == SHEET:
		_dev_button.position = _dev_home
	else:   # compact: just above the panel's top edge, clear of it
		var top: float = global_position.y if is_inside_tree() else _dev_home.y + 80.0
		_dev_button.position = Vector2(_dev_home.x, minf(_dev_home.y, top - _dev_button.size.y - 8.0))


func _refresh() -> void:
	if _money_label != null:
		_money_label.text = "$%d" % Economy.money   # header money follows purchases
	for id: String in _rows:
		var r: Dictionary = _rows[id]
		var lv: int = Economy.level(id)
		var maxed: bool = Economy.is_maxed(id)
		var gate: String = Economy.gate_text(id)
		var level_label: Label = r["level"]
		var gate_label: Label = r["gate"]
		var buy: Button = r["buy"]
		if level_label != null:
			if id == "plant_patch":
				level_label.text = "%d / %d" % [lv, Economy.max_level(id)]   # 0.3 item 3
			elif Economy.is_one_time(id):
				level_label.text = "Owned" if lv >= 1 else "Not owned"
			else:
				level_label.text = "Lv %d / %d" % [lv, Economy.max_level(id)]
		if gate_label != null:
			gate_label.text = gate
			gate_label.visible = gate != ""
		if buy != null:
			buy.disabled = not Economy.can_buy(id)
			buy.text = ("Thriving" if id == "plant_patch" else "Max") if maxed else "$%d" % Economy.cost(id)
