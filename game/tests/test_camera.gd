extends "res://tests/test_layout.gd"

# Quinn: 0.1.3c camera tests, written from game/specs/0.1.3-next-revision.md (Changes 2, Contract -> Quinn) before the code.
# First stop = the fork's zoom (zoom_size); second stop = the pan that starts when the bucket is full (pan_zoom_size, camera_pan_seconds).
# Every expected number is read from the config. The viewport is 720 x 1280. Each file extends the one before it.
#
# Measures, all from the live camera and the scene's boxes (nothing from the camera script):
#  - silhouette: the 2D convex hull of every visible mesh box of a prop, projected; "share shown" = sample points (SIL_STEP px grid) inside any
#    hull that lie in the viewport / all sample points inside any hull. The hive's share at the second stop must be > 0 and < 100% (round 6).
#  - V7 (M2 style row): the glass bucket's projected rect covers less than BUCKET_MAX_SHARE of the bottom-right third of the view
#    (right half of the bottom third), and no wood mesh (wood.tres, crate_wood.tres) is cut by the left screen edge.

const SIL_STEP: float = 10.0
const QUAD_MIN_SHARE: float = 0.9     # of the visible hive samples, this share lies in the upper-right quadrant
const BUCKET_MAX_SHARE: float = 0.5
const LEAN_TOL_DEG: float = 1.0
const MOVE_EPS: float = 1.0e-5
const HUD_CLASSES: Array[String] = ["Button", "Label", "RichTextLabel", "PanelContainer", "Panel", "ProgressBar", "TextureProgressBar", "TextureRect", "ColorRect"]


var _root_size_saved: Vector2i = Vector2i.ZERO


## The headless test window is not portrait: set the root window to the phone's 720 x 1280 for the pixel measures (restored by _cleanup).
func _portrait() -> void:
	if _root_size_saved == Vector2i.ZERO:
		_root_size_saved = root.size
	root.size = Vector2i(720, 1280)


func _cleanup() -> void:
	super._cleanup()
	if _root_size_saved != Vector2i.ZERO:
		root.size = _root_size_saved
		_root_size_saved = Vector2i.ZERO


func _cam() -> Camera3D:
	return root.get_viewport().get_camera_3d()


func _vp() -> Rect2:
	return Rect2(Vector2.ZERO, root.get_visible_rect().size)


func _pose(cam: Camera3D) -> Dictionary:
	return {"size": cam.size, "pos": cam.global_position, "rot": cam.global_basis.get_euler()}


func _pose_diff(a: Dictionary, b: Dictionary) -> float:
	return absf(float(a["size"]) - float(b["size"])) + (a["pos"] as Vector3).distance_to(b["pos"] as Vector3) + (a["rot"] as Vector3).distance_to(b["rot"] as Vector3)


# ---------------------------------------------------------------- measuring helpers

## One hull per box: {"poly": closed polygon, "box": its bounding Rect2}.
func _hulls(boxes: Array, cam: Camera3D) -> Array:
	var out: Array = []
	for bx in boxes:
		var c: Vector3 = (bx as Array)[0]
		var ax: Array = (bx as Array)[1]
		var pts := PackedVector2Array()
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					pts.append(cam.unproject_position(c + (ax[0] as Vector3) * sx + (ax[1] as Vector3) * sy + (ax[2] as Vector3) * sz))
		var poly: PackedVector2Array = Geometry2D.convex_hull(pts)
		if poly.size() < 3:
			continue
		var r := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			r = r.expand(q)
		out.append({"poly": poly, "box": r})
	return out


func _rect_hull(r: Rect2) -> Dictionary:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	return {"poly": Geometry2D.convex_hull(pts), "box": r}


## Share of a silhouette (union of hulls) inside `vp`, where the visible part lies and how much of it is in the upper-right quadrant.
func _sil_stats(hulls: Array, vp: Rect2, step: float = SIL_STEP) -> Dictionary:
	var out: Dictionary = {"total": 0, "shown": 0, "share": 0.0, "quad": 0.0, "bbox": Rect2(), "centroid": Vector2.ZERO}
	if hulls.is_empty():
		return out
	var all: Rect2 = (hulls[0] as Dictionary)["box"]
	for h in hulls:
		all = all.merge((h as Dictionary)["box"])
	var quad_r := Rect2(vp.position + Vector2(vp.size.x * 0.5, 0.0), vp.size * 0.5)
	var total: int = 0
	var shown: int = 0
	var quad: int = 0
	var sum := Vector2.ZERO
	var bbox := Rect2()
	var y: float = all.position.y + step * 0.5
	while y < all.end.y:
		var x: float = all.position.x + step * 0.5
		while x < all.end.x:
			var p := Vector2(x, y)
			var inside: bool = false
			for h in hulls:
				var hd: Dictionary = h
				if (hd["box"] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, hd["poly"] as PackedVector2Array):
					inside = true
					break
			if inside:
				total += 1
				if vp.has_point(p):
					shown += 1
					sum += p
					if quad_r.has_point(p):
						quad += 1
					bbox = Rect2(p, Vector2.ZERO) if shown == 1 else bbox.expand(p)
			x += step
		y += step
	out["total"] = total
	out["shown"] = shown
	out["share"] = float(shown) / float(maxi(total, 1))
	out["quad"] = float(quad) / float(maxi(shown, 1))
	out["bbox"] = bbox
	out["centroid"] = sum / float(maxi(shown, 1))
	return out


func _overlap_area(a: Rect2, b: Rect2) -> float:
	return a.intersection(b).get_area()


## Visible HUD controls of the running main scene (leaf widgets and panels; layout containers and the Dev panel and overlay are not HUD).
func _hud_controls(m: Node) -> Array:
	var out: Array = []
	for n in m.find_children("*", "Control", true, false):
		var c: Control = n as Control
		if not c.is_visible_in_tree() or c.size.x < 1.0 or c.size.y < 1.0:
			continue
		var cls_ok: bool = false
		for k in HUD_CLASSES:
			if c.is_class(k):
				cls_ok = true
		if not cls_ok:
			continue
		var skip: bool = false
		var a: Node = c
		while a != null and a != m:
			if a.name.to_lower().contains("dev") or a.name.to_lower().contains("uibounds"):
				skip = true
			a = a.get_parent()
		if not skip:
			out.append(c)
	return out


func _hud_hits(controls: Array, target: Rect2) -> Array:
	var out: Array = []
	for c in controls:
		var r: Rect2 = (c as Control).get_global_rect()
		if _overlap_area(r, target) > 1.0:
			out.append("%s %s" % [(c as Control).name, str(r)])
	return out


## First and last frame at which the camera pose changed from `pose0`: the pan's duration in wall seconds (a frame quantises each end) and
## the longest frame in between. samples: [[usec, pose], ...] one per rendered frame.
func _pan_span(samples: Array, pose0: Dictionary) -> Dictionary:
	var i0: int = -1
	var i1: int = -1
	var prev: Dictionary = pose0
	for i in samples.size():
		var pz: Dictionary = (samples[i] as Array)[1]
		if i0 < 0 and _pose_diff(pz, pose0) > MOVE_EPS:
			i0 = i
		if i0 >= 0 and _pose_diff(pz, prev) > MOVE_EPS * 0.1:
			i1 = i
		prev = pz
	if i0 < 0 or i1 < 0:
		return {"ok": false, "secs": 0.0, "worst": 0.0}
	var worst: float = 0.0
	for i in range(maxi(i0, 1), i1 + 1):
		worst = maxf(worst, float((samples[i] as Array)[0] - (samples[i - 1] as Array)[0]) / 1.0e6)
	return {"ok": true, "secs": float((samples[i1] as Array)[0] - (samples[i0] as Array)[0]) / 1.0e6, "worst": worst}


## The glass bucket's boxes: every glass.tres mesh of the centrifuge outside the spigot jar.
func _bucket_boxes(c: Node) -> Array:
	var out: Array = []
	for b in _obbs(c, [c.find_child("SpigotJar", true, false)]):
		var mi: MeshInstance3D = (b as Array)[2] as MeshInstance3D
		if _mat_path(mi).ends_with("glass.tres"):
			out.append(b)
	return out


# ---------------------------------------------------------------- driving the two stops (real input)

## Full hive, fork, then real drags frame by frame until the bucket is full; returns once the camera sits at pan_zoom_size and has rested.
## speed: the Dev panel's speed row is pressed (a real button) just before the last frame's drags. Returns {} when it could not get there.
func _go_second_stop(speed: float = 1.0, pan_seconds: float = -1.0) -> Dictionary:
	_portrait()
	if speed != 1.0:
		_set_dev_mode(true)
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		return {}
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var hive: Node = p["Hive"]
	var pose0: Dictionary = _pose(_cam())
	if pan_seconds > 0.0:
		_set_cfg("camera_pan_seconds", pan_seconds)
	var rec: Dictionary = {"s": []}
	var cb: Callable = func() -> void:
		var cam: Camera3D = root.get_viewport().get_camera_3d()
		if cam != null:
			(rec["s"] as Array).append([_gus(), _pose(cam)])
	process_frame.connect(cb)
	var frames_needed: int = _frames_n()   # 0.1.3c: a full bucket does not pan: every frame is finished first (the extra cells go to the pile), then the pan
	for k in frames_needed:
		if k == frames_needed - 1 and speed != 1.0:
			if not await _press_speed(m, speed):
				process_frame.disconnect(cb)
				return {}
		var f: int = await _scrape_risen(m, hive, tr)
		if k < frames_needed - 1:
			ck(await _next_frame(tr, f), "frame %d done: the next frame rose" % f)
	var secs: float = float(cv("camera_pan_seconds"))
	var reached: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01, secs / speed * 3.0 + 8.0)
	await _wait(0.4)
	process_frame.disconnect(cb)
	Engine.time_scale = 1.0
	ck(reached, "the camera reached pan_zoom_size %s once the bucket was full (now %s)" % [str(cv("pan_zoom_size")), str(_cam().size)])
	if not reached:
		return {}
	return {"m": m, "p": p, "tr": tr, "pose0": pose0, "samples": rec["s"]}


# ---------------------------------------------------------------- first zoom

func _first_zoom_setup() -> Dictionary:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		return {}
	var vp: Rect2 = _vp()
	eq(vp.size, Vector2(720.0, 1280.0), "the viewport is 720 x 1280 (the pixel measures need it)")
	near(_cam().size, float(cv("zoom_size")), 0.05, "the first stop sits at zoom_size")
	return z


# Item 2, first zoom: the smallest cell is at least min_cell_px wide on screen.
func t_camera_first_zoom_cells() -> void:
	var z: Dictionary = await _first_zoom_setup()
	if z.is_empty():
		_fin()
		return
	var cam: Camera3D = _cam()
	var hc: Node = (z["m"] as Node).find_child("Honeycomb", true, false)
	ck(hc != null, "Honeycomb exists")
	var n: int = 0
	var lo: float = 1.0e9
	if hc != null:
		for mi in hc.find_children("*", "MeshInstance3D", true, false):
			var mm: MeshInstance3D = mi as MeshInstance3D
			if mm.mesh == null or not mm.is_visible_in_tree():
				continue
			var w: float = _cell_face_w(mm, cam)
			if w > 0.0:
				lo = minf(lo, w)
				n += 1
	eq(n, _cpf(), "all %d cells of the risen frame were measured" % _cpf())
	ck(n > 0 and lo >= float(cv("min_cell_px")), "the smallest cell is at least min_cell_px wide: %.1f px >= %s (zoom_size %s)" % [lo, str(cv("min_cell_px")), str(cv("zoom_size"))])
	ck(float(cv("min_cell_px")) >= 20.0, "min_cell_px is at least 20 (STYLE V14, designer 2026-11-05)")
	_fin()


# Round 6, first zoom: every frame of the risen rack (cells and bar) and the centrifuge's BucketMouth are on screen; the hive's and the
# centrifuge's outer edges may crop. Round 6 A: zoom_size is the ZoomFraming value. Every frame rises to the same place, so the risen one stands for all.
func t_camera_first_zoom_in_frame() -> void:
	var z: Dictionary = await _first_zoom_setup()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var cam: Camera3D = _cam()
	var vp: Rect2 = _vp()
	var hive: Node = p["Hive"]
	var hc: Node = hive.find_child("Honeycomb", true, false)
	var fb: Node = hive.find_child("FrameBar%d" % (int(tr["risen"]) + 1), true, false)
	var rack: Array = _obbs(hc) if hc != null else []
	if fb != null:
		rack.append_array(_obbs(fb))
	ck(rack.size() >= _cpf(), "the risen rack has boxes (%d: %d cells and the bar)" % [rack.size(), _cpf()])
	var rr: Rect2 = _screen_of(rack, cam)
	ck(vp.encloses(rr), "every frame of the risen rack is on screen (screen box %s, viewport %s)" % [str(rr), str(vp)])
	ck(not Rect2(Vector2.ZERO, vp.size * 0.1).encloses(rr), "self-check: the rack does not fit a tenth of the viewport, so 'on screen' can fail")
	ck(not Rect2(rr.position + rr.size * 0.5, rr.size).encloses(rr), "self-check: a rect shifted half a rack is not enclosing")
	var mouth: Node3D = _nn(m, "BucketMouth") as Node3D
	ck(mouth != null, "BucketMouth exists")
	if mouth != null:
		var mp: Vector2 = cam.unproject_position(mouth.global_position)
		ck(not cam.is_position_behind(mouth.global_position) and vp.has_point(mp), "the centrifuge's BucketMouth is on screen (%s in %s)" % [str(mp), str(vp)])
	var zf: Node = m.find_child("ZoomFraming", true, false)
	ck(zf != null and zf.has_meta("zoom_size"), "ZoomFraming carries the zoom_size metadata")
	if zf != null and zf.has_meta("zoom_size"):
		near(float(cam.size), float(zf.get_meta("zoom_size")), 0.05, "the first stop's camera size equals the ZoomFraming metadata")
		near(float(cv("zoom_size")), float(zf.get_meta("zoom_size")), 0.05, "config zoom_size equals the ZoomFraming metadata")
	_fin()


# Item 2, first zoom, the M2 V7 row: the glass bucket no longer fills the bottom-right third; no wood slab outside the hive is cut off at
# the left edge (round 6: the hive's outer edges may crop now).
func t_camera_first_zoom_v7() -> void:
	var z: Dictionary = await _first_zoom_setup()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var cam: Camera3D = _cam()
	var vp: Rect2 = _vp()
	var c: Node = (z["p"] as Dictionary)["Centrifuge"]
	var bb: Array = _bucket_boxes(c)
	ck(bb.size() > 0, "the centrifuge has glass bucket boxes to measure (%d)" % bb.size())
	var third := Rect2(vp.position + Vector2(vp.size.x * 0.5, vp.size.y * 2.0 / 3.0), Vector2(vp.size.x * 0.5, vp.size.y / 3.0))
	var share: float = 0.0
	if bb.size() > 0:
		var br: Rect2 = _screen_of(bb, cam)
		share = _overlap_area(br, third) / third.get_area()
		ck(share < BUCKET_MAX_SHARE, "the glass bucket (screen box %s) covers %.0f%% of the view's bottom-right third %s, less than %.0f%%" % [str(br), share * 100.0, str(third), BUCKET_MAX_SHARE * 100.0])
		ck(_overlap_area(Rect2(third.position, third.size), third) / third.get_area() >= BUCKET_MAX_SHARE, "self-check: a bucket that covers the whole third is reported")
	var wood: int = 0
	var cut: Array = []
	var hive_n: Node = (z["p"] as Dictionary)["Hive"]
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var mm: MeshInstance3D = mi as MeshInstance3D
		if mm.mesh == null or not mm.is_visible_in_tree() or hive_n.is_ancestor_of(mm) or (m.find_child("Truck", true, false) != null and m.find_child("Truck", true, false).is_ancestor_of(mm)):   # round 6 A: the truck waits at the edge of the first zoom and may crop, like the hive
			continue
		var mp: String = _mat_path(mm)
		if not (mp.ends_with("/wood.tres") or mp.ends_with("/crate_wood.tres")):
			continue
		wood += 1
		var r: Rect2 = _screen_of(_obbs(mm), cam)
		if r.position.x < -1.0 and r.end.x > 1.0 and r.end.y > 0.0 and r.position.y < vp.size.y:
			cut.append("%s %s" % [mm.name, str(r)])
	ck(wood > 0, "wood meshes exist to measure (%d)" % wood)
	eq(cut, [], "no wood mesh outside the hive is cut off by the left screen edge")
	ck(Rect2(-20.0, 100.0, 60.0, 50.0).position.x < -1.0 and Rect2(-20.0, 100.0, 60.0, 50.0).end.x > 1.0, "self-check: a slab spanning x -20..40 counts as cut")
	_fin()


# ---------------------------------------------------------------- second stop

# Item 2, second stop: the centrifuge, crate and truck are wholly in frame.
func t_camera_second_stop_in_frame() -> void:
	var s: Dictionary = await _go_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var cam: Camera3D = _cam()
	var vp: Rect2 = _vp()
	near(cam.size, float(cv("pan_zoom_size")), 0.02, "the second stop sits at pan_zoom_size")
	var crate: Node = _crate_root(m)
	var parts: Dictionary = {"Centrifuge": (s["p"] as Dictionary)["Centrifuge"], "Crate": crate, "Truck": (s["p"] as Dictionary)["Truck"]}
	for nm in parts:
		ck(parts[nm] != null, "%s found" % nm)
		if parts[nm] == null:
			continue
		var r: Rect2 = _screen_of(_obbs(parts[nm] as Node), cam)
		ck(vp.encloses(r), "%s is wholly in frame at the second stop (screen box %s, viewport %s)" % [nm, str(r), str(vp)])
	ck(not Rect2(Vector2.ZERO, vp.size * 0.2).encloses(_screen_of(_obbs((s["p"] as Dictionary)["Truck"] as Node), cam)), "self-check: the truck does not fit 20% of the viewport")
	_fin()


# Round 6, second stop: the hive shows in the upper-right and is partly cut by the screen edge (share > 0 and < 100%).
func t_camera_second_stop_hive_share() -> void:
	var s: Dictionary = await _go_second_stop()
	if s.is_empty():
		_fin()
		return
	var cam: Camera3D = _cam()
	var vp: Rect2 = _vp()
	var hive: Node = (s["p"] as Dictionary)["Hive"]
	var hulls: Array = _hulls(_obbs(hive), cam)
	ck(hulls.size() > 0, "the hive has boxes to project (%d)" % hulls.size())
	var st: Dictionary = _sil_stats(hulls, vp)
	ck(int(st["total"]) > 200, "the silhouette was sampled (%d points at %s px)" % [int(st["total"]), str(SIL_STEP)])
	var share: float = float(st["share"])
	ck(int(st["shown"]) > 0 and int(st["shown"]) < int(st["total"]), "the hive is partly shown: %.1f%% of its silhouette is on screen (want > 0 and < 100%%; %d of %d points)" % [share * 100.0, int(st["shown"]), int(st["total"])])
	ck(int(st["shown"]) > 0 and float(st["quad"]) >= QUAD_MIN_SHARE, "the visible part is in the upper-right quadrant (%.0f%% of its points; centroid %s; want >= %.0f%%)" % [float(st["quad"]) * 100.0, str(st["centroid"]), QUAD_MIN_SHARE * 100.0])
	_fin()


# Item 2, second stop: no HUD control overlaps the hive's or the centrifuge's screen rect.
func t_camera_second_stop_hud_clear() -> void:
	var s: Dictionary = await _go_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var cam: Camera3D = _cam()
	var vp: Rect2 = _vp()
	var p: Dictionary = s["p"]
	var st: Dictionary = _sil_stats(_hulls(_obbs(p["Hive"] as Node), cam), vp)
	ck(int(st["shown"]) > 0, "part of the hive shows (its visible box is the rect no control may cover)")
	var hive_rect: Rect2 = st["bbox"]
	var cen_rect: Rect2 = _screen_of(_obbs(p["Centrifuge"] as Node), cam)
	var controls: Array = _hud_controls(m)
	ck(controls.size() > 0, "HUD controls are visible at the second stop (%d)" % controls.size())
	eq(_hud_hits(controls, hive_rect), [], "no HUD control overlaps the hive's visible screen rect %s" % str(hive_rect))
	eq(_hud_hits(controls, cen_rect), [], "no HUD control overlaps the centrifuge's screen rect %s" % str(cen_rect))
	# the checks can fail: a control placed on each rect is reported
	var probe := Button.new()
	probe.name = "ProbeButton"
	probe.size = Vector2(60.0, 60.0)
	probe.position = cen_rect.get_center() - Vector2(30.0, 30.0)
	(m.find_child("HarvestUI", true, false) as Node if m.find_child("HarvestUI", true, false) != null else m).add_child(probe)
	ck(_hud_hits(_hud_controls(m), cen_rect).size() >= 1, "self-check: a button on the centrifuge is reported as overlapping")
	probe.queue_free()
	_fin()


# Item 2, Back: from the second stop the camera returns to the farm view.
func t_camera_back_from_second_stop() -> void:
	var s: Dictionary = await _go_second_stop()
	if s.is_empty():
		_fin()
		return
	var p: Dictionary = s["p"]
	var farm_ui: Control = p["MoneyLabel"]
	ck(_shown(p["BackButton"]), "BackButton shows at the second stop")
	if not _shown(p["BackButton"]):
		_fin()
		return
	await fi.click_ctl(p["BackButton"] as Control)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")) + float(cv("camera_pan_seconds")))
	var cam: Camera3D = _cam()
	ck(cam.size > float(cv("pan_zoom_size")) - 0.02 or absf(cam.size - float(cv("zoom_size"))) > 0.05, "Back left the second stop (size %.3f)" % cam.size)
	ck(_shown(farm_ui), "the farm UI is back after Back")
	ck(not _shown(p["BackButton"]), "BackButton hides on the farm")
	ck(cam.size > float(cv("pan_zoom_size")) + 0.5, "the farm view is wider than the second stop (size %.3f > pan_zoom_size %s)" % [cam.size, str(cv("pan_zoom_size"))])
	_fin()


# ---------------------------------------------------------------- the pan's time

# Item 2, Contract: the pan takes camera_pan_seconds (+- one frame), read when it starts, so a live change shows at once.
func t_camera_pan_seconds() -> void:
	var s: Dictionary = await _go_second_stop()
	if s.is_empty():
		_fin()
		return
	var sp: Dictionary = _pan_span(s["samples"] as Array, s["pose0"] as Dictionary)
	ck(bool(sp["ok"]), "the camera moved between the first and second stop (%d frames sampled)" % (s["samples"] as Array).size())
	if bool(sp["ok"]):
		var want: float = float(cv("camera_pan_seconds"))
		var tol: float = float(sp["worst"]) + 0.01
		ck(absf(float(sp["secs"]) - want) <= tol, "the pan took %.3f s; camera_pan_seconds is %.3f s +- %.3f s (one frame)" % [float(sp["secs"]), want, tol])
		near(float((s["pose0"] as Dictionary)["size"]), float(cv("zoom_size")), 0.05, "the pan started from the first stop (size zoom_size)")
	# a live change: 2.5 s is read when the pan starts (a fresh scene)
	_cleanup()
	_eco_reset()
	var s2: Dictionary = await _go_second_stop(1.0, 2.5)
	if not s2.is_empty():
		var sp2: Dictionary = _pan_span(s2["samples"] as Array, s2["pose0"] as Dictionary)
		ck(bool(sp2["ok"]), "the pan with camera_pan_seconds 2.5 moved the camera")
		if bool(sp2["ok"]):
			var tol2: float = float(sp2["worst"]) + 0.01
			ck(absf(float(sp2["secs"]) - 2.5) <= tol2, "after a live change to 2.5 the pan took %.3f s +- %.3f s" % [float(sp2["secs"]), tol2])
	_fin()


# Item 2, Contract: the pan follows Engine.time_scale (the Dev row): x5 takes a fifth, x0.5 twice as long.
func t_camera_pan_follows_time_scale() -> void:
	for n in [5.0, 0.5]:
		var s: Dictionary = await _go_second_stop(n)
		if s.is_empty():
			Engine.time_scale = 1.0
			continue
		var sp: Dictionary = _pan_span(s["samples"] as Array, s["pose0"] as Dictionary)
		ck(bool(sp["ok"]), "x%s: the camera moved" % str(n))
		if bool(sp["ok"]):
			var want: float = float(cv("camera_pan_seconds")) / n
			var tol: float = float(sp["worst"]) + 0.01
			ck(absf(float(sp["secs"]) - want) <= tol, "at x%s the pan took %.3f s; camera_pan_seconds / %s = %.3f s +- %.3f s" % [str(n), float(sp["secs"]), str(n), want, tol])
		_cleanup()
		_eco_reset()
	Engine.time_scale = 1.0
	_fin()


# The measuring helpers themselves can fail (synthetic data, no scene).
func t_camera_helpers_can_fail() -> void:
	var vp := Rect2(0.0, 0.0, 720.0, 1280.0)
	var inside: Dictionary = _sil_stats([_rect_hull(Rect2(100.0, 100.0, 200.0, 200.0))], vp)
	near(float(inside["share"]), 1.0, "a hull inside the viewport shows 100%", 0.01)
	var half: Dictionary = _sil_stats([_rect_hull(Rect2(620.0, 100.0, 200.0, 200.0))], vp)
	near(float(half["share"]), 0.5, "a hull half outside the right edge shows 50%", 0.03)
	ck(float(half["quad"]) >= QUAD_MIN_SHARE, "a visible part in the upper right is in the upper-right quadrant")
	var low: Dictionary = _sil_stats([_rect_hull(Rect2(-100.0, 900.0, 200.0, 200.0))], vp)
	ck(float(low["quad"]) < 0.1 and float(low["share"]) < 0.55, "a lower-left sliver is reported as not in the upper-right quadrant")
	var out: Dictionary = _sil_stats([_rect_hull(Rect2(800.0, 100.0, 100.0, 100.0))], vp)
	eq(int(out["shown"]), 0, "a hull wholly off screen shows nothing")
	eq(_hud_hits([], Rect2(0.0, 0.0, 10.0, 10.0)), [], "no controls, no hits")
	var b := Button.new()
	b.size = Vector2(100.0, 100.0)
	b.position = Vector2(50.0, 50.0)
	_add_root(b)
	ck(_hud_hits([b], Rect2(100.0, 100.0, 100.0, 100.0)).size() == 1, "a control over the rect is a hit")
	ck(_hud_hits([b], Rect2(300.0, 300.0, 50.0, 50.0)).is_empty(), "a control away from the rect is no hit")
	# a pan trace: linear 1.2 s at 60 fps is read as 1.2 s, not 0.6 s
	var pose0: Dictionary = {"size": 7.0, "pos": Vector3.ZERO, "rot": Vector3.ZERO}
	var tr: Array = []
	for i in 140:
		var t: float = float(i) / 60.0
		var k: float = clampf((t - 0.2) / 1.2, 0.0, 1.0)
		tr.append([int(t * 1.0e6), {"size": 7.0 + 2.0 * k, "pos": Vector3(k, 0.0, 0.0), "rot": Vector3.ZERO}])
	var sp: Dictionary = _pan_span(tr, pose0)
	ck(bool(sp["ok"]) and absf(float(sp["secs"]) - 1.2) <= 0.04, "a 1.2 s synthetic pan is measured as %.3f s" % float(sp["secs"]))
	ck(absf(float(sp["secs"]) - 0.6) > 0.3, "self-check: it is not mistaken for 0.6 s")
	ck(not bool(_pan_span([[0, pose0], [16667, pose0]], pose0)["ok"]), "a camera that never moved gives no pan")
	_fin()


# ---------------------------------------------------------------- the centrifuge lid leans like the hive's

# Item 2, Contract: the centrifuge lid's leaned pose has the hive lid's angle (+- 1 degree), at the centrifuge's LidLeanSpot.
func t_camera_lid_lean_matches_hive() -> void:
	var h: Dictionary = await _hive_setup()
	if h.is_empty():
		_fin()
		return
	var hive: Node = h["hive"]
	hive.call("open_lid")
	await _wait(float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.4)
	var tilt_hive: float = _lid_tilt(h["lid"] as Node3D)
	ck(tilt_hive > 55.0, "the hive lid leans (%.1f deg from flat)" % tilt_hive)
	# the centrifuge, in its own scene: the lid at the start (EMPTY), and again after a bottled batch
	_cleanup()
	_eco_reset()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	_set_cfg("base_seconds_per_jar", 1.0e9)
	_set_cfg("bottling_seconds_per_jar", 0.2)
	var c: Node = _nn(m, "Centrifuge")
	var lid: Node3D = c.find_child("Lid", true, false) as Node3D
	var lean: Node3D = c.find_child("LidLeanSpot", true, false) as Node3D
	ck(lid != null, "the centrifuge has a lid node named Lid")
	ck(lean != null, "the centrifuge has a LidLeanSpot marker (spec: the centrifuge has a lid-lean anchor)")
	if lid == null or lean == null:
		_fin()
		return
	await _frames(3)
	var t0: float = _lid_tilt(lid)
	ck(absf(t0 - tilt_hive) <= LEAN_TOL_DEG, "an EMPTY centrifuge's lid leans %.1f deg; the hive lid %.1f deg (+- %.0f deg)" % [t0, tilt_hive, LEAN_TOL_DEG])
	var cells: int = 20
	c.call("add_cells", cells, _jars_of(cells))
	c.call("close_lid")
	await _wait(float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + float(cv("close_delay_seconds")) + 0.4)
	var closed: float = _lid_tilt(lid)
	ck(closed >= 0.0 and closed < 10.0, "self-check: the closed lid is near flat (%.1f deg), so the lean is measured, not assumed" % closed)
	c.call("begin_crank")
	_crank_done(c)
	_begin_bottling(c)
	var empty: int = _st(c, "EMPTY")
	var done: bool = await _until(func() -> bool: return int(c.get("state")) == empty, float(cv("bottling_seconds_per_jar")) * 4.0 + 6.0)
	ck(done, "bottling ended (EMPTY)")
	await _wait(float(cv("barrel_stop_seconds")) + float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.5)
	var t1: float = _lid_tilt(lid)
	ck(absf(t1 - tilt_hive) <= LEAN_TOL_DEG, "after bottling the centrifuge lid leans %.1f deg; the hive lid %.1f deg (+- %.0f deg)" % [t1, tilt_hive, LEAN_TOL_DEG])
	ck(lid.global_position.distance_to(lean.global_position) <= 0.05, "the leaned lid sits at LidLeanSpot (%.3f units away)" % lid.global_position.distance_to(lean.global_position))
	ck(rad_to_deg(_angle_between(lid.global_basis, lean.global_basis)) <= LEAN_TOL_DEG, "the leaned lid's rotation is LidLeanSpot's (%.2f deg apart)" % rad_to_deg(_angle_between(lid.global_basis, lean.global_basis)))
	_fin()


# Item 2, Contract: one shared component, not a copy: both lids are driven by LidMotion (scripts/lid_motion.gd).
func t_camera_lid_component_shared() -> void:
	var uses: Dictionary = {}
	for f in ["hive.gd", "centrifuge.gd"]:
		var fa: FileAccess = FileAccess.open("res://scripts/" + f, FileAccess.READ)
		ck(fa != null, "scripts/%s can be read" % f)
		uses[f] = (fa.get_as_text().count("LidMotion.new(") if fa != null else 0)
		ck(int(uses[f]) >= 1, "%s drives its lid with LidMotion.new(...) (%d)" % [f, int(uses[f])])
	var lm: FileAccess = FileAccess.open("res://scripts/lid_motion.gd", FileAccess.READ)
	ck(lm != null and lm.get_as_text().contains("class_name LidMotion"), "scripts/lid_motion.gd is the shared LidMotion class")
	# the centrifuge must not bring its own copy of the tilt-and-lean path
	var cen_txt: String = FileAccess.open("res://scripts/centrifuge.gd", FileAccess.READ).get_as_text()
	var own_path: bool = false
	for line in cen_txt.split("\n"):
		var code: String = line.split("#")[0]
		if code.contains("create_tween") and code.to_lower().contains("lid"):
			own_path = true
	ck(not own_path, "centrifuge.gd has no tween of its own for the lid")
	_fin()
