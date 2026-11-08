extends "res://tests/test_crank_pause.gd"

# Quinn: 0.1.4 item 14 lid fix (T14.5), written from game/specs/0.1.4-ui-placement.md (item 14, play-test 2026-11-08), not from the code.
# After the real Back press from the first zoom (main scene, time scale 1), at every rendered frame of the close no lid mesh box sinks more
# than _LID_SINK into any visible hive mesh (walls, floor, frames, bars, combs; MultiMesh instances included), the closed pose included.
# A tilt of about 1 degree is fine (designer, 2026-11-08: "it just can't clip").

const _LID_SINK: float = 0.005       # spec T14.5: the most a lid box may sink into a hive mesh box
const _LID_TILT_MAX_DEG: float = 2.0 # "a tilt of about 1 degree is fine"
const _LID_REST: float = 0.02        # world units the closed lid's underside may be off the wall tops


## Boxes [centre, [axes], node] of every visible mesh under `root_n` (a MultiMesh gives one box per visible instance), skipping subtree `skip`.
func _vis_boxes(root_n: Node, skip: Node) -> Array:
	var out: Array = []
	var all: Array = root_n.find_children("*", "VisualInstance3D", true, false)
	if root_n is VisualInstance3D:
		all.append(root_n)
	for n in all:
		if skip != null and (n == skip or skip.is_ancestor_of(n)):
			continue
		var n3: Node3D = n as Node3D
		if not n3.is_visible_in_tree():
			continue
		var gt: Transform3D = n3.global_transform
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			if mi.mesh != null:
				out.append(_vbox(gt, mi.mesh.get_aabb(), n))
		elif n is MultiMeshInstance3D:
			var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			var cnt: int = mm.instance_count if mm.visible_instance_count < 0 else mini(mm.visible_instance_count, mm.instance_count)
			for i in cnt:
				out.append(_vbox(gt * mm.get_instance_transform(i), mm.mesh.get_aabb(), n))
	return out


func _vbox(gt: Transform3D, a: AABB, n: Node) -> Array:
	return [gt * (a.position + a.size * 0.5), [gt.basis.x * (a.size.x * 0.5), gt.basis.y * (a.size.y * 0.5), gt.basis.z * (a.size.z * 0.5)], n]


## Worst penetration of any lid box into any body box (<= 0 when clear), with the body node it sank into.
func _worst_sink(lid_boxes: Array, body: Array) -> Array:
	var worst: float = -1.0e9
	var who: String = ""
	for l in lid_boxes:
		var lr: float = 0.0
		for v in ((l as Array)[1] as Array):
			lr += (v as Vector3).length()
		for b in body:
			var br: float = 0.0
			for v in ((b as Array)[1] as Array):
				br += (v as Vector3).length()
			if (((l as Array)[0] as Vector3) - ((b as Array)[0] as Vector3)).length() > lr + br:
				continue
			var p: float = _obb_pen(l as Array, b as Array)
			if p > worst:
				worst = p
				who = str(((b as Array)[2] as Node).name)
	return [worst, who]


## T14.5: press Back (real mouse events) in the first zoom and sample the lid against every visible hive mesh at every frame of the close.
# goal T14.5
func t_lid_close_never_clips_hive() -> void:
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var hive: Node = p["Hive"]
	var lid: Node3D = hive.find_child("HiveLid", true, false) as Node3D
	var back: Control = p["BackButton"] as Control
	ck(lid != null and back != null and back.is_visible_in_tree(), "the lid and a visible Back button exist in the first zoom")
	if lid == null or back == null or not back.is_visible_in_tree():
		_fin()
		return
	eq(Engine.time_scale, 1.0, "the close runs at time scale 1")
	await _frames(20)
	# self-check: the measure can fail (a lid-sized box sunk into a wall reads as a sink; the lid alone does not)
	var bodies: Array = _vis_boxes(hive, lid)
	ck(bodies.size() > 20, "the visible hive meshes were gathered (%d boxes: walls, floor, frames, bars, combs)" % bodies.size())
	var walls: Array = _walls_of(hive)
	if walls.is_empty():
		ck(false, "the hive has walls to test against")
		_fin()
		return
	var probe: MeshInstance3D = _mk_box(Vector3(1.4, 0.12, 1.4), Transform3D(Basis.IDENTITY, (walls[0] as Node3D).global_position))
	var pr: Array = _worst_sink(_obbs(probe), bodies)
	ck(float(pr[0]) > _LID_SINK, "self-check: a box sunk into a wall reads as a sink (%.3f)" % float(pr[0]))
	probe.queue_free()
	var open_xf: Transform3D = lid.global_transform
	# the real Back press: a mouse click pushed into the viewport on the button; sample once per rendered frame from then on
	fi.click_ctl(back)
	var frames: int = 0
	var moving: int = 0
	var worst: float = -1.0e9
	var worst_at: int = -1
	var worst_who: String = ""
	var prev: Transform3D = lid.global_transform
	var still: int = 0
	var t0: int = _gms()
	var had_moved: bool = false
	while _gms() - t0 < 15000:
		await process_frame
		frames += 1
		var xf: Transform3D = lid.global_transform
		if not xf.origin.is_equal_approx(prev.origin) or _angle_between(xf.basis, prev.basis) > 0.0005:
			moving += 1
			had_moved = true
			still = 0
		else:
			still += 1
		prev = xf
		var body_now: Array = _vis_boxes(hive, lid)
		body_now.append(_body_volume(hive, walls))   # the whole body as one solid: a lid dipping into the open box between the walls is a clip too
		var r: Array = _worst_sink(_vis_boxes(lid, null), body_now)
		if float(r[0]) > worst:
			worst = float(r[0])
			worst_at = frames
			worst_who = String(r[1])
		if had_moved and still >= 20:
			break
	ck(had_moved and moving >= 20, "the lid moved over %d rendered frames of the close (%d of them differ from the previous)" % [frames, moving])
	ck(not xf_equal(open_xf, lid.global_transform), "the lid left its open pose")
	ck(worst <= _LID_SINK, "at every rendered frame of the close no lid box sinks more than %.3f into a hive mesh: worst %.4f into %s at frame %d of %d" % [_LID_SINK, worst, worst_who, worst_at, frames])
	# the closed pose: flat within about 1 degree, on the wall tops
	var tilt: float = _lid_tilt(lid)
	ck(tilt >= 0.0 and tilt <= _LID_TILT_MAX_DEG, "closed, the lid is level within %.0f deg (tilt %.2f)" % [_LID_TILT_MAX_DEG, tilt])
	var wall_boxes: Array = []
	for w in walls:
		wall_boxes.append_array(_obbs(w))
	var wy: Vector2 = _box_corners_y(wall_boxes)
	var ly: Vector2 = _box_corners_y(_obbs(lid))
	ck(absf(ly.x - wy.y) <= _LID_REST, "closed, the lid's underside (y %.3f) rests on the wall tops (y %.3f)" % [ly.x, wy.y])
	# Frame-independent sweep of the same close: the lid's own path at 400 progress values from open to closed, measuring how deep any lid
	# box corner sits inside the body solid (a corner poking into the walls at an angle is the clip the designer sees; SAT depth can hide it).
	var lm: Variant = hive.get("_lid_motion")
	if lm == null:
		ck(false, "the hive exposes its lid motion for the sweep")
		_fin()
		return
	var sweep_worst: float = 0.0
	var sweep_at: float = 1.0
	for i in 401:
		var s: float = 1.0 - float(i) / 400.0
		lm.apply(s)
		var d: float = _corner_sink(_vis_boxes(lid, null), _body_volume(hive, walls))
		if d > sweep_worst:
			sweep_worst = d
			sweep_at = s
	ck(sweep_worst <= _LID_SINK, "along the whole lid path no lid corner sinks more than %.3f into the hive body: worst %.4f at progress %.3f" % [_LID_SINK, sweep_worst, sweep_at])
	_fin()


## Deepest a corner of any lid box sits inside the solid box `body` ([centre, axes, node]), 0 when none is inside.
func _corner_sink(lid_boxes: Array, body: Array) -> float:
	var c: Vector3 = body[0]
	var ax: Array = body[1]
	var worst: float = 0.0
	for l in lid_boxes:
		var lc: Vector3 = (l as Array)[0]
		var la: Array = (l as Array)[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var pt: Vector3 = lc + (la[0] as Vector3) * sx + (la[1] as Vector3) * sy + (la[2] as Vector3) * sz - c
					var depth: float = 1.0e9
					for a in ax:
						var h: float = (a as Vector3).length()
						var q: float = absf(pt.dot((a as Vector3) / h))
						depth = minf(depth, h - q)
					worst = maxf(worst, depth)
	return worst


## The hive body as one box: the wall tops' footprint (outer wall faces) from the ground to the wall tops, [centre, axes, node].
func _body_volume(hive: Node, walls: Array) -> Array:
	var wb: Array = []
	for w in walls:
		wb.append_array(_obbs(w))
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for b in wb:
		var c: Vector3 = (b as Array)[0]
		var ext := Vector3.ZERO
		for v in ((b as Array)[1] as Array):
			ext += (v as Vector3).abs()
		lo = Vector3(minf(lo.x, c.x - ext.x), minf(lo.y, c.y - ext.y), minf(lo.z, c.z - ext.z))
		hi = Vector3(maxf(hi.x, c.x + ext.x), maxf(hi.y, c.y + ext.y), maxf(hi.z, c.z + ext.z))
	var h3: Node3D = hive as Node3D
	var ctr: Vector3 = (lo + hi) * 0.5
	var half: Vector3 = (hi - lo) * 0.5
	var bs: Basis = Basis.IDENTITY
	return [ctr, [bs.x * half.x, bs.y * half.y, bs.z * half.z], h3]


func xf_equal(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.is_equal_approx(b.origin) and _angle_between(a.basis, b.basis) < 0.01
