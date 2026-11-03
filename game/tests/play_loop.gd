# Quinn: Prototype 0 integration test, windowed. Drives the real scenes through the node names in the spec.
#   Godot --path game --script res://tests/play_loop.gd
# Exit code 0 = all pass, 1 = any failure. Saves screenshots and FPS to game/reports/2026-11-03-prototype-0/.
extends SceneTree

const SHOT_DIR := "res://reports/2026-11-03-prototype-0/"

var main: Node
var fails: int = 0
var checks: int = 0
var fps_farm: Dictionary = {}
var fps_stage1: Dictionary = {}
var fps_stage2: Dictionary = {}
var fps_summary: Dictionary = {}
var _batch_signal: int = -1


func _initialize() -> void:
	_run()


func ck(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("PASS  ", what)
	else:
		fails += 1
		print("FAIL  ", what)


func eq(actual: Variant, expected: Variant, what: String) -> void:
	ck(actual == expected, "%s (expected %s, got %s)" % [what, str(expected), str(actual)])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(SHOT_DIR + name + ".png")
	var err: int = img.save_png(path)
	print("screenshot ", name, " ", img.get_size(), " err=", err)


func _measure(label: String, seconds: float) -> Dictionary:
	var samples: Array[float] = []
	var start: int = Time.get_ticks_msec()
	var frames_start: int = Engine.get_process_frames()
	await _frames(90)   # warm up (first samples after a scene load are not representative)
	var t0: int = Time.get_ticks_msec()
	var f0: int = Engine.get_process_frames()
	while Time.get_ticks_msec() - t0 < int(seconds * 1000.0):
		await _frames(15)
		samples.append(Engine.get_frames_per_second())
	var dt: float = float(Time.get_ticks_msec() - t0) / 1000.0
	var avg: float = float(Engine.get_process_frames() - f0) / dt
	var mn: float = samples.min()
	var res := {"avg": avg, "min_sample": mn, "seconds": dt}
	print("FPS ", label, " avg=%.1f min_sample=%.1f over %.1fs" % [avg, mn, dt])
	return res


func _n(name: String) -> Node:
	var n: Node = main.find_child(name, true, false)
	if n == null:
		print("FAIL  node missing: ", name)
		fails += 1
	return n


func _vis(n: Node) -> bool:
	return n != null and n.is_visible_in_tree()


func _drag_row(hc: Honeycomb, cam: Camera3D, row: int) -> void:
	# Real mouse drag across one row of cells, through the viewport input path (raycast code in honeycomb.gd).
	var cols: int = hc.config.grid_cols
	# unproject_position gives viewport pixels (720x1280); push_input expects window pixels, like a real
	# mouse (the window is 405x720 with canvas_items stretch), so scale between the two.
	var to_window: Vector2 = Vector2(root.size) / root.get_visible_rect().size
	var first: Vector2 = cam.unproject_position(hc.get_node("Cell_%d" % (row * cols)).global_position) * to_window
	var last: Vector2 = cam.unproject_position(hc.get_node("Cell_%d" % (row * cols + cols - 1)).global_position) * to_window
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = first
	root.push_input(down)
	await process_frame
	for s in 1 + 12:
		var mv := InputEventMouseMotion.new()
		mv.position = first.lerp(last, float(s) / 12.0)
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(mv)
		await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = last
	root.push_input(up)
	await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var eco: Node = root.get_node("Economy")
	eco.reset()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	print("window size ", DisplayServer.window_get_size(), " viewport ", root.get_visible_rect().size)

	var hive: Hive = _n("Hive") as Hive
	var harvest_btn: Button = _n("HarvestButton") as Button
	var sell_btn: Button = _n("SellButton") as Button
	var upgrade_btn: Button = _n("UpgradeButton") as Button
	var money_label: Label = _n("MoneyLabel") as Label
	var jars_label: Label = _n("JarsLabel") as Label
	var fill_bar: ProgressBar = _n("FillBar") as ProgressBar
	var fill_label: Label = _n("FillLabel") as Label
	var paused_label: Label = _n("PausedLabel") as Label
	var level_label: Label = _n("LevelLabel") as Label
	var farm_world: Node3D = _n("FarmWorld") as Node3D
	var bees: MultiMeshInstance3D = _n("Bees") as MultiMeshInstance3D
	ck(hive != null and harvest_btn != null and sell_btn != null and upgrade_btn != null, "farm nodes found")
	ck(bees != null and bees.multimesh != null and bees.multimesh.instance_count > 0, "bees MultiMesh built")
	ck(get_nodes_in_group("flower_patch").size() >= 2, "flower patches in group flower_patch")
	ck(get_nodes_in_group("bee_home").size() == 1, "hive in group bee_home")
	ck(not harvest_btn.visible, "HarvestButton hidden at start")
	ck(not paused_label.visible, "PausedLabel hidden at start")
	ck(sell_btn.disabled, "SellButton disabled with 0 jars")
	ck(upgrade_btn.disabled, "UpgradeButton disabled with $0")
	eq(money_label.text, "$0", "MoneyLabel at start")
	eq(fill_label.text.begins_with("Hive: "), true, "FillLabel format: " + fill_label.text)

	# ---- farm FPS (fresh farm, bees flying, hive filling in real time)
	fps_farm = await _measure("farm", 4.0)
	ck(hive.storage > 0.0, "hive filled in real time (storage %.2f)" % hive.storage)
	ck(fill_bar.value > 0.0, "FillBar value follows storage (%.2f)" % fill_bar.value)

	# =============== ROUND 1 ===============
	print("=== round 1 (tap mode) ===")
	# advance time until full (real process also ticks)
	hive.advance(60.0, 1.0)
	await _frames(3)
	ck(hive.is_full(), "round 1: hive full")
	ck(harvest_btn.visible, "round 1: HarvestButton visible when full")
	eq(fill_label.text, "Hive: 10 / 10", "round 1: FillLabel")
	await _shot("1-farm-hive-full")
	harvest_btn.pressed.emit()
	await _frames(5)
	var hc: Honeycomb = _n("Honeycomb") as Honeycomb
	var cen: Centrifuge = _n("Centrifuge") as Centrifuge
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	ck(hc != null and cen != null, "round 1: harvest scene instanced")
	ck(not farm_world.visible, "round 1: farm world hidden")
	ck(not _vis(harvest_btn), "round 1: farm UI hidden")
	ck(cam != null and cam.get_parent().name == "Harvest", "round 1: harvest camera is current")
	ck(_vis(_n("Stage1Panel")), "round 1: Stage1Panel visible")
	ck(not _vis(_n("Stage2Panel")), "round 1: Stage2Panel hidden")
	ck(hive.storage < 10.0, "round 1: take_frame removed the frame from the hive (storage %.2f)" % hive.storage)
	eq(hc.cell_count(), 35, "round 1: 35 cells")
	for i in 35:
		if hc.get_state(i) != 0:
			ck(false, "round 1: cell %d starts Capped" % i)
			break
	# real drag across row 0 (raycast path)
	await _drag_row(hc, cam, 0)
	var row0_ok: bool = true
	for c in 7:
		if hc.get_state(c) != 1:
			row0_ok = false
	ck(row0_ok, "round 1: mouse drag across row 0 uncaps its 7 cells via raycast")
	var uncapped_n: int = 0
	for i in 35:
		if hc.get_state(i) == 1:
			uncapped_n += 1
	print("info: cells uncapped by the single drag: ", uncapped_n)
	ck(uncapped_n >= 7 and uncapped_n < 35, "round 1: drag did not uncap unrelated rows (n=%d)" % uncapped_n)
	ck(not _vis(_n("Stage2Panel")), "round 1: stage 2 not open until all uncapped")
	# FPS in stage 1 with part-uncapped frame
	fps_stage1 = await _measure("harvest stage 1", 3.0)
	await _shot("2-stage1-uncapping")
	# uncap the rest
	for i in 35:
		hc.uncap_at(i)
	await _frames(5)
	ck(hc.all_uncapped(), "round 1: all cells Uncapped")
	ck(_vis(_n("Stage2Panel")), "round 1: Stage2Panel opens")
	ck(_vis(cen) and not _vis(hc), "round 1: centrifuge shown, honeycomb hidden")
	eq((_n("JarCounterLabel") as Label).text, "Jars: 0 / 10", "round 1: jar counter")
	var crank: Button = _n("CrankButton") as Button
	_batch_signal = -1
	cen.batch_done.connect(func(j: int) -> void: _batch_signal = j)
	for i in 10:
		crank.button_down.emit()
		crank.button_up.emit()
		await process_frame
	eq(cen.jars_filled, 5, "round 1: 10 taps = 5 jars")
	eq((_n("JarCounterLabel") as Label).text, "Jars: 5 / 10", "round 1: jar counter mid-crank")
	ck(cen.spin_speed > 0.0, "round 1: barrel spinning after taps")
	fps_stage2 = await _measure("harvest stage 2 (idle after taps)", 2.0)
	await _shot("3-stage2-centrifuge")
	for i in 10:
		crank.button_down.emit()
		crank.button_up.emit()
		await process_frame
	eq(_batch_signal, 10, "round 1: batch_done(10) after 20 taps")
	await _frames(3)
	eq(eco.jars, 10, "round 1: Economy.jars = 10")
	for i in 35:
		if hc.get_state(i) != 2:
			ck(false, "round 1: cell %d Extracted" % i)
			break
	ck(hc.get_state(34) == 2 and hc.get_state(0) == 2, "round 1: cells Extracted (2)")
	ck(_vis(_n("SummaryModal")), "round 1: SummaryModal visible")
	ck((_n("SummaryJarsLabel") as Label).text.contains("10"), "round 1: summary jars: " + (_n("SummaryJarsLabel") as Label).text)
	eq((_n("SummaryValueLabel") as Label).text, "Value per jar: $3", "round 1: summary value")
	eq((_n("SummaryTotalLabel") as Label).text, "Batch total: $30", "round 1: summary total")
	fps_summary = await _measure("harvest summary", 2.0)
	await _shot("4-summary")
	(_n("ContinueButton") as Button).pressed.emit()
	await _frames(5)
	ck(farm_world.visible, "round 1: farm visible after Continue")
	ck(harvest_btn.is_inside_tree() and _vis(sell_btn), "round 1: farm UI visible after Continue")
	ck(root.get_viewport().get_camera_3d().get_parent() == main, "round 1: farm camera current again")
	ck(main.find_child("Harvest", true, false) == null or main.find_child("Harvest", true, false).is_queued_for_deletion(), "round 1: harvest scene freed")
	await _frames(2)
	eq(main.find_child("Honeycomb", true, false), null, "round 1: Honeycomb gone after free")
	ck(not sell_btn.disabled, "round 1: SellButton enabled with jars")
	print("sell button text: ", sell_btn.text)
	sell_btn.pressed.emit()
	await _frames(2)
	eq(eco.money, 30, "round 1: sold 10 jars for $30")
	eq(eco.jars, 0, "round 1: jars 0 after sell")
	eq(money_label.text, "$30", "round 1: MoneyLabel")
	eq(jars_label.text, "Jars: 0", "round 1: JarsLabel")
	ck(sell_btn.disabled, "round 1: SellButton disabled after sell")
	ck(not upgrade_btn.disabled, "round 1: UpgradeButton enabled at $30")
	print("upgrade button text: ", upgrade_btn.text, " | level label: ", level_label.text)
	upgrade_btn.pressed.emit()
	await _frames(2)
	eq(eco.swarm_level, 1, "round 1: Worker Swarm Count level 1")
	eq(eco.money, 5, "round 1: money $5 after $25 upgrade")
	eq(money_label.text, "$5", "round 1: MoneyLabel after purchase")
	ck(level_label.text.contains("1"), "round 1: LevelLabel shows level 1: " + level_label.text)
	ck(upgrade_btn.disabled, "round 1: UpgradeButton disabled ($5 < $30)")
	print("upgrade button text after: ", upgrade_btn.text)
	near_fill(eco)

	# =============== ROUND 2 ===============
	print("=== round 2 (No-Rapid-Tap hold mode) ===")
	hive.storage = 0.0
	hive.overflow = 0.0
	hive._full_announced = false
	hive.storage_changed.emit(0.0, 0.0)
	await _frames(2)
	ck(not harvest_btn.visible, "round 2: HarvestButton hidden again after harvest")
	# level 1 = 1.15x: full needs 52.17 s
	hive.advance(50.0, eco.fill_multiplier())
	ck(not hive.is_full(), "round 2: not full after 50 s at level 1 (%.2f)" % hive.storage)
	hive.advance(3.0, eco.fill_multiplier())
	await _frames(3)
	ck(hive.is_full(), "round 2: full after 53 s at level 1 (faster than 60 s)")
	ck(harvest_btn.visible, "round 2: HarvestButton visible")
	# pause label: fill overflow
	hive.advance(200.0, eco.fill_multiplier())
	await _frames(3)
	ck(hive.is_paused(), "round 2: paused with overflow full")
	ck(paused_label.visible, "round 2: PausedLabel visible when paused")
	await _shot("5-farm-paused")
	harvest_btn.pressed.emit()
	await _frames(5)
	hc = _n("Honeycomb") as Honeycomb
	cen = _n("Centrifuge") as Centrifuge
	cam = root.get_viewport().get_camera_3d()
	ck(hive.overflow < 0.5, "round 2: overflow consumed by take_frame (%.3f, only a few frames of new production)" % hive.overflow)
	ck(hive.is_full(), "round 2: full overflow refilled storage, hive immediately full again")
	for i in 35:
		if hc.get_state(i) != 0:
			ck(false, "round 2: cell %d reset to Capped on next harvest (state %d)" % [i, hc.get_state(i)])
			break
	ck(hc.get_state(0) == 0 and hc.get_state(34) == 0, "round 2: cells Capped again")
	for i in 35:
		hc.uncap_at(i)
	await _frames(5)
	ck(_vis(_n("Stage2Panel")), "round 2: Stage2Panel opens")
	var check: CheckButton = _n("NoRapidTapCheck") as CheckButton
	check.button_pressed = true
	await _frames(2)
	ck(cen.hold_mode and eco.no_rapid_tap_mode, "round 2: NoRapidTapCheck switches centrifuge to hold mode")
	crank = _n("CrankButton") as Button
	crank.button_down.emit()   # tap in hold mode starts holding
	var t0: int = Time.get_ticks_msec()
	_batch_signal = -1
	cen.batch_done.connect(func(j: int) -> void: _batch_signal = j)
	while cen.running and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	var held: float = float(Time.get_ticks_msec() - t0) / 1000.0
	crank.button_up.emit()
	print("hold mode batch took %.2f s" % held)
	ck(held > 4.5 and held < 5.7, "round 2: hold mode takes about 5 s (%.2f)" % held)
	eq(_batch_signal, 10, "round 2: batch_done(10) in hold mode")
	await _frames(3)
	eq(eco.jars, 10, "round 2: jars 10")
	ck(hc.get_state(0) == 2 and hc.get_state(34) == 2, "round 2: cells Extracted")
	ck(_vis(_n("SummaryModal")), "round 2: summary visible")
	eq((_n("SummaryTotalLabel") as Label).text, "Batch total: $30", "round 2: batch total")
	(_n("ContinueButton") as Button).pressed.emit()
	await _frames(5)
	ck(farm_world.visible, "round 2: back on the farm")
	sell_btn.pressed.emit()
	await _frames(2)
	eq(eco.money, 35, "round 2: money $35 after selling")
	ck(not upgrade_btn.disabled, "round 2: UpgradeButton enabled at $35 (cost $30)")
	upgrade_btn.pressed.emit()
	await _frames(2)
	eq(eco.swarm_level, 2, "round 2: level 2")
	eq(eco.money, 5, "round 2: $35 - $30 = $5")
	print("upgrade button text after 2nd buy: ", upgrade_btn.text)

	# ---- results
	var out: String = "# raw play_loop output\n"
	out += "farm avg=%.1f min_sample=%.1f\n" % [fps_farm["avg"], fps_farm["min_sample"]]
	out += "stage1 avg=%.1f min_sample=%.1f\n" % [fps_stage1["avg"], fps_stage1["min_sample"]]
	out += "stage2 avg=%.1f min_sample=%.1f\n" % [fps_stage2["avg"], fps_stage2["min_sample"]]
	out += "summary avg=%.1f min_sample=%.1f\n" % [fps_summary["avg"], fps_summary["min_sample"]]
	var f := FileAccess.open(ProjectSettings.globalize_path(SHOT_DIR + "fps.txt"), FileAccess.WRITE)
	f.store_string(out)
	f.close()
	print("---- %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func near_fill(eco: Node) -> void:
	ck(absf(eco.fill_multiplier() - 1.15) < 0.0001, "round 1: fill multiplier 1.15 at level 1")
