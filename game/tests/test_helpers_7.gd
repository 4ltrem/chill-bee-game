extends "res://tests/test_playtest_b.gd"

# Quinn: shared steps of the 0.3.2 item 3 tests (the 0.3.1 test lines that never got a test), written from
# game/specs/0.3.2-tests-and-quick-buy.md item 3 and the 0.3.1 spec's item lines, before the code, from node names only.
# Every tap is a real mouse event (farm_input.gd); every number comes from the config, the scene, the translation table or ProjectSettings.

const CB_TAB_ROWS: Dictionary = {   # 0.3.1 item 3, Tree map: tab suffix -> its rows (node names Row_<id>), in order
	"Bees": ["Row_swarm", "Row_flight"],
	"Hive": ["Row_heated_fork", "Row_gearing", "Row_spigot_flow", "Row_faster_delivery", "Row_auto_sell"],
	"Habitat": ["Row_plant_patch"],
}
const CB_EMPTY_TABS: Array[String] = ["Research", "Refinery"]


## Game seconds since the run began.
func _cb_secs() -> float:
	return float(_gus()) / 1.0e6


func _cb_viewport() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width")), float(ProjectSettings.get_setting("display/window/size/viewport_height"))))


func _cb_rich() -> Node:
	var e: Node = _eco()
	e.set("money", 1000000000)
	e.emit_signal("money_changed", 1000000000)
	return e


## The text the toast shows now, "" when no toast shows.
func _cb_toast_text(m: Node) -> String:
	var t: Control = m.find_child("PhaseToast", true, false) as Control
	var l: Label = m.find_child("ToastLabel", true, false) as Label
	if t == null or l == null or not t.is_visible_in_tree() or t.modulate.a < 0.05:
		return ""
	return l.text


## What is wrong with a showing toast being seen: on screen, nothing drawn over its centre.
func _cb_toast_unseen(m: Node) -> Array:
	var t: Control = m.find_child("PhaseToast", true, false) as Control
	if t == null or not t.is_visible_in_tree():
		return ["the toast does not show"]
	var out: Array = []
	if not _cb_viewport().encloses(t.get_global_rect()):
		out.append("the toast %s is not whole on screen" % str(t.get_global_rect()))
	for n in _pt_covers(t, t.get_global_rect().get_center()):
		out.append("%s is drawn over the toast" % n)
	return out


## Record the toast every frame: {"log": [[game seconds, text], ...], "step": the longest frame, "cb": the callable}.
func _cb_watch(m: Node) -> Dictionary:
	var w: Dictionary = {"log": [], "step": 0.0, "last": -1.0}
	var cb: Callable = func() -> void:
		var now: float = _cb_secs()
		if float(w["last"]) >= 0.0:
			w["step"] = maxf(float(w["step"]), now - float(w["last"]))
		w["last"] = now
		(w["log"] as Array).append([now, _cb_toast_text(m)])
	w["cb"] = cb
	process_frame.connect(cb)
	return w


func _cb_unwatch(w: Dictionary) -> void:
	if process_frame.is_connected(w["cb"]):
		process_frame.disconnect(w["cb"])


## The distinct non-empty toast texts the log saw, in order.
func _cb_texts(w: Dictionary) -> Array:
	var out: Array = []
	for r in w["log"]:
		var t: String = str((r as Array)[1])
		if t != "" and (out.is_empty() or out[out.size() - 1] != t):
			out.append(t)
	return out


## [first, last] game second `text` showed in the log, [] when it never did.
func _cb_span(w: Dictionary, text: String) -> Array:
	var first: float = -1.0
	var last: float = -1.0
	for r in w["log"]:
		if str((r as Array)[1]) == text:
			if first < 0.0:
				first = float((r as Array)[0])
			last = float((r as Array)[0])
	return [] if first < 0.0 else [first, last]


## Digits of a text as an int ("$1 234" -> 1234), -1 when it has none.
func _cb_digits(s: String) -> int:
	var d: String = ""
	for ch in s:
		if ch >= "0" and ch <= "9":
			d += ch
	return int(d) if d != "" else -1


## Does `text` read like the format string `fmt` (each %d / %s any text)?  "Abeilles : 20" matches "Abeilles : %d".
func _cb_fmt_matches(text: String, fmt: String) -> bool:
	var parts: PackedStringArray = fmt.replace("%d", "\u0001").replace("%s", "\u0001").split("\u0001")
	var at: int = 0
	for i in parts.size():
		if parts[i] == "":
			continue
		var f: int = text.find(parts[i], at)
		if f < 0 or (i == 0 and f != 0):
			return false
		at = f + parts[i].length()
	return parts[parts.size() - 1] == "" or text.ends_with(parts[parts.size() - 1])


## Does the node's text read as the translation of `key` in the language `lang`? (the table's own text, never retyped)
func _cb_reads(text: String, key: String, lang: String) -> bool:
	var loc0: String = TranslationServer.get_locale()
	TranslationServer.set_locale(lang)
	var fmt: String = TranslationServer.translate(key)
	TranslationServer.set_locale(loc0)
	return _cb_fmt_matches(text, fmt)


## The text of the key in a language ("" if untranslated).
func _cb_tr(key: String, lang: String) -> String:
	var loc0: String = TranslationServer.get_locale()
	TranslationServer.set_locale(lang)
	var s: String = TranslationServer.translate(key)
	TranslationServer.set_locale(loc0)
	return s


## With the Shop open: a real tap on the Habitat tab, then on the plant row's Buy. False when a step is missing.
func _cb_buy_patch_in_shop(m: Node) -> bool:
	await _pt_tab(m, "Habitat")
	var row: Control = m.find_child("Row_plant_patch", true, false) as Control
	if row == null or not row.is_visible_in_tree():
		return false
	var b: Button = _row_buy(row)
	if b == null or b.disabled or not b.is_visible_in_tree():
		return false
	await _pt_tap(b)
	return true


## Names of the Shop rows showing now, in order (node names Row_<id>).
func _cb_row_names(m: Node) -> Array:
	var out: Array = []
	var holder: Node = m.find_child("ShopRows", true, false)
	if holder == null:
		return out
	for c in holder.get_children():
		if c is Control and c.name != &"RowTemplate" and (c as Control).is_visible_in_tree():
			out.append(String(c.name))
	return out


## A Dev panel button by the text it carries; the Dev panel exists when dev mode is on (set before the scene is made).
func _cb_dev_button(m: Node, needle: String) -> Button:
	var p: Node = _find_dev_panel(m)
	return _button_with(p, needle) if p != null else null


## Every drawn shape (Line2D / Polygon2D) under a control: [[node, points in canvas coordinates], ...].
func _cb_shapes(c: Control) -> Array:
	var out: Array = []
	for n in c.find_children("*", "Node2D", true, false):
		var xf: Transform2D = (n as Node2D).get_global_transform()
		if n is Polygon2D or n is Line2D:
			var pts: PackedVector2Array = (n as Polygon2D).polygon if n is Polygon2D else (n as Line2D).points
			var world: Array = []
			for pt in pts:
				world.append(xf * pt)
			out.append([n, world])
	return out


## Visible Labels or Buttons under a control whose text is `word` (case-insensitive), the word the icon lost.
func _cb_word_on(c: Control, word: String) -> Array:
	var out: Array = []
	if c is Button and (c as Button).text.strip_edges().to_lower() == word.to_lower():
		out.append(String(c.name))
	for n in c.find_children("*", "Label", true, false):
		if (n as Label).text.strip_edges().to_lower() == word.to_lower():
			out.append(String(n.name))
	return out


## The panel-open check the 0.3.1 spec's item 7 names: open from its button, toasts wait and the hint hides while it is open, Close closes it, open again.
## The scene runs with show_hint true and a showing hint step (a hint test launch), so "the hint hides" is a real check.
func _check_panel(m: Node, button_name: String, panel_name: String) -> void:
	var btn: Control = _nn(m, button_name) as Control
	var panel: Control = _nn(m, panel_name) as Control
	var close: Control = _nn(m, panel_name.replace("Panel", "CloseButton")) as Control
	if btn == null or panel == null or close == null:
		return
	ck(bool(cv("show_hint")), "%s: the hint is on, so 'the hint hides' can be seen" % panel_name)
	var waiting: String = TranslationServer.translate("toast_patch_planted")
	for rn in [1, 2]:
		var L: String = "%s round %d" % [panel_name, rn]
		ck(await _until(func() -> bool: return _cb_toast_text(m) == "", float(cv("toast_seconds")) * 3.0 + float(cv("victory_delay_seconds")) + 4.0), "%s step start: no toast is showing" % L)
		ck(await _until(func() -> bool: return _hi_key() != "", 3.0), "%s step start: a hint bubble shows (got '%s')" % [L, _hi_key()])
		ck(not panel.is_visible_in_tree(), "%s step start: the panel is closed" % L)
		ck(_shown(btn), "%s step start: %s shows" % [L, button_name])
		await _pt_tap(btn)
		ck(panel.is_visible_in_tree(), "%s step open: a real tap on %s opens the panel" % [L, button_name])
		_cb_rich()
		_eco().call("buy", "plant_patch")   # queues toast_patch_planted while the panel is up
		await _wait(float(cv("toast_seconds")) * 0.5)
		eq(_cb_toast_text(m), "", "%s step open: the toast waits while the panel is open" % L)
		eq(_hi_key(), "", "%s step open: the hint bubble hides while the panel is open" % L)
		await _pt_tap(close)
		ck(not panel.is_visible_in_tree(), "%s step Close: a real tap on Close closes the panel" % L)
		ck(await _until(func() -> bool: return _cb_toast_text(m) == waiting, 2.0), "%s step Close: the waiting toast shows (got '%s')" % [L, _cb_toast_text(m)])
		ck(await _until(func() -> bool: return _hi_key() != "", float(cv("toast_seconds")) + 3.0), "%s step Close: the hint bubble is back" % L)


## With the panel open at thriving the victory waits; it shows after the panel closes. `button_name` opens the panel, `close_name` closes it.
func _cb_victory_waits(m: Node, button_name: String, panel_name: String) -> void:
	var o: Node = _vic_overlay(m)
	var btn: Control = _nn(m, button_name) as Control
	var panel: Control = _nn(m, panel_name) as Control
	var close: Control = _nn(m, panel_name.replace("Panel", "CloseButton")) as Control
	if o == null or btn == null or panel == null or close == null:
		return
	var delay: float = float(cv("victory_delay_seconds"))
	_eco().call("reset")
	await _frames(3)
	_eco().call("add_habitat", int(cv("habitat_health_max")) * 3)   # thriving
	await _frames(3)
	ck(_shown(btn), "%s: %s shows at thriving" % [panel_name, button_name])
	await _pt_tap(btn)
	ck(panel.is_visible_in_tree(), "%s step open: the panel opened" % panel_name)
	await _wait(float(cv("toast_seconds")) + delay + 1.0)
	ck(panel.is_visible_in_tree(), "%s step wait: the panel is still open" % panel_name)
	eq(_vic_shown(o), false, "%s step wait: the victory waits while the panel is open" % panel_name)
	await _pt_tap(close)
	ck(not panel.is_visible_in_tree(), "%s step close: the panel closed" % panel_name)
	var ok: bool = await _until(func() -> bool: return _vic_shown(o), float(cv("toast_seconds")) + delay + 3.0)
	ck(ok, "%s step shown: the victory shows after the panel closes" % panel_name)
	if ok and o.has_method("close"):
		o.call("close")
	_eco().call("reset")
