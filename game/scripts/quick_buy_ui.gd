# Implements 0.3.2 item 6 (game/specs/0.3.2-tests-and-quick-buy.md): bottom slot A, the QuickBuy bar (ui-screens.md §3 option A).
# Wires Bob's QuickBuy panel (QuickBuyName, QuickBuyPrice, QuickBuyButton). Added at runtime by shop_ui.gd, like JournalUI.
# The next upgrade = the Shop row (Economy.UPGRADE_IDS order) that is unlocked, not maxed, with the lowest price; a tie goes to the earlier row.
# Buy runs Economy.buy(id), the call the Shop's own row buttons make. Shown only on the uncovered farm view.
class_name QuickBuyUI
extends Node

const BAR: String = "QuickBuy"
const MIN_BUTTON_PX: float = 120.0   # V11
const FONT_PX: int = 28              # V12
const NAME_KEYS: Dictionary = ShopUI.NAME_KEYS   # the Shop row's own tr() keys

var _bar: Control
var _name: Label
var _price: Label
var _button: Button
var _main: Node
var _victory: Node
var _next: String = ""
var _shown_key: String = ""


func _ready() -> void:
	Economy.money_changed.connect(func(_m: int) -> void: _refresh())
	Economy.upgrade_changed.connect(func(_id: String, _l: int) -> void: _refresh())


func _process(_delta: float) -> void:
	if _bar == null or not is_instance_valid(_bar):
		_bind()
		if _bar == null:
			return
	_sync_visibility()


func _bind() -> void:
	var root: Node = get_tree().root
	_bar = root.find_child(BAR, true, false) as Control
	if _bar == null:
		return
	_name = _bar.find_child("QuickBuyName", true, false) as Label
	_price = _bar.find_child("QuickBuyPrice", true, false) as Label
	_button = _bar.find_child("QuickBuyButton", true, false) as Button
	if _button != null:
		_button.custom_minimum_size.y = maxf(_button.custom_minimum_size.y, MIN_BUTTON_PX)
		_button.add_theme_font_size_override("font_size", FONT_PX)
		_button.pressed.connect(_buy)
	for label: Label in [_name, _price]:
		if label != null:
			label.add_theme_font_size_override("font_size", FONT_PX)
	var n: Node = _bar
	while n != null and not n.has_method("any_panel_open"):
		n = n.get_parent()
	_main = n
	_victory = root.find_child("VictoryOverlay", true, false)
	_refresh()


## The Shop row to offer, or "" when none is left (all maxed or locked).
func next_upgrade() -> String:
	var best: String = ""
	var best_cost: int = 0
	for id: String in Economy.UPGRADE_IDS:
		if Economy.is_maxed(id) or Economy.is_locked(id):
			continue
		var c: int = Economy.cost(id)
		if best == "" or c < best_cost:   # strict: a tie keeps the earlier row
			best = id
			best_cost = c
	return best


func _buy() -> void:
	if _next != "":
		Economy.buy(_next)   # money, level, effects, toasts, Health and thriving all follow the signals; the bar refreshes on upgrade_changed


func _price_text(id: String) -> String:
	var c: int = Economy.cost(id)
	return "%d $" % c if TranslationServer.get_locale().begins_with("fr") else "$%d" % c   # French price order ("%d $", house style)


func _refresh() -> void:
	if _bar == null:
		return
	_next = next_upgrade()
	if _next == "":
		return
	PreviewTile.fill(_bar.find_child("PreviewTile", true, false) as Control, _next)   # 0.3.2 item 7: re-rendered once when the next upgrade changes
	if _name != null:
		_name.text = tr(NAME_KEYS[_next])
	var price: String = _price_text(_next)
	if _price != null:
		_price.text = price
	if _button != null:
		_button.text = price   # the Shop row's buy text is its price
		_button.disabled = not Economy.can_buy(_next)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh()


func _sync_visibility() -> void:
	var cfg: GameConfig = GameConfig.live()
	var want: bool = cfg.shop_layout == 1 and cfg.bottom_slot == 1 and _next != "" and _covered() == false
	if _bar.visible != want:
		_bar.visible = want
	if want and _button != null:
		_button.disabled = not Economy.can_buy(_next)


## True while anything covers the farm view: a zoom, the second stop, the welcome, a panel or sheet (any_panel_open) or the victory.
func _covered() -> bool:
	if _victory == null or not is_instance_valid(_victory):
		_victory = get_tree().root.find_child("VictoryOverlay", true, false)
	if _victory != null and _victory.has_method("is_showing") and bool(_victory.call("is_showing")):
		return true
	if _main == null or not is_instance_valid(_main):
		return false
	if _main.has_method("farm_view_idle"):
		return not bool(_main.call("farm_view_idle"))
	return bool(_main.call("any_panel_open"))
