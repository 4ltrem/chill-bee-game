# Bob: A/B layout shots (centrifuge moved by the crate). Usage (windowed, 720 x 1280), the variant after "--":
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/ab_shots.gd -- A      (or B)
# B copies ZoomFramingB's position and zoom_size into ZoomFraming before the zoom. Shots go to game/reports/ab-centrifuge-shots/.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const OUT := "res://reports/ab-centrifuge-shots/"

var fi: RefCounted
var main: Node
var risen: int = -1
var variant: String = "A"


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
	print("shot ", name, " ", img.get_size(), " err=", img.save_png(ProjectSettings.globalize_path(OUT + name + ".png")))


func _cfg() -> Object:
	return root.get_node("Economy").get("config")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		variant = args[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	fi = FarmInput.new(self)
	FarmInput.reset_dev_config()
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	if variant == "B":
		var zf: Node3D = main.find_child("ZoomFraming", true, false) as Node3D
		var zb: Node3D = main.find_child("ZoomFramingB", true, false) as Node3D
		zf.global_transform = zb.global_transform
		zf.set_meta("zoom_size", zb.get_meta("zoom_size"))
	var hive: Node = main.find_child("Hive", true, false)
	var cfg: Object = _cfg()
	hive.connect("frame_raised", func(i: Variant) -> void: risen = int(i))
	hive.connect("frame_lowered", func(_i: Variant) -> void: risen = -1)
	hive.call("fill_now")
	cfg.set("zoom_size", 0.0)   # 0 = read the ZoomFraming metadata
	cfg.set("base_seconds_per_jar", 1.0e9)
	cfg.set("cell_fly_seconds", 0.5)
	await _frames(5)
	await _shot("ab-%s-1-farm-full-hive" % variant)
	await fi.click_icon(main.find_child("ForkIcon", true, false) as Control)
	var t0: int = Time.get_ticks_msec()
	while risen < 0 and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	var lift: Variant = cfg.get("lid_lift_seconds")
	await _wait(float(cfg.get("zoom_seconds")) + float(cfg.get("lid_drop_seconds")) + (float(lift) if lift != null else 0.0) + float(cfg.get("slide_seconds")) + 0.6)
	await _shot("ab-%s-2-zoom-rack-risen" % variant)
	var hc: Node = main.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var min_w: float = 1.0e9
	var n: int = 0
	for mi in hc.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var aabb: AABB = m.mesh.get_aabb()
		var c: Vector3 = aabb.position + aabb.size * 0.5
		c.y = aabb.end.y
		var hx: Vector3 = Vector3(aabb.size.x * 0.5, 0.0, 0.0)
		var gt: Transform3D = m.global_transform
		var w: float = cam.unproject_position(gt * (c + hx)).distance_to(cam.unproject_position(gt * (c - hx)))
		min_w = minf(min_w, w)
		n += 1
	print("MEASURE variant %s: %d cells, smallest width %.1f px, zoom_size %.2f, min_cell_px %s" % [variant, n, min_w, cam.size, str(cfg.get("min_cell_px"))])
	var rws: Array = fi.rows(hc, cam)
	Engine.time_scale = 0.1
	var t1: int = Time.get_ticks_msec()
	await fi.drag_row(rws[0])
	var fly: float = float(cfg.get("cell_fly_seconds"))
	var target_ms: float = (0.18 + fly * 0.5) / 0.1 * 1000.0
	while float(Time.get_ticks_msec() - t1) < target_ms:
		await process_frame
	await _shot("ab-%s-3-zoom-cells-flying-to-bucket" % variant)
	Engine.time_scale = 1.0
	print("COMPLETED")
	quit(0)
