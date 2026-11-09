# Bob: UI / layout comparison shots for the Design Votes page. Same script, same file names, in every version. Usage (windowed, 720 x 1280):
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/ui_compare_shots.gd -- <label>
# Plays the real game from a fresh state with real input (tests/farm_input.gd): the shipped default config (no user://dev_config.tres overlay;
# the file is left alone), no input recording (user://recordings is not written). Saves 720 x 1280 PNGs 1-farm-start .. 9-dev-speed-x5 and
# shots.json (name -> caption, or "missing: reason") to game/reports/ui-compare/<label>/.
# A label ending in "B" in the centrifuge-by-crate mock copies ZoomFramingB over ZoomFraming (as tests/ab_shots.gd does); other versions ignore that.
# One deliberate tweak: truck_capacity_jars is set to the 4 jars one bucket gives, so shot 8 (Sell) needs one bucket, not three.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const WORKING: int = 3          # main.gd Zoom.WORKING
const FULL: int = 2             # Centrifuge.State.FULL
const CRANKING: int = 3
const BOTTLING: int = 5

# The moments, in play order: file name, default caption, step function (a method below). A new screen, phase or menu = one entry here
# plus its step function; nothing else changes. The 9 names are fixed so versions line up on the Design Votes page.
const MOMENTS: Array = [
	{"name": "1-farm-start", "caption": "the farm at launch (fresh state, shipped defaults)", "step": "_step_farm_start"},
	{"name": "2-farm-hive-full", "caption": "hive full, Harvest (fork) button showing", "step": "_step_hive_full"},
	{"name": "3-zoom-hive", "caption": "first zoom on the hive, rack risen and settled, Back visible", "step": "_step_zoom_hive"},
	{"name": "4-zoom-scraping", "caption": "rack risen, a row scraped, cells flying to the bucket (slowed 0.1x for the shot)", "step": "_step_zoom_scraping"},
	{"name": "5-bucket-full", "caption": "bucket full during the zoom", "step": "_step_bucket_full"},
	{"name": "6-centrifuge-stop", "caption": "the centrifuge stop, Spin visible", "step": "_step_centrifuge_stop"},
	{"name": "6b-farm-spin", "caption": "Back from the centrifuge stop with a full bucket: the farm view, Spin visible", "step": "_step_farm_spin"},
	{"name": "7-bottling", "caption": "bottling: jars filling at the spigot (truck capacity set to 4 for shot 8)", "step": "_step_bottling"},
	{"name": "8-sell", "caption": "crate and truck, Sell visible", "step": "_step_sell"},
	{"name": "9-dev-speed-x5", "caption": "Dev mode open, speed x5 chosen, tag at the top-left", "step": "_step_dev_speed"},
]

var fi: RefCounted
var main: Node
var cen: Node
var hive: Node
var cfg: Object
var has_second_stop: bool = false
var label: String = "unlabelled"
var out_dir: String = ""
var manifest: Dictionary = {}
var risen: int = -1
var row_i: int = 0


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Waits `sec` of game time (real time x Engine.time_scale).
func _gwait(sec: float) -> void:
	var left: float = sec
	var last: int = Time.get_ticks_msec()
	while left > 0.0:
		await process_frame
		var now: int = Time.get_ticks_msec()
		left -= float(now - last) / 1000.0 * Engine.time_scale
		last = now


## Waits until `cond` is true; gives up after `timeout` real seconds. Returns whether it became true.
func _until(cond: Callable, timeout: float) -> bool:
	var t0: int = Time.get_ticks_msec()
	while not cond.call():
		if float(Time.get_ticks_msec() - t0) > timeout * 1000.0:
			return false
		await process_frame
	return true


func _cfg() -> Object:
	return GameConfig.live()


func _visible(node_name: String) -> bool:
	var n: Node = main.find_child(node_name, true, false)
	return n != null and (n as CanvasItem).is_visible_in_tree()


func _shot(name: String, caption: String, expect_visible: Array = []) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var warn: PackedStringArray = []
	for n in expect_visible:
		if not _visible(String(n)):
			warn.append(String(n) + " not visible")
	if img.get_size() != Vector2i(720, 1280):
		warn.append("image is %s, not 720x1280" % str(img.get_size()))
	var err: int = img.save_png(out_dir + name + ".png")
	manifest[name] = caption + ((" [CHECK: " + ", ".join(warn) + "]") if warn.size() > 0 else "")
	print("shot ", name, " ", img.get_size(), " err=", err, " ", warn)


func _missing(name: String, reason: String) -> void:
	manifest[name] = "missing: " + reason
	print("missing ", name, ": ", reason)


func _state() -> int:
	return int(cen.get("state"))


func _zoom() -> int:
	return int(main.get("zoom"))


func _finish(code: int) -> void:
	Engine.time_scale = 1.0
	var f := FileAccess.open(out_dir + "shots.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("COMPLETED" if code == 0 else "ABORTED")
	quit(code)


## Drags the rows of the risen frame one by one (as a player does) until the bucket is full, the zoom ends or time runs out.
func _scrape_until_full() -> void:
	var hc: Node = main.find_child("Honeycomb", true, false)
	var t0: int = Time.get_ticks_msec()
	while _state() != FULL and _zoom() != 0 and Time.get_ticks_msec() - t0 < 60000:
		if _zoom() != WORKING:
			await process_frame
			continue
		var cam: Camera3D = root.get_viewport().get_camera_3d()
		var rws: Array = fi.rows(hc, cam)
		if row_i >= rws.size():
			await _frames(5)   # the frame is finishing: it sinks, the next one rises
			continue
		await fi.drag_row(rws[row_i])
		row_i += 1
		await _gwait(0.3)


## Design Votes options (orchestrator, 2026-11-07): after the label, `key=value` sets a config value and `Node.prop=value`
## (or `Node.prop*=value`, a multiply) sets a property of the first node of that name: a mock of a scene change, for a vote only.
## Values are Godot literals (str_to_var): 1.35, -40, Vector3(1.7, 1, 1.7). Written into shots.json as "overrides".
func _apply_overrides(args: PackedStringArray, nodes: bool) -> void:
	var done: Array[String] = []
	for i in range(1, args.size()):
		var a: String = args[i]
		var mul: bool = a.contains("*=")
		var kv: PackedStringArray = a.split("*=" if mul else "=", false, 1)
		if kv.size() != 2:
			continue
		var val: Variant = str_to_var(kv[1])
		if kv[0].contains(".") != nodes:
			continue
		if nodes:
			var parts: PackedStringArray = kv[0].split(".", false, 1)
			var n: Node = main if parts[0] == main.name else main.find_child(parts[0], true, false)
			if n == null:
				push_warning("override: no node " + parts[0])
				continue
			n.set(parts[1], n.get(parts[1]) * val if mul else val)
		else:
			cfg.set(kv[0], cfg.get(kv[0]) * val if mul else val)
		done.append(a)
	if not done.is_empty():
		manifest["overrides"] = (str(manifest.get("overrides", "")) + ", " if manifest.has("overrides") else "") + ", ".join(done)
		print("overrides: ", done)


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		label = args[0]
	out_dir = ProjectSettings.globalize_path("res://reports/ui-compare/" + label + "/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	fi = FarmInput.new(self)
	# shipped defaults without touching the player's user://dev_config.tres: lay default_config.tres over the live config
	GameConfig.apply_from(GameConfig.live(), GameConfig.fresh_default())
	cfg = _cfg()
	if "record_from_launch" in cfg:
		cfg.set("record_from_launch", false)   # the input recorder would write user://recordings
	root.get_node("Economy").call("reset")
	_apply_overrides(args, false)   # config values first: some are read when the scene is built (grid_cols)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	_apply_overrides(args, true)
	cen = main.find_child("Centrifuge", true, false)
	hive = main.find_child("Hive", true, false)
	var zfb: Node3D = main.find_child("ZoomFramingB", true, false) as Node3D
	if zfb != null:   # the centrifuge-by-crate mock: its zoom framing comes from the markers, as in ab_shots.gd
		cfg.set("zoom_size", 0.0)
		if label.ends_with("B"):
			var zf: Node3D = main.find_child("ZoomFraming", true, false) as Node3D
			zf.global_transform = zfb.global_transform
			zf.set_meta("zoom_size", zfb.get_meta("zoom_size"))
	hive.connect("frame_raised", func(i: Variant) -> void:
		risen = int(i)
		row_i = 0)
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	has_second_stop = main.has_method("at_second_stop")
	var aborted: String = ""
	for m in MOMENTS:
		var name: String = m["name"]
		if aborted != "":
			_missing(name, aborted)
			continue
		var r: Dictionary = await call(m["step"])
		if r.has("missing"):
			_missing(name, String(r["missing"]))
			if r.get("abort", false):
				aborted = "an earlier step failed (%s)" % name
			continue
		await _shot(name, String(r.get("caption", m["caption"])), r.get("expect", []))
	_finish(1 if aborted != "" else 0)


# --- the steps: each drives the game to its moment with real input and returns {} (the runner takes the shot), or
# {"missing": reason[, "abort": true]}, optionally {"caption": ..., "expect": [node names that must be visible]} ---

func _step_farm_start() -> Dictionary:
	await _gwait(1.0)
	return {}


func _step_hive_full() -> Dictionary:
	hive.call("fill_now")
	await _until(func() -> bool: return _visible("ForkIcon"), 5.0)
	await _gwait(0.8)
	return {"expect": ["ForkIcon"]}


func _step_zoom_hive() -> Dictionary:
	await fi.click_icon(main.find_child("ForkIcon", true, false) as Control)
	if not await _until(func() -> bool: return _zoom() == WORKING, 15.0):
		return {"missing": "the zoom never reached the uncapping stage", "abort": true}
	await _gwait(0.5)
	return {"expect": ["BackButton"]}


## One row, slowed to 0.1x so the cells are caught in flight to the bucket (as ab_shots.gd does).
func _step_zoom_scraping() -> Dictionary:
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var rws: Array = fi.rows(hc, cam)
	Engine.time_scale = 0.1
	var t1: int = Time.get_ticks_msec()
	await fi.drag_row(rws[0])
	row_i = 1
	var fly: float = float(cfg.get("cell_fly_seconds"))
	var target_ms: float = (0.18 + fly * 0.5) / 0.1 * 1000.0
	while float(Time.get_ticks_msec() - t1) < target_ms:
		await process_frame
	await _frames(3)   # the runner's own _shot waits too; the slowed cells stay in flight
	return {"expect": ["BackButton"]}


func _step_bucket_full() -> Dictionary:
	Engine.time_scale = 1.0
	await _scrape_until_full()
	if _state() != FULL:
		return {"missing": "the bucket never became full", "abort": true}
	await _gwait(1.5)
	var spin_in_zoom: bool = _visible("CentrifugeIcon")
	return {"caption": "bucket full during the zoom, as the player sees it (Spin %s in the zoom)" % ("shows" if spin_in_zoom else "does not show"), "expect": ["BackButton"]}


func _step_centrifuge_stop() -> Dictionary:
	var back: Control = main.find_child("BackButton", true, false) as Control
	await fi.click_ctl(back)
	await _until(func() -> bool: return _zoom() == 0, 15.0)
	await _gwait(1.0)
	var cap6: String = "the second camera stop after Back (centrifuge, crate, truck), Spin visible" if has_second_stop else "no second stop in this version: the farm view after Back, Spin visible"
	return {"caption": cap6, "expect": ["CentrifugeIcon"]}


## 0.1.4 item 22: Spin in the farm view (full bucket, Back from the second stop). Step 7's Spin tap pans back to the second stop.
func _step_farm_spin() -> Dictionary:
	if not has_second_stop:
		return {"missing": "no second stop in this version: shot 6 is already the farm view"}
	await fi.click_ctl(main.find_child("BackButton", true, false) as Control)
	await _until(func() -> bool: return not bool(main.call("at_second_stop")), 5.0)
	await _gwait(float(cfg.get("camera_pan_seconds")) + 1.0)
	if not _visible("CentrifugeIcon"):
		return {"missing": "Spin did not show in the farm view"}
	return {"expect": ["CentrifugeIcon"]}


func _step_bottling() -> Dictionary:
	await fi.click_icon(main.find_child("CentrifugeIcon", true, false) as Control)
	if not await _until(func() -> bool: return _state() == CRANKING, 5.0):
		return {"missing": "Spin did not start the crank", "abort": true}
	var free: Vector2 = fi.free_spot(main)
	# spaced real taps (a windowed hold gets cancelled by the OS cursor's own events), one per 1 / max_tap_rate
	var gap: float = 1.0 / float(cfg.get("max_tap_rate")) + 0.03
	var sent: int = 0
	while _state() == CRANKING and sent < 60:
		await fi.click_at(free)
		await _gwait(gap)
		sent += 1
	await _until(func() -> bool: return _state() == BOTTLING, 10.0)
	if "truck_capacity_jars" in cfg:
		cfg.set("truck_capacity_jars", 4)
	await _gwait(1.5)
	return {}


func _step_sell() -> Dictionary:
	Engine.time_scale = 5.0
	await _until(func() -> bool: return _visible("SellIcon"), 60.0)
	Engine.time_scale = 1.0
	await _gwait(2.0)
	if not _visible("SellIcon"):
		return {"missing": "the Sell icon never showed"}
	return {"expect": ["SellIcon"]}


## Dev mode open, speed x5 and the corner tag.
func _step_dev_speed() -> Dictionary:
	var panel: Node = main.get_node_or_null("DevPanel")
	var tag: Node = main.find_child("DevSpeedTag", true, false)
	var x5: Button = null
	if panel != null:
		var ev := InputEventKey.new()
		ev.keycode = KEY_QUOTELEFT
		ev.pressed = true
		root.push_input(ev)
		await _frames(3)
		if not (panel as CanvasLayer).visible:
			panel.call("toggle")
			await _frames(3)
		for b in panel.find_children("*", "Button", true, false):
			if (b as Button).text == String.chr(215) + "5":
				x5 = b as Button
	if panel == null or tag == null or x5 == null:
		return {"missing": "this version has no Dev speed row / on-screen speed tag"}
	await fi.click_ctl(x5)
	await _frames(5)
	return {"caption": "Dev mode open, speed x5 chosen, tag at the top-left (time_scale %s)" % str(Engine.time_scale), "expect": ["DevSpeedTag"]}
