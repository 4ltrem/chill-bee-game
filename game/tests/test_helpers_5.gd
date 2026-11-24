extends "res://tests/test_hint.gd"

# Quinn: shared steps of the 0.3.1 item 8 Tools tests (game/specs/0.3.1-playtest-fixes.md item 8), written before the code.
# Spec-level reads only: the nodes ToolsButton, ShopButton, ShopPanel, ShopTitle, ShopMoney, ShopCloseButton, Row_<id>, Tab<Name>, BackButton;
# the rows by the config ids; the sizes from the spec's V11 (120 px) and the viewport from ProjectSettings.

const TOOLS_MIN_PX: float = 120.0   # spec: "A ToolsButton (120 x 120, V11)"
const _TL_TABS: Array[String] = ["TabBees", "TabHive", "TabHabitat", "TabResearch", "TabRefinery"]
const _TL_ROW_IDS: Array[String] = ["swarm", "flight", "heated_fork", "gearing", "spigot_flow", "faster_delivery", "auto_sell", "plant_patch"]


func _tl_btn() -> Control:
	return root.find_child("ToolsButton", true, false) as Control


func _tl_on() -> bool:
	var b: Control = _tl_btn()
	return b != null and b.is_visible_in_tree()


func _tl_shop_btn_on() -> bool:
	var b: Control = root.find_child("ShopButton", true, false) as Control
	return b != null and b.is_visible_in_tree()


func _tl_sheet_open() -> bool:
	var s: Control = root.find_child("ShopPanel", true, false) as Control
	return s != null and s.is_visible_in_tree()


## The word under the icon: a visible Label showing the translated `tools_icon` (the sheet's own title is not it).
func _tl_label() -> Label:
	for n in root.find_children("*", "Label", true, false):
		var l: Label = n as Label
		if l.name != &"ShopTitle" and l.is_visible_in_tree() and TranslationServer.translate(l.text) == TranslationServer.translate("tools_icon"):   # the label holds the key; Godot shows it translated
			return l
	return null


## Ids of the rows showing on the sheet now (the config ids, in the Shop's order).
func _tl_row_ids() -> Array:
	var out: Array = []
	for id in _TL_ROW_IDS:
		var r: Control = root.find_child("Row_%s" % id, true, false) as Control
		if r != null and r.is_visible_in_tree():
			out.append(id)
	return out


func _tl_want_ids(second: bool) -> Array:
	return ["gearing", "spigot_flow"] if second else ["heated_fork"]


## What is wrong with the icon right now in the zoom (first zoom or second stop): size, side, clear of Back, the text, the comb or crank, the label under it.
func _tl_place_problems(second: bool) -> Array:
	var out: Array = []
	var b: Control = _tl_btn()
	if b == null or not b.is_visible_in_tree():
		return ["the ToolsButton does not show"]
	var r: Rect2 = b.get_global_rect()
	var vp: Vector2 = Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width")), float(ProjectSettings.get_setting("display/window/size/viewport_height")))
	if r.size.x < TOOLS_MIN_PX or r.size.y < TOOLS_MIN_PX:
		out.append("smaller than %d px: %s" % [int(TOOLS_MIN_PX), str(r.size)])
	if not Rect2(Vector2.ZERO, vp).encloses(r):
		out.append("not whole on screen: %s" % str(r))
	if r.get_center().x <= vp.x * 0.5 or r.get_center().y <= vp.y * 0.5:
		out.append("not bottom-right: centre %s" % str(r.get_center()))
	for nm in ["BackButton", "HintLabel", "HintBubble", "CentrifugeLabel", "HiveCountLabel"]:
		var c: Control = root.find_child(nm, true, false) as Control
		if c != null and c.is_visible_in_tree() and c.get_global_rect().size.x > 0.0 and r.intersects(c.get_global_rect()):
			out.append("overlaps %s" % nm)
	for t in _hi_targets("hint_crank" if second else "hint_uncap"):
		if r.intersects((t as Rect2).grow(TOOLS_MIN_PX * 0.5)):
			out.append("on the %s" % ("crank" if second else "comb"))
	var l: Label = _tl_label()
	if l == null:
		out.append("no label with the translated tools_icon shows")
	elif l.get_global_rect().get_center().y <= r.get_center().y or not Rect2(Vector2.ZERO, vp).encloses(l.get_global_rect()):
		out.append("the label is not under the icon, on screen: %s" % str(l.get_global_rect()))
	if _tl_shop_btn_on():
		out.append("the ShopButton shows in a zoom")
	return out


## Real tap on the Tools icon, then what the open sheet must look like in Tools mode. Leaves the sheet open.
func _tl_open_check(m: Node, second: bool, label: String) -> void:
	ck(_tl_on(), "%s step open: the ToolsButton shows" % label)
	if not _tl_on():
		return
	await fi.tap_at(_tl_btn().get_global_rect().get_center())
	await _frames(3)
	ck(_tl_sheet_open(), "%s step open: a real tap on Tools opens the sheet over the zoom" % label)
	eq(_tl_row_ids(), _tl_want_ids(second), "%s step open: exactly the rows of the machine in view" % label)
	for tab in _TL_TABS:
		var t: Control = root.find_child(tab, true, false) as Control
		ck(t == null or not t.is_visible_in_tree(), "%s step open: no %s (no tabs in Tools mode)" % [label, tab])
	var title: Label = root.find_child("ShopTitle", true, false) as Label
	ck(title != null and title.text == TranslationServer.translate("tools_icon"), "%s step open: the title is the tools_icon text (got '%s')" % [label, title.text if title != null else "<none>"])
	ck(not _tl_on(), "%s step open: the Tools icon hides while its sheet is open" % label)
	ck(not _tl_shop_btn_on(), "%s step open: the ShopButton stays hidden" % label)
	var vp: Rect2 = _vp()
	for id in _tl_want_ids(second):
		var row: Control = root.find_child("Row_%s" % id, true, false) as Control
		ck(row != null and vp.encloses(row.get_global_rect()), "%s step open: the %s row is whole on screen" % [label, id])
	for nm in ["ShopMoney", "ShopCloseButton"]:
		var c: Control = root.find_child(nm, true, false) as Control
		ck(c != null and c.is_visible_in_tree(), "%s step open: %s shows" % [label, nm])


## Close with a real tap on Close; the zoom is where it was and the icon is back.
func _tl_close_check(m: Node, p: Dictionary, label: String) -> void:
	await _zs_settle()
	var before: Dictionary = _zs_state(m, p)
	await fi.tap_at((root.find_child("ShopCloseButton", true, false) as Control).get_global_rect().get_center())
	await _frames(3)
	ck(not _tl_sheet_open(), "%s step Close: the sheet is closed" % label)
	_zs_same_state(m, p, before, label + " step Close")
	ck(_tl_on(), "%s step Close: the Tools icon shows again" % label)


## Back to the farm view with a real tap and wait for the camera.
func _tl_to_farm(m: Node, p: Dictionary, label: String) -> void:
	await _tap_back({"p": p})
	ck(await _until(func() -> bool: return int(m.get("zoom")) == 0 and not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("zoom_seconds")) + float(cv("camera_pan_seconds")) + _zoom_settle() + 6.0), "%s: Back reached the farm view" % label)
	await _wait(_zoom_settle())
