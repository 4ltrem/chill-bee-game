extends RefCounted
## Shared flow steps for the windowed suites (play, measure, snapshot), which extend SceneTree. Preload and call statically.
## 0.2.1 item 14: with shop_layout 1 the shop is hidden on the farm and opens from the ShopButton or ShopUI.set_sheet_open(true).


## Opens the shop sheet when the layout has one and it is closed. real = a real tap on the ShopButton (fi: the FarmInput helper), else set_sheet_open(true).
static func shop_open(main: Node, fi: RefCounted = null, real: bool = false) -> void:
	var panel: Node = main.find_child("ShopPanel", true, false)
	if panel == null or not panel.has_method("set_sheet_open") or (panel as CanvasItem).visible:
		return
	var sb: Control = main.find_child("ShopButton", true, false) as Control
	if real and fi != null and sb != null and sb.is_visible_in_tree():
		await fi.tap_at(sb.get_global_rect().get_center())
	else:
		panel.call("set_sheet_open", true)
	for i in 3:
		await main.get_tree().process_frame


## Closes the shop sheet again (no-op in the compact layout or when already closed).
static func shop_close(main: Node) -> void:
	var panel: Node = main.find_child("ShopPanel", true, false)
	if panel == null or not panel.has_method("set_sheet_open") or not (panel as CanvasItem).visible:
		return
	panel.call("set_sheet_open", false)
	for i in 3:
		await main.get_tree().process_frame
