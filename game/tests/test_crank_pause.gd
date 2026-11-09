extends "res://tests/test_hive_model.gd"

# Quinn: 0.1.4 item 15, written from game/specs/0.1.4-ui-placement.md ("Leaving the centrifuge stops the crank") before the code.
# Every tap is a real mouse event pushed into the viewport in window pixels (farm_input.gd). Expected numbers come from the config.


## Pan to the second stop (bucket FULL, Capped frames left), then a real tap on Spin: the crank runs there. {m, p, cen} or {}.
func _cranking_at_second_stop() -> Dictionary:
	var s: Dictionary = await _second_stop_with_capped()
	if s.is_empty():
		return {}
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var cen: Node = p["Centrifuge"]
	var spin: Control = p["CentrifugeIcon"]
	ck(_shown(spin), "Spin shows at the second stop")
	await fi.tap_at(spin.get_global_rect().get_center())
	await _frames(3)
	eq(cen.get("state"), _st(cen, "CRANKING"), "a real tap on Spin starts the crank at the second stop")
	return {"m": m, "p": p, "cen": cen}


## One real tap in free screen space, then wait out the tap-rate cap so the next tap is not capped.
func _tap_free(m: Node) -> void:
	await fi.tap_at(fi.free_spot(m))
	await _wait(_tap_gap())


## item 15: "Back at the second stop while cranking pauses the crank: no turn counts outside the second stop, and progress is kept.
## Spin shows again in the farm view while a crank is paused, and tapping it pans back to the second stop, where the crank resumes."
func t_crank_pauses_on_back_and_resumes_on_spin() -> void:
	var s: Dictionary = await _cranking_at_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var cen: Node = s["cen"]
	var spin: Control = p["CentrifugeIcon"]
	# positive control: at the second stop a real tap counts a turn (the test can fail if taps never count)
	var t0: int = int(cen.get("turns_counted"))
	for i in 3:
		await _tap_free(m)
	var progress: int = int(cen.get("turns_counted"))
	ck(progress >= t0 + 1, "positive control: real taps at the second stop count turns (%d -> %d)" % [t0, progress])
	ck(progress < _turns_for(_bucket_cells()), "the crank is part-way, not finished (%d of %d turns)" % [progress, _turns_for(_bucket_cells())])
	# Back from the second stop while cranking
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	await _until(func() -> bool: return not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	eq(bool(m.call("at_second_stop")), false, "Back leaves the second stop")
	ck(_cam().size > float(cv("pan_zoom_size")) + 0.5, "the camera is on the farm view (size %.3f)" % _cam().size)
	var kept: int = int(cen.get("turns_counted"))
	eq(kept, progress, "Back itself counted no turn and progress is kept")
	# later-fix 1 (designer, 2026-11-08): the centrifuge text shows only on the spin screen, so Back from a started spin hides it
	var lab: Control = m.find_child("CentrifugeLabel", true, false) as Control
	ck(lab != null and not lab.is_visible_in_tree(), "the centrifuge text is hidden in the farm view while a crank is paused")
	# taps in the farm view count no turns
	for i in 5:
		await _tap_free(m)
	await fi.tap_at(fi.free_spot(m))
	await _wait(1.0)
	eq(int(cen.get("turns_counted")), progress, "taps in the farm view count no turns: the crank's progress is unchanged")
	# a hold in the farm view counts none either
	var hold_at: Vector2 = fi.free_spot(m)
	_push_mouse(hold_at, true)
	await _wait(1.0)
	_push_mouse(hold_at, false)
	eq(int(cen.get("turns_counted")), progress, "a hold in the farm view counts no turn")
	# Spin shows while the crank is paused
	ck(_shown(spin), "Spin shows in the farm view while a crank is paused")
	# item 22: in the farm view Spin is drawn at spin_farm_visual_px, its touch rect stays at least 120 x 120
	var vs: Vector2 = spin.call("visible_size")
	eq(int(round(vs.x)), int(cv("spin_farm_visual_px")) + int(spin.size.x) - 120, "item 22: Spin's drawn size in the farm view is spin_farm_visual_px (%s)" % str(vs))
	ck(spin.size.x >= 120.0 and spin.size.y >= 120.0, "item 22: Spin's touch rect stays at least 120 x 120 (%s)" % str(spin.size))
	# tapping it returns to the second stop, where turns count again
	await fi.tap_at(spin.get_global_rect().get_center())
	var back: bool = await _until(func() -> bool: return absf(_cam().size - float(cv("pan_zoom_size"))) < 0.01 and bool(m.call("at_second_stop")), float(cv("camera_pan_seconds")) + _zoom_settle() + float(cv("zoom_seconds")) + 4.0)
	await _wait(0.4)
	ck(back, "tapping Spin pans back to the second stop (size %s)" % str(_cam().size))
	eq(cen.get("state"), _st(cen, "CRANKING"), "the crank is still the same crank: CRANKING at the second stop")
	eq(int(cen.get("turns_counted")), progress, "resuming kept the progress (no turn lost or added by the pan)")
	ck(lab != null and lab.is_visible_in_tree(), "the centrifuge text shows again at the second stop")
	var vs2: Vector2 = spin.call("visible_size")
	eq(int(round(vs2.x)), int(cv("icon_visual_px")) + int(spin.size.x) - 120, "item 22: at the second stop Spin is drawn at icon_visual_px again (%s)" % str(vs2))
	await _wait(_tap_gap())
	await _tap_free(m)
	eq(int(cen.get("turns_counted")), progress + 1, "at the second stop again a real tap counts a turn from where it stopped")
	_fin()


## The same rule from the other side: Spin must show in the farm view while paused, and taps there must not finish the bucket,
## however many (self-check: enough taps to finish it by the config's turn count are sent, and none counts).
func t_paused_crank_never_finishes_in_farm_view() -> void:
	var s: Dictionary = await _cranking_at_second_stop()
	if s.is_empty():
		_fin()
		return
	var m: Node = s["m"]
	var p: Dictionary = s["p"]
	var cen: Node = s["cen"]
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	await _until(func() -> bool: return not bool(m.call("at_second_stop")) and _cam().size > float(cv("pan_zoom_size")) + 0.5, float(cv("camera_pan_seconds")) + _zoom_settle() + 4.0)
	await _wait(_zoom_settle() + float(cv("zoom_seconds")))
	var n: int = _turns_for(_bucket_cells())
	for i in n + 2:
		await _tap_free(m)
	eq(int(cen.get("turns_counted")), 0, "%d taps in the farm view counted no turn" % (n + 2))
	eq(cen.get("state"), _st(cen, "CRANKING"), "the crank is paused, not finished or bottling")
	ck(_shown(p["CentrifugeIcon"]), "Spin shows while the crank is paused")
	_fin()
