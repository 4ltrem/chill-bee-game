extends "res://tests/test_victory.gd"

# Quinn: shared steps of the 0.3.1 item 4 hint tests (game/specs/0.3.1-playtest-fixes.md item 4), written before the code.
# Spec-level reads only: the bubble is the node HintBubble (its line HintBubbleLabel, its button HintSkipButton, its tail HintTail); the step
# showing is the key whose translated text is on the line; every text is read from content/first-time-hint.md; no number but the spec's own
# (28 px text V12, 120 px Skip V11, 720 x 1280).

const HINT_KEYS: Array[String] = ["hint_wait", "hint_harvest", "hint_uncap", "hint_spin", "hint_crank", "hint_sell", "hint_shop", "hint_plant"]
const HINT_SKIP_KEY: String = "hint_skip"
const HINT_TEXT_PX: int = 28    # spec: "28 px text (V12)"
const HINT_SKIP_PX: float = 120.0   # spec: "a 120 px Skip target (V11)"
const _HI_CONTROL_TARGETS: Dictionary = {
	"hint_wait": "HiveCountLabel", "hint_harvest": "ForkIcon", "hint_spin": "CentrifugeIcon", "hint_sell": "SellIcon", "hint_shop": "ShopButton",
}
const _HI_POINT_TARGETS: Dictionary = {"hint_uncap": "Honeycomb", "hint_crank": "Crank"}

var _hi_cache: Dictionary = {}


func _hi_n(nm: String) -> Node:
	var n: Variant = _hi_cache.get(nm)
	if not is_instance_valid(n) or not (n as Node).is_inside_tree():
		n = root.find_child(nm, true, false)
		_hi_cache[nm] = n
	return n as Node


## {key: {"en": text, "fr": text}} from the code block of content/first-time-hint.md (William's approved text, never retyped here).
func _hi_content() -> Dictionary:
	var path: String = ProjectSettings.globalize_path("res://").path_join("../content/first-time-hint.md").simplify_path()
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var in_block: bool = false
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line.begins_with("```"):
			in_block = not in_block
		elif in_block and line.begins_with("hint_"):
			var i: int = line.find(",")
			var cols: PackedStringArray = line.substr(i + 1).trim_prefix("\"").trim_suffix("\"").split("\",\"")
			if cols.size() == 2:
				out[line.substr(0, i)] = {"en": cols[0], "fr": cols[1]}
	return out


## {key: {column: text}} over every CSV of game/translations (the spec exports the hint rows there by script; it names no file).
func _hi_csv_rows() -> Dictionary:
	var out: Dictionary = {}
	for fn: String in DirAccess.get_files_at("res://translations"):
		if not fn.ends_with(".csv"):
			continue
		var f: FileAccess = FileAccess.open("res://translations/" + fn, FileAccess.READ)
		if f == null:
			continue
		var header: PackedStringArray = f.get_csv_line()
		while not f.eof_reached():
			var line: PackedStringArray = f.get_csv_line()
			if line.size() < 2 or line[0] == "":
				continue
			var r: Dictionary = {}
			for i in range(1, mini(header.size(), line.size())):
				r[header[i]] = line[i]
			out[line[0]] = r
	return out


## A launch with show_hint true (a hint test sets it itself, before _mk_main: test_base), in English, at the phone's 720 x 1280.
func _hi_setup(welcome: bool = false) -> void:
	_set_cfg("show_hint", true)
	if welcome:
		_set_cfg("show_welcome", true)
	TranslationServer.set_locale("en")
	_portrait()
	_hi_cache.clear()


func _hi_launch(welcome: bool = false) -> Node:
	_hi_setup(welcome)
	return await _mk_main()


## In the open Shop: the Habitat tab is selected (a real tap on TabHabitat unless it already is); true when the plant row then shows.
func _hi_select_habitat() -> bool:
	var tab: Control = _hi_n("TabHabitat") as Control
	if tab != null and not (tab is BaseButton and (tab as BaseButton).button_pressed):
		await _hi_tap(tab)
		await _frames(3)
	var row: Control = _hi_n("Row_plant_patch") as Control
	return row != null and row.is_visible_in_tree()


func _hi_label() -> Label:
	return _hi_n("HintBubbleLabel") as Label


func _hi_skip_btn() -> Button:
	return _hi_n("HintSkipButton") as Button


## The step showing now: "" when no bubble shows, the step's key, or "?<text>" for a line that is no step's text.
func _hi_key() -> String:
	var b: Control = _hi_n("HintBubble") as Control
	var lab: Label = _hi_label()
	if b == null or lab == null or not b.is_visible_in_tree():
		return ""
	for k in HINT_KEYS:
		if lab.text == tr(k):
			return k
	return "?" + lab.text


func _hi_wait_key(key: String, timeout: float) -> bool:
	return await _until(func() -> bool: return _hi_key() == key, timeout)


func _hi_sheet_open() -> bool:
	var s: Node = _hi_n("ShopPanel")
	return s != null and s.has_method("is_sheet_open") and bool(s.call("is_sheet_open"))


func _hi_tap(c: Control) -> void:
	await fi.tap_at(c.get_global_rect().get_center())


## The screen rects the step points at ([] when none can be measured now). A 3D target (comb, crank) is its projected point.
## hint_plant: TabHabitat until it is selected, then the "Plant wildflower patch" row (Row_plant_patch).
func _hi_targets(key: String) -> Array:
	if _HI_CONTROL_TARGETS.has(key):
		var c: Control = _hi_n(_HI_CONTROL_TARGETS[key]) as Control
		return [c.get_global_rect()] if c != null and c.is_visible_in_tree() else []
	if _HI_POINT_TARGETS.has(key):
		var n3: Node3D = _hi_n(_HI_POINT_TARGETS[key]) as Node3D
		var cam: Camera3D = root.get_viewport().get_camera_3d()
		if n3 == null or cam == null or cam.is_position_behind(n3.global_position):
			return []
		return [Rect2(cam.unproject_position(n3.global_position) - Vector2.ONE, Vector2(2.0, 2.0))]
	if key == "hint_plant":
		var tab: Control = _hi_n("TabHabitat") as Control
		if tab != null and tab.is_visible_in_tree() and not (tab is BaseButton and (tab as BaseButton).button_pressed):
			return [tab.get_global_rect()]
		var row: Control = _hi_n("Row_plant_patch") as Control
		return [row.get_global_rect()] if row != null and row.is_visible_in_tree() else []
	return []


func _hi_dist(p: Vector2, r: Rect2) -> float:
	return Vector2(maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x), maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)).length()


## The tip of the tail: the polygon point farthest from the bubble's centre (Vector2.INF when there is no tail).
func _hi_tip() -> Vector2:
	var tail: Polygon2D = _hi_n("HintTail") as Polygon2D
	var b: Control = _hi_n("HintBubble") as Control
	if tail == null or b == null or not tail.visible:
		return Vector2.INF
	var c: Vector2 = b.get_global_rect().get_center()
	var best: Vector2 = Vector2.INF
	var far: float = -1.0
	for p: Vector2 in tail.polygon:
		var g: Vector2 = tail.get_global_transform() * p
		if g.distance_to(c) > far:
			far = g.distance_to(c)
			best = g
	return best


## What is wrong with the bubble right now, from the spec's own rules (empty when none shows or all is right).
func _hi_problems() -> Array:
	var out: Array = []
	var key: String = _hi_key()
	if key == "":
		return out
	var b: Control = _hi_n("HintBubble") as Control
	var r: Rect2 = b.get_global_rect()
	if key.begins_with("?"):
		out.append("the line is no step's text: %s" % key)
	if not Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(r):
		out.append("%s: the bubble %s is not wholly on screen" % [key, r])
	if _hi_label().get_theme_font_size("font_size") != HINT_TEXT_PX:
		out.append("%s: the line is %d px, not %d" % [key, _hi_label().get_theme_font_size("font_size"), HINT_TEXT_PX])
	var sk: Rect2 = _hi_skip_btn().get_global_rect()
	if sk.size.x < HINT_SKIP_PX or sk.size.y < HINT_SKIP_PX:
		out.append("%s: the Skip target is %s, under %d px" % [key, sk.size, int(HINT_SKIP_PX)])
	if _hi_skip_btn().text != tr(HINT_SKIP_KEY):
		out.append("%s: the Skip text is '%s', not tr(hint_skip)" % [key, _hi_skip_btn().text])
	var toast: Control = _hi_n("PhaseToast") as Control
	if toast != null and toast.size != Vector2.ZERO and toast.is_visible_in_tree() and r.intersects(toast.get_global_rect()):   # a hidden toast holds no place (hint.gd _toast_rect)
		out.append("%s: the bubble %s overlaps the toasts' place %s; diag: toast visible=%s alpha=%.2f in_tree_visible=%s, targets=%s, viewport=%s" % [key, r, toast.get_global_rect(), toast.visible, toast.modulate.a, toast.is_visible_in_tree(), _hi_targets(key), root.get_visible_rect().size])
	var targets: Array = _hi_targets(key)
	var nearest: float = INF
	for t: Rect2 in targets:
		nearest = minf(nearest, _hi_dist(_hi_tip(), t))
		if r.intersects(t):
			out.append("%s: the bubble %s covers its own target %s" % [key, r, t])
	if not targets.is_empty() and nearest > r.size.y:
		out.append("%s: the tail tip %s is %.0f px from its target (more than the bubble's height)" % [key, _hi_tip(), nearest])
	return out


## Draw order of a CanvasItem: [canvas layer, effective z, tree position]; a higher array draws over a lower one.
func _hi_order(n: CanvasItem, tree_idx: Dictionary) -> Array:
	var z: int = 0
	var cur: Node = n
	while cur is CanvasItem:
		z += (cur as CanvasItem).z_index
		if not (cur as CanvasItem).z_as_relative:
			break
		cur = cur.get_parent()
	var layer: int = 0
	var q: Node = n
	while q != null:
		if q is CanvasLayer:
			layer = (q as CanvasLayer).layer
			break
		q = q.get_parent()
	return [layer, z, int(tree_idx.get(n, 0))]


func _hi_over(a: Array, b: Array) -> bool:
	for i in 3:
		if a[i] != b[i]:
			return a[i] > b[i]
	return false


## Names of the drawn Controls (panels, dims, textures, buttons) that draw over the bubble at the point `at`: it is "seen" only when none.
func _hi_covers(at: Vector2) -> Array:
	var out: Array = []
	var b: Control = _hi_n("HintBubble") as Control
	if b == null:
		return out
	var all: Array = root.find_children("*", "CanvasItem", true, false)
	var idx: Dictionary = {}
	for i in all.size():
		idx[all[i]] = i
	var kb: Array = _hi_order(b, idx)
	for n in all:
		var c: Control = n as Control
		if c == null or c == b or b.is_ancestor_of(c) or c.is_ancestor_of(b) or not c.is_visible_in_tree() or c.modulate.a < 0.05:
			continue
		if c is ColorRect and (c as ColorRect).color.a < 0.05:
			continue
		if not (c is Panel or c is PanelContainer or c is ColorRect or c is TextureRect or c is BaseButton):
			continue
		if c.get_global_rect().has_point(at) and _hi_over(_hi_order(c, idx), kb):
			out.append(String(c.name))
	return out


## Samples every frame: the distinct steps shown in order, the problems seen, and what each rule (a Callable returning "" or a message) reports.
func _hi_watch(rules: Array = []) -> Dictionary:
	var w: Dictionary = {"keys": [], "problems": [], "rules": rules}
	var cb: Callable = func() -> void:
		var k: String = _hi_key()
		var keys: Array = w["keys"]
		if k != "" and (keys.is_empty() or keys.back() != k):
			keys.append(k)
		var msgs: Array = _hi_problems()
		for rule: Callable in w["rules"]:
			var s: String = rule.call()
			if s != "":
				msgs.append(s)
		for s2 in msgs:
			if not (w["problems"] as Array).has(s2) and (w["problems"] as Array).size() < 12:
				(w["problems"] as Array).append(s2)
	w["cb"] = cb
	process_frame.connect(cb)
	return w


func _hi_unwatch(w: Dictionary) -> void:
	if process_frame.is_connected(w["cb"]):
		process_frame.disconnect(w["cb"])


## One whole farm through real input: full hive, the first zoom, every frame, Spin, the crank, the sale, Back, the Shop, the patch.
## Returns {"keys": the distinct steps shown in order, "problems": [...], "ok": bool}.
func _hi_walk() -> Dictionary:
	_hi_setup()
	var quiet: Callable = func() -> String:
		var c: Node = _hi_n("Centrifuge")
		var si: Control = _hi_n("SellIcon") as Control
		if c != null and int(c.get("state")) == _st(c, "BOTTLING") and int(_eco().get("money")) == 0 \
				and not (si != null and si.is_visible_in_tree()) and _hi_key() != "":
			return "a bubble (%s) showed while bottling ran and no step's condition held" % _hi_key()
		return ""
	var w: Dictionary = _hi_watch([quiet])
	print("WALK go_second_stop")   # DIAG 11/23: stage markers for the unit-suite hang
	var s: Dictionary = await _go_second_stop()
	print("WALK at second stop: ", not s.is_empty())
	var res: Dictionary = {"keys": [], "problems": [], "ok": false}
	if s.is_empty():
		_hi_unwatch(w)
		return res
	var m: Node = s["m"]
	res["m"] = m
	var c2: Node = (s["p"] as Dictionary)["Centrifuge"]
	await _frames(3)
	eq(_hi_key(), "hint_crank", "walk: at the second stop with the crank not turned the bubble is hint_crank")
	var sent: int = 0
	# 0.3.2 item 1 (C1): a bucket larger than one load bottles, reloads from the pile and goes back to CRANKING; the walk cranks every
	# load (it hung waiting for Sell after the first). It stops once the centrifuge is past cranking with no reload left (Sell shows).
	var cap: int = (_turns_for(_bucket_cells()) * 2 + 10) * 4
	var idle: float = 0.0
	var idle_cap: float = _secs_for_jars(_hive_jars()) + float(cv("cell_fly_seconds")) + 20.0
	while sent < cap and idle < idle_cap:
		var si0: Control = _hi_n("SellIcon") as Control
		if si0 != null and si0.is_visible_in_tree():
			break
		if int(c2.get("state")) == _st(c2, "CRANKING"):
			await fi.tap_at(fi.free_spot(m))
			await _wait(_tap_gap())
			sent += 1
		else:
			await _wait(0.25)
			idle += 0.25
	await _frames(3)
	print("WALK cranked: sent ", sent, " state ", c2.get("state"))
	var money0: int = int(_eco().get("money"))
	# Looked up on every poll (never held across frames) so a rebuilt or not-yet-made icon is a miss, not an error in the loop; one line
	# per game-second block (frame, clock, centrifuge state) locates a stall if the poll ever stops again.
	var beat: Array = [0]
	var up: bool = await _until(func() -> bool:
		var si: Control = _hi_n("SellIcon") as Control
		var cc: Node = _hi_n("Centrifuge")
		var blk: int = int(float(_gms()) / 5000.0)
		if blk != beat[0]:
			beat[0] = blk
			print("WALK poll frame ", Engine.get_process_frames(), " gms ", _gms(), " state ", cc.get("state") if cc != null else -1, " icon ", si != null)
		return si != null and si.is_visible_in_tree(), _secs_for_jars(_hive_jars()) + float(cv("cell_fly_seconds")) + 20.0)
	var sell_icon: Control = _hi_n("SellIcon") as Control
	ck(up, "walk: SellIcon shows once bottled")
	print("WALK sell up: ", up, " t=", Time.get_ticks_msec(), " limit=", _secs_for_jars(_hive_jars()), " paused=", paused, " ts=", Engine.time_scale)
	if up:
		eq(await _hi_wait_key("hint_sell", 3.0), true, "walk: SellIcon shows: the bubble is hint_sell")
		await fi.click_icon(sell_icon)
	await _until(func() -> bool: return int(_eco().get("money")) > money0, 8.0)
	await _frames(3)
	print("WALK sold: money ", _eco().get("money"), " t=", Time.get_ticks_msec())
	eq(_hi_key(), "", "walk: first sale made but still at the second stop: no bubble (hint_shop is for the farm view)")
	await _hi_tap(_hi_n("BackButton") as Control)
	print("WALK Back tapped t=", Time.get_ticks_msec())
	await _until(func() -> bool: return not bool(m.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	print("WALK left second stop: ", not bool(m.call("at_second_stop")), " t=", Time.get_ticks_msec())
	eq(await _hi_wait_key("hint_shop", 5.0), true, "walk: after the sale, on the farm view: hint_shop")
	print("WALK sold, back on farm; opening Shop")
	await _shop_open(m, true)
	print("WALK Shop open")
	eq(await _hi_wait_key("hint_plant", 3.0), true, "walk: in the Shop: hint_plant")
	ck(await _hi_select_habitat(), "walk: with the Habitat tab selected the plant row shows")
	_eco().call("earn", int(_eco().call("cost", "plant_patch")) * 2)
	await _frames(3)
	var row: Node = _hi_n("Row_plant_patch")
	var buy: Button = row.find_child("UpgradeButton", true, false) as Button if row != null else null
	ck(buy != null and buy.is_visible_in_tree(), "walk: the plant row's button shows")
	if buy != null:
		await _hi_tap(buy)
	await _frames(4)
	eq(int(_eco().call("level", "plant_patch")), 1, "walk: a real tap on the row planted the first patch")
	eq(_hi_key(), "", "walk: the first patch is planted: the hint is over")
	print("WALK done")
	_hi_unwatch(w)
	res["keys"] = w["keys"]
	res["problems"] = w["problems"]
	res["ok"] = true
	return res
