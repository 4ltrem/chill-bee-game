# Quinn: what the player SEES when the hive lid closes, shot by shot, plus the numbers behind it. Usage (windowed, 720 x 1280):
#   Godot --path game --resolution 720x1280 --position 0,0 -s res://tests/lid_shots.gd -- --out=<ABSOLUTE dir>
# Plays the real game to the hive's first zoom (fork click, as tests/ui_compare_shots.gd), pins a copy of that camera, then presses Back: the
# close is the game's own (main._start_closing), at Engine.time_scale 1. Saves lid-close-00..100.png (percent of the close = 100 x (1 - lid
# progress)). A second close, started by hive.close_lid() after reopening, is shot from a side camera looking along the hinge axis
# (lid-side-00..100.png). lid-close.txt lists, per rendered frame of the first close, the lid transform and the OBB penetration of every lid
# mesh into every visible geometry node under the hive (MeshInstance3D and each instance of MultiMeshInstance3D), worst per frame, and a
# per-node summary. Prints COMPLETED and exits 0; exits 1 if a save fails or the close never ran.
extends SceneTree

const FarmInput := preload("res://tests/farm_input.gd")
const WORKING: int = 3   # main.gd Zoom.WORKING

var fi: RefCounted
var main: Node
var hive: Node
var lid: Node3D
var out_dir: String = ""
var failed: bool = false
var lines: PackedStringArray = []
var node_worst: Dictionary = {}   # node path -> [pen, close percent]


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, timeout: float) -> bool:
	var t0: int = Time.get_ticks_msec()
	while not cond.call():
		if float(Time.get_ticks_msec() - t0) > timeout * 1000.0:
			return false
		await process_frame
	return true


func _progress() -> float:
	var lm: Object = hive.get("_lid_motion")
	return float(lm.get("progress")) if lm != null else -1.0


func _save(img: Image, name: String) -> void:
	var err: int = img.save_png(out_dir + name + ".png")
	print("shot ", name, " err=", err)
	if err != OK:
		failed = true


# --- boxes: [center, [half axis x, y, z], node] as tests/test_helpers_2.gd _obbs ---

func _box(gt: Transform3D, a: AABB, n: Node) -> Array:
	return [gt * (a.position + a.size * 0.5), [gt.basis.x * (a.size.x * 0.5), gt.basis.y * (a.size.y * 0.5), gt.basis.z * (a.size.z * 0.5)], n]


func _radius(b: Array) -> float:
	var r: float = 0.0
	for v in (b[1] as Array):
		r += (v as Vector3).length()
	return r


## Separating-axis penetration depth (15 axes): <= 0 when separated, else the smallest overlap along any axis.
func _pen(a: Array, b: Array) -> float:
	var aa: Array = a[1]
	var ab: Array = b[1]
	var axes: Array = []
	axes.append_array(aa)
	axes.append_array(ab)
	for i in 3:
		for j in 3:
			axes.append((aa[i] as Vector3).cross(ab[j] as Vector3))
	var d: Vector3 = (b[0] as Vector3) - (a[0] as Vector3)
	var best: float = 1.0e9
	for ax in axes:
		var l: float = (ax as Vector3).length()
		if l < 1.0e-4:
			continue
		var u: Vector3 = (ax as Vector3) / l
		var ra: float = 0.0
		for v in aa:
			ra += absf((v as Vector3).dot(u))
		var rb: float = 0.0
		for v in ab:
			rb += absf((v as Vector3).dot(u))
		var p: float = ra + rb - absf(d.dot(u))
		if p <= 0.0:
			return p
		best = minf(best, p)
	return best


func _vis(n: Node3D) -> bool:
	return n.is_visible_in_tree()


## Every visible geometry box under `root_n` (a MultiMesh gives one box per visible instance), skipping the subtree `skip`.
func _boxes_under(root_n: Node, skip: Node) -> Array:
	var out: Array = []
	var all: Array = root_n.find_children("*", "VisualInstance3D", true, false)
	for n in all:
		if skip != null and (n == skip or skip.is_ancestor_of(n)):
			continue
		var n3: Node3D = n as Node3D
		if not _vis(n3):
			continue
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			if mi.mesh != null:
				out.append(_box(mi.global_transform, mi.mesh.get_aabb(), mi))
		elif n is MultiMeshInstance3D:
			var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			var cnt: int = mm.instance_count if mm.visible_instance_count < 0 else mini(mm.visible_instance_count, mm.instance_count)
			var ab: AABB = mm.mesh.get_aabb()
			for i in cnt:
				out.append(_box(n3.global_transform * mm.get_instance_transform(i), ab, n))
	return out


func _lid_boxes() -> Array:
	var out: Array = []
	out.append_array(_boxes_under(lid, null))
	if lid is MeshInstance3D and (lid as MeshInstance3D).mesh != null:
		out.append(_box(lid.global_transform, (lid as MeshInstance3D).mesh.get_aabb(), lid))
	return out


func _sample(pct: float, body: Array, lidb: Array) -> void:
	var origin: Vector3 = lid.global_transform.origin
	var q: Quaternion = lid.global_transform.basis.get_rotation_quaternion()
	var head: String = "close %5.1f%%  progress %.3f  lid origin (%.3f, %.3f, %.3f)  quat (%.3f, %.3f, %.3f, %.3f)" % [pct, _progress(), origin.x, origin.y, origin.z, q.x, q.y, q.z, q.w]
	var worst: float = 0.0
	var worst_name: String = ""
	var hits: PackedStringArray = []
	var lid_r: Array = []
	for lb in lidb:
		lid_r.append(_radius(lb))
	var per_node: Dictionary = {}
	for bb in body:
		var br: float = _radius(bb)
		for i in lidb.size():
			var lb: Array = lidb[i]
			if ((lb[0] as Vector3) - (bb[0] as Vector3)).length() > float(lid_r[i]) + br:
				continue
			var p: float = _pen(lb, bb)
			if p <= 0.0005:
				continue
			var nm: String = "%s (lid mesh %s)" % [str(hive.get_path_to(bb[2] as Node)), str(lid.get_path_to(lb[2] as Node)) if lb[2] != lid else "HiveLid"]
			per_node[nm] = maxf(float(per_node.get(nm, 0.0)), p)
	for nm in per_node:
		var p2: float = per_node[nm]
		hits.append("%s: %.4f" % [nm, p2])
		if p2 > worst:
			worst = p2
			worst_name = nm
		var cur: Array = node_worst.get(nm, [0.0, 0.0])
		if p2 > float(cur[0]):
			node_worst[nm] = [p2, pct]
	lines.append(head)
	lines.append("    worst penetration %.4f %s" % [worst, worst_name])
	for h in hits:
		lines.append("      " + h)


func _look_pinned(src: Camera3D) -> Camera3D:
	var c := Camera3D.new()
	c.projection = src.projection
	c.fov = src.fov
	c.size = src.size
	c.near = src.near
	c.far = src.far
	c.keep_aspect = src.keep_aspect
	c.h_offset = src.h_offset
	c.v_offset = src.v_offset
	main.add_child(c)
	c.global_transform = src.global_transform
	c.make_current()
	return c


## Closes the lid with `closer`, saving 11 shots (prefix-00 .. 100) and, if `log` is set, sampling every frame. Returns the frames seen.
func _close_run(prefix: String, closer: Callable, log: bool) -> int:
	var body: Array = _boxes_under(hive, lid)
	var shots: Dictionary = {}
	var next_k: int = 0
	var frames: int = 0
	await RenderingServer.frame_post_draw
	shots[0] = root.get_texture().get_image()
	if log:
		_sample(0.0, body, _lid_boxes())
	next_k = 1
	closer.call()
	var t0: int = Time.get_ticks_msec()
	var started: bool = false
	while Time.get_ticks_msec() - t0 < 15000:
		await RenderingServer.frame_post_draw
		frames += 1
		var pg: float = _progress()
		var pct: float = (1.0 - pg) * 100.0
		if log:
			_sample(pct, _boxes_under(hive, lid), _lid_boxes())
		if pg < 0.999:
			started = true
		while next_k <= 10 and pct >= float(next_k * 10) - 0.001:
			shots[next_k] = root.get_texture().get_image()
			next_k += 1
		if started and pg <= 0.0:
			break
	await _frames(3)
	await RenderingServer.frame_post_draw
	shots[10] = root.get_texture().get_image()
	for k in 11:
		if not shots.has(k):
			print("missing shot ", k)
			failed = true
			continue
		_save(shots[k] as Image, "%s-%02d" % [prefix, k * 10] if k < 10 else "%s-100" % prefix)
	return frames


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	if out_dir == "":
		print("need --out=<absolute dir>")
		quit(1)
		return
	if out_dir.is_relative_path():   # relative to the repo root (the folder above the project)
		out_dir = ProjectSettings.globalize_path("res://").path_join("..").path_join(out_dir).simplify_path()
	if not out_dir.ends_with("/"):
		out_dir += "/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	Engine.time_scale = 1.0
	fi = FarmInput.new(self)
	GameConfig.apply_from(GameConfig.live(), GameConfig.fresh_default())
	var cfg: Object = GameConfig.live()
	if "record_from_launch" in cfg:
		cfg.set("record_from_launch", false)
	root.get_node("Economy").call("reset")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(10)
	hive = main.find_child("Hive", true, false)
	lid = hive.find_child("HiveLid", true, false) as Node3D
	var spot: Node3D = hive.find_child("HiveLidSpot", true, false) as Node3D
	var closed_q: Quaternion = lid.quaternion
	hive.call("fill_now")
	await _until(func() -> bool: return (main.find_child("ForkIcon", true, false) as CanvasItem).is_visible_in_tree(), 5.0)
	await _frames(30)
	await fi.click_icon(main.find_child("ForkIcon", true, false) as Control)
	if not await _until(func() -> bool: return int(main.get("zoom")) == WORKING, 15.0):
		print("the zoom never reached WORKING")
		quit(1)
		return
	await _frames(30)
	var pinned: Camera3D = _look_pinned(root.get_viewport().get_camera_3d())
	await _frames(3)
	print("lid open, progress ", _progress())
	# 1) the real close: Back
	var back: Control = main.find_child("BackButton", true, false) as Control
	var n1: int = await _close_run("lid-close", func() -> void: fi.click_ctl(back), true)
	# per-node summary
	lines.append("")
	lines.append("SUMMARY: worst penetration per node over the close (depth in metres, at what percent of the close)")
	var keys: Array = node_worst.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return float((node_worst[a] as Array)[0]) > float((node_worst[b] as Array)[0]))
	for k in keys:
		lines.append("  %s: %.4f at %.1f%%" % [k, (node_worst[k] as Array)[0], (node_worst[k] as Array)[1]])
	if keys.is_empty():
		lines.append("  no overlap above 0.0005 m with any node")
	lines.append("frames rendered during the close: %d" % n1)
	var f := FileAccess.open(out_dir + "lid-close.txt", FileAccess.WRITE)
	if f == null:
		failed = true
	else:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	# 2) the side view: reopen, camera along the hinge axis, close
	await _until(func() -> bool: return int(main.get("zoom")) == 0, 15.0)
	await _frames(60)
	hive.call("open_lid")
	await _until(func() -> bool: return _progress() >= 0.999, 10.0)
	await _frames(10)
	var par: Node3D = lid.get_parent() as Node3D
	var dq: Quaternion = spot.quaternion * closed_q.inverse()
	var ax: Vector3 = dq.get_axis() if dq.get_angle() > 0.01 else Vector3.RIGHT
	var axw: Vector3 = (par.global_basis * ax).normalized()
	var body: Array = _boxes_under(hive, lid)
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	for b in body:
		var c: Vector3 = b[0]
		var r: float = _radius(b)
		mn = Vector3(minf(mn.x, c.x - r), minf(mn.y, c.y - r), minf(mn.z, c.z - r))
		mx = Vector3(maxf(mx.x, c.x + r), maxf(mx.y, c.y + r), maxf(mx.z, c.z + r))
	var mid: Vector3 = (mn + mx) * 0.5
	var dist: float = (mx - mn).length() * 0.9
	var side := Camera3D.new()
	main.add_child(side)
	var up: Vector3 = Vector3.UP if absf(axw.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	side.global_position = mid + axw * dist
	side.look_at(mid, up)
	side.fov = 45.0
	side.far = 200.0
	side.make_current()
	lines.append("")
	print("side camera along axis ", axw, " hinge angle deg ", rad_to_deg(dq.get_angle()))
	await _frames(5)
	await _close_run("lid-side", func() -> void: hive.call("close_lid"), false)
	var ff := FileAccess.open(out_dir + "lid-close.txt", FileAccess.READ_WRITE)
	if ff != null:
		ff.seek_end()
		ff.store_string("side camera along hinge axis %s, hinge angle %.1f deg\n" % [str(axw), rad_to_deg(dq.get_angle())])
		ff.close()
	pinned.queue_free()
	Engine.time_scale = 1.0
	print("COMPLETED" if not failed else "FAILED")
	quit(1 if failed else 0)
