extends "res://tests/test_truck_wait.gd"

# Quinn: 0.2 item 9, written from game/specs/0.2-first-automation.md before the code.
# "A full bucket no longer ends the first zoom or pans the camera: the player keeps harvesting (cells go to the pile), and when the zoom ends
# (all frames done, or Back) the camera returns to the farm view. The camera goes to the second stop only when Spin is tapped."
# Every number is read from the config; every tap is a real mouse event (farm_input.gd tap_at / drags).


func _zoom_closed(m: Node) -> bool:
	return int(m.get("zoom")) == 0


## In the open first zoom: scrape the frames the bucket needs with real drags; the bucket ends FULL and Capped frames are left.
func _fill_bucket_in_zoom(z: Dictionary) -> void:
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var frames: int = int(ceil(float(_bucket_cells()) / float(_cpf())))
	for k in frames:
		var f: int = await _scrape_risen(m, p["Hive"], tr)
		ck(await _next_frame(tr, f), "fill: frame %d done, the next frame rose" % f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)


## Step 1: the full bucket leaves the zoom open (no pan, still harvesting, cells go to the pile).
func _ck_zoom_stays_open(z: Dictionary, label: String, paused_crank: bool = false) -> void:
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var cen: Node = p["Centrifuge"]
	# paused_crank: run 1's Spin left the crank paused as CRANKING (0.1.4 item 15); reopening the zoom keeps it
	eq(cen.get("state"), _st(cen, "CRANKING" if paused_crank else "FULL"), "%s: the bucket is %s" % [label, "paused CRANKING" if paused_crank else "FULL"])
	ck(not _zoom_closed(m), "%s: the zoom is still open with a full bucket" % label)
	near(_cam().size, float(cv("zoom_size")), 0.05, "%s: the camera stays at the first zoom (no pan)" % label)
	eq(bool(m.call("at_second_stop")), false, "%s: not at the second stop" % label)
	ck(int(tr["risen"]) >= 0, "%s: a frame is risen, the player keeps harvesting" % label)
	var pile: Node = p["Pile"]
	var before: int = int(pile.get("cells"))
	if int(tr["risen"]) >= 0:
		await _scrape_risen(m, p["Hive"], tr, 1)
		await _wait(float(cv("cell_fly_seconds")) + 0.3)
		ck(int(pile.get("cells")) > before, "%s: cells scraped with a full bucket go to the pile (%d -> %d)" % [label, before, int(pile.get("cells"))])


## Step 2/3: the zoom has ended: the camera is at the pose the farm view started with, not at the second stop.
func _ck_farm_pose(z: Dictionary, label: String, spun_before: bool = false) -> void:
	var m: Node = z["m"]
	var farm: Dictionary = z["farm"]
	var closed: bool = await _until(func() -> bool: return _zoom_closed(m), float(cv("zoom_seconds")) + _zoom_settle() + 8.0)
	ck(closed, "%s: the zoom ended" % label)
	await _wait(_zoom_settle() + 0.3)
	ck(not farm.is_empty(), "%s: the farm pose was recorded before the zoom" % label)
	if farm.is_empty():
		return
	near(_cam().size, float(farm["size"]), 0.02, "%s: camera size is the farm view's" % label)
	ck(_cam().global_position.distance_to(farm["pos"] as Vector3) < 0.02, "%s: camera position is the farm view's (off by %.3f)" % [label, _cam().global_position.distance_to(farm["pos"] as Vector3)])
	ck(absf(_cam().size - float(cv("pan_zoom_size"))) > 0.5, "%s: the camera is not at the second stop's size %s" % [label, str(cv("pan_zoom_size"))])
	eq(bool(m.call("at_second_stop")), false, "%s: at_second_stop is false after the zoom ends with no Spin" % label)
	eq(bool(m.get("_spin_mode")), spun_before, "%s: spin mode %s" % [label, "stays on from the earlier Spin (paused crank)" if spun_before else "off without a Spin tap"])


## Step 3: a real tap on Spin from the farm view reaches the second stop. Returns the camera size there.
func _spin_to_second_stop(z: Dictionary, label: String) -> float:
	var m: Node = z["m"]
	var spin: Control = (z["p"] as Dictionary)["CentrifugeIcon"]
	ck(_shown(spin), "%s: Spin shows on the farm view" % label)
	await fi.tap_at(spin.get_global_rect().get_center())
	var reached: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01 and bool(m.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(0.4)
	ck(reached, "%s: Spin from the farm view reaches the second stop (size %.3f, pan_zoom_size %s)" % [label, _cam().size, str(cv("pan_zoom_size"))])
	return _cam().size


func _tap_back(z: Dictionary) -> void:
	await fi.tap_at(((z["p"] as Dictionary)["BackButton"] as Control).get_global_rect().get_center())


# goal T9.1
## Sequence: fill the bucket in the first zoom (stays open), leave by Back, farm pose, Spin to the second stop; come back (Back, Harvest again)
## and do it a second time on the same scene; then the other exit (every frame done) on a fresh scene: all runs match.
func t_zoom_end_farm_pose_then_spin_second_stop_twice() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	await _fill_bucket_in_zoom(z)
	await _ck_zoom_stays_open(z, "run 1")
	await _tap_back(z)   # exit: Back
	await _ck_farm_pose(z, "run 1 (Back)")
	var s1: float = await _spin_to_second_stop(z, "run 1")
	# come back and do it a second time: Back from the second stop, Harvest again (frames are still Capped), Back from the zoom
	(z["tr"] as Dictionary)["risen"] = -1
	var raised: bool = await _open_zoom(m, z["p"], z["tr"])
	ck(raised, "run 2: Harvest again opens the zoom")
	if raised:
		await _ck_zoom_stays_open(z, "run 2", true)
		await _tap_back(z)
		await _ck_farm_pose(z, "run 2 (Back)", true)
		var s2: float = await _spin_to_second_stop(z, "run 2")
		near(s2, s1, 0.01, "run 2 reached the same second stop as run 1")
	# the other exit: every frame done, on a fresh scene
	m.get_parent().remove_child(m)
	_to_free.erase(m)
	m.free()
	var z3: Dictionary = await _zoom_open_main()
	if z3.is_empty():
		_fin()
		return
	await _fill_bucket_in_zoom(z3)
	await _ck_zoom_stays_open(z3, "run 3")
	var done: bool = await _uncap_all(z3["m"], z3["p"], z3["tr"])
	ck(done, "run 3: every frame was uncapped with real drags")
	await _ck_farm_pose(z3, "run 3 (all frames done)")
	var s3: float = await _spin_to_second_stop(z3, "run 3")
	near(s3, s1, 0.01, "run 3 reached the same second stop as run 1")
	_fin()
