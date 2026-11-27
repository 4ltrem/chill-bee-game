# Quinn: milestone 0.1 (Harvest) integration test, WINDOWED, written from game/specs/0.1-harvest.md before the code.
#   Godot --path game --script res://tests/play_loop.gd
# Plays the harvest twice through REAL input (events pushed into the viewport in window pixels, as a real mouse sends them;
# tests/farm_input.gd): the projected fork icon, drags on the upright risen frame through the farm camera, Back after one
# frame and a half (the half frame is kept), the return, cells piling while the centrifuge cranks, Spin and spaced real clicks
# (one real hold in round 2), bottling by itself (0.1.2: no Continue), (floor(jars) with the carried leftover), the pile loading into the empty bucket,
# a Worker Swarm Count purchase mid-harvest, Sell. Screenshots: every centrifuge state on the farm, the zoom with a risen
# frame, a cell in flight, a pile, Show UI bounds. Exit code 0 only if no check failed AND the final "COMPLETED" line printed.
# 0.2.1 rewrite: Spin from the farm view pans to the second stop and the crank starts after the pan (item 9); Back there pauses the crank and Spin
# resumes it (0.1.4 item 15); a reloaded bucket stays CRANKING by itself (item 7); the truck leaves after the jars in flight land (item 13).
# CHEATS (Dev mode actions, all marked "CHEAT" below, config restored at the end): the hive is filled with fill_now and its
# fill frozen (base_seconds_per_jar huge) so nothing arrives behind the test; bottling is 1 s per jar; truck_trip_seconds is
# doubled so the truck is still away while round 2 bottles.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const Flow := preload("res://tests/flow.gd")
const MAIN_SCENE := "res://scenes/main.tscn"
const SHOT_DIR := "res://reports/_runs/shots/play_loop/"
# r3 numbers for the disabled UpgradeButton at $0 (reports/builds/prototype-0/round-3/report.md): background (97, 87, 76)
const DISABLED_BG := Color8(97, 87, 76)

var fi: RefCounted
var main: Node
var fails: int = 0
var checks: int = 0
var _cfg_saved: Dictionary = {}
var tr: Dictionary = {"risen": -1, "raised": [], "lowered": [], "lid": []}
var P: Dictionary = {}


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


func _until(cond: Callable, timeout: float) -> bool:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < timeout * 1000.0:
		if cond.call():
			return true
		await process_frame
	return cond.call()


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


func _cpf() -> int:
	return int(_cv("grid_cols")) * int(_cv("grid_rows"))


func _jars_of(cells: int) -> float:
	return float(cells * int(_cv("frame_jars"))) / float(_cpf())


@warning_ignore("integer_division")
func _turns_for(cells: int) -> int:
	var num: int = cells * int(_cv("frame_jars")) * int(_cv("taps_per_jar"))
	return (num + _cpf() - 1) / _cpf()


func _shot(name: String) -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err: int = img.save_png(ProjectSettings.globalize_path(SHOT_DIR + name + ".png"))
	print("screenshot ", name, " ", img.get_size(), " err=", err)
	return img


## Viewport (720 x 1280) point to a pixel of a screenshot (the image has the window's size under canvas_items stretch).
func _px(img: Image, vp: Vector2) -> Vector2i:
	var k: Vector2 = Vector2(img.get_size()) / root.get_visible_rect().size
	return Vector2i(int(vp.x * k.x), int(vp.y * k.y))


## The most common pixel inside a rect of the viewport: the button's background.
func _dominant(img: Image, rect: Rect2) -> Color:
	var counts: Dictionary = {}
	var a: Vector2i = _px(img, rect.position)
	var b: Vector2i = _px(img, rect.end)
	for y in range(maxi(a.y, 0), mini(b.y, img.get_height()), 2):
		for x in range(maxi(a.x, 0), mini(b.x, img.get_width()), 2):
			var c: Color = img.get_pixel(x, y)
			var key: int = c.to_rgba32()
			counts[key] = int(counts.get(key, 0)) + 1
	var best_key: int = 0
	var best_n: int = -1
	for k in counts:
		if int(counts[k]) > best_n:
			best_n = int(counts[k])
			best_key = int(k)
	return Color.hex(best_key)


## A mouse button through Input.parse_input_event, like the OS sends it (also updates Input.is_mouse_button_pressed, which
## centrifuge.gd polls to end a hold; root.push_input does not).
func _mouse_button_os(vp_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos * fi.to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _st(o: Object, state_name: String) -> int:
	var map: Dictionary = (o.get_script() as GDScript).get_script_constant_map()
	for k in map:
		var v: Variant = map[k]
		if v is Dictionary and (v as Dictionary).has(state_name):
			return int((v as Dictionary)[state_name])
	ck(false, "no enum member %s in the centrifuge script" % state_name)
	return -999


func _n(name: String) -> Node:
	var n: Node = main.find_child(name, true, false)
	if n == null:
		print("FAIL  node missing (spec: Node paths for Bob): ", name)
		fails += 1
		checks += 1
	return n


# ---------------------------------------------------------------- the zoom, through real input

func _zoom_settle() -> float:
	return float(_cv("zoom_seconds")) + _lid_t() + float(_cv("slide_seconds")) + 0.5


func _open_zoom(tag: String) -> bool:
	var fork: Control = P["ForkIcon"]
	ck(_vis(fork), "%s: the fork icon floats above the hive" % tag)
	var on: bool = await fi.click_icon(fork)
	ck(on, "%s: the fork icon sits at its anchor's projected position" % tag)
	var raised: bool = await _until(func() -> bool: return int(tr["risen"]) >= 0, 3.0)
	await _wait(_zoom_settle())
	ck(raised, "%s: tapping the fork raised a frame" % tag)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	near(cam.size, float(_cv("zoom_size")), "%s: the camera is at zoom_size" % tag, 0.05)
	# 0.1.3c: a paused crank (Back at the second stop, item 15) keeps Spin on screen in the first zoom, so only the other farm UI must be hidden then
	ck(not _vis(fork) and not _vis(P["UpgradeButton"]) and (tag.contains("paused") or not _vis(P["CentrifugeIcon"])), "%s: the farm UI is hidden in the zoom" % tag)
	ck(_vis(P["BackButton"]), "%s: BackButton shows" % tag)
	return raised


func _risen_cells_capped() -> int:
	return fi.capped(P["Hive"], int(tr["risen"])) if int(tr["risen"]) >= 0 else 0


## Real drags, row by row, over the risen frame until no Capped cell is left on it or the zoom moved on.
func _scrape_risen(touch_first: bool = false) -> int:
	var f: int = int(tr["risen"])
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var first: bool = touch_first
	for pass_i in 5:
		if int(tr["risen"]) != f or fi.capped(P["Hive"], f) == 0:
			break
		for r in fi.rows(hc, cam):
			if int(tr["risen"]) != f or fi.capped(P["Hive"], f) == 0:
				break
			if first:
				await fi.drag_row_touch(r)   # a finger, not a mouse
				first = false
			else:
				await fi.drag_row(r)
	return f


func _next_frame(was: int) -> bool:
	var moved: bool = await _until(func() -> bool: return int(tr["risen"]) >= 0 and int(tr["risen"]) != was, 4.0)
	await _wait(float(_cv("slide_seconds")) + 0.45)
	return moved


func _zoom_out_wait() -> void:
	await _wait(_zoom_settle() + float(_cv("zoom_seconds")) + _lid_t() + float(_cv("close_delay_seconds")))


## Spin icon, then spaced real clicks until DONE (or one real hold). Returns the number of counted turns by this call.
func _crank(tag: String, use_hold: bool) -> void:
	var cen: Node = P["Centrifuge"]
	var cicon: Control = P["CentrifugeIcon"]
	ck(_vis(cicon), "%s: Spin shows" % tag)
	ck(cicon.size.x >= 120.0 and cicon.size.y >= 120.0, "%s: Spin touch area at least 120 x 120 (%s)" % [tag, str(cicon.size)])
	var cells: int = int(cen.get("cells"))
	await fi.click_icon(cicon)
	var cranking: int = _st(cen, "CRANKING")
	# 0.2 item 9 (0.1.4 item 11): Spin from the farm view pans to the second stop first; the crank starts when the pan ends
	await _until(func() -> bool: return int(cen.get("state")) == cranking, float(_cv("camera_pan_seconds")) + 4.0)
	await _frames(3)
	eq(cen.get("state"), cranking, "%s: tapping Spin starts CRANKING (after the pan to the second stop)" % tag)
	ck(not _vis(cicon), "%s: Spin hides while cranking" % tag)
	var spot: Vector2 = fi.free_spot(main)
	var rate: float = float(_cv("max_tap_rate"))
	var gap: float = 1.0 / rate + 0.03
	var need: int = _turns_for(cells)
	var done_turns: int = int(cen.get("turns_counted"))
	if use_hold:
		var expected: float = float(need - done_turns - 1) / rate   # the press counts one turn, then max_tap_rate per second
		var t0: int = Time.get_ticks_msec()
		_mouse_button_os(spot, true)
		var finished: bool = await _until(func() -> bool: return int(cen.get("state")) != cranking, expected * 3.0 + 10.0)
		var held: float = float(Time.get_ticks_msec() - t0) / 1000.0
		_mouse_button_os(spot, false)
		ck(finished, "%s: the hold finished the cranking" % tag)
		near(held, expected, "%s: real hold time (turns - counted - 1) / max_tap_rate" % tag, 0.4)
	else:
		var sent: int = 0
		while int(cen.get("state")) == cranking and sent < need + 6:
			await fi.click_at(spot)
			await _wait(gap)
			sent += 1
		eq(sent, need - done_turns, "%s: ceil(jars x taps_per_jar) real clicks in all (%d turns for %d cells)" % [tag, need, cells])
	ck(_extracted(cen), "%s: extraction done (DONE, or BOTTLING already: 0.1.2 starts bottling by itself)" % tag)
	await _frames(4)


## 0.1.2: no Continue. Bottling starts by itself after the extraction (no input at all), the jars go to the truck or the crate,
## and NO summary shows after bottling. Returns the jars bottled.
func _bottle(tag: String, mid: Callable = Callable()) -> int:
	var cen: Node = P["Centrifuge"]
	var truck: Node = P["Truck"]
	var cells: int = int(cen.get("cells"))
	var lo: Variant = cen.get("leftover_jars")
	ck(lo != null, "%s: centrifuge.gd has leftover_jars" % tag)
	var leftover0: float = float(lo) if lo != null else 0.0
	var want: int = int(floorf(_jars_of(cells) + leftover0 + 0.000001))
	var before: int = int(truck.get("loaded_jars")) + int(truck.get("crate_jars"))
	var bottling: int = _st(cen, "BOTTLING")
	var started: bool = await _until(func() -> bool: return int(cen.get("state")) == bottling or int(cen.get("state")) == _st(cen, "EMPTY"), 5.0)
	ck(started, "%s: bottling started by itself, with no input after the extraction" % tag)
	if mid.is_valid() and int(cen.get("state")) == bottling:
		await _wait(float(_cv("bottling_seconds_per_jar")) * 1.5)
		await mid.call()
	var done: bool = await _until(func() -> bool: return int(cen.get("state")) != bottling, 40.0)
	ck(done, "%s: bottling ended" % tag)
	ck(not _vis(P["SummaryModal"]), "%s: no summary after bottling (0.1.2 change 7: it comes after Sell)" % tag)
	var after: int = int(truck.get("loaded_jars")) + int(truck.get("crate_jars"))
	eq(after - before, want, "%s: floor(jars + carried leftover) = %d jars bottled" % [tag, want])
	await _frames(3)
	return want


## True once the extraction is over: DONE, or already BOTTLING / EMPTY (the state may pass through DONE for one frame).
func _extracted(cen: Node) -> bool:
	var s: int = int(cen.get("state"))
	return s == _st(cen, "DONE") or s == _st(cen, "BOTTLING") or s == _st(cen, "EMPTY")


## After Sell: the modal shows jars sold, price per jar and the total, then OK closes it.
func _summary_after_sell(tag: String, jars: int, per: int) -> void:
	var shown: bool = await _until(func() -> bool: return _vis(P["SummaryModal"]), 5.0)
	ck(shown, "%s: the summary shows after Sell" % tag)
	if not shown:
		return
	for pair in [["SummaryJarsLabel", jars], ["SummaryValueLabel", per], ["SummaryTotalLabel", jars * per]]:
		var lb: Node = _n(pair[0])
		ck(lb != null and (lb as Label).text.contains(str(int(pair[1]))), "%s: %s shows %d (text '%s')" % [tag, pair[0], int(pair[1]), (lb as Label).text if lb != null else "?"])
	ck(main.find_child("SummaryBonusLabel", true, false) == null, "%s: no SummaryBonusLabel" % tag)
	await fi.click_ctl(P["SummaryOkButton"] as Control)
	await _frames(3)
	ck(not _vis(P["SummaryModal"]), "%s: OK closes the summary" % tag)


# ---------------------------------------------------------------- the run

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	fi = FarmInput.new(self)
	var eco: Node = root.get_node("Economy")
	if eco.has_method("reset"):
		eco.call("reset")
	var ps: Variant = load(MAIN_SCENE)
	if ps == null:
		_abort("%s failed to load" % MAIN_SCENE)
		return
	Flow.no_welcome(self)
	main = (ps as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	for nm in ["Hive", "Centrifuge", "Pile", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon", "UpgradeButton",
			"BackButton", "HintLabel", "SummaryModal", "SummaryOkButton", "CentrifugeLabel", "MoneyLabel", "HiveCountLabel", "BeeCountLabel", "Bees"]:
		P[nm] = _n(nm)
		if P[nm] == null:
			_abort("a required node is missing; see the lines above")
			return
	var hive: Node = P["Hive"]
	var cen: Node = P["Centrifuge"]
	var pile: Node = P["Pile"]
	var truck: Node = P["Truck"]
	var upgrade: Button = P["UpgradeButton"]
	hive.connect("frame_raised", func(i: Variant) -> void:
		tr["risen"] = int(i)
		(tr["raised"] as Array).append(int(i)))
	hive.connect("frame_lowered", func(i: Variant) -> void:
		(tr["lowered"] as Array).append(int(i))
		if int(tr["risen"]) == int(i):
			tr["risen"] = -1)
	hive.connect("lid_moved", func(o: Variant) -> void: (tr["lid"] as Array).append(bool(o)))
	var NF: int = int(_cv("frames_per_hive"))
	var CPF: int = _cpf()
	var CAP_CELLS: int = int(_cv("centrifuge_capacity_frames")) * CPF
	var TOTAL: int = NF * CPF
	var JARS: int = NF * int(_cv("frame_jars"))
	var TRUCK_CAP: int = int(_cv("truck_capacity_jars"))
	var PER: int = int(eco.call("jar_value"))
	var bees_base: int = int(eco.call("bee_count"))

	# ---- start state; focus item 7: the disabled UpgradeButton renders its disabled style even when told to take focus
	ck(main.find_child("Harvest", true, false) == null, "no Harvest close-up root (harvest.tscn retired)")
	# 0.1.4 item 1: "The Harvest button is always shown ... pressable only when full", so at start it shows, disabled
	ck(_vis(P["ForkIcon"]) and (P["ForkIcon"] as Button).disabled, "Harvest shows at start, disabled (hive not full)")
	ck(not _vis(P["CentrifugeIcon"]) and not _vis(P["SellIcon"]) and not _vis(P["SummaryModal"]), "no Spin, Sell or summary at start")
	ck(main.find_child("ContinueButton", true, false) == null, "0.1.2 change 6: there is no ContinueButton node")
	ck(main.find_child("SummaryBonusLabel", true, false) == null, "0.1.2 change 7: there is no SummaryBonusLabel node")
	eq((P["MoneyLabel"] as Label).text, "$0", "MoneyLabel at start")
	eq((P["BeeCountLabel"] as Label).text, "Bees: %d" % bees_base, "BeeCountLabel at start")
	await Flow.shop_open(main, fi, true)   # item 14: the sheet is closed on the farm; a real Shop tap opens it
	ck(upgrade.disabled, "UpgradeButton disabled with $0")
	upgrade.grab_focus()
	await _frames(3)
	ck(not upgrade.has_focus(), "item 7: grab_focus() did not focus the disabled UpgradeButton (focus_mode None)")
	var img0: Image = await _shot("r4-0-farm-start")
	var ur: Rect2 = upgrade.get_global_rect()   # in the shop sheet the drawn pill is thin inside a taller rect: sample a strip at the left of its centre line, clear of the price text
	var bg: Color = _dominant(img0, Rect2(ur.position.x + 6.0, ur.get_center().y - 3.0, 20.0, 6.0))
	ck(absf(bg.r8 - DISABLED_BG.r8) <= 2 and absf(bg.g8 - DISABLED_BG.g8) <= 2 and absf(bg.b8 - DISABLED_BG.b8) <= 2, "item 7: the disabled UpgradeButton renders the disabled style (97, 87, 76) +-2 (got %d, %d, %d)" % [bg.r8, bg.g8, bg.b8])
	await Flow.shop_close(main)
	_set_cfg("bottling_seconds_per_jar", 1.0)   # CHEAT: quicker bottling
	var spj: float = float(_cv("bottling_seconds_per_jar"))

	for rnd in [1, 2]:
		var T: String = "round %d" % rnd
		print("=== ", T, " ===")
		# CHEAT (Dev action Fill hive now), then freeze the fill so nothing arrives behind the test
		hive.call("fill_now")
		_set_cfg("base_seconds_per_jar", 1.0e9)
		tr["raised"] = []
		tr["lid"] = []
		await _frames(4)
		eq(fi.capped_total(hive, NF), TOTAL, "%s: 5 full frames" % T)
		eq(cen.get("state"), _st(cen, "EMPTY"), "%s: the bucket is EMPTY" % T)
		ck(_vis(P["ForkIcon"]), "%s: fork shows at a full hive" % T)
		ck((P["ForkIcon"] as Control).size.x >= 120.0 and (P["ForkIcon"] as Control).size.y >= 120.0, "%s: fork touch area at least 120 x 120" % T)
		if rnd == 1:
			await _shot("r4-1-farm-fork-empty")

		# ---- zoom in, frame 0 scraped by real drags (round 2: the first row by touch), frame 1 half scraped
		ck(await _open_zoom(T), "%s: zoom open" % T)
		eq(tr["risen"], 0, "%s: the first frame rises first" % T)
		if rnd == 1:
			await _shot("r4-2-zoom-risen-frame")
		var f0: int = await _scrape_risen(rnd == 2)
		ck(await _next_frame(f0), "%s: frame %d done, frame %d rose" % [T, f0, f0 + 1])
		var hc: Node = main.find_child("Honeycomb", true, false)
		var cam: Camera3D = root.get_viewport().get_camera_3d()
		var rws: Array = fi.rows(hc, cam)
		ck(rws.size() >= 2, "%s: the second frame shows its rows" % T)
		await fi.drag_row(rws[0])
		if rnd == 1:
			await _shot("r4-3-zoom-cell-in-flight")
		await fi.drag_row(rws[1])
		await _wait(float(_cv("cell_fly_seconds")) + 0.4)
		var left: int = fi.capped(hive, 1)
		ck(left > 0 and left < CPF, "%s: half of frame 1 scraped (%d of %d Capped left)" % [T, left, CPF])
		var snap: PackedByteArray = hive.call("frame_cells", 1)
		eq(int(tr["risen"]), 1, "%s: frame 1 is still up" % T)
		var in_bucket: int = CPF + (CPF - left)
		eq(cen.get("cells"), in_bucket, "%s: %d cells in the bucket" % [T, in_bucket])
		ck(in_bucket < CAP_CELLS, "%s: the bucket still has room" % T)

		# ---- Back: half frame kept, lid on, Spin and the fork show
		await fi.click_ctl(P["BackButton"] as Control)
		await _zoom_out_wait()
		eq(hive.call("frame_cells", 1), snap, "%s: Back kept the half frame's cells" % T)
		eq(cen.get("lid_open"), false, "%s: Back with cells in the bucket: lid on" % T)
		eq(cen.get("state"), _st(cen, "FULL"), "%s: FULL (waiting for Spin)" % T)
		ck(_vis(P["CentrifugeIcon"]), "%s: Spin shows after Back" % T)
		ck(_vis(P["ForkIcon"]), "%s: the fork stays while Capped cells remain" % T)
		eq(hive.call("next_frame_to_harvest"), 1, "%s: the half frame is next" % T)
		if rnd == 1:
			await _shot("r4-4-farm-full-spin-and-fork")

		# ---- Spin (CRANKING), then the fork again: cells pile up while cranking, crank clicks do not count in the zoom
		# 0.2 item 9: Spin from the farm view pans to the second stop first, the crank starts after the pan (wait for CRANKING, as r4_measure.gd does)
		await fi.click_icon(P["CentrifugeIcon"] as Control)
		var cr_state: int = _st(cen, "CRANKING")
		await _until(func() -> bool: return int(cen.get("state")) == cr_state, float(_cv("camera_pan_seconds")) + 4.0)
		await _frames(3)
		eq(cen.get("state"), cr_state, "%s: CRANKING after the pan to the second stop" % T)
		ck(bool(main.call("at_second_stop")), "%s: Spin panned to the second stop" % T)
		ck(not _vis(P["ForkIcon"]), "%s: the fork is hidden at the second stop" % T)
		if rnd == 1:
			await _shot("r4-5-farm-cranking-with-fork")
		var spot: Vector2 = fi.free_spot(main)
		await fi.click_at(spot)
		var turns1: int = int(cen.get("turns_counted"))
		eq(turns1, 1, "%s: one real click at the second stop counted one turn" % T)
		await _wait(1.0 / float(_cv("max_tap_rate")) + 0.05)
		# 0.1.4 item 15: Back at the second stop pauses the crank (progress kept); the camera returns to the farm view, where the fork shows again
		ck(_vis(P["BackButton"]), "%s: BackButton shows at the second stop" % T)
		await fi.click_ctl(P["BackButton"] as Control)
		await _wait(float(_cv("zoom_seconds")) + 0.5)
		eq(cen.get("state"), cr_state, "%s: Back left the bucket CRANKING (paused)" % T)
		eq(cen.get("crank_enabled"), false, "%s: Back paused the crank (no turn counts off the second stop)" % T)
		# the spot found at the second stop can sit under Spin on the farm view (it would pan back and resume): pick a spot on the farm view
		await fi.click_at(fi.free_spot(main))
		await _wait(1.0 / float(_cv("max_tap_rate")) + 0.05)
		eq(cen.get("turns_counted"), turns1, "%s: a click on the farm view while paused counted no turn" % T)
		ck(not bool(main.call("at_second_stop")), "%s: a click on the farm view stayed on the farm view" % T)
		tr["raised"] = []
		ck(await _open_zoom(T + " (return, paused crank)"), "%s: the fork opened the zoom with the crank paused" % T)
		eq(tr["risen"], 1, "%s: the half frame rises first on the return" % T)
		for i in 4:
			await fi.click_at(fi.free_spot(main))
			await _wait(float(1.0 / float(_cv("max_tap_rate"))) + 0.05)
		eq(cen.get("turns_counted"), turns1, "%s: clicks in the zoom counted no turn" % T)
		var n_frames_left: int = NF - 1
		for k in n_frames_left:
			var f: int = await _scrape_risen()
			if k == 0:
				eq(cen.get("turns_counted"), turns1, "%s: dragging on the frame was never a crank turn" % T)
			if k < n_frames_left - 1:
				ck(await _next_frame(f), "%s: frame %d done, the next rose" % [T, f])
		await _wait(float(_cv("close_delay_seconds")) + _zoom_settle() + float(_cv("cell_fly_seconds")) + float(_cv("zoom_seconds")))
		eq(fi.capped_total(hive, NF), 0, "%s: no Capped cell left" % T)
		eq(pile.get("cells"), TOTAL - in_bucket, "%s: every later cell piled up (%d)" % [T, TOTAL - in_bucket])
		eq(cen.get("cells"), in_bucket, "%s: the cranking bucket took no cell" % T)
		ck(_vis(P["MoneyLabel"]) and (P["ForkIcon"] as Button).disabled, "%s: the zoom ended on its own: farm UI back, Harvest disabled (0.1.4 item 1: always shown)" % T)
		if rnd == 1:
			await _shot("r4-6-farm-pile-while-cranking")
		eq(cen.get("state"), _st(cen, "CRANKING"), "%s: still CRANKING after the zoom" % T)
		eq(cen.get("crank_enabled"), false, "%s: the crank is still paused on the farm view" % T)
		# 0.1.4 item 15: Spin on the paused crank pans back to the second stop and the crank resumes where it stopped
		ck(_vis(P["CentrifugeIcon"]), "%s: Spin shows for the paused crank" % T)
		await fi.click_icon(P["CentrifugeIcon"] as Control)
		await _until(func() -> bool: return bool(cen.get("crank_enabled")), float(_cv("camera_pan_seconds")) + 4.0)
		eq(cen.get("crank_enabled"), true, "%s: cranking counts again after Spin pans back" % T)
		ck(bool(main.call("at_second_stop")), "%s: Spin on the paused crank went to the second stop" % T)
		eq(cen.get("turns_counted"), turns1, "%s: the crank resumed where it stopped" % T)
		await _frames(3)

		# ---- finish this batch, bottle it; the pile loads in; repeat until everything is bottled
		var batch: int = 0
		var bottled_total: int = 0
		while true:
			batch += 1
			var TB: String = "%s batch %d" % [T, batch]
			var cells: int = int(cen.get("cells"))
			if int(cen.get("state")) == _st(cen, "CRANKING"):
				# the rest of the turns by real clicks (round 2 batch 1: one real hold)
				var spot2: Vector2 = fi.free_spot(main)
				var gap: float = 1.0 / float(_cv("max_tap_rate")) + 0.03
				var need: int = _turns_for(cells)
				var cranking: int = _st(cen, "CRANKING")
				var tc0: int = int(cen.get("turns_counted"))   # turns already counted (batch 1: the one click; a reloaded bucket: none)
				if rnd == 2 and batch == 1:
					var expected: float = float(need - int(cen.get("turns_counted")) - 1) / float(_cv("max_tap_rate"))
					var t0: int = Time.get_ticks_msec()
					_mouse_button_os(spot2, true)
					var fin: bool = await _until(func() -> bool: return int(cen.get("state")) != cranking, expected * 3.0 + 10.0)
					var held: float = float(Time.get_ticks_msec() - t0) / 1000.0
					_mouse_button_os(spot2, false)
					ck(fin, "%s: the hold finished the cranking" % TB)
					near(held, expected, "%s: real hold time" % TB, 0.4)
				else:
					var sent: int = 0
					while int(cen.get("state")) == cranking and sent < need + 6:
						await fi.click_at(spot2)
						await _wait(gap)
						sent += 1
					# the game's own counter is the truth: a click the tap-rate gate dropped is not a turn (diag showed sent+tc0 = 13 but turns_counted = 12)
					eq(int(cen.get("turns_counted")), need, "%s: ceil(jars x taps_per_jar) = %d turns in all (diag: sent=%d tc0=%d cells=%d state=%s turns_counted_now=%s)" % [TB, need, sent, tc0, cells, str(cen.get("state")), str(cen.get("turns_counted"))])
				ck(_extracted(cen), "%s: extraction done" % TB)
				await _frames(4)
			else:
				await _crank(TB, false)
			if rnd == 1 and batch == 1:
				await _shot("r4-7-farm-done-bottling-starts")
			var mid: Callable = Callable()
			if rnd == 2 and batch == 1:
				mid = func() -> void:
					# the shop works whenever the farm UI shows, mid-harvest, while bottling
					var cost: int = int(eco.call("swarm_cost"))
					ck(int(eco.get("money")) >= cost, "%s: money %s covers the swarm cost %d" % [TB, str(eco.get("money")), cost])
					await Flow.shop_open(main, fi, true)
					ck(not upgrade.disabled, "%s: UpgradeButton enabled while bottling" % TB)
					var before: int = int(eco.get("money"))
					await fi.click_ctl(upgrade)
					await _frames(3)
					eq(eco.get("swarm_level"), 1, "%s: Worker Swarm Count level 1 bought mid-harvest" % TB)
					eq(eco.get("money"), before - cost, "%s: money after the purchase" % TB)
					eq((P["BeeCountLabel"] as Label).text, "Bees: %d" % (bees_base + int(_cv("bees_per_swarm_level"))), "%s: BeeCountLabel after the purchase" % TB)
					eq(cen.get("state"), _st(cen, "BOTTLING"), "%s: the purchase did not disturb bottling" % TB)
					await Flow.shop_close(main)
			if rnd == 1 and batch == 1:
				await _shot("r4-8-farm-bottling")
			bottled_total += await _bottle(TB, mid)
			await _wait(float(_cv("cell_fly_seconds")) + _lid_t() + 0.8)
			if int(pile.get("cells")) > 0 or int(cen.get("cells")) > 0:
				# the pile loaded into the empty bucket by itself
				ck(int(cen.get("cells")) > 0, "%s: the pile loaded into the empty bucket" % TB)
				eq(cen.get("lid_open"), false, "%s: the bucket closed after the load (full, or no zoom open)" % TB)
				# spec 0.3.2 item 11: "Spin mode's own crank (main.gd, the reloaded bucket) waits for the lid" -> wait for the lid first
				await Flow.wait_lid_on(self, cen)
				await _frames(3)
				# 0.1.4 item 7: at the second stop the reloaded bucket stays CRANKING by itself (no Spin prompt); the loop's next pass cranks it
				eq(cen.get("state"), _st(cen, "CRANKING"), "%s: the reloaded bucket is CRANKING by itself" % TB)
				ck(not _vis(P["CentrifugeIcon"]), "%s: no Spin prompt for the reloaded bucket" % TB)
				if rnd == 1 and batch == 1:
					ck(int(cen.get("cells")) == mini(CAP_CELLS, TOTAL - in_bucket), "%s: the pile loaded up to the bucket's capacity" % TB)
					await _shot("r4-9-farm-pile-loaded")
			else:
				break
			if batch > 6:
				ck(false, "%s: more than 6 batches, the pile does not drain" % TB)
				break
		eq(bottled_total, JARS, "%s: all %d jars bottled over %d batches (the leftover fractions were carried, none lost)" % [T, JARS, batch])
		eq(cen.get("state"), _st(cen, "EMPTY"), "%s: bucket EMPTY at the end" % T)
		eq(cen.get("lid_open"), true, "%s: bucket open at the end" % T)
		eq(pile.get("cells"), 0, "%s: pile empty at the end" % T)

		# ---- Sell (round 1) / the truck is away (round 2)
		# spin mode ends with the last batch: the camera pans back to the farm view, where the Sell icon shows
		await _until(func() -> bool: return not bool(main.call("at_second_stop")), 4.0)
		await _wait(float(_cv("zoom_seconds")) + 0.5)
		if rnd == 1:
			ck(_vis(P["SellIcon"]), "round 1: the Sell icon floats above the full truck")
			eq(truck.get("loaded_jars"), TRUCK_CAP, "round 1: the truck holds 10 jars")
			_set_cfg("truck_trip_seconds", float(_cv("truck_trip_seconds")) * 2.0)   # CHEAT: still away during round 2
			var m0: int = int(eco.get("money"))
			await fi.click_icon(P["SellIcon"] as Control)
			await _frames(2)
			eq(eco.get("money"), m0 + TRUCK_CAP * PER, "round 1: money credited at the tap")
			# 0.2 item 13: the truck leaves once every jar in flight to its bed has landed
			ck(await _until(func() -> bool: return bool(truck.get("away")), 5.0), "round 1: the truck is away (after the jars in flight landed)")
			await _summary_after_sell("round 1", TRUCK_CAP, PER)
			await _shot("r4-10-farm-truck-away")
		else:
			var back_home: bool = await _until(func() -> bool: return not truck.get("away"), float(_cv("truck_trip_seconds")) + 15.0)
			ck(back_home, "round 2: the truck came back")
			await _frames(4)
			eq(int(truck.get("loaded_jars")) + int(truck.get("crate_jars")), JARS, "round 2: jars conserved: truck + crate = the batch")
			if _vis(P["SellIcon"]):
				var m2: int = int(eco.get("money"))
				var sold: int = int(truck.get("loaded_jars"))
				await fi.click_icon(P["SellIcon"] as Control)
				await _frames(2)
				ck(int(eco.get("money")) > m2, "round 2: Sell credited money at the tap")
				await _summary_after_sell("round 2", sold, PER)

	# ---- 0.1.3c (written from game/specs/0.1.3-next-revision.md before the code): both camera stops in the loop, through real input.
	# A full hive, the fork: first stop (zoom_size); the first frames scraped until the bucket is full: the camera pans over camera_pan_seconds
	# to pan_zoom_size (second stop); Back returns to the farm view; Spin, crank, bottle and the pile all still work.
	print("=== two camera stops ===")
	var camc: Camera3D = root.get_viewport().get_camera_3d()
	var size_farm: float = camc.size
	hive.call("fill_now")
	_set_cfg("base_seconds_per_jar", 1.0e9)
	tr["raised"] = []
	tr["lid"] = []
	await _frames(4)
	eq(cen.get("state"), _st(cen, "EMPTY"), "stops: the bucket is EMPTY before the extra batch")
	ck(await _open_zoom("stops"), "stops: first stop open")
	near(camc.size, float(_cv("zoom_size")), "stops: the first stop is at zoom_size", 0.05)
	var n_fill: int = NF   # 0.1.3c: finish, then pan: every frame is uncapped (extras go to the pile) before the camera pans
	for k in n_fill:
		var fk: int = await _scrape_risen()
		if k < n_fill - 1:
			ck(await _next_frame(fk), "stops: frame %d done, the next rose" % fk)
	# 0.2 item 9: a full bucket does not pan; the zoom ends on the farm view after the last frame and only Spin goes to the second stop
	await _zoom_out_wait()
	await _wait(float(_cv("camera_pan_seconds")) + 0.5)
	eq(cen.get("cells"), CAP_CELLS, "stops: the bucket holds its capacity")
	ck(not bool(main.call("at_second_stop")), "stops: the full bucket did not pan to the second stop (0.2 item 9)")
	near(camc.size, size_farm, "stops: the zoom ended on the farm view", 0.05)
	ck(_vis(P["MoneyLabel"]), "stops: the farm UI is back")
	eq(cen.get("state"), _st(cen, "FULL"), "stops: FULL after Back (Spin waits)")
	await _crank("stops", false)
	var stops_jars: int = await _bottle("stops", Callable())
	eq(stops_jars, int(CAP_CELLS * int(_cv("frame_jars")) / CPF), "stops: the full bucket bottled its jars")
	await _wait(float(_cv("cell_fly_seconds")) + _lid_t() + 0.8)

	# ---- Show UI bounds (Dev action): screenshot with the outlines on, then off
	var bounds: Button = null
	for b in main.get_tree().root.find_children("*", "Button", true, false):
		if (b as Button).text.to_lower().contains("bounds"):
			bounds = b as Button
	ck(bounds != null, "the dev panel has a Show UI bounds button")
	if bounds != null:
		bounds.pressed.emit()
		await _shot("r4-11-show-ui-bounds")
		bounds.pressed.emit()

	for k in _cfg_saved:
		root.get_node("Economy").get("config").set(k, _cfg_saved[k])
	print("---- %d checks, %d failed" % [checks, fails])
	print("COMPLETED")
	quit(1 if fails > 0 else 0)


## Lid time of 0.1.1: the lift then the fall (lid_lift_seconds is absent from older configs: counts as 0).
func _lid_t() -> float:
	var lift: Variant = root.get_node("Economy").get("config").get("lid_lift_seconds")
	return float(_cv("lid_drop_seconds")) + (float(lift) if lift != null else 0.0)
