extends "res://tests/test_ui_placement.gd"

# Quinn: 0.1.4 item 10 tests, written from game/specs/0.1.4-ui-placement.md (item 10) and game/specs/0.1.4-node-handoff.md, not from the code.
# T10.1: the comb cells of every frame show while the frame sits in the hive (no frame raised), filling as the hive fills (empty, half, full),
#        and in the first zoom for the frames that did not rise.
# T10.2: the comb cells cover each frame's inner area edge to edge, and the hive body is whole (all four walls drawn) after the rescale.
# Black box: a "comb cell" is any visible MeshInstance3D under the Hive, outside the one Honeycomb, drawn with the shared cell_capped or
# cell_uncapped material; its frame is the nearest Slot marker. Expected counts come from Hive.frames (0 Capped, 1 Uncapped, 2 Extracted).

const _COVER_MIN: float = 0.9   # the cells' span is at least this share of the frame's Back panel span, on both axes ("edge to edge")
const _COVER_MAX: float = 1.1   # and no more than this (cells must not spill out of the frame)


## [[MeshInstance3D, state]] of the comb cells drawn in the hive now (the Honeycomb's own cells are the risen frame's, not counted).
func _hive_cells(hive: Node) -> Array:
	var out: Array = []
	var hc: Node = hive.find_child("Honeycomb", true, false)
	for n in hive.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or (hc != null and hc.is_ancestor_of(mi)):
			continue
		var mp: String = _mat_path(mi)
		if mp.ends_with("/cell_capped.tres"):
			out.append([mi, 0])
		elif mp.ends_with("/cell_uncapped.tres"):
			out.append([mi, 1])
	return out


## Index of the Slot marker nearest to a world point (the frame a cell belongs to).
func _nearest_slot(hive: Node, p: Vector3) -> int:
	var best: int = -1
	var bd: float = 1.0e9
	for f in int(hive.call("frame_count")):
		var s: Node3D = hive.find_child("Slot%d" % (f + 1), true, false) as Node3D
		if s == null:
			continue
		var d: float = s.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = f
	return best


## Per frame {state: visible cell count}, for the cells in `cells`.
func _counts_by_frame(hive: Node, cells: Array) -> Array:
	var out: Array = []
	for f in int(hive.call("frame_count")):
		out.append({0: 0, 1: 0})
	for c in cells:
		var f: int = _nearest_slot(hive, ((c as Array)[0] as Node3D).global_position)
		if f >= 0:
			out[f][int((c as Array)[1])] += 1
	return out


## Expected per frame {state: count} from the hive's data, skipping the risen frame (the Honeycomb draws that one).
func _expected_by_frame(hive: Node, skip: int) -> Array:
	var out: Array = []
	for f in int(hive.call("frame_count")):
		var d: Dictionary = {0: 0, 1: 0}
		if f != skip:
			for s in (hive.get("frames") as Array)[f]:
				if int(s) == 0 or int(s) == 1:
					d[int(s)] += 1
		out.append(d)
	return out


## Compare drawn comb cells with the data: every Capped and Uncapped cell of every frame in the hive is drawn, no other.
func _check_cells_match(hive: Node, skip: int, label: String) -> int:
	var cells: Array = _hive_cells(hive)
	var got: Array = _counts_by_frame(hive, cells)
	var want: Array = _expected_by_frame(hive, skip)
	eq(got, want, "%s: the comb cells drawn in each frame (capped, uncapped) match the hive's cells" % label)
	var total: int = 0
	for d in want:
		total += int(d[0]) + int(d[1])
	return total


func _total_cells(hive: Node) -> int:
	return int(hive.call("frame_count")) * int(hive.get("config").call("cells_per_frame"))


## T10.1: the hive's frames show their comb cells in the hive (no frame raised) as it fills (empty, half, full), and in the first zoom.
func t_combs_visible_in_hive() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	var tr: Dictionary = _track(hive)
	_set_cfg("base_seconds_per_jar", 1.0e9)   # CHEAT (Dev mode, marked): nothing arrives by itself; the test pours honey by hand
	await _frames(4)
	var total: int = _total_cells(hive)
	var cfg: Variant = hive.get("config")
	# self-check: the cell finder can fail (a hive of no cells yields none; it is not a constant)
	ck(total > 0, "the hive has cells to show (%d)" % total)
	# empty
	eq(int(tr["risen"]), -1, "no frame is raised at the start")
	var n_empty: int = _check_cells_match(hive, -1, "empty hive")
	eq(n_empty, 0, "an empty hive has no Capped or Uncapped cells")
	# half: pour honey for half the cells by hand
	var half: int = total / 2
	hive.call("advance", float(half) * float(cfg.call("cell_value")) * float(cfg.get("base_seconds_per_jar")), 1.0)
	await _frames(3)
	var n_half: int = _check_cells_match(hive, -1, "half-full hive")
	eq(n_half, half, "half the hive's cells hold honey (%d of %d)" % [half, total])
	ck(n_half > 0 and n_half < total, "self-check: half is neither empty nor full")
	eq(int(tr["risen"]), -1, "still no frame raised at half")
	# one more cell: the drawn count follows
	hive.call("advance", float(cfg.call("cell_value")) * float(cfg.get("base_seconds_per_jar")), 1.0)
	await _frames(3)
	eq(_check_cells_match(hive, -1, "half plus one cell"), half + 1, "one more cell of honey draws one more comb cell")
	# full
	hive.call("fill_now")
	await _frames(3)
	var n_full: int = _check_cells_match(hive, -1, "full hive")
	eq(n_full, total, "a full hive draws every cell (%d)" % total)
	eq(int(tr["risen"]), -1, "still no frame raised at full")
	# the first zoom: the frame that rose is drawn by the Honeycomb, the other frames' cells stay drawn in the hive
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "the zoom opened with a risen frame")
	if raised:
		var risen: int = int(tr["risen"])
		var n_zoom: int = _check_cells_match(hive, risen, "first zoom")
		eq(n_zoom, total - _cpf(), "first zoom: the %d other frames show all their cells" % (int(hive.call("frame_count")) - 1))
		var cam: Camera3D = _cam()
		var vp: Rect2 = _vp()
		var on_screen: int = 0
		for c in _hive_cells(hive):
			var wp: Vector3 = ((c as Array)[0] as Node3D).global_position
			if not cam.is_position_behind(wp) and vp.has_point(cam.unproject_position(wp)):
				on_screen += 1
		ck(on_screen >= _cpf(), "first zoom: at least one frame's worth of in-hive comb cells is on screen (%d, need %d)" % [on_screen, _cpf()])
	_fin()


## Span [lo, hi] along slot-local axis `axis` (0 = x, 2 = z) of the boxes' corners, seen from `slot`'s frame.
func _span_in(slot: Node3D, boxes: Array, axis: int) -> Vector2:
	var inv: Transform3D = slot.global_transform.affine_inverse()
	var lo: float = 1.0e9
	var hi: float = -1.0e9
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var v: float = (inv * (c + (ax[0] as Vector3) * sx + (ax[1] as Vector3) * sy + (ax[2] as Vector3) * sz))[axis]
					lo = minf(lo, v)
					hi = maxf(hi, v)
	return Vector2(lo, hi)


## T10.2: with the hive full and no frame raised, each frame's cells span its Back panel (inner area) edge to edge on both axes; the hive body
## is whole: the four walls are drawn and the visible body spans the Floor on every side (a missing wall shrinks one side).
func t_combs_fill_frame_and_hive_whole() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	if p.is_empty():
		_fin()
		return
	var hive: Node = p["Hive"]
	_set_cfg("base_seconds_per_jar", 1.0e9)
	hive.call("fill_now")
	await _frames(4)
	var checked: int = 0
	for f in int(hive.call("frame_count")):
		var slot: Node3D = hive.find_child("Slot%d" % (f + 1), true, false) as Node3D
		var back: Node = hive.find_child("FrameBar%d" % (f + 1), true, false)
		back = back.find_child("Back", true, false) if back != null else null
		if slot == null or back == null:
			ck(false, "frame %d: its Slot and FrameBar Back panel exist" % (f + 1))
			continue
		var mine: Array = []
		for c in _hive_cells(hive):
			var mi: MeshInstance3D = (c as Array)[0] as MeshInstance3D
			if _nearest_slot(hive, mi.global_position) == f:
				mine.append_array(_obbs(mi))
		var bb: Array = _obbs(back)
		ck(mine.size() == _cpf() and bb.size() == 1, "frame %d: %d cells and its Back panel were measured" % [f + 1, mine.size()])
		if mine.size() != _cpf() or bb.size() != 1:
			continue
		for axis in [0, 2]:
			var cs: Vector2 = _span_in(slot, mine, axis)
			var bs: Vector2 = _span_in(slot, bb, axis)
			# the panel's thin axis (depth) is skipped: only the two with a real width are compared
			var ratio: float = (cs.y - cs.x) / maxf(bs.y - bs.x, 1.0e-6)
			ck(ratio >= _COVER_MIN and ratio <= _COVER_MAX, "frame %d, slot axis %d: the cells span %.0f%% of the frame's inner area (%.2f to %.2f)" % [f + 1, axis, ratio * 100.0, _COVER_MIN, _COVER_MAX])
			checked += 1
	ck(checked >= 2, "frame coverage was measured (%d axis checks)" % checked)
	# the hive body is whole
	var body: Node = hive.find_child("HiveBody", true, false)
	var floor_n: Node = body.find_child("Floor", true, false) if body != null else null
	ck(floor_n != null, "the hive has a body with a Floor")
	if floor_n != null:
		var inv: Transform3D = (hive as Node3D).global_transform.affine_inverse()
		var fl: Rect2 = _hive_xz(inv, _obbs(floor_n))
		var walls: Array = []
		var drawn: int = 0
		for n in body.get_children():
			if n is MeshInstance3D and n != floor_n and (n as MeshInstance3D).mesh != null:
				drawn += 1 if (n as MeshInstance3D).is_visible_in_tree() else 0
				walls.append_array(_obbs(n))
		eq(drawn, 4, "all four wall pieces of the hive body are drawn")
		var wr: Rect2 = _hive_xz(inv, walls)
		var tol: float = 0.1 * minf(fl.size.x, fl.size.y)
		ck(wr.position.x <= fl.position.x + tol and wr.end.x >= fl.end.x - tol, "the walls reach the Floor's left and right edges (walls %s, floor %s)" % [str(wr), str(fl)])
		ck(wr.position.y <= fl.position.y + tol and wr.end.y >= fl.end.y - tol, "the walls reach the Floor's front and back edges (walls %s, floor %s)" % [str(wr), str(fl)])
		# self-check: three walls leave one side short
		var three: Array = walls.slice(0, walls.size() - 1) if walls.size() > 1 else []
		var best_short: float = 0.0
		for k in walls.size():
			var rest: Array = walls.duplicate()
			rest.remove_at(k)
			var r3: Rect2 = _hive_xz(inv, rest)
			best_short = maxf(best_short, maxf(r3.position.x - wr.position.x, maxf(wr.end.x - r3.end.x, maxf(r3.position.y - wr.position.y, wr.end.y - r3.end.y))))
		ck(three.size() > 0 and best_short > 0.0, "self-check: dropping a wall shrinks the span on some side (%.3f)" % best_short)
	_fin()


## The XZ rectangle (hive-local) that the boxes' corners span.
func _hive_xz(inv: Transform3D, boxes: Array) -> Rect2:
	var r: Rect2
	var have: bool = false
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var v: Vector3 = inv * (c + (ax[0] as Vector3) * sx + (ax[1] as Vector3) * sy + (ax[2] as Vector3) * sz)
					if not have:
						r = Rect2(Vector2(v.x, v.z), Vector2.ZERO)
						have = true
					else:
						r = r.expand(Vector2(v.x, v.z))
	return r
