extends RefCounted
## Shared flow steps for the windowed suites (play, measure, snapshot), which extend SceneTree. Preload and call statically.
## 0.2.1 item 14: with shop_layout 1 the shop is hidden on the farm and opens from the ShopButton or ShopUI.set_sheet_open(true).


## 0.3 item 1 (T1.1): every windowed run sets show_welcome false before it instantiates main.tscn (the welcome tests set it true themselves).
static func no_welcome(tree: SceneTree) -> void:
	var eco: Node = tree.root.get_node_or_null("Economy")
	if eco != null and eco.get("config") != null and eco.get("config").get("show_welcome") != null:
		eco.get("config").set("show_welcome", false)
	# 0.3.1 item 4: "Config `show_hint` (bool, default true; every test run sets it false except the hint tests)".
	if eco != null and eco.get("config") != null and eco.get("config").get("show_hint") != null:
		eco.get("config").set("show_hint", false)


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
