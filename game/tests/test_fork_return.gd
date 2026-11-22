extends "res://tests/test_journal.gd"

# Quinn: 0.2 item 10 (the fork goes back into the Harvest icon), written from game/specs/0.2-first-automation.md (item 10) and
# game/specs/0.2-node-handoff.md, not from the code. Expected numbers are read from the config (fork_return_seconds, button_screen_margin).
# Black box: real mouse events in window pixels; the prop is the node named UncapFork; the icon is ForkIcon; the zoom ended is main.zoom == 0.


## One run in an open zoom (frames raised, Harvest tapped): a released drag hides the fork; then one held press over every cell of the
## last frame; sample every frame until the zoom ends and the fork hides; then release. Returns the measurements.
func _fork_return_run(m: Node, p: Dictionary, tr: Dictionary, fork: Node3D, label: String) -> Dictionary:
	var out: Dictionary = {}
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var hc: Node = m.find_child("Honeycomb", true, false)
	# step 1: a drag that is released, wherever it ends, leaves no fork on screen
	var rows: Array = fi.rows(hc, cam)
	await fi.drag_row(rows[0])
	await _frames(2)
	out["hidden_after_release"] = not fork.visible
	ck(bool(out["hidden_after_release"]), "%s: after a released drag the fork prop is hidden" % label)
	# step 2: the press stays held while the last frame ends
	var held: Dictionary = await _drag_last_frame_held(m, p, tr)
	ck(bool(held["ok"]), "%s: every frame was uncapped by real drags and the last one by a press that is still held" % label)
	var zoom_ended: int = -1
	var hidden_at: int = -1
	var shown_at_end: bool = false
	var last_pt: Vector2 = Vector2(-1.0e6, -1.0e6)
	var secs: float = float(cv("fork_return_seconds"))
	var t0: int = _gms()
	var deadline: float = float(cv("zoom_seconds")) + _zoom_settle() + 8.0 + secs
	while float(_gms() - t0) < deadline * 1000.0:
		await process_frame
		var now: int = _gms()
		var ended: bool = int(m.get("zoom")) == 0
		if ended and zoom_ended < 0:
			zoom_ended = now
			shown_at_end = fork.visible
		if fork.visible:
			last_pt = cam.unproject_position(fork.global_position)
		if zoom_ended >= 0 and not fork.visible:
			hidden_at = now
			break
	out["zoom_ended"] = zoom_ended >= 0
	out["shown_at_end"] = shown_at_end
	out["hidden_in_time"] = hidden_at >= 0 and float(hidden_at - zoom_ended) <= (secs + 0.1) * 1000.0
	var icon: Control = p["ForkIcon"] as Control
	var icon_c: Vector2 = icon.get_global_rect().get_center()
	var margin: float = float(cv("button_screen_margin"))
	out["near_icon"] = last_pt.distance_to(icon_c) <= margin
	ck(zoom_ended >= 0, "%s: the zoom ended (zoom NONE) with the press still held" % label)
	ck(shown_at_end, "%s: the fork prop is still on screen when the zoom ends (it flies into the icon)" % label)
	ck(bool(out["hidden_in_time"]), "%s: the fork prop is hidden within fork_return_seconds (%.2f) + 0.1 s of the zoom ending (took %s ms)" % [label, secs, str(hidden_at - zoom_ended) if hidden_at >= 0 else "never"])
	ck(bool(out["near_icon"]), "%s: the fork's last shown screen point %s is within button_screen_margin (%.0f px) of the Harvest icon's centre %s" % [label, str(last_pt), margin, str(icon_c)])
	# step 3: releasing the press afterwards leaves it hidden and the prop at its normal scale
	fi.mouse_button(held["hold"], false)
	await _frames(3)
	out["hidden_after_hold_release"] = not fork.visible
	ck(bool(out["hidden_after_hold_release"]), "%s: after the held press is released the fork prop stays hidden" % label)
	return out


## Held press at the last frame's end, twice in one session: the fork goes back into the Harvest icon, hides in time, comes back at its
## normal size for the second run, and the second run matches the first. Exits mid-drag (Back, app pause) are open questions.
# goal T10.1
func t_fork_returns_to_icon_twice() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var fork: Node3D = m.find_child("UncapFork", true, false) as Node3D
	ck(fork != null, "FarmWorld/UncapFork exists (handoff)")
	if fork == null:
		_fin()
		return
	var scale0: Vector3 = fork.scale
	var runs: Array = []
	for n in 2:
		var label: String = "run %d" % (n + 1)
		var r: Dictionary = await _fork_return_run(m, p, tr, fork, label)
		eq(fork.scale, scale0, "%s: once hidden the fork prop is back at its normal scale" % label)
		runs.append(r)
		if n == 0:
			await _wait(_zoom_settle() + 0.3)
			tr["risen"] = -1
			_full_hive_frozen(p["Hive"])
			await _frames(3)
			var raised: bool = await _open_zoom(m, p, tr)
			ck(raised, "Harvest again for run 2: a frame rises")
			await _wait(_zoom_settle())
	eq(runs[1], runs[0], "twice: the second run hides and returns the fork as the first run did")
	_eco().call("reset")
	_fin()
