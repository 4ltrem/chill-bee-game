extends "res://tests/test_motor.gd"

# Quinn: 0.1.4 item 14 tests, written from game/specs/0.1.4-ui-placement.md (item 14) and game/specs/0.1.4-node-handoff.md, not from the code.
# T14.1: five frames, each upright (comb face vertical); the hive body has four walls whose rects enclose every frame in the farm view.
# T14.2: on a raised frame in the first zoom the comb cells cover >= 90% of the frame's inner rect on screen, and one cell's width over
#        the frame's inner width is within 15% of the round 9 pick's (hive-frames-a.tscn, cell radius 0.14).
# T14.3: at every 10% of the lid's close animation the lid's box meets no wall's box; closed, it rests flat on the top of the four walls.
# Black box: "frame" = FrameBars/FrameBarN (its Back panel is the inner rect, as in T10.2), "wall" = a MeshInstance3D of HiveBody that is not
# the Floor, "cell" = a visible mesh under Honeycomb. Numbers come from the config or from the spec text (0.14, 90%, 15%, 10%).

const _PICK_SCENE: String = "res://scenes/variants/hive-frames/hive-frames-a.tscn"
const _PICK_CELL_RADIUS: float = 0.14   # spec item 14: round 9 variant a
const _PICK_COVER: float = 0.9          # spec T14.2: cells cover at least 90% of the inner rect
const _PICK_RATIO_TOL: float = 0.15     # spec T14.2: within 15% of the pick's cell width / frame inner width
const _UPRIGHT_MAX_DEG: float = 5.0     # a comb face normal is horizontal within this (upright = face vertical)
const _WALL_EPS: float = 0.01           # world units a lid box may sink into a wall box (touching is fine)
const _REST_EPS: float = 0.02           # world units the closed lid may be off the wall tops


## The wall nodes of a hive: visible mesh children of HiveBody other than the Floor.
func _walls_of(hive: Node) -> Array:
	var out: Array = []
	var body: Node = hive.find_child("HiveBody", true, false)
	if body == null:
		return out
	for n in body.get_children():
		if n is MeshInstance3D and n.name != "Floor" and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).is_visible_in_tree():
			out.append(n)
	return out


## Which side of `centre` a wall sits on: "+x", "-x", "+z" or "-z" (hive-local, by the larger offset), "" when it is at the centre.
func _wall_side(inv: Transform3D, wall: Node3D, centre: Vector3) -> String:
	var d: Vector3 = inv * wall.global_position - centre
	if maxf(absf(d.x), absf(d.z)) < 0.05:
		return ""
	if absf(d.x) >= absf(d.z):
		return "+x" if d.x > 0.0 else "-x"
	return "+z" if d.z > 0.0 else "-z"


## Tilt of a comb face's normal from the horizontal, in degrees (0 = face vertical).
func _face_tilt_deg(normal: Vector3) -> float:
	return rad_to_deg(asin(clampf(absf(normal.normalized().y), 0.0, 1.0)))


## A frame's Back panel box [centre, axes, mesh], or [] when it is missing.
func _back_box(hive: Node, i: int) -> Array:
	var fb: Node = hive.find_child("FrameBar%d" % (i + 1), true, false)
	var back: Node = fb.find_child("Back", true, false) if fb != null else null
	if back == null:
		return []
	var b: Array = _obbs(back)
	return b[0] if b.size() == 1 else []


## The direction of the box's thinnest axis (its face normal).
func _thin_axis(bx: Array) -> Vector3:
	var ax: Array = bx[1]
	var thin: int = 0
	for k in 3:
		if (ax[k] as Vector3).length() < (ax[thin] as Vector3).length():
			thin = k
	return (ax[thin] as Vector3).normalized()


## T14.1: five frames, each upright; four walls (one per side) whose rects enclose every frame, in the world plan and on screen in the farm view.
func t_hive_five_upright_frames_four_walls() -> void:
	# self-check: a flat panel (normal up) is not upright, a vertical one is
	ck(_face_tilt_deg(Vector3.UP) > _UPRIGHT_MAX_DEG, "self-check: a face looking up is not upright")
	ck(_face_tilt_deg(Vector3.RIGHT) <= _UPRIGHT_MAX_DEG, "self-check: a face looking sideways is upright")
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var hive: Node = _nn(m, "Hive")
	if hive == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	await _frames(6)
	var want: int = _frames_n()
	eq(int(hive.call("frame_count")), want, "the hive has %d frames (config)" % want)
	var bars: Node = hive.find_child("FrameBars", true, false)
	ck(bars != null and bars.get_child_count() == want, "FrameBars holds exactly %d frame bars (%d)" % [want, bars.get_child_count() if bars != null else -1])
	ck(hive.find_child("Slot%d" % (want + 1), true, false) == null and hive.find_child("FrameBar%d" % (want + 1), true, false) == null, "there is no frame past %d" % want)
	var frame_boxes: Array = []
	var frame_screen: Array = []
	var cam: Camera3D = _cam()
	for i in want:
		var slot: Node3D = hive.find_child("Slot%d" % (i + 1), true, false) as Node3D
		var bb: Array = _back_box(hive, i)
		ck(slot != null and bb.size() == 3, "frame %d: its Slot and its FrameBar Back panel exist" % (i + 1))
		if slot == null or bb.size() != 3:
			continue
		var n1: float = _face_tilt_deg(_thin_axis(bb))
		var n2: float = _face_tilt_deg(slot.global_basis.y)
		ck(n1 <= _UPRIGHT_MAX_DEG, "frame %d stands upright: its Back panel's face is %.1f deg off vertical (max %.0f)" % [i + 1, n1, _UPRIGHT_MAX_DEG])
		ck(n2 <= _UPRIGHT_MAX_DEG, "frame %d: its Slot's face normal is %.1f deg off horizontal (max %.0f)" % [i + 1, n2, _UPRIGHT_MAX_DEG])
		var fb: Node = hive.find_child("FrameBar%d" % (i + 1), true, false)
		var boxes: Array = _obbs(fb)
		frame_boxes.append(boxes)
		frame_screen.append(_screen_of(boxes, cam))
		# the tall side of the panel is vertical: its vertical extent exceeds the hive wall thickness (a frame standing on its edge is not upright)
		var ext: Vector2 = _box_corners_y(boxes)
		ck(ext.y - ext.x > 0.2, "frame %d has height (%.2f)" % [i + 1, ext.y - ext.x])
	# walls
	var walls: Array = _walls_of(hive)
	eq(walls.size(), 4, "the hive body has four visible walls")
	var inv: Transform3D = (hive as Node3D).global_transform.affine_inverse()
	var body: Node = hive.find_child("HiveBody", true, false)
	var floor_n: Node = body.find_child("Floor", true, false) if body != null else null
	var centre: Vector3 = Vector3.ZERO
	if floor_n != null:
		centre = inv * (floor_n as Node3D).global_position
		centre.y = 0.0
	var sides: Array = []
	var wall_boxes: Array = []
	var wall_screen: Array = []
	for w in walls:
		sides.append(_wall_side(inv, w as Node3D, centre))
		wall_boxes.append_array(_obbs(w))
		wall_screen.append(_screen_of(_obbs(w), cam))
	sides.sort()
	eq(sides, ["+x", "+z", "-x", "-z"], "the four walls stand on the four sides of the body (one each)")
	if walls.size() == 4 and wall_boxes.size() == 4:
		var wr: Rect2 = _hive_xz(inv, wall_boxes)
		var ws: Rect2 = wall_screen[0]
		for r in wall_screen:
			ws = ws.merge(r as Rect2)
		for i in frame_boxes.size():
			var fr: Rect2 = _hive_xz(inv, frame_boxes[i])
			ck(wr.encloses(fr.grow(-0.001)), "frame %d: the walls' plan %s encloses the frame's plan %s" % [i + 1, str(wr), str(fr)])
			ck(ws.encloses((frame_screen[i] as Rect2).grow(-0.5)), "frame %d: the walls' screen rect %s encloses the frame's %s in the farm view" % [i + 1, str(ws), str(frame_screen[i])])
		# self-check: dropping one wall shrinks the enclosing plan on that side, so a missing wall would be caught
		var three: Array = wall_boxes.duplicate()
		three.remove_at(0)
		var r3: Rect2 = _hive_xz(inv, three)
		ck(r3.get_area() < wr.get_area() - 1.0e-4, "self-check: the plan of three walls is smaller than that of four (%.3f < %.3f)" % [r3.get_area(), wr.get_area()])
	_fin()


## Frame screen helper: share of `inner`'s area covered by the screen rect of `cells`.
func _cover_share(cells: Array, inner: Array, cam: Camera3D) -> float:
	var rc: Rect2 = _screen_of(cells, cam)
	var ri: Rect2 = _screen_of(inner, cam)
	if ri.get_area() <= 0.0:
		return 0.0
	return rc.intersection(ri).get_area() / ri.get_area()


## The width of a cell: the larger of its mesh's x and z extents in world units (a hex cell's across-corners width).
func _cell_diam(mi: MeshInstance3D) -> float:
	var a: AABB = mi.mesh.get_aabb()
	var gt: Transform3D = mi.global_transform
	return maxf(a.size.x * gt.basis.x.length(), a.size.z * gt.basis.z.length())


## A frame's inner width: the longer of the two wide axes of its Back panel box, in world units.
func _inner_width(bx: Array) -> float:
	var ls: Array = []
	for v in (bx[1] as Array):
		ls.append((v as Vector3).length() * 2.0)
	ls.sort()
	return float(ls[2])


## Cell width over frame inner width in the round 9 pick (variant a, frame 1).
func _pick_ratio() -> float:
	var ps: PackedScene = load(_PICK_SCENE) as PackedScene
	ck(ps != null, "the round 9 pick scene loads")
	if ps == null:
		return -1.0
	var pick: Node = ps.instantiate()
	root.add_child(pick)
	_to_free.append(pick)
	await _frames(2)
	var cell: MeshInstance3D = pick.find_child("F1C00", true, false) as MeshInstance3D
	var back: Node = pick.find_child("FrameBar1", true, false)
	back = back.find_child("Back", true, false) if back != null else null
	ck(cell != null and back != null, "the pick has F1C00 and FrameBar1/Back")
	if cell == null or back == null:
		return -1.0
	var rad: float = float((cell.mesh as CylinderMesh).top_radius) if cell.mesh is CylinderMesh else -1.0
	near(rad, _PICK_CELL_RADIUS, "the pick's cell radius is the spec's 0.14", 1.0e-4)
	var bb: Array = _obbs(back)
	return _cell_diam(cell) / _inner_width(bb[0])


## T14.2: raised frame, first zoom: cells cover >= 90% of the inner rect on screen; cell width / inner width within 15% of the pick's.
func t_raised_frame_cells_fill_and_size() -> void:
	var pick: float = await _pick_ratio()
	ck(pick > 0.05 and pick < 0.6, "the pick's cell width over its frame's inner width is sane (%.3f)" % pick)
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var hive: Node = p["Hive"]
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var risen: int = int(tr["risen"])
	ck(risen >= 0, "a frame is raised in the first zoom (%d)" % risen)
	var hc: Node = m.find_child("Honeycomb", true, false)
	var bb: Array = _back_box(hive, risen) if risen >= 0 else []
	ck(hc != null and bb.size() == 3, "the raised frame's Back panel and the Honeycomb exist")
	if hc == null or bb.size() != 3:
		_fin()
		return
	var cells: Array = []
	var first: MeshInstance3D = null
	for n in hc.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi.mesh != null and mi.is_visible_in_tree():
			cells.append_array(_obbs(mi))
			if first == null:
				first = mi
	eq(cells.size(), _cpf(), "the raised frame draws all %d cells (grid_cols x grid_rows)" % _cpf())
	if cells.is_empty() or first == null:
		_fin()
		return
	var share: float = _cover_share(cells, [bb], cam)
	# self-checks: the measure can fail (half the cells cover less; no cells cover nothing; the panel covers itself)
	ck(_cover_share(cells.slice(0, cells.size() / 2), [bb], cam) < _PICK_COVER, "self-check: half the cells do not cover 90%% of the inner rect")
	ck(_cover_share([bb], [bb], cam) >= 0.99, "self-check: the panel covers itself")
	ck(share >= _PICK_COVER, "the cells cover %.0f%% of the frame's inner rect on screen (need %.0f%%)" % [share * 100.0, _PICK_COVER * 100.0])
	var ratio: float = _cell_diam(first) / _inner_width(bb)
	ck(absf(ratio / pick - 1.0) <= _PICK_RATIO_TOL, "cell width over inner width is %.3f, the pick's is %.3f (within %.0f%%: %.0f%% off)" % [ratio, pick, _PICK_RATIO_TOL * 100.0, absf(ratio / pick - 1.0) * 100.0])
	ck(absf(0.5 * pick / pick - 1.0) > _PICK_RATIO_TOL, "self-check: half the pick's ratio would fail the 15% rule")
	_fin()


## T14.3: close the lid and sample its box against each wall's at 0%, 10% ... 100% of the animation; then it rests flat on the wall tops.
func t_lid_closes_clear_of_walls() -> void:
	var h: Dictionary = await _hive_setup()
	if h.is_empty():
		_fin()
		return
	var hive: Node = h["hive"]
	var lid: Node3D = h["lid"]
	var walls: Array = _walls_of(hive)
	var wall_boxes: Array = []
	for w in walls:
		wall_boxes.append_array(_obbs(w))
	eq(walls.size(), 4, "four walls to test the lid against")
	var closed: Transform3D = lid.global_transform
	var secs: float = float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.35
	hive.call("open_lid")
	await _sample_lid(lid, func() -> Array: return [], secs)
	ck(not lid.global_transform.origin.is_equal_approx(closed.origin), "the lid is open before closing")
	hive.call("close_lid")
	var s: Array = await _sample_lid(lid, func() -> Array: return [], secs)
	# every sample's worst penetration into any wall (own measure: the strict wall eps, walls only)
	var first: int = -1
	var last: int = -1
	var final_xf: Transform3D = (s[s.size() - 1] as Dictionary)["xf"]
	for i in s.size():
		var xf: Transform3D = (s[i] as Dictionary)["xf"]
		if first < 0 and not xf.origin.is_equal_approx(((s[0] as Dictionary)["xf"] as Transform3D).origin):
			first = i
		if not xf.origin.is_equal_approx(final_xf.origin) or _angle_between(xf.basis, final_xf.basis) > 0.01:
			last = i + 1
	ck(s.size() >= 30 and first >= 0 and last > first + 10, "the close animation was sampled and it moves (%d samples, moving %d..%d)" % [s.size(), first, last])
	if s.size() < 30 or first < 0 or last <= first + 10:
		_fin()
		return
	last = mini(last, s.size() - 1)
	# self-check: the penetration measure can fail (a lid box pushed into the walls reads as a penetration)
	var probe: MeshInstance3D = _mk_box(Vector3(1.4, 0.12, 1.4), Transform3D(Basis.IDENTITY, (walls[0] as Node3D).global_position))
	ck(_max_pen(_obbs(probe), wall_boxes) > _WALL_EPS, "self-check: a lid-sized box inside a wall reads as overlapping (%.3f)" % _max_pen(_obbs(probe), wall_boxes))
	var worst_all: float = -1.0e9
	for k in 11:
		var idx: int = first + int(round(float(k) / 10.0 * float(last - first)))
		var xf: Transform3D = (s[idx] as Dictionary)["xf"]
		lid.global_transform = xf
		var pen: float = _max_pen(_obbs(lid), wall_boxes)
		worst_all = maxf(worst_all, pen)
		ck(pen <= _WALL_EPS, "close animation at %d%%: the lid box penetrates the walls by %.3f (max %.2f)" % [k * 10, pen, _WALL_EPS])
	lid.global_transform = final_xf
	# closed: flat on the top of the four walls
	ck(_angle_between(final_xf.basis, closed.basis) <= 0.03, "the lid ends in its closed pose")
	var tilt: float = _lid_tilt(lid)
	ck(tilt >= 0.0 and tilt <= 1.0, "closed, the lid is flat (tilt %.2f deg)" % tilt)
	var wy: Vector2 = _box_corners_y(wall_boxes)
	var ly: Vector2 = _box_corners_y(_obbs(lid))
	ck(absf(ly.x - wy.y) <= _REST_EPS, "closed, the lid's underside (y %.3f) rests on the wall tops (y %.3f)" % [ly.x, wy.y])
	var inv: Transform3D = (hive as Node3D).global_transform.affine_inverse()
	var wr: Rect2 = _hive_xz(inv, wall_boxes)
	var lr: Rect2 = _hive_xz(inv, _obbs(lid))
	ck(lr.grow(_REST_EPS).encloses(wr), "closed, the lid's plan %s covers the plan of all four walls %s" % [str(lr), str(wr)])
	_fin()
