extends "res://tests/test_flight.gd"

# Quinn: 0.2 item 3 (Heated Uncapping Fork), written from game/specs/0.2-first-automation.md (item 3) and game/specs/0.2-node-handoff.md, not from the code.
# T3.1: reach and the post-automation yield; T3.2: the fork prop's look. Every expected number is read from the config.
# Black box: the player drags with real mouse events (window pixels) over the risen frame's cells; the cells uncapped are the cell_scraped
# signal's; the fork prop is the node named UncapFork (handoff) with the Head and Handle groups.


## A fresh main, Heated Fork at `level`, a full frozen hive, the first zoom open. {} when it could not be set up.
func _fork_setup(level: int) -> Dictionary:
	_portrait()
	var e: Node = _eco()
	e.call("reset")
	e.call("set_level", "heated_fork", level)
	var m: Node = await _mk_main()
	if m == null:
		return {}
	var p: Dictionary = _parts(m)
	if p.is_empty():
		return {}
	var hive: Node = p["Hive"]
	var tr: Dictionary = _track(hive)
	_full_hive_frozen(hive)
	await _frames(3)
	var raised: bool = await _open_zoom(m, p, tr)
	ck(raised, "Heated %d: the zoom opened with a risen frame" % level)
	var hc: Node = m.find_child("Honeycomb", true, false)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	if not raised or hc == null or cam == null:
		return {}
	var cells: Dictionary = {}   # cell index -> {local: Vector3 in the Honeycomb's frame, screen: Vector2 in viewport px}
	var sum: Vector3 = Vector3.ZERO
	for c in fi.cells(hc):
		var lp: Vector3 = hc.to_local((c as Node3D).global_position)
		cells[int(c.get_meta("cell_index"))] = {"local": lp, "screen": cam.unproject_position((c as Node3D).global_position)}
		sum += lp
	ck(cells.size() >= 2, "Heated %d: the risen frame shows its cells (%d)" % [level, cells.size()])
	var scraped: Array = []   # [cell, jar value] in the order the drag uncapped them
	hc.connect("cell_scraped", func(c: Variant, v: Variant, _w: Variant) -> void: scraped.append([int(c), float(v)]))
	return {"m": m, "p": p, "hc": hc, "cam": cam, "cells": cells, "centre": sum / float(maxi(cells.size(), 1)), "scraped": scraped, "tr": tr}


func _fork_drop(s: Dictionary) -> void:
	var m: Node = s.get("m") as Node
	if m != null and is_instance_valid(m):
		m.get_parent().remove_child(m)
		m.free()


## The cell nearest the frame's centre (it has neighbours on every side the grid allows).
func _fork_mid_cell(s: Dictionary) -> int:
	var best: int = -1
	var bd: float = 1.0e9
	for i in (s["cells"] as Dictionary):
		var d: float = ((s["cells"][i]["local"]) as Vector3).distance_to(s["centre"] as Vector3)
		if d < bd:
			bd = d
			best = int(i)
	return best


## One drag point: a real press on a cell's centre, then the release; the scraped list gets the cells it uncapped.
func _fork_one_point(s: Dictionary, cell: int) -> void:
	var pt: Vector2 = s["cells"][cell]["screen"]
	fi.mouse_button(pt, true)
	await _frames(1)
	fi.mouse_button(pt, false)
	await _frames(3)


## Cells within `reach` pitches of the hit cell, the spec's set, from the config.
func _fork_expected(s: Dictionary, hit: int, level: int) -> Array:
	var reach: float = float(cv("uncap_radius")) * (1.0 + float(cv("heated_fork_radius_bonus_per_level")) * float(level))
	var pitch: float = float((s["hc"] as Node).get("cell_pitch"))
	var out: Array = []
	var o: Vector3 = s["cells"][hit]["local"]
	for i in (s["cells"] as Dictionary):
		var lp: Vector3 = s["cells"][i]["local"]
		out.append([int(i), Vector2(lp.x - o.x, lp.z - o.z).length() / pitch, reach])
	return out


## One drag point at Heated 0 uncaps one cell; at Heated 5 more, and each lies within uncap_radius x (1 + bonus x level) of the hit cell.
# goal T3.1
func t_fork_reach_by_level() -> void:
	var results: Dictionary = {}
	var max_l: int = int(cv("heated_fork_max_level"))
	for level in [0, max_l]:
		var s: Dictionary = await _fork_setup(level)
		if s.is_empty():
			_fin()
			return
		var hit: int = _fork_mid_cell(s)
		var table: Array = _fork_expected(s, hit, level)
		await _fork_one_point(s, hit)
		var got: Array = []
		for r in (s["scraped"] as Array):
			got.append(int(r[0]))
		got.sort()
		var want: Array = []
		var reach: float = 0.0
		for row in table:
			reach = float(row[2])
			if float(row[1]) <= reach + 0.001:
				want.append(int(row[0]))
		want.sort()
		ck(got.has(hit), "Heated %d: the drag point's own cell %d is uncapped" % [level, hit])
		for c in got:
			var dist: float = 0.0
			for row in table:
				if int(row[0]) == int(c):
					dist = float(row[1])
			ck(dist <= reach + 0.01, "Heated %d: uncapped cell %d lies %.2f pitches from the hit, within the reach %.2f" % [level, int(c), dist, reach])
		eq(got, want, "Heated %d: exactly the capped cells within reach %.2f pitches of the hit are uncapped" % [level, reach])
		results[level] = got.size()
		_fork_drop(s)
	eq(int(results.get(0, -1)), 1, "Heated 0: one drag point uncaps one cell")
	ck(int(results.get(max_l, 0)) > int(results.get(0, 99)), "Heated %d uncaps more cells (%s) than Heated 0 (%s) on the same drag point" % [max_l, str(results.get(max_l)), str(results.get(0))])
	_eco().call("reset")
	_fin()


## With "own auto-scraper" on, each cell's yield is cell_value x (1 + heated_fork_post_auto_yield_bonus_per_level x level); off, no effect.
# goal T3.1
func t_fork_post_auto_yield_bonus() -> void:
	var max_l: int = int(cv("heated_fork_max_level"))
	var bonus: float = float(cv("heated_fork_post_auto_yield_bonus_per_level"))
	for case in [[0, true], [max_l, true], [max_l, false]]:
		var level: int = int(case[0])
		var on: bool = bool(case[1])
		_set_cfg("dev_own_auto_scraper", on)
		var s: Dictionary = await _fork_setup(level)
		if s.is_empty():
			_fin()
			return
		await _fork_one_point(s, _fork_mid_cell(s))
		var want: float = _cell_value() * ((1.0 + bonus * float(level)) if on else 1.0)
		ck((s["scraped"] as Array).size() >= 1, "Heated %d, auto-scraper %s: the drag uncapped a cell" % [level, str(on)])
		for r in (s["scraped"] as Array):
			near(float(r[1]), want, "Heated %d, auto-scraper %s: cell %d yields cell_value x %.2f" % [level, str(on), int(r[0]), want / _cell_value()], 0.0001)
		_fork_drop(s)
	_eco().call("reset")
	_fin()


## Screen distance (viewport px) from a world point's projection to a viewport point.
func _fork_px(s: Dictionary, fork: Node3D, pt: Vector2) -> float:
	return (s["cam"] as Camera3D).unproject_position(fork.global_position).distance_to(pt)


## A viewport point whose camera ray hits no cell collider and no stopping Control (the spot where a drag is not over the combs).
func _fork_empty_point(s: Dictionary) -> Vector2:
	var cam: Camera3D = s["cam"]
	var space: PhysicsDirectSpaceState3D = (s["hc"] as Node3D).get_world_3d().direct_space_state
	for y in [1180.0, 1100.0, 1000.0, 900.0]:
		for x in [360.0, 120.0, 600.0, 240.0, 480.0]:
			var pt := Vector2(x, y)
			if fi.blocked(s["m"], pt):
				continue
			var from: Vector3 = cam.project_ray_origin(pt)
			if space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(pt) * 200.0)).is_empty():
				return pt
	return Vector2(-1.0, -1.0)


## The fork prop: not shown from a press away from the combs; shown within button_screen_margin of the drag point from a press on the
## combs, following the drag; hidden on release; and the same again for a second drag (sequence test: start, follow, end, twice).
## Exits mid-drag (Back, zoom out, app pause) are open questions in the report: the spec does not say what they do to the prop.
# goal T3.2
func t_fork_prop_follows_drag_twice() -> void:
	var s: Dictionary = await _fork_setup(0)
	if s.is_empty():
		_fin()
		return
	var fork: Node3D = s["m"].find_child("UncapFork", true, false) as Node3D
	ck(fork != null, "FarmWorld/UncapFork exists (handoff)")
	if fork == null:
		_fin()
		return
	var margin: float = float(cv("button_screen_margin"))
	ck(not fork.visible, "before any drag the fork prop is hidden")
	# step 1: a drag that starts away from the combs shows no fork
	var away: Vector2 = _fork_empty_point(s)
	ck(away.x >= 0.0, "found a screen point away from the combs and the controls")
	fi.mouse_button(away, true)
	await _frames(1)
	fi.mouse_move(away + Vector2(10.0, 0.0))
	await _frames(1)
	ck(not fork.visible, "step 1: a drag that starts away from the combs shows no fork")
	fi.mouse_button(away, false)
	await _frames(2)
	var ids: Array = (s["cells"] as Dictionary).keys()
	ids.sort()
	var runs: Array = []
	for n in 2:
		var a: int = int(ids[n * 2])
		var b: int = int(ids[n * 2 + 1])
		var pa: Vector2 = s["cells"][a]["screen"]
		var pb: Vector2 = s["cells"][b]["screen"]
		var run: Dictionary = {}
		fi.mouse_button(pa, true)
		await _frames(2)
		run["shown"] = fork.visible
		run["near_start"] = _fork_px(s, fork, pa) <= margin
		var start_pos: Vector3 = fork.global_position
		for st in range(1, 7):
			fi.mouse_move(pa.lerp(pb, float(st) / 6.0))
			await _frames(1)
		await _frames(1)
		run["shown_moving"] = fork.visible
		run["near_end"] = _fork_px(s, fork, pb) <= margin
		run["moved"] = fork.global_position.distance_to(start_pos) > 0.01
		fi.mouse_button(pb, false)
		await _frames(2)
		run["hidden_after"] = not fork.visible
		ck(bool(run["shown"]), "drag %d: the fork prop is shown while the drag is on the combs" % (n + 1))
		ck(bool(run["near_start"]), "drag %d: the fork is within button_screen_margin (%.0f px) of the first drag point" % [n + 1, margin])
		ck(bool(run["shown_moving"]) and bool(run["near_end"]) and bool(run["moved"]), "drag %d: the fork follows the drag point (within %.0f px of the last point)" % [n + 1, margin])
		ck(bool(run["hidden_after"]), "drag %d: the fork prop is hidden after the drag ends" % (n + 1))
		runs.append(run)
	eq(runs[1], runs[0], "twice: the second drag shows, follows and hides the fork as the first did")
	_fork_drop(s)
	_eco().call("reset")
	_fin()


## sRGB colour -> CIE Lab (D65), for the palette's delta E.
func _lab(c: Color) -> Vector3:
	var lin: Array = []
	for v in [c.r, c.g, c.b]:
		lin.append(pow((float(v) + 0.055) / 1.055, 2.4) if float(v) > 0.04045 else float(v) / 12.92)
	var x: float = (0.4124 * lin[0] + 0.3576 * lin[1] + 0.1805 * lin[2]) / 0.95047
	var y: float = 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
	var z: float = (0.0193 * lin[0] + 0.1192 * lin[1] + 0.9505 * lin[2]) / 1.08883
	var f: Array = []
	for t in [x, y, z]:
		f.append(pow(float(t), 1.0 / 3.0) if float(t) > 0.008856 else 7.787 * float(t) + 16.0 / 116.0)
	return Vector3(116.0 * f[1] - 16.0, 500.0 * (f[0] - f[1]), 200.0 * (f[1] - f[2]))


func _delta_e(a: Color, b: Color) -> float:
	return _lab(a).distance_to(_lab(b))


## The head's MeshInstance3D materials (one StandardMaterial3D each; handoff: all share one) and the handle's.
func _fork_mats(fork: Node, group: String) -> Array:
	var out: Array = []
	var g: Node = fork.find_child(group, true, false)
	if g == null:
		return out
	for n in g.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n as MeshInstance3D
		var mat: Material = mi.material_override if mi.material_override != null else mi.get_active_material(0)
		out.append(mat)
	return out


## Samples of [seconds since the press, head colour] every frame over `secs`, checking each frame that every head mesh shows the same colour
## and that emission is off.
func _fork_sample(fork: Node, secs: float, label: String) -> Array:
	var out: Array = []
	var t0: int = _gms()
	var heads: Array = _fork_mats(fork, "Head")
	while float(_gms() - t0) < secs * 1000.0:
		await process_frame
		var c0: Color = (heads[0] as StandardMaterial3D).albedo_color
		for h in heads:
			var sm: StandardMaterial3D = h as StandardMaterial3D
			ck(sm != null and not sm.emission_enabled, "%s: emission stays off on every head mesh" % label)
			if sm != null:
				ck(_delta_e(sm.albedo_color, c0) < 0.5, "%s: every head mesh (tines, crossbar, ferrule) has the same colour at once" % label)
		out.append([float(_gms() - t0) / 1000.0, c0])
	return out


## At Heated 0 the head stays steel (and the handle wood) during a drag; at Heated >= 1 it eases steel -> crank orange -> steel once per
## fork_pulse_seconds, as an albedo tween with no emission, the handle unchanged.
# goal T3.2
func t_fork_head_colour_by_level() -> void:
	var steel: Color = (load("res://materials/steel.tres") as StandardMaterial3D).albedo_color
	var orange := Color(0.95, 0.50, 0.20)   # STYLE_GUIDE Accent: crank orange
	var pulse: float = float(cv("fork_pulse_seconds"))
	for level in [0, 3]:
		var s: Dictionary = await _fork_setup(level)
		if s.is_empty():
			_fin()
			return
		var fork: Node = s["m"].find_child("UncapFork", true, false)
		ck(fork != null, "Heated %d: UncapFork exists" % level)
		if fork == null:
			_fork_drop(s)
			continue
		var heads: Array = _fork_mats(fork, "Head")
		var handles: Array = _fork_mats(fork, "Handle")
		ck(heads.size() >= 9 and handles.size() >= 1, "Heated %d: the fork has a head (tines, crossbar, ferrule: %d meshes) and a handle (%d)" % [level, heads.size(), handles.size()])
		if heads.is_empty() or handles.is_empty():
			_fork_drop(s)
			continue
		var wood: Color = (handles[0] as StandardMaterial3D).albedo_color
		# Spec 0.2 item 10: "it hides ... when the frame or zoom ends during a drag". At Heated 3 the wide reach can finish the whole
		# frame on the press and hide the fork, so keep the reach at level 0 (honeycomb hook) and the pulse at `level` (fork hook).
		(fork as UncapFork).heated_level_override = level
		s["hc"].heated_level_override = 0
		var pt: Vector2 = s["cells"][_fork_mid_cell(s)]["screen"]
		fi.mouse_button(pt, true)
		await _frames(1)
		var samples: Array = await _fork_sample(fork, pulse * 2.0, "Heated %d" % level)
		ck(samples.size() >= 8, "Heated %d: enough frames sampled over two pulses (%d)" % [level, samples.size()])
		var lab: String = "Heated %d" % level
		if level == 0:
			for smp in samples:
				ck(_delta_e(smp[1], steel) <= 2.0, "%s: the head stays steel at t=%.2f s (dE %.1f)" % [lab, float(smp[0]), _delta_e(smp[1], steel)])
		else:
			var best_peak: Array = [99.0, 0.0, 99.0, 0.0]   # [dE to orange, time] in each pulse's middle half
			var near_start: float = 99.0
			var near_end: float = 99.0
			var far_mid: float = 0.0
			for smp in samples:
				var t: float = float(smp[0])
				var u: float = t / pulse
				var de_o: float = _delta_e(smp[1], orange)
				var de_s: float = _delta_e(smp[1], steel)
				if u >= 0.25 and u <= 0.75 and de_o < float(best_peak[0]):
					best_peak[0] = de_o
					best_peak[1] = t
				if u >= 1.25 and u <= 1.75 and de_o < float(best_peak[2]):
					best_peak[2] = de_o
					best_peak[3] = t
				if u <= 0.1:
					near_start = minf(near_start, de_s)
				if u >= 0.9 and u <= 1.1:
					near_end = minf(near_end, de_s)
				if u >= 0.4 and u <= 0.6:
					far_mid = maxf(far_mid, de_s)
			ck(float(best_peak[0]) <= 12.0, "%s: at the first pulse's peak the head reaches crank orange (best dE %.1f at %.2f s, want <= 12)" % [lab, best_peak[0], best_peak[1]])
			ck(float(best_peak[2]) <= 12.0, "%s: at the second pulse's peak the head reaches crank orange again (best dE %.1f at %.2f s)" % [lab, best_peak[2], best_peak[3]])
			ck(near_start <= 12.0, "%s: the pulse starts at steel (dE %.1f)" % [lab, near_start])
			ck(near_end <= 12.0, "%s: one fork_pulse_seconds (%.2f s) later the head is back to steel (dE %.1f)" % [lab, pulse, near_end])
			ck(far_mid > 12.0, "%s: mid-pulse the head is far from steel (dE %.1f): the albedo changes over the pulse" % [lab, far_mid])
		for h in handles:
			ck(_delta_e((h as StandardMaterial3D).albedo_color, wood) < 0.5 and not (h as StandardMaterial3D).emission_enabled, "%s: the handle stays wood, no emission" % lab)
		fi.mouse_button(pt, false)
		await _frames(2)
		_fork_drop(s)
	_eco().call("reset")
	_fin()
