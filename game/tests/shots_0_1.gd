# Quinn: the 0.1 Harvest shot set (game/CONTEXT.md Process 6: one screenshot per state in the spec's state table plus every new view),
# WINDOWED at 720 x 1280, into game/reports/0.1-shots/ with the prefix "q-" (Bob's own shots there are not touched).
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/shots_0_1.gd
# The zoom, the scrape and the Back are real input (tests/farm_input.gd); the states in between are set up with the same Dev-style cheats as
# play_loop.gd (fill_now, add_cells, begin_crank and turns through tap()). The cell in flight is shot in slow motion (Engine.time_scale)
# so three frames fall at 25 %, 50 % and 75 % of a flight, with the bucket empty so the flying cells stand out.
# Exit code 0 only if the last line "COMPLETED" printed; the images are for the eye, no pass/fail beyond "each file was written".
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const OUT := "res://reports/0.1-shots/"

var fi: RefCounted
var main: Node
var P: Dictionary = {}
var risen: int = -1
var written: int = 0


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < sec * 1000.0:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err: int = img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("shot ", name, " ", img.get_size(), " err=", err)
	if err == OK:
		written += 1


func _cfg() -> Object:
	return root.get_node("Economy").get("config")


func _settle() -> float:
	var c: Object = _cfg()
	return float(c.get("zoom_seconds")) + _lid_t(c) + float(c.get("slide_seconds")) + 0.6


func _open_zoom() -> void:
	await fi.click_icon(P["ForkIcon"] as Control)
	var t0: int = Time.get_ticks_msec()
	while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	await _wait(_settle())


func _scrape_frame() -> void:
	var f: int = risen
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	for r in fi.rows(hc, cam):
		if risen != f or FarmInput.capped(P["Hive"], f) == 0:
			break
		await fi.drag_row(r)
		await _wait(0.25)
	await _wait(float(_cfg().get("slide_seconds")) * 2.0 + 0.7)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	fi = FarmInput.new(self)
	print("Dev config reset: stale file ", "FOUND and removed" if FarmInput.reset_dev_config() else "not present")
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	for nm in ["Hive", "Centrifuge", "Pile", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon"]:
		P[nm] = main.find_child(nm, true, false)
	var hive: Node = P["Hive"]
	var cen: Node = P["Centrifuge"]
	var pile: Node = P["Pile"]
	var cfg: Object = _cfg()
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	var cpf: int = int(cfg.get("grid_cols")) * int(cfg.get("grid_rows"))
	await _shot("q-01-farm-empty-start")
	hive.call("fill_now")
	cfg.set("base_seconds_per_jar", 1.0e9)
	cfg.set("bottling_seconds_per_jar", 4.0)
	await _frames(4)
	await _shot("q-02-farm-full-hive-fork-EMPTY")
	await _open_zoom()
	await _shot("q-03-zoom-risen-frame-hive-lid-off")
	# the flight, in slow motion: row 0 scraped at once, a shot at 25 %, 50 % and 75 % of the 0.5 s flight (it starts 0.18 s after the scrape)
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var rws: Array = fi.rows(hc, cam)
	Engine.time_scale = 0.1
	var t0: int = Time.get_ticks_msec()
	await fi.drag_row(rws[0])
	var fly: float = float(cfg.get("cell_fly_seconds"))
	for frac in [0.25, 0.5, 0.75]:
		var target_ms: float = (0.18 + fly * float(frac)) / 0.1 * 1000.0
		while float(Time.get_ticks_msec() - t0) < target_ms:
			await process_frame
		await _shot("q-04-zoom-cell-in-flight-%d" % int(round(float(frac) * 100.0)))
	Engine.time_scale = 1.0
	await _wait(fly + 0.5)
	# finish frame 1 (35 cells in the bucket: LOADING, lid off), shot of the heap; frame 2 half scraped
	await _scrape_frame()
	await _shot("q-05-zoom-bucket-LOADING-lid-off-frame-2-risen")
	await fi.click_ctl(main.find_child("BackButton", true, false) as Control)
	await _wait(_settle() + 1.0)
	await _shot("q-06-farm-FULL-lid-on-spin-icon-and-fork")
	await fi.click_icon(P["CentrifugeIcon"] as Control)
	await _frames(3)
	await _shot("q-07-farm-CRANKING-start-fork-kept")
	var need: int = int(ceil(float(cpf * int(cfg.get("frame_jars"))) / float(cpf) * float(cfg.get("taps_per_jar"))))
	var gap: int = int((1.0 / float(cfg.get("max_tap_rate")) + 0.03) * 1000.0)
	var spot: Vector2 = fi.free_spot(main)
	for k in need / 2:
		await fi.click_at(spot)
		await _wait(float(gap) / 1000.0)
	await _shot("q-08-farm-CRANKING-half-combs-melting")
	# cells pile up while cranking: the zoom again (fork kept), one frame to the pile
	tr_clear()
	await _open_zoom()
	await _scrape_frame()
	await _shot("q-09-zoom-while-CRANKING-cells-to-the-pile")
	await fi.click_ctl(main.find_child("BackButton", true, false) as Control)
	await _wait(_settle() + 1.0)
	await _shot("q-10-farm-CRANKING-pile-beside-the-centrifuge")
	var state_cranking: int = int(cen.get("state"))
	while int(cen.get("state")) == state_cranking:
		await fi.click_at(spot)
		await _wait(float(gap) / 1000.0)
	await _frames(4)
	await _shot("q-11-farm-DONE-bottling-starts-by-itself")
	await _wait(float(cfg.get("bottling_seconds_per_jar")) * 1.5)
	await _shot("q-12-farm-BOTTLING-jar-filling-honey-level-dropping")
	var bottling: int = int(cen.get("state"))
	var t1: int = Time.get_ticks_msec()
	while int(cen.get("state")) == bottling and Time.get_ticks_msec() - t1 < 40000:
		await process_frame
	await _wait(float(cfg.get("cell_fly_seconds")) + _lid_t(cfg) + 1.0)
	await _shot("q-13-farm-pile-loaded-into-bucket-summary")
	var ok: Node = main.find_child("SummaryOkButton", true, false)
	if ok != null and (ok as CanvasItem).is_visible_in_tree():
		await fi.click_ctl(ok as Control)
		await _frames(4)
	await _shot("q-14-farm-after-summary-FULL-or-sell")
	if (P["SellIcon"] as CanvasItem).is_visible_in_tree():
		await fi.click_icon(P["SellIcon"] as Control)
		await _wait(2.0)
		await _shot("q-15-farm-truck-away")
	var bounds: Button = null
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text.to_lower().contains("bounds"):
			bounds = b as Button
	if bounds != null:
		bounds.pressed.emit()
		await _shot("q-16-show-ui-bounds")
		bounds.pressed.emit()
	print("---- %d shots written" % written)
	print("COMPLETED")
	quit(0 if written >= 16 else 1)


func tr_clear() -> void:
	risen = -1


## Lid time of 0.1.1: the lift then the fall (lid_lift_seconds is absent from older configs: counts as 0).
func _lid_t(c: Object) -> float:
	var lift: Variant = c.get("lid_lift_seconds")
	return float(c.get("lid_drop_seconds")) + (float(lift) if lift != null else 0.0)
