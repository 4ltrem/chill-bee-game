extends "res://tests/test_fork_return.gd"

# Quinn: 0.2 item 11 (the lid stays still; the crank drives the gears), written from game/specs/0.2-first-automation.md before the code.
# Nodes by name (spec + node handoff): Lid, LidDisc, Crank, Gear1, Spinner. Angles are measured, never read from a script variable.


## One crank run through the real tap path: returns the turn of each node between the start and a few frames later, or {} if no centrifuge.
## Lid and LidDisc are compared by their global basis (they must not move at all); Crank, Gear1 and Spinner by their signed turn about Y.
func _lid_still_run() -> Dictionary:
	_eco().call("reset")
	var c: Object = await _mk_cen()
	if c == null:
		return {}
	var n: Node = c as Node
	var lid: Node3D = n.find_child("Lid", true, false) as Node3D
	var disc: Node3D = n.find_child("LidDisc", true, false) as Node3D
	var crank: Node3D = n.find_child("Crank", true, false) as Node3D
	var g1: Node3D = n.find_child("Gear1", true, false) as Node3D
	var sp: Node3D = n.find_child("Spinner", true, false) as Node3D
	ck(lid != null and disc != null and crank != null and g1 != null and sp != null, "nodes Lid, LidDisc, Crank, Gear1, Spinner all exist")
	if lid == null or disc == null or crank == null or g1 == null or sp == null:
		return {}
	_to_cranking(c)
	await _wait(float(cv("lid_lift_seconds")) + float(cv("lid_drop_seconds")) + 0.5)   # the closing lid reaches its seat before the first sample
	var lid0: Basis = lid.global_transform.basis
	var disc0: Basis = disc.global_transform.basis
	var lidp0: Vector3 = lid.global_transform.origin
	var crank0: Basis = crank.transform.basis
	var g10: Basis = g1.transform.basis
	var sp0: Basis = sp.transform.basis
	ck(c.call("tap"), "step start: a tap counts a turn and starts the crank")
	for k in 12:
		c.call("_process", 1.0 / 60.0)
	return {
		"lid": _basis_gap(lid0, lid.global_transform.basis) + lidp0.distance_to(lid.global_transform.origin),
		"disc": _basis_gap(disc0, disc.global_transform.basis),
		"crank": _turn_y(crank0, crank.transform.basis),
		"gear1": _turn_y(g10, g1.transform.basis),
		"spinner": _turn_y(sp0, sp.transform.basis),
	}


## size of the difference between two bases (0 when identical)
func _basis_gap(a: Basis, b: Basis) -> float:
	return (a.x - b.x).length() + (a.y - b.y).length() + (a.z - b.z).length()


## signed turn about Y between two bases
func _turn_y(a: Basis, b: Basis) -> float:
	return (b * a.inverse()).get_euler().y


## While cranking: Lid and LidDisc do not rotate, Crank turns, Gear1 turns by the same angle and way as Crank, Spinner still turns; twice.
# goal T11.1
func t_lid_still_crank_and_gear1_turn_twice() -> void:
	var runs: Array = []
	for r in 2:
		var d: Dictionary = await _lid_still_run()
		if d.is_empty():
			_fin()
			return
		runs.append(d)
		var tag: String = "run %d" % (r + 1)
		ck(float(d["lid"]) < 0.0001, "%s: Lid's global rotation (and place) stay unchanged while cranking (change %.6f)" % [tag, float(d["lid"])])
		ck(float(d["disc"]) < 0.0001, "%s: LidDisc's global rotation stays unchanged while cranking (change %.6f)" % [tag, float(d["disc"])])
		ck(absf(float(d["crank"])) > 0.001, "%s: Crank's rotation changes while cranking (%.5f rad)" % [tag, float(d["crank"])])
		near(float(d["gear1"]), float(d["crank"]), "%s: Gear1 turns the same angle in the same direction as Crank" % tag, 0.0005)
		ck(absf(float(d["spinner"])) > 0.001, "%s: Spinner still turns (%.5f rad)" % [tag, float(d["spinner"])])
	if runs.size() == 2:
		ck(float(runs[0]["crank"]) * float(runs[1]["crank"]) > 0.0, "run 2 turns Crank the same way as run 1")
		near(float(runs[1]["crank"]), float(runs[0]["crank"]), "run 2 turns Crank the same angle as run 1", 0.02)
		ck(float(runs[0]["spinner"]) * float(runs[1]["spinner"]) > 0.0, "run 2 turns Spinner the same way as run 1")
	_eco().call("reset")
	_fin()
