extends "res://tests/test_gearing.gd"

# Quinn: 0.2 item 5 (Faster Delivery), written from game/specs/0.2-first-automation.md before the code.
# Every expected number comes from the config. Groups are found by the names Stacks, DecalsSmall, DecalsBold, FlamesTop (node handoff).


func _delivery_level(n: int) -> void:
	_eco().call("reset")
	_eco().call("set_level", "faster_delivery", n)


## Which of the four groups the item 5 table shows at level n.
func _expected_groups(n: int) -> Dictionary:
	return {"Stacks": n >= 1, "DecalsSmall": n == 2, "DecalsBold": n >= 3, "FlamesTop": n == 4}


## All MeshInstance3D under a node (recursive).
func _meshes_under(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for ch in n.get_children():
		out.append_array(_meshes_under(ch))
	return out


## Item 5 look: at each level 0..max exactly the groups in the table are visible; Stacks never uses the flame (crank orange) material.
# goal T5.1
func t_delivery_look_groups_by_level() -> void:
	var max_l: int = int(cv("faster_delivery_max_level"))
	eq(max_l, 4, "the spec's Faster Delivery max level (config faster_delivery_max_level)")
	for n in range(0, max_l + 1):
		_delivery_level(n)
		var t: Object = await _mk_truck()
		if t == null:
			_fin()
			return
		for k in 3:
			await process_frame
		var want: Dictionary = _expected_groups(n)
		for g: String in want:
			var node: Node3D = (t as Node).find_child(g, true, false) as Node3D
			ck(node != null, "Faster Delivery %d: node %s exists" % [n, g])
			if node == null:
				continue
			eq(node.is_visible_in_tree(), want[g], "Faster Delivery %d: %s is %s" % [n, g, "visible" if want[g] else "hidden"])
	_eco().call("reset")
	_fin()


## No mesh under Stacks may use the flame material (materials/crank_handle.tres, crank orange), at any level.
# goal T5.1
func t_delivery_stacks_not_flame_material() -> void:
	_delivery_level(1)
	var t: Object = await _mk_truck()
	if t == null:
		_fin()
		return
	var stacks: Node = (t as Node).find_child("Stacks", true, false)
	ck(stacks != null, "node Stacks exists under the truck")
	if stacks == null:
		_fin()
		return
	var flame: Material = load("res://materials/crank_handle.tres") as Material
	ck(flame != null, "the flame material (crank orange) loads")
	var meshes: Array = _meshes_under(stacks)
	ck(meshes.size() >= 2, "Stacks holds at least the two pipes as meshes (got %d)" % meshes.size())
	for mi: MeshInstance3D in meshes:
		var mats: Array = [mi.material_override, mi.get_active_material(0)]
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				mats.append(mi.mesh.surface_get_material(s))
				mats.append(mi.get_surface_override_material(s))
		for m in mats:
			if m == null:
				continue
			ck(m != flame and m.resource_path != flame.resource_path, "%s does not use the flame material" % mi.name)
			if m is StandardMaterial3D and flame is StandardMaterial3D:
				ck((m as StandardMaterial3D).albedo_color != (flame as StandardMaterial3D).albedo_color, "%s albedo is not crank orange" % mi.name)
	_eco().call("reset")
	_fin()


## Trip time at Faster Delivery 0..max is truck_trip_seconds x (1 - cut x level) (30, 25.5, 21, 16.5, 12 s), +- 0.1 s.
# goal T5.2
func t_delivery_trip_time_by_level() -> void:
	var base: float = float(cv("truck_trip_seconds"))
	var cut: float = float(cv("faster_delivery_trip_cut_per_level"))
	var max_l: int = int(cv("faster_delivery_max_level"))
	var cap: int = int(cv("truck_capacity_jars"))
	for n in range(0, max_l + 1):
		_delivery_level(n)
		var t: Object = await _mk_truck()
		if t == null:
			_fin()
			return
		var want: float = base * (1.0 - cut * float(n))
		for i in cap:
			t.call("receive_jar")
		t.call("sell")
		ck(t.get("away"), "Faster Delivery %d: away after Sell" % n)
		t.call("advance", want - 0.1)
		ck(t.get("away"), "Faster Delivery %d: still away 0.1 s before %.1f s" % [n, want])
		t.call("advance", 0.2)
		ck(not t.get("away"), "Faster Delivery %d: back by %.1f s + 0.1" % [n, want])
	_eco().call("reset")
	_fin()
