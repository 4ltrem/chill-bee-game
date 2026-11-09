extends "res://tests/test_combs.gd"

# Quinn: 0.1.4 item 12 tests, written from game/specs/0.1.4-ui-placement.md (item 12), not from the code.
# T12.1: with no motor owned, the centrifuge never spins while the camera is in the farm view or the first zoom, including after a pour with
#        a pile waiting. Spec: it spins only at the second stop, cranked by the player; the motor (GDD Automation) is never owned in Phase 1.
# Black box: "spun" = the centrifuge state is CRANKING, DONE or BOTTLING (read through the enum by name); the motor is the `motor_owned`
# flag on the main node (spec: "once the motor is owned"). Every number (capacity, seconds) comes from the config.


func _spun(cen: Node) -> bool:
	var s: Variant = cen.get("state")
	return s == _st(cen, "CRANKING") or s == _st(cen, "DONE") or s == _st(cen, "BOTTLING")


## Samples the state every 0.1 game seconds for `secs`; true if the centrifuge ever spun.
func _spun_within(cen: Node, secs: float) -> bool:
	var steps: int = int(ceil(secs / 0.1))
	for i in steps:
		await _wait(0.1)
		if _spun(cen):
			return true
	return _spun(cen)


func _watch_secs() -> float:
	return float(cv("cell_fly_seconds")) + _lid_t() + float(cv("camera_pan_seconds")) + float(cv("pile_load_stagger_seconds")) * 10.0 + 3.0


## Farm view, bucket empty and open, a pile waiting, spin mode on (as after a pour at the second stop and a Back): the pour finishes.
## Returns {spun, full, auto, farm} for the run; `motor` sets the motor flag first.
func _pour_in_farm_view(motor: bool) -> Dictionary:
	var out: Dictionary = {"ok": false}
	var m: Node = await _mk_main()
	if m == null:
		return out
	var p: Dictionary = _parts(m)
	if p.is_empty():
		return out
	var cen: Node = p["Centrifuge"]
	var pile: Node = p["Pile"]
	var cap: int = _bucket_cells()
	m.set("motor_owned", motor)
	ck(_cam().size > float(cv("pan_zoom_size")) + 0.5, "precondition: the camera is on the farm view (size %.3f)" % _cam().size)
	eq(bool(m.call("at_second_stop")), false, "precondition: not at the second stop")
	eq(cen.get("state"), _st(cen, "EMPTY"), "precondition: the bucket is empty")
	ck(bool(cen.get("lid_open")), "precondition: the bucket is open")
	pile.call("add", cap + 4, float(cv("frame_jars")))
	pile.call("land", cap + 4)
	ck(int(pile.get("cells")) == cap + 4, "precondition: the pile holds %d cells" % (cap + 4))
	m.set("_spin_mode", true)
	cen.emit_signal("bottling_done", 0)
	var spun: bool = false
	var full: bool = false
	for i in int(ceil(_watch_secs() / 0.1)):
		await _wait(0.1)
		full = full or cen.get("state") == _st(cen, "FULL")
		if _spun(cen):
			spun = true
			break
	out = {"ok": true, "spun": spun, "full": full, "auto": bool(m.get("_auto_spin")), "farm": _cam().size > float(cv("pan_zoom_size")) + 0.5,
			"second": bool(m.call("at_second_stop")), "cen": cen, "icon": p["CentrifugeIcon"], "m": m}
	return out


## The motor flag starts false: Phase 1 never owns it (spec item 12).
func t_no_motor_in_phase_1() -> void:
	var m: Node = await _mk_main()
	if m != null:
		var v: Variant = m.get("motor_owned")
		ck(v != null, "main has a `motor_owned` flag (spec: the farm view may spin only once the motor is owned)")
		eq(v, false, "a fresh game owns no motor")
	_fin()


## Farm view, the bucket FULL: nothing cranks it by itself, however long it waits; Spin stays on offer.
func t_no_spin_farm_view_without_motor() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var p: Dictionary = _parts(m)
	var cen: Node = p["Centrifuge"]
	var cap: int = _bucket_cells()
	eq(m.get("motor_owned"), false, "no motor owned")
	eq(cen.call("add_cells", cap, float(cv("frame_jars"))), cap, "the bucket took a full load")
	cen.call("land_cells", cap)
	await _wait(_lid_t() + float(cv("cell_fly_seconds")) + 0.3)
	eq(cen.get("state"), _st(cen, "FULL"), "precondition: the bucket is FULL")
	ck(_cam().size > float(cv("pan_zoom_size")) + 0.5, "precondition: the camera is on the farm view")
	ck(not await _spun_within(cen, 4.0), "a full bucket in the farm view does not spin without the motor")
	eq(bool(m.call("at_second_stop")), false, "the camera did not go to the second stop by itself")
	ck(_shown(p["CentrifugeIcon"]), "Spin is still on offer")
	_fin()


## After a pour with a pile waiting (spin mode, farm view): the reloaded bucket fills but does not auto-spin; Spin waits for the player.
func t_no_spin_after_pour_farm_view() -> void:
	var r: Dictionary = await _pour_in_farm_view(false)
	if not r["ok"]:
		_fin()
		return
	ck(r["full"], "precondition: the pile reloaded the bucket to FULL")
	ck(r["farm"] and not r["second"], "the camera stayed on the farm view")
	eq(r["spun"], false, "the reloaded bucket does not spin by itself in the farm view without the motor")
	eq(r["auto"], false, "no auto-spin is left pending")
	ck(_shown(r["icon"]), "Spin is on offer for the player")
	_fin()


## Control: the same pour with the motor owned does spin by itself (so the test above can fail).
func t_spin_after_pour_farm_view_with_motor() -> void:
	var r: Dictionary = await _pour_in_farm_view(true)
	if not r["ok"]:
		_fin()
		return
	ck(r["farm"] and not r["second"], "the camera stayed on the farm view")
	eq(r["spun"], true, "with the motor owned, the reloaded bucket spins by itself in the farm view")
	_fin()


## First zoom, bucket filled in it (frames still Capped): the centrifuge does not spin by itself while the zoom stays open.
func t_no_spin_first_zoom_without_motor() -> void:
	_portrait()
	var z: Dictionary = await _zoom_open_main()
	if z.is_empty():
		_fin()
		return
	var m: Node = z["m"]
	var p: Dictionary = z["p"]
	var tr: Dictionary = z["tr"]
	var cen: Node = p["Centrifuge"]
	eq(m.get("motor_owned"), false, "no motor owned")
	var frames: int = int(ceil(float(_bucket_cells()) / float(_cpf())))
	for k in frames:
		var f: int = await _scrape_risen(m, p["Hive"], tr)
		ck(await _next_frame(tr, f), "frame %d done: the next frame rose" % f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	eq(cen.get("state"), _st(cen, "FULL"), "precondition: the bucket is full")
	near(_cam().size, float(cv("zoom_size")), 0.05, "precondition: still in the first zoom")
	ck(not await _spun_within(cen, 3.0), "a full bucket in the first zoom does not spin without the motor")
	near(_cam().size, float(cv("zoom_size")), 0.05, "the camera is still in the first zoom")
	ck(_shown(p["CentrifugeIcon"]), "Spin shows in the first zoom")
	_fin()
