# Quinn: Prototype 0 revision 3 integration test, WINDOWED, written from game/specs/prototype-0.md before the code.
#   Godot --path game --script res://tests/play_loop.gd
# Drives the loop 1 -> 9 twice through REAL input (events pushed into the viewport in window pixels, like a real
# mouse): the fork icon, a drag to uncap, Back in round 1, the full uncap, the centrifuge icon, real taps, one real
# hold, a click on UpgradeButton during CRANKING (must not crank), Continue, bottling, the summary's OK, the Sell icon
# (money credited at the tap), the truck away with the crate filling, and one Worker Swarm Count purchase mid-harvest.
# Exit code 0 only if no check failed AND the final "COMPLETED" line printed. No COMPLETED line = FAILURE (a script
# error mid-flow stops the run silently otherwise).
# Cheats, all marked "CHEAT" below, are the Dev-mode actions: filling the hive (hive.advance) and doubling
# truck_trip_seconds so the truck is still away while round 2 bottles. The config is restored at the end.
# Spec line numbers in the comments refer to game/specs/prototype-0.md.
extends SceneTree

# ---- Node names from the spec's "Node paths for Bob" (L136-L203). Change them here only.
const MAIN_SCENE := "res://scenes/main.tscn"
const N_HIVE := "Hive"
const N_CENTRIFUGE := "Centrifuge"
const N_TRUCK := "Truck"
const N_FARM_WORLD := "FarmWorld"
const N_BEES := "Bees"
const N_FORK_ICON := "ForkIcon"
const N_CENTRIFUGE_ICON := "CentrifugeIcon"
const N_SELL_ICON := "SellIcon"
const N_CONTINUE := "ContinueButton"
const N_SUMMARY := "SummaryModal"
const N_SUMMARY_JARS := "SummaryJarsLabel"
const N_SUMMARY_VALUE := "SummaryValueLabel"
const N_SUMMARY_BONUS := "SummaryBonusLabel"
const N_SUMMARY_TOTAL := "SummaryTotalLabel"
const N_SUMMARY_OK := "SummaryOkButton"
const N_UPGRADE := "UpgradeButton"
const N_SHOP_PANEL := "ShopPanel"
const N_LEVEL_LABEL := "LevelLabel"
const N_MONEY := "MoneyLabel"
const N_FILL_LABEL := "FillLabel"
const N_BEE_LABEL := "BeeCountLabel"
const N_CRANK_LABEL := "CentrifugeLabel"
const N_HONEYCOMB := "Honeycomb"
const N_BACK := "BackButton"
const N_HINT := "HintLabel"
const N_FARM_UI := "FarmUI"
const N_JARS_LABEL_REMOVED := "JarsLabel"          # must NOT exist (L30)
const N_OLD_NODES_REMOVED := ["HarvestButton", "SellButton", "ExtractButton", "CrankButton", "NoRapidTapCheck", "Stage1Panel", "Stage2Panel"]
const HARVEST_ROOT := "Harvest"
const CAMERA_PARENT_FARM := "Main"                 # the farm camera is a direct child of Main (L147)

const SHOT_DIR := "res://reports/2026-11-04-prototype-0-r3/"

var main: Node
var fails: int = 0
var checks: int = 0
var _cfg_saved: Dictionary = {}


func _initialize() -> void:
	_run()


# ---------------------------------------------------------------- harness

func ck(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("PASS  ", what)
	else:
		fails += 1
		print("FAIL  ", what)


func eq(actual: Variant, expected: Variant, what: String) -> void:
	ck(actual == expected, "%s (expected %s, got %s)" % [what, str(expected), str(actual)])


func near(actual: float, expected: float, what: String, tol: float) -> void:
	ck(absf(actual - expected) <= tol, "%s (expected %s +- %s, got %s)" % [what, str(expected), str(tol), str(actual)])


func _abort(why: String) -> void:
	print("FAIL  ABORT: ", why)
	print("---- %d checks, %d failed (aborted)" % [checks, fails + 1])
	quit(1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < sec * 1000.0:
		await process_frame


## Poll until cond.call() is true or timeout (s); returns whether it became true.
func _until(cond: Callable, timeout: float) -> bool:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < timeout * 1000.0:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _n(name: String) -> Node:
	var n: Node = main.find_child(name, true, false)
	if n == null:
		print("FAIL  node missing (spec: Node paths for Bob): ", name)
		fails += 1
		checks += 1
	return n


func _gone(name: String) -> bool:
	var n: Node = main.find_child(name, true, false)
	return n == null or n.is_queued_for_deletion()


func _vis(n: Node) -> bool:
	return n != null and (n as CanvasItem).is_visible_in_tree()


func _cv(name: String) -> Variant:
	var cfg: Variant = root.get_node("Economy").get("config")
	var v: Variant = cfg.get(name) if cfg != null else null
	if v == null:
		_abort("config value '%s' missing (spec Values table)" % name)
		return 0
	return v


func _set_cfg(name: String, value: Variant) -> void:
	var cfg: Variant = root.get_node("Economy").get("config")
	if not _cfg_saved.has(name):
		_cfg_saved[name] = cfg.get(name)
	cfg.set(name, value)


func _shot(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err: int = img.save_png(ProjectSettings.globalize_path(SHOT_DIR + name + ".png"))
	print("screenshot ", name, " ", img.get_size(), " err=", err)


# ---------------------------------------------------------------- real input

## Viewport pixels (720 x 1280) to window pixels: the window is smaller (canvas_items stretch), and push_input takes
## window pixels, like a real mouse. Revision 2 fixed this; do not remove it.
func _to_window() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func _mouse_button(vp_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos * _to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(ev)


## A mouse button through Input.parse_input_event, like the OS sends it: it also updates the Input singleton's button
## state (Input.is_mouse_button_pressed) and runs the engine's touch emulation. root.push_input does neither, and
## centrifuge.gd polls Input.is_mouse_button_pressed in _process to end a mouse hold, so a hold pushed with
## push_input was released on the next frame (harness bug, fixed 2026-11-04 in the r3 run).
func _mouse_button_os(vp_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos * _to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _mouse_move(vp_pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = vp_pos * _to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(ev)


func _click_at(vp_pos: Vector2) -> void:
	_mouse_button(vp_pos, true)
	await process_frame
	_mouse_button(vp_pos, false)
	await process_frame


func _click_ctl(ctl: Control) -> void:
	await _click_at(ctl.get_global_rect().get_center())


## Click a floating icon at the screen position its anchor projects to (L127: unproject_position(anchor) +
## screen_offset). The spec does not say whether that point is the icon's corner or centre, so the click goes to the
## projected point clamped 6 px inside the icon's rect, and the projected point must lie within 6 px of the rect.
func _click_icon(icon: Control) -> void:
	var anchor: Node3D = icon.get_node_or_null(icon.get("anchor_path")) as Node3D
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	if anchor == null or cam == null:
		ck(false, "icon %s: anchor or camera not found for the projected click" % icon.name)
		await _click_ctl(icon)
		return
	var projected: Vector2 = cam.unproject_position(anchor.global_position) + (icon.get("screen_offset") as Vector2)
	var rect: Rect2 = icon.get_global_rect()
	ck(rect.grow(6.0).has_point(projected), "icon %s sits at its anchor's projected position %s (rect %s)" % [icon.name, str(projected), str(rect)])
	var inside := Vector2(clampf(projected.x, rect.position.x + 6.0, rect.end.x - 6.0), clampf(projected.y, rect.position.y + 6.0, rect.end.y - 6.0))
	await _click_at(inside)


## Tree rects of everything that takes presses on the farm: a tap spot must be outside all of them.
func _blocked(p: Vector2) -> bool:
	for c in main.find_children("*", "Control", true, false):
		var ctl: Control = c as Control
		if ctl.is_visible_in_tree() and ctl.mouse_filter == Control.MOUSE_FILTER_STOP and ctl.get_global_rect().has_point(p):
			return true
	return false


## A spot on the farm where a tap reaches _unhandled_input: the centrifuge on screen, else any free spot.
func _crank_spot() -> Vector2:
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var cen: Node3D = _n(N_CENTRIFUGE) as Node3D
	var candidates: Array[Vector2] = []
	if cam != null and cen != null:
		candidates.append(cam.unproject_position(cen.global_position))
	candidates.append_array([Vector2(360.0, 640.0), Vector2(360.0, 520.0), Vector2(200.0, 480.0), Vector2(520.0, 480.0), Vector2(360.0, 760.0)])
	for p in candidates:
		if p.x > 0.0 and p.y > 0.0 and p.x < 720.0 and p.y < 1280.0 and not _blocked(p):
			return p
	ck(false, "no free spot on screen for a crank tap")
	return Vector2(360.0, 640.0)


# ---------------------------------------------------------------- the close-up (cells found without internal names)

## The cells of the close-up: collision objects under Honeycomb, else its mesh instances. The spec names no cell nodes.
func _cells(hc: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in hc.find_children("*", "CollisionObject3D", true, false):
		out.append(n as Node3D)
	if out.size() == 0:
		for n in hc.find_children("*", "MeshInstance3D", true, false):
			out.append(n as Node3D)
	return out


## Cell centres on screen, grouped into rows (top to bottom), each row sorted left to right.
func _rows(hc: Node, cam: Camera3D) -> Array:
	var pts: Array[Vector2] = []
	for c in _cells(hc):
		pts.append(cam.unproject_position(c.global_position))
	var rows_n: int = int(_cv("grid_rows"))
	var n: int = int(_cv("grid_cols")) * rows_n
	if pts.size() != n:
		ck(false, "found %d cells under Honeycomb, expected %d (the spec names no cell nodes; this test needs one collider or mesh per cell)" % [pts.size(), n])
		return []
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	var pitch: float = (pts[n - 1].y - pts[0].y) / float(maxi(rows_n - 1, 1))
	var rows: Array = []
	var cur: Array[Vector2] = []
	var row_y: float = pts[0].y
	for p in pts:
		if absf(p.y - row_y) > pitch * 0.5 and cur.size() > 0:
			rows.append(cur)
			cur = []
			row_y = p.y
		cur.append(p)
	rows.append(cur)
	for r in rows:
		(r as Array).sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return rows


## Real mouse drag along one row of cells: press on the first cell, one motion event per frame, release at the last.
func _drag_row(row: Array) -> void:
	var first: Vector2 = row[0]
	var last: Vector2 = row[row.size() - 1]
	_mouse_button(first, true)
	await process_frame
	var steps: int = row.size() * 4
	for s in range(1, steps + 1):
		_mouse_move(first.lerp(last, float(s) / float(steps)))
		await process_frame
	_mouse_button(last, false)
	await process_frame


## The same drag with touch events (a finger): ScreenTouch down, ScreenDrag per frame, ScreenTouch up, through Input
## so the engine's own touch handling runs. Honeycomb must react to a finger as well as to a mouse (L55).
func _drag_row_touch(row: Array) -> void:
	var first: Vector2 = row[0] * _to_window()
	var last: Vector2 = row[row.size() - 1] * _to_window()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = first
	Input.parse_input_event(down)
	Input.flush_buffered_events()
	await process_frame
	var steps: int = row.size() * 4
	var prev: Vector2 = first
	for s in range(1, steps + 1):
		var p: Vector2 = first.lerp(last, float(s) / float(steps))
		var mv := InputEventScreenDrag.new()
		mv.index = 0
		mv.position = p
		mv.relative = p - prev
		prev = p
		Input.parse_input_event(mv)
		Input.flush_buffered_events()
		await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = last
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await process_frame


func _cell_state(hc: Node, i: int) -> int:
	return int(hc.call("get_state", i)) if hc.has_method("get_state") else -1


func _count_state(hc: Node, state: int) -> int:
	var n: int = int(_cv("grid_cols")) * int(_cv("grid_rows"))
	var k: int = 0
	for i in n:
		if _cell_state(hc, i) == state:
			k += 1
	return k


## Open the close-up through the fork icon and wait for it (slide-in up to 0.4 s camera + 0.3 s frame).
func _open_closeup() -> Node:
	var fork: Control = _n(N_FORK_ICON) as Control
	await _click_icon(fork)
	var opened: bool = await _until(func() -> bool: return main.find_child(N_HONEYCOMB, true, false) != null, 3.0)
	ck(opened, "tapping the fork icon opened the close-up (Honeycomb appeared)")
	await _wait(0.9)
	return main.find_child(N_HONEYCOMB, true, false)


func _centroid(n: Node3D) -> Vector3:
	var sum := Vector3.ZERO
	var k: int = 0
	for m in n.find_children("*", "MeshInstance3D", true, false):
		sum += (m as Node3D).global_position
		k += 1
	return sum / float(maxi(k, 1))


# ---------------------------------------------------------------- the run

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var eco: Node = root.get_node("Economy")
	if eco.has_method("reset"):
		eco.call("reset")
	var ps: Variant = load(MAIN_SCENE)
	if ps == null:
		_abort("%s failed to load" % MAIN_SCENE)
		return
	main = (ps as PackedScene).instantiate()
	if main == null:
		_abort("main.tscn failed to instantiate")
		return
	root.add_child(main)
	await _frames(10)
	print("window size ", DisplayServer.window_get_size(), " viewport ", root.get_visible_rect().size)

	var hive: Node = _n(N_HIVE)
	var cen: Node = _n(N_CENTRIFUGE)
	var truck: Node = _n(N_TRUCK)
	var farm: Node3D = _n(N_FARM_WORLD) as Node3D
	var bees: Node = _n(N_BEES)
	var fork: Control = _n(N_FORK_ICON) as Control
	var cicon: Control = _n(N_CENTRIFUGE_ICON) as Control
	var sell: Control = _n(N_SELL_ICON) as Control
	var cont: Control = _n(N_CONTINUE) as Control
	var summary: Control = _n(N_SUMMARY) as Control
	var upgrade: Button = _n(N_UPGRADE) as Button
	var crank_label: Label = _n(N_CRANK_LABEL) as Label
	var money_label: Label = _n(N_MONEY) as Label
	var bee_label: Label = _n(N_BEE_LABEL) as Label
	var fill_label: Label = _n(N_FILL_LABEL) as Label
	for n in [hive, cen, truck, farm, bees, fork, cicon, sell, cont, summary, upgrade, crank_label, money_label, bee_label, fill_label]:
		if n == null:
			_abort("a required node is missing; see the lines above")
			return

	var J: int = int(_cv("frame_jars"))
	var TAPS: int = int(_cv("taps_per_frame"))
	var RATE: float = float(_cv("max_tap_rate"))
	var SPJ: float = float(_cv("bottling_seconds_per_jar"))
	var CAP: int = int(_cv("truck_capacity_jars"))
	var PER: int = int(eco.call("jar_value"))
	var GAP: float = 1.0 / RATE + 0.03   # one counted tap per GAP: clear of the cap
	var CRANKING_S: int = -1
	var bees_base: int = int(eco.call("bee_count"))

	# ---- start state (L53, L30, L26)
	ck(main.find_child(N_JARS_LABEL_REMOVED, true, false) == null, "JarsLabel removed (L30)")
	for old in N_OLD_NODES_REMOVED:
		ck(main.find_child(old, true, false) == null, "%s removed in revision 3 (L19-L27)" % old)
	ck(not _vis(fork) and not _vis(cicon) and not _vis(cont) and not _vis(sell) and not _vis(summary), "no icon, Continue or summary at start")
	eq(money_label.text, "$0", "MoneyLabel at start")
	eq(bee_label.text, "Bees: %d" % bees_base, "BeeCountLabel at start")
	ck(upgrade.disabled, "UpgradeButton disabled with $0")
	await _wait(2.0)
	ck(float(hive.get("storage")) > 0.0, "the hive filled in real time (storage %.2f)" % float(hive.get("storage")))
	ck(fill_label.text.begins_with("Hive: "), "FillLabel format: " + fill_label.text)

	# =============================================================== ROUND 1
	print("=== round 1 ===")
	# CHEAT (Dev action): exactly one frame in the hive, overflow empty, so Back's "storage unchanged" can fail.
	hive.call("advance", float(J) * float(_cv("base_seconds_per_jar")), 1.0)
	await _frames(4)
	ck(hive.call("is_full"), "round 1: hive full")
	ck(float(hive.get("overflow")) < float(J) * 0.5, "round 1: overflow well under a frame (%s)" % str(hive.get("overflow")))
	eq(cen.get("state"), _st(cen, "EMPTY"), "round 1: centrifuge EMPTY")
	ck(_vis(fork), "round 1: fork icon floats above the full hive (L54)")
	ck(fork.size.x >= 120.0 and fork.size.y >= 120.0, "round 1: fork icon touch area >= 120 x 120 (%s)" % str(fork.size))
	ck(not _vis(cicon) and not _vis(cont), "round 1: centrifuge icon and Continue hidden")
	var storage_before: float = float(hive.get("storage"))
	await _shot("r3-1-farm-fork")

	# ---- fork -> close-up (L55)
	var hc: Node = await _open_closeup()
	if hc == null:
		_abort("no Honeycomb after tapping the fork icon")
		return
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	ck(not farm.visible, "round 1: FarmWorld hidden in the close-up")
	ck(not _vis(fork) and not _vis(upgrade), "round 1: farm UI hidden in the close-up")
	ck(cam != null and cam.get_parent() != null and cam.get_parent().name == HARVEST_ROOT, "round 1: the close-up camera is current")
	var back: Control = _n(N_BACK) as Control
	if back == null:
		_abort("no BackButton in the close-up")
		return
	ck(back.size.y >= 120.0, "round 1: BackButton at least 120 px high (%s)" % str(back.size.y))
	eq(_count_state(hc, 0), int(_cv("grid_cols")) * int(_cv("grid_rows")), "round 1: all cells start Capped (35)")
	var rows: Array = _rows(hc, cam)
	if rows.size() == 0:
		_abort("cannot locate the cells for the drag")
		return
	eq(rows.size(), int(_cv("grid_rows")), "round 1: the cells form grid_rows screen rows")

	# ---- a real drag uncaps (L55); positive control: nothing was uncapped before it
	eq(_count_state(hc, 1), 0, "round 1: nothing uncapped before the drag")
	await _drag_row(rows[0])
	var uncapped: int = _count_state(hc, 1)
	ck(uncapped >= int(_cv("grid_cols")), "round 1: a real mouse drag along one row uncaps at least that row (%d cells)" % uncapped)
	ck(uncapped < int(_cv("grid_cols")) * int(_cv("grid_rows")), "round 1: a one-row drag does not uncap the whole frame (%d)" % uncapped)
	await _shot("r3-2-closeup-partial")

	# ---- Back (L56, L227)
	await _click_ctl(back)
	await _wait(0.9)
	ck(_gone(N_HONEYCOMB), "round 1: Back freed the close-up")
	ck(farm.visible, "round 1: back on the farm")
	ck(float(hive.get("storage")) >= storage_before - 0.0001, "round 1: hive storage unchanged after Back (before %s, now %s): the frame is still in the hive" % [str(storage_before), str(hive.get("storage"))])
	ck(hive.call("is_full"), "round 1: hive still full after Back")
	eq(cen.get("state"), _st(cen, "EMPTY"), "round 1: centrifuge still EMPTY after Back")
	ck(_vis(fork), "round 1: the fork icon shows again after Back")

	# ---- reopen: the cells reset to Capped (L56)
	hc = await _open_closeup()
	if hc == null:
		_abort("no Honeycomb on the second open")
		return
	cam = root.get_viewport().get_camera_3d()
	eq(_count_state(hc, 0), int(_cv("grid_cols")) * int(_cv("grid_rows")), "round 1: the next open shows every cell Capped again")
	rows = _rows(hc, cam)
	if rows.size() == 0:
		_abort("cannot locate the cells for the second drag")
		return

	# ---- the full uncap by real drags, row by row (L57)
	var hint: Label = _n(N_HINT) as Label
	for r in rows.size() - 1:
		await _drag_row(rows[r])
	var n_cells: int = int(_cv("grid_cols")) * int(_cv("grid_rows"))
	ck(_count_state(hc, 1) < n_cells, "round 1: one row short, the frame is not done")
	ck(hint != null and hint.text != "All cells uncapped!", "round 1: hint not final yet")
	await _drag_row(rows[rows.size() - 1])
	ck(hc.call("all_uncapped"), "round 1: every cell uncapped by real drags (%d of %d)" % [_count_state(hc, 1), n_cells])
	ck(hint != null and hint.text == "All cells uncapped!", "round 1: hint reads 'All cells uncapped!' (got '%s')" % (hint.text if hint != null else "null"))
	var closed: bool = await _until(func() -> bool: return _gone(N_HONEYCOMB), 4.0)
	ck(closed, "round 1: the close-up closed by itself after the last cell (about 0.5 s plus the slide)")
	await _frames(3)
	ck(farm.visible, "round 1: the farm returned")
	ck(float(hive.get("storage")) < float(J) - 0.5, "round 1: take_frame() ran, the hive gave up the frame (storage %s)" % str(hive.get("storage")))
	eq(cen.get("state"), _st(cen, "FULL"), "round 1: centrifuge FULL")
	eq(cen.get("jars_total"), J, "round 1: centrifuge holds the frame's jars")

	# ---- FULL (L59, state table): centrifuge icon shown, nothing spins until tapped
	hive.call("advance", 100000.0, 1.0)   # CHEAT (Dev: fill the hive now): a full hive, to prove the fork stays hidden
	await _frames(4)
	ck(hive.call("is_full"), "round 1: hive full again")
	ck(not _vis(fork), "round 1: fork hidden while the centrifuge holds a frame, although the hive is full (L54)")
	ck(_vis(cicon), "round 1: centrifuge icon floats above the full centrifuge")
	ck(cicon.size.x >= 120.0 and cicon.size.y >= 120.0, "round 1: centrifuge icon touch area >= 120 x 120 (%s)" % str(cicon.size))
	ck(not _vis(cont), "round 1: Continue hidden")
	eq(cen.get("state"), _st(cen, "FULL"), "round 1: nothing spins before the tap (still FULL)")
	await _shot("r3-3-farm-centrifuge-icon")

	# ---- centrifuge icon starts cranking (L60)
	await _click_icon(cicon)
	await _frames(3)
	CRANKING_S = _st(cen, "CRANKING")
	eq(cen.get("state"), CRANKING_S, "round 1: tapping the centrifuge icon starts CRANKING")
	ck(not _vis(cicon), "round 1: the centrifuge icon hides")
	ck(not _vis(fork), "round 1: fork hidden while cranking")
	ck(_vis(crank_label), "round 1: the centrifuge label shows while cranking")
	ck(crank_label.text.to_lower().contains("tap or hold"), "round 1: hint 'Tap or hold to spin' while waiting for the first tap (got '%s')" % crank_label.text)
	await _shot("r3-4-farm-cranking")

	# ---- real taps (L61)
	var spot: Vector2 = _crank_spot()
	var k_taps: int = TAPS / 4
	for i in k_taps:
		await _click_at(spot)
		await _wait(GAP)
	var lo: int = int(floorf(float(k_taps) * float(J) / float(TAPS)))
	var hi: int = int(ceilf(float(k_taps) * float(J) / float(TAPS)))
	var got: int = int(cen.get("jars_extracted"))
	ck(got >= lo and got <= hi, "round 1: %d real clicks spaced past the cap extract %d to %d jars (got %d)" % [k_taps, lo, hi, got])
	ck(crank_label.text.contains(str(got)) and crank_label.text.to_lower().contains("honey"), "round 1: label shows the progress 'Honey: n / %d' (got '%s')" % [J, crank_label.text])

	# ---- a click on UpgradeButton during CRANKING is not a crank (L61, Done-when)
	# Positive control first: clicks on a free spot, spaced past the cap, DO advance the extraction.
	var per_jar_turns: int = int(ceilf(float(TAPS) / float(J)))
	var before_ctrl: int = int(cen.get("jars_extracted"))
	for i in per_jar_turns * 2:
		await _click_at(spot)
		await _wait(GAP)
	var after_ctrl: int = int(cen.get("jars_extracted"))
	ck(after_ctrl > before_ctrl, "round 1: positive control, %d free-spot clicks advanced the extraction (%d -> %d)" % [per_jar_turns * 2, before_ctrl, after_ctrl])
	ck(upgrade.is_visible_in_tree() and upgrade.disabled and int(eco.get("money")) < int(eco.call("swarm_cost")), "round 1: UpgradeButton visible and disabled with $0")
	var before_btn: int = int(cen.get("jars_extracted"))
	for i in per_jar_turns * 2:
		await _click_ctl(upgrade)
		await _wait(GAP)
	eq(cen.get("jars_extracted"), before_btn, "round 1: %d clicks on UpgradeButton during CRANKING did not crank" % (per_jar_turns * 2))
	eq(cen.get("state"), CRANKING_S, "round 1: still CRANKING")
	eq(eco.get("swarm_level"), 0, "round 1: a disabled UpgradeButton bought nothing")

	# ---- one real hold finishes the frame (L62)
	var turns_done: int = k_taps + per_jar_turns * 2   # every spaced click counted exactly one turn
	var expected_hold: float = float(TAPS - turns_done - 1) / RATE   # the press counts one turn, then RATE per second
	var t0: int = Time.get_ticks_msec()
	_mouse_button_os(spot, true)
	var finished: bool = await _until(func() -> bool: return int(cen.get("state")) != CRANKING_S, expected_hold * 3.0 + 10.0)
	var held: float = float(Time.get_ticks_msec() - t0) / 1000.0
	_mouse_button_os(spot, false)
	ck(finished, "round 1: the hold finished the frame")
	near(held, expected_hold, "round 1: real hold finish time ((taps - counted - 1) / max_tap_rate)", 0.4)
	eq(cen.get("state"), _st(cen, "DONE"), "round 1: DONE after the hold")
	eq(cen.get("jars_extracted"), J, "round 1: all jars extracted")

	# ---- DONE: Continue (L64)
	await _frames(4)
	ck(_vis(cont), "round 1: Continue shown when extraction is done")
	ck(cont.size.y >= 120.0, "round 1: Continue at least 120 px high (%s)" % str(cont.size.y))
	ck(cont.get_global_rect().get_center().y >= 640.0, "round 1: Continue in the lower half of the screen")
	ck(not _vis(fork) and not _vis(cicon), "round 1: fork and centrifuge icon hidden in DONE")
	await _shot("r3-5-farm-done-continue")

	# ---- Continue -> bottling (L65)
	await _click_ctl(cont)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "BOTTLING"), "round 1: Continue opens the spigot (BOTTLING)")
	ck(not _vis(cont), "round 1: Continue hides itself")
	var t_bottle: int = Time.get_ticks_msec()
	var jar_times: Array = []
	var seen_loaded: int = int(truck.get("loaded_jars"))
	while int(cen.get("state")) == _st(cen, "BOTTLING") and float(Time.get_ticks_msec() - t_bottle) < (SPJ * J + 15.0) * 1000.0:
		await process_frame
		var l: int = int(truck.get("loaded_jars"))
		if l > seen_loaded:
			jar_times.append(float(Time.get_ticks_msec() - t_bottle) / 1000.0)
			seen_loaded = l
		if jar_times.size() == 1:
			ck(not _vis(fork), "round 1: fork hidden while bottling although the hive is full")
			ck(not _vis(summary), "round 1: summary not shown before the last jar")
	var bottle_total: float = float(Time.get_ticks_msec() - t_bottle) / 1000.0
	near(bottle_total, SPJ * float(J), "round 1: bottling takes jars x bottling_seconds_per_jar", 0.6)
	eq(jar_times.size(), J, "round 1: each jar loaded onto the truck one at a time")
	for k in jar_times.size():
		near(float(jar_times[k]), SPJ * float(k + 1), "round 1: jar %d loaded at k x bottling_seconds_per_jar" % (k + 1), 0.6)
	eq(truck.get("loaded_jars"), J, "round 1: the truck holds the batch")
	eq(truck.get("crate_jars"), 0, "round 1: the crate stayed empty while the truck was home")
	eq(cen.get("state"), _st(cen, "EMPTY"), "round 1: the centrifuge is empty again")
	await _frames(3)

	# ---- summary and OK (L65)
	ck(_vis(summary), "round 1: the batch summary shows on the farm")
	ck((_n(N_SUMMARY_JARS) as Label).text.contains(str(J)), "round 1: summary jars: " + (_n(N_SUMMARY_JARS) as Label).text)
	ck((_n(N_SUMMARY_VALUE) as Label).text.contains("$%d" % PER), "round 1: summary value per jar: " + (_n(N_SUMMARY_VALUE) as Label).text)
	var bonus_txt: String = (_n(N_SUMMARY_BONUS) as Label).text
	ck(bonus_txt.contains("Tool bonus: $0") and bonus_txt.contains("Quality bonus: $0"), "round 1: bonuses are $0: " + bonus_txt)
	eq((_n(N_SUMMARY_TOTAL) as Label).text, "Batch total: $%d" % (J * PER), "round 1: batch total")
	eq(eco.get("money"), 0, "round 1: no money before the Sell tap (L66)")
	var ok_btn: Control = _n(N_SUMMARY_OK) as Control
	ck(ok_btn.size.y >= 120.0, "round 1: OK at least 120 px high (%s)" % str(ok_btn.size.y))
	ck(ok_btn.get_global_rect().get_center().y >= 640.0, "round 1: OK in the lower half of the screen")
	await _shot("r3-6-farm-summary")
	await _click_ctl(ok_btn)
	await _frames(3)
	ck(not _vis(summary), "round 1: OK closes the summary")

	# ---- Sell icon (L66)
	ck(_vis(sell), "round 1: the Sell icon floats above the full truck at home")
	ck(sell.size.y >= 120.0, "round 1: Sell icon at least 120 px high (%s)" % str(sell.size.y))
	var sell_text: String = (sell as Button).text
	ck(sell_text.contains("Sell") and sell_text.contains("$%d" % (CAP * PER)), "round 1: Sell icon reads 'Sell $%d' (got '%s')" % [CAP * PER, sell_text])
	var home_pos: Vector3 = _centroid(truck as Node3D)
	_set_cfg("truck_trip_seconds", float(_cv("truck_trip_seconds")) * 2.0)   # CHEAT: the truck stays away through round 2's bottling
	var trip: float = float(_cv("truck_trip_seconds"))
	await _click_icon(sell)
	await _frames(2)
	eq(eco.get("money"), CAP * PER, "round 1: money credited at the tap, not at the truck's return")
	ck(truck.get("away"), "round 1: the truck is away")
	eq(truck.get("loaded_jars"), 0, "round 1: the truck is empty")
	ck(not _vis(sell), "round 1: the Sell icon is hidden while the truck is away")
	eq(money_label.text, "$%d" % (CAP * PER), "round 1: MoneyLabel")
	await _wait(5.0)
	ck(_centroid(truck as Node3D).distance_to(home_pos) > 0.5, "round 1: the truck slid away from home (moved %.2f)" % _centroid(truck as Node3D).distance_to(home_pos))
	await _shot("r3-7-farm-truck-away")

	# =============================================================== ROUND 2
	print("=== round 2 ===")
	# the hive is full (cheat above); the truck is away
	await _frames(2)
	ck(hive.call("is_full"), "round 2: hive full")
	ck(_vis(fork), "round 2: fork icon shows again (centrifuge EMPTY)")
	hc = await _open_closeup()
	if hc == null:
		_abort("round 2: no Honeycomb")
		return
	cam = root.get_viewport().get_camera_3d()
	eq(_count_state(hc, 0), n_cells, "round 2: the frame starts all Capped (L68)")
	rows = _rows(hc, cam)
	if rows.size() == 0:
		_abort("round 2: cannot locate cells")
		return
	await _drag_row_touch(rows[0])   # a finger, not a mouse
	ck(_count_state(hc, 1) >= int(_cv("grid_cols")), "round 2: a touch drag uncaps a row (%d cells)" % _count_state(hc, 1))
	for r in range(1, rows.size()):
		await _drag_row(rows[r])
	if not hc.call("all_uncapped"):
		await _drag_row(rows[0])   # the touch drag may have missed cells on a device without touch emulation; finish with the mouse
	ck(hc.call("all_uncapped"), "round 2: every cell uncapped")
	closed = await _until(func() -> bool: return _gone(N_HONEYCOMB), 4.0)
	ck(closed, "round 2: the close-up closed by itself")
	await _frames(3)
	hive.call("advance", 100000.0, 1.0)   # CHEAT (Dev: fill the hive now)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "FULL"), "round 2: centrifuge FULL")
	ck(_vis(cicon), "round 2: centrifuge icon shown")
	await _click_icon(cicon)
	await _frames(3)
	eq(cen.get("state"), CRANKING_S, "round 2: CRANKING")
	spot = _crank_spot()
	# a hold from the first press: (taps_per_frame - 1) / max_tap_rate
	var exp2: float = float(TAPS - 1) / RATE
	t0 = Time.get_ticks_msec()
	_mouse_button_os(spot, true)
	finished = await _until(func() -> bool: return int(cen.get("state")) != CRANKING_S, exp2 * 3.0 + 10.0)
	held = float(Time.get_ticks_msec() - t0) / 1000.0
	_mouse_button_os(spot, false)
	ck(finished, "round 2: the hold finished the frame")
	near(held, exp2, "round 2: real hold from the first press, (taps_per_frame - 1) / max_tap_rate", 0.4)
	await _frames(4)
	ck(_vis(cont), "round 2: Continue shown")
	await _click_ctl(cont)
	await _frames(3)
	eq(cen.get("state"), _st(cen, "BOTTLING"), "round 2: BOTTLING")

	# ---- the truck is away: bottled jars fill the crate (L65)
	ck(truck.get("away"), "round 2: the truck is still away while bottling starts")
	var crate_ok: bool = await _until(func() -> bool: return int(truck.get("crate_jars")) >= 2, SPJ * 4.0 + 5.0)
	ck(crate_ok, "round 2: jars bottled while the truck is away fill the crate (crate %s)" % str(truck.get("crate_jars")))
	eq(truck.get("loaded_jars"), 0, "round 2: nothing loaded on the away truck")
	await _shot("r3-8-farm-crate-filling")

	# ---- one purchase mid-harvest, while bottling (L67)
	var cost: int = int(eco.call("swarm_cost"))
	ck(int(eco.get("money")) >= cost, "round 2: money %s covers the Worker Swarm Count cost %d" % [str(eco.get("money")), cost])
	ck(not upgrade.disabled, "round 2: UpgradeButton enabled while bottling (the shop works at every stage)")
	var money_before: int = int(eco.get("money"))
	await _click_ctl(upgrade)
	await _frames(3)
	eq(eco.get("swarm_level"), 1, "round 2: Worker Swarm Count level 1 bought mid-harvest")
	eq(eco.get("money"), money_before - cost, "round 2: money after the purchase")
	eq(bee_label.text, "Bees: %d" % (bees_base + int(_cv("bees_per_swarm_level"))), "round 2: BeeCountLabel after the purchase")
	eq(int(bees.call("drawn_count")), bees_base + int(_cv("bees_per_swarm_level")), "round 2: drawn bees after the purchase")
	ck(upgrade.disabled, "round 2: UpgradeButton disabled again (cannot afford the next level)")
	eq(cen.get("state"), _st(cen, "BOTTLING"), "round 2: the purchase did not disturb bottling")

	# ---- finish bottling: every jar in the crate, none lost
	var bottled: bool = await _until(func() -> bool: return int(cen.get("state")) == _st(cen, "EMPTY"), SPJ * float(J) + 10.0)
	ck(bottled, "round 2: bottling finished")
	await _frames(3)
	if truck.get("away"):
		eq(int(truck.get("crate_jars")) + int(truck.get("loaded_jars")), J, "round 2: jars conserved: crate + truck = the batch")
		eq(truck.get("loaded_jars"), 0, "round 2: all the batch is in the crate while the truck is away")
	ck(_vis(summary), "round 2: summary shown")
	await _click_ctl(_n(N_SUMMARY_OK) as Control)
	await _frames(3)
	ck(not _vis(summary), "round 2: OK closes the summary")

	# ---- the truck returns and loads the crate (L66)
	var back_home: bool = await _until(func() -> bool: return not truck.get("away"), trip + 15.0)
	ck(back_home, "round 2: the truck came back")
	await _frames(4)
	eq(truck.get("loaded_jars"), mini(CAP, J), "round 2: the crate loaded onto the returned truck up to its capacity")
	eq(int(truck.get("crate_jars")), maxi(J - CAP, 0), "round 2: the rest stays in the crate")
	ck(_vis(sell), "round 2: the Sell icon shows on the full truck")
	var m2: int = int(eco.get("money"))
	await _click_icon(sell)
	await _frames(2)
	eq(eco.get("money"), m2 + CAP * PER, "round 2: Sell credited at the tap")
	ck(truck.get("away"), "round 2: the truck is away again")

	# ---- done
	for k in _cfg_saved:
		root.get_node("Economy").get("config").set(k, _cfg_saved[k])
	print("---- %d checks, %d failed" % [checks, fails])
	print("COMPLETED")
	quit(1 if fails > 0 else 0)


## Enum member of the centrifuge's state, wherever the enum lives (the spec names the states, not the enum).
func _st(o: Object, state_name: String) -> int:
	var map: Dictionary = (o.get_script() as GDScript).get_script_constant_map()
	for k in map:
		var v: Variant = map[k]
		if v is Dictionary and (v as Dictionary).has(state_name):
			return int((v as Dictionary)[state_name])
	ck(false, "no enum member %s in the centrifuge script" % state_name)
	return -999
