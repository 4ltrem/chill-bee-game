# Implements GDD 3 (Tree A: Worker Swarm Count) and 9 (Upgrade Shop panel) for Prototype 0.
# 0.2 item 1: one row per upgrade in Economy's table, duplicated from RowTemplate (names in game/specs/0.2-node-handoff.md).
# 0.2 item 14: no scroll container; rows go into whatever parent RowTemplate has (all seven shown at once).
# Each buy button shows the next cost and is disabled when unaffordable, maxed or locked.
class_name ShopUI
extends Control

var _rows: Dictionary = {}   # id -> {"buy": Button, "level": Label, "gate": Label}


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


func _process(_delta: float) -> void:
	if _cfg == null:
		_cfg = GameConfig.live()
	var key := Vector3i(clampi(_cfg.shop_layout, 0, 1), _cfg.shop_row_height, _cfg.shop_font_size)
	if key != _applied:
		_apply_layout()
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
	_sync_visibility()
	for dev_layer in get_tree().get_nodes_in_group("dev_button_layer") if is_inside_tree() else []:
		(dev_layer as CanvasLayer).visible = not _open   # Dev sits on CanvasLayer 50, above any z_index here; hidden it neither draws nor takes presses
	if _open:
		_place_sheet()
		_place_sheet.call_deferred()   # labels wrap at the final width, so re-measure once laid out


## Sizes the sheet to its real minimum height and anchors it to the bottom of the view.
func _place_sheet() -> void:
	if not _open or not top_level:
		return
	var view: Vector2 = get_viewport_rect().size
	size = Vector2(minf(672.0, view.x - 48.0), 0.0)
	reset_size()
	var sz: Vector2 = get_combined_minimum_size()
	sz.x = minf(672.0, view.x - 48.0)
	size = sz
	position = Vector2((view.x - sz.x) * 0.5, maxf(view.y - 24.0 - sz.y, 0.0))


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
		reset_size()
		var view: Vector2 = get_viewport_rect().size
		var sz: Vector2 = get_combined_minimum_size()
		sz.x = minf(672.0, view.x - 48.0)
		size = sz
		position = Vector2((view.x - sz.x) * 0.5, maxf(view.y - 24.0 - sz.y, 0.0))
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
	_place_dev_button()


func _build_sheet_parts() -> void:
	if _shop_button != null:
		return
	_shop_button = Button.new()   # the Shop icon: bottom-right of the farm HUD (placement is Bob's call; see the 0.2.1 handoff)
	_shop_button.name = "ShopButton"
	_shop_button.text = "Shop"
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
	_close_button = Button.new()
	_close_button.name = "ShopCloseButton"
	_close_button.text = "Close"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.add_theme_font_size_override("font_size", 32)
	_close_button.pressed.connect(func() -> void: set_sheet_open(false))
	var box: Node = find_child("ShopBox", true, false)
	if box != null:
		box.add_child(_close_button)


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
		_shop_button.visible = sheet and not _open
	if _close_button != null:
		_close_button.visible = sheet


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
