extends "res://tests/test_helpers_3.gd"

# Quinn: economy tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

# L67: cost = 25 x 1.18^level, rounded; max level 10.
func t_cost_formula() -> void:
	var e: Node = _eco()
	var base: float = float(cv("swarm_base_cost"))
	var growth: float = float(cv("swarm_cost_growth"))
	eq(e.call("swarm_cost"), roundi(base), "level 0 cost")
	for lvl in int(cv("swarm_max_level")):
		e.set("swarm_level", lvl)
		eq(e.call("swarm_cost"), roundi(base * pow(growth, lvl)), "cost at level %d" % lvl)
	_fin()


# L67: max level 10; button disabled when maxed.
func t_cost_max_level() -> void:
	var e: Node = _eco()
	var maxl: int = int(cv("swarm_max_level"))
	e.set("money", 100000000)
	for i in maxl:
		ck(e.call("buy_swarm"), "buy %d should succeed" % i)
	eq(e.get("swarm_level"), maxl, "level after max buys")
	ck(not e.call("can_buy_swarm"), "cannot buy at max")
	var m: int = e.get("money")
	ck(not e.call("buy_swarm"), "buy beyond max refused")
	eq(e.get("swarm_level"), maxl, "level stays at max")
	eq(e.get("money"), m, "money unchanged on refused buy")
	_fin()


# L67
func t_buy_deducts_and_levels() -> void:
	var e: Node = _eco()
	var c0: int = int(e.call("swarm_cost"))
	e.set("money", c0 * 4)
	ck(e.call("buy_swarm"), "buy ok")
	eq(e.get("money"), c0 * 4 - c0, "money after first buy")
	eq(e.get("swarm_level"), 1, "level 1")
	var c1: int = int(e.call("swarm_cost"))
	ck(e.call("buy_swarm"), "second buy ok")
	eq(e.get("money"), c0 * 4 - c0 - c1, "money after second buy")
	_fin()


# L67: disabled when unaffordable.
func t_buy_blocked_unaffordable() -> void:
	var e: Node = _eco()
	var c0: int = int(e.call("swarm_cost"))
	e.set("money", c0 - 1)
	ck(not e.call("can_buy_swarm"), "cannot buy with cost-1")
	ck(not e.call("buy_swarm"), "buy refused")
	eq(e.get("swarm_level"), 0, "level 0")
	eq(e.get("money"), c0 - 1, "money unchanged")
	_fin()


# L67: Worker Swarm Count gives +15% fill rate per level (GDD).
func t_fill_multiplier() -> void:
	var e: Node = _eco()
	var bonus: float = float(cv("swarm_fill_bonus_per_level"))
	near(float(e.call("fill_multiplier")), 1.0, "level 0")
	for lvl in int(cv("swarm_max_level")) + 1:
		e.set("swarm_level", lvl)
		near(float(e.call("fill_multiplier")), 1.0 + bonus * lvl, "level %d" % lvl)
	_fin()


# L67, L105: +bees_per_swarm_level bees per level.
func t_bee_count() -> void:
	var e: Node = _eco()
	var per: int = int(cv("bees_per_swarm_level"))
	var b0: int = int(e.call("bee_count"))
	ck(b0 > 0, "level 0 has bees (got %d)" % b0)
	for lvl in int(cv("swarm_max_level")) + 1:
		e.set("swarm_level", lvl)
		eq(e.call("bee_count"), b0 + lvl * per, "bees at level %d" % lvl)
	e.set("swarm_level", 0)
	e.set("money", 100000)
	e.call("buy_swarm")
	eq(e.call("bee_count"), b0 + per, "a purchase adds bees_per_swarm_level bees")
	_fin()


# L67: the extra bees give the fill rate: multiplier = bees / base bees.
func t_fill_multiplier_is_bees_over_base() -> void:
	var e: Node = _eco()
	e.set("swarm_level", 0)
	var b0: float = float(e.call("bee_count"))
	for lvl in int(cv("swarm_max_level")) + 1:
		e.set("swarm_level", lvl)
		near(float(e.call("fill_multiplier")), float(e.call("bee_count")) / b0, "multiplier = bees / base at level %d" % lvl)
	_fin()


# L122, L26, L30: jars, add_jars(), sell_jars(), jars_changed are gone from Economy; earn() exists.
func t_economy_removed_jars() -> void:
	var e: Node = _eco()
	ck(not ("jars" in e), "Economy.jars must be removed (jars live in centrifuge, crate, truck)")
	ck(not e.has_method("add_jars"), "Economy.add_jars() must be removed")
	ck(not e.has_method("sell_jars"), "Economy.sell_jars() must be removed")
	ck(not e.has_signal("jars_changed"), "Economy.jars_changed must be removed")
	ck(e.has_method("earn"), "Economy.earn(amount) must exist")
	ck(e.has_method("jar_value"), "Economy.jar_value() must exist")
	ck(e.has_signal("money_changed"), "Economy.money_changed must exist")
	ck(e.has_signal("swarm_level_changed"), "Economy.swarm_level_changed must exist")
	ck(not ("no_rapid_tap_mode" in e), "Economy.no_rapid_tap_mode must be removed (L26)")
	_fin()


# L122, L66
func t_earn_and_jar_value() -> void:
	var e: Node = _eco()
	eq(e.call("jar_value"), int(cv("sale_value_per_jar")), "jar_value() = sale_value_per_jar")
	var seen: Array = []
	e.connect("money_changed", func(m: Variant) -> void: seen.append(m))
	e.call("earn", 30)
	eq(e.get("money"), 30, "money after earn(30)")
	ck(seen.size() >= 1, "money_changed emitted by earn()")
	e.call("earn", 12)
	eq(e.get("money"), 42, "money accumulates")
	_fin()


# L38, L105: the drawn flock is capped at visual_bee_cap while the counter keeps rising.
func t_drawn_count_capped() -> void:
	var e: Node = _eco()
	var b: Object = _make("bees.gd")
	if b == null:
		_fin()
		return
	var per: int = int(cv("bees_per_swarm_level"))
	var b0: int = int(e.call("bee_count"))
	var cap: int = b0 + per + per / 2   # level 1 is under the cap, level 2 is over it
	_set_cfg("visual_bee_cap", cap)
	root.add_child(b as Node)
	await process_frame
	await process_frame   # _ready builds the MultiMesh and sizes the flock
	ck(b.has_method("drawn_count"), "bees.gd has drawn_count()")
	if not b.has_method("drawn_count"):
		_fin()
		return
	eq(b.call("drawn_count"), b0, "level 0: all bees drawn (under the cap)")
	e.set("swarm_level", 2)
	e.emit_signal("swarm_level_changed", 2)
	eq(e.call("bee_count"), b0 + 2 * per, "counter keeps rising")
	eq(b.call("drawn_count"), cap, "drawn capped at visual_bee_cap")
	eq((b as MultiMeshInstance3D).multimesh.instance_count, cap, "multimesh.instance_count capped")
	e.set("swarm_level", 10)
	e.emit_signal("swarm_level_changed", 10)
	eq(b.call("drawn_count"), cap, "still capped at max level")
	_fin()


# ---------------------------------------------------------------- contract and config

# "Node paths for Bob", "Models as reusable scenes", "Changes": the scene has the named nodes, harvest.tscn is gone.
func t_node_contract() -> void:
	ck(not FileAccess.file_exists("res://scenes/harvest.tscn"), "harvest.tscn must be deleted (spec: retired)")
	for scene in ["truck", "jar", "jar_crate", "flower_patch", "hive", "centrifuge", "honey_cell"]:
		ck(FileAccess.file_exists("res://scenes/props/%s.tscn" % scene), "scenes/props/%s.tscn missing (spec: Models as reusable scenes)" % scene)
	var mats: int = 0
	var d := DirAccess.open("res://materials")
	ck(d != null, "game/materials/ missing (spec: materials as .tres)")
	if d != null:
		for f in d.get_files():
			if f.ends_with(".tres"):
				mats += 1
	ck(mats >= 7, "game/materials/ holds %d .tres, spec lists 7 (capped, uncapped, extracted, jar amber, glass, steel, wood)" % mats)
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	for nm in ["Hive", "ForkAnchor", "HiveLidSpot", "FrameSlots", "Honeycomb", "Centrifuge", "CentrifugeAnchor",
			"CentrifugeLidSpot", "BucketMouth", "Pile", "ZoomFraming", "HarvestUIRoot", "HarvestUI", "HintLabel", "BackButton",
			"FarmWorld", "Truck", "ForkIcon", "CentrifugeIcon", "SellIcon", "UpgradeButton"]:
		_nn(m, nm)
	ck(m.find_child("ContinueButton", true, false) == null, "ContinueButton is removed (0.1.2 change 6)")
	for i in _frames_n():
		_nn(m, "Slot%d" % (i + 1))
	ck(m.find_child("Harvest", true, false) == null, "no 'Harvest' close-up root any more")
	var hive: Node = m.find_child("Hive", true, false)
	if hive != null:
		ck(hive.is_in_group("bee_home"), "Hive is in the group bee_home")
	var ui: Node = m.find_child("HarvestUI", true, false)
	if ui != null and ui is Control:
		eq((ui as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "HarvestUI ignores the mouse (full rect, never in the way)")
	var back: Node = m.find_child("BackButton", true, false)
	if back != null and back is Control:
		ck((back as Control).size.y >= 120.0, "BackButton at least 120 px high (%s)" % str((back as Control).size.y))
	_fin()


# ---------------------------------------------------------------- flower patch B (game/specs/flower-patch-b.md)

const FP_COLORS: Array = [Color(0.97, 0.66, 0.78), Color(0.78, 0.7, 0.93), Color(1.0, 0.85, 0.3)]
const FP_RADII: Array = [0.9, 0.8, 0.7]
const FP_PALETTE_DE: float = 12.0   # STYLE_GUIDE V1


func t_flower_patch_b() -> void:
	await _fp_all()
	_fin()


func _fp_all(main: Node = null) -> void:
	var m: Node = main if main != null else await _mk_main()
	if m == null:
		return
	_fp_prop_contract()
	_fp_main(m)


func _fp_blossoms(patch: Node) -> Array:
	var out: Array = []
	var b: Node = patch.get_node_or_null("Blossoms")
	if b != null:
		for c in b.get_children():
			out.append(c)
	return out


func _fp_prop() -> Node:
	var ps: Variant = load("res://scenes/props/flower_patch.tscn")
	ck(ps != null, "props/flower_patch.tscn loads")
	if ps == null:
		return null
	return (ps as PackedScene).instantiate()   # not added to the tree: _ready has not run, positions are as authored


func _fp_lab(c: Color) -> Vector3:
	var lin: Array = []
	for v in [c.r, c.g, c.b]:
		lin.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	var x: float = (0.4124 * lin[0] + 0.3576 * lin[1] + 0.1805 * lin[2]) / 0.95047
	var y: float = 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
	var z: float = (0.0193 * lin[0] + 0.1192 * lin[1] + 0.9505 * lin[2]) / 1.08883
	var f: Array = []
	for t in [x, y, z]:
		f.append(pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0)
	return Vector3(116.0 * f[1] - 16.0, 500.0 * (f[0] - f[1]), 200.0 * (f[1] - f[2]))


func _fp_tokens() -> Array:
	var f := FileAccess.open(ProjectSettings.globalize_path("res://") + "../STYLE_GUIDE.md", FileAccess.READ)
	var out: Array = []
	if f == null:
		return out
	var rx := RegEx.new()
	rx.compile("^\\s+- .+? \\(([\\d.]+),\\s*([\\d.]+),\\s*([\\d.]+)\\)")
	var in_pal: bool = false
	for line in f.get_as_text().split("\n"):
		if line.begins_with("## "):
			in_pal = line.begins_with("## Palette")
			continue
		var r: RegExMatch = rx.search(line) if in_pal else null
		if r != null:
			out.append(Color(float(r.get_string(1)), float(r.get_string(2)), float(r.get_string(3))))
	return out


func _fp_prop_contract() -> void:
	var p: Node = _fp_prop()
	if p == null:
		return
	_to_free.append(p)
	eq(String(p.name), "FlowerPatch", "the prop root is named FlowerPatch")
	ck(p is Node3D, "the prop root is a Node3D")
	ck(p.get_script() != null and String(p.get_script().resource_path).ends_with("scripts/flower_patch.gd"), "the root carries scripts/flower_patch.gd")
	var base: Node = p.get_node_or_null("Base")
	ck(base is MeshInstance3D, "Base is a MeshInstance3D")
	var stems: Node = p.get_node_or_null("Stems")
	ck(stems is Node3D and stems.get_child_count() >= 1, "Stems is a Node3D holding the stems")
	var bl: Node = p.get_node_or_null("Blossoms")
	ck(bl is Node3D and bl.get_child_count() >= 1, "Blossoms is a Node3D holding the blossom heads")
	for c in _fp_blossoms(p):
		ck(c is MeshInstance3D, "Blossoms holds only MeshInstance3D (%s is %s)" % [c.name, c.get_class()])
	ck(p.find_child("PatchMesh", true, false) == null, "PatchMesh is removed from the prop")
	# the group is joined in _ready: a throwaway instance in the tree proves it, then goes
	var q: Node = _fp_prop()
	if q != null:
		root.add_child(q)
		ck(q.is_in_group("flower_patch"), "a FlowerPatch joins the group flower_patch")
		root.remove_child(q)
		q.free()
	# every material colour in the prop, as authored, is within dE 12 of a palette token (STYLE_GUIDE V1)
	var tokens: Array = _fp_tokens()
	ck(tokens.size() >= 10, "STYLE_GUIDE.md palette read (%d tokens)" % tokens.size())
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var mat: Material = (mi as MeshInstance3D).get_active_material(0)
		ck(mat is StandardMaterial3D, "%s has a StandardMaterial3D" % mi.name)
		if mat is StandardMaterial3D and tokens.size() > 0:
			var col: Color = (mat as StandardMaterial3D).albedo_color
			var best: float = 999.0
			for t in tokens:
				best = minf(best, _fp_lab(col).distance_to(_fp_lab(t)))
			ck(best <= FP_PALETTE_DE, "%s colour %s is dE %.1f from the nearest palette token (limit 12)" % [mi.name, str(col), best])
	var leaf: Variant = load("res://materials/leaf.tres")
	ck(leaf is StandardMaterial3D, "materials/leaf.tres exists")
	if leaf is StandardMaterial3D and base is MeshInstance3D and stems != null:
		var lc: Color = (leaf as StandardMaterial3D).albedo_color
		near(lc.r, 0.62, "leaf.tres albedo r", 0.01)
		near(lc.g, 0.84, "leaf.tres albedo g", 0.01)
		near(lc.b, 0.52, "leaf.tres albedo b", 0.01)
		ck(_mat_path(base as MeshInstance3D).ends_with("leaf.tres"), "Base uses leaf.tres (%s)" % _mat_path(base as MeshInstance3D))
		for s in stems.get_children():
			if s is MeshInstance3D:
				ck(_mat_path(s as MeshInstance3D).ends_with("leaf.tres"), "stem %s uses leaf.tres" % s.name)


func _fp_main(m: Node) -> void:
	var proto: Node = _fp_prop()
	if proto == null:
		return
	_to_free.append(proto)
	var auth: Array = _fp_blossoms(proto)
	var auth_stems: Array = proto.get_node("Stems").get_children() if proto.get_node_or_null("Stems") != null else []
	var base_scale: Vector3 = (proto.get_node("Base") as Node3D).scale if proto.get_node_or_null("Base") != null else Vector3.ONE
	var def: Variant = load("res://materials/flower_default.tres")
	ck(def is StandardMaterial3D, "flower_default.tres loads")
	if def is StandardMaterial3D:
		var dc: Color = (def as StandardMaterial3D).albedo_color
		near(dc.r, 0.97, "flower_default.tres albedo r unchanged", 0.001)
		near(dc.g, 0.66, "flower_default.tres albedo g unchanged", 0.001)
		near(dc.b, 0.78, "flower_default.tres albedo b unchanged", 0.001)
	var patches: Array = []
	for i in 3:
		var p: Node = m.find_child("FlowerPatch%d" % (i + 1), true, false)
		ck(p != null, "main.tscn has FlowerPatch%d" % (i + 1))
		if p == null:
			return
		patches.append(p)
	var seen: Array = []
	var first_mat: Material = null
	for i in 3:
		var n: int = i + 1
		var p: Node3D = patches[i] as Node3D
		var want: Color = FP_COLORS[i]
		var col: Color = p.get("color")
		near(col.r, want.r, "FlowerPatch%d color r (scene data)" % n, 0.01)
		near(col.g, want.g, "FlowerPatch%d color g (scene data)" % n, 0.01)
		near(col.b, want.b, "FlowerPatch%d color b (scene data)" % n, 0.01)
		var bs: Array = _fp_blossoms(p)
		eq(bs.size(), auth.size(), "FlowerPatch%d blossom count" % n)
		for b in bs:
			var mat: Material = (b as MeshInstance3D).material_override
			ck(mat is StandardMaterial3D, "FlowerPatch%d %s has a material_override StandardMaterial3D" % [n, b.name])
			if mat is StandardMaterial3D:
				var a: Color = (mat as StandardMaterial3D).albedo_color
				ck(absf(a.r - col.r) <= 0.01 and absf(a.g - col.g) <= 0.01 and absf(a.b - col.b) <= 0.01,
					"FlowerPatch%d %s shows %s, expected the patch color %s" % [n, b.name, str(a), str(col)])
				ck(mat != def and mat.resource_path != "res://materials/flower_default.tres", "FlowerPatch%d %s override is not the shared flower_default.tres" % [n, b.name])
				if i == 0 and first_mat == null:
					first_mat = mat
				elif i > 0:
					ck(mat != first_mat, "FlowerPatch%d %s does not share patch 1's material object" % [n, b.name])
		if bs.size() > 0 and (bs[0] as MeshInstance3D).material_override is StandardMaterial3D:
			seen.append(((bs[0] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color)
		# radius: k = radius / 0.9
		var k: float = float(FP_RADII[i]) / 0.9
		near(float(p.get("radius")), float(FP_RADII[i]), "FlowerPatch%d radius (scene data)" % n, 0.001)
		var base: Node3D = p.get_node("Base") as Node3D
		near(base.scale.x, k * base_scale.x, "FlowerPatch%d Base scale x = k" % n, 0.01)
		near(base.scale.z, k * base_scale.z, "FlowerPatch%d Base scale z = k" % n, 0.01)
		near(base.scale.y, base_scale.y, "FlowerPatch%d Base scale y unchanged" % n, 0.01)
		for j in mini(bs.size(), auth.size()):
			var ap: Vector3 = (auth[j] as Node3D).position
			var np: Vector3 = (bs[j] as Node3D).position
			near(np.x, k * ap.x, "FlowerPatch%d blossom %d x = k * authored" % [n, j], 0.01)
			near(np.z, k * ap.z, "FlowerPatch%d blossom %d z = k * authored" % [n, j], 0.01)
			near(np.y, ap.y, "FlowerPatch%d blossom %d y unchanged" % [n, j], 0.01)
			var asc: Vector3 = (auth[j] as Node3D).scale
			var nsc: Vector3 = (bs[j] as Node3D).scale
			ck(nsc.distance_to(asc) <= 0.01, "FlowerPatch%d blossom %d scale unchanged (%s vs %s)" % [n, j, str(nsc), str(asc)])
		var sts: Array = p.get_node("Stems").get_children()
		for j in mini(sts.size(), auth_stems.size()):
			var sp: Vector3 = (auth_stems[j] as Node3D).position
			var cp: Vector3 = (sts[j] as Node3D).position
			near(cp.x, k * sp.x, "FlowerPatch%d stem %d x = k * authored" % [n, j], 0.01)
			near(cp.z, k * sp.z, "FlowerPatch%d stem %d z = k * authored" % [n, j], 0.01)
			near(cp.y, sp.y, "FlowerPatch%d stem %d y unchanged" % [n, j], 0.01)
		# the root transform belongs to main.tscn: scale stays 1
		near(p.scale.x, 1.0, "FlowerPatch%d root scale x not written" % n, 0.001)
		near(p.scale.z, 1.0, "FlowerPatch%d root scale z not written" % n, 0.001)
	ck(seen.size() == 3, "three patches have blossoms")
	if seen.size() == 3:
		ck(_fp_lab(seen[0]).distance_to(_fp_lab(seen[1])) > 5.0 and _fp_lab(seen[1]).distance_to(_fp_lab(seen[2])) > 5.0
			and _fp_lab(seen[0]).distance_to(_fp_lab(seen[2])) > 5.0, "the three patches show three different colours")
	eq(get_nodes_in_group("flower_patch").size(), 3, "three nodes in group flower_patch while main runs")
	var bees: Node = m.find_child("Bees", true, false)
	ck(bees != null, "Bees node exists")
	if bees != null:
		var tg: Variant = bees.get("_targets")
		ck(tg is Array, "bees.gd keeps its _targets list")
		if tg is Array:
			eq((tg as Array).size(), 3, "the bees find 3 flower patches (not the fallback spot)")



# "Values" table: every new value, checked on the defaults file itself.
func t_config_values() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres failed to load")
	if c == null:
		_fin()
		return
	var table: Dictionary = {
		"frames_per_hive": 5, "frame_jars": 2, "overflow_hives": 1, "centrifuge_capacity_frames": 2, "taps_per_jar": 4,
		"zoom_seconds": 0.6, "lid_drop_seconds": 0.4, "slide_seconds": 0.3, "cell_fly_seconds": 0.5,
		"icon_visual_px": 88, "min_cell_px": 20, "hive_scale": 1.4,
		# unchanged from revision 3
		"sale_value_per_jar": 3, "truck_capacity_jars": 10, "truck_trip_seconds": 30.0,
		"bottling_seconds_per_jar": 3.0, "max_tap_rate": 5.0, "hold_ramp_seconds": 1.5,
		"base_seconds_per_jar": 6.0, "swarm_fill_bonus_per_level": 0.15, "swarm_base_cost": 25.0,
		"swarm_cost_growth": 1.18, "swarm_max_level": 10, "grid_cols": 5, "grid_rows": 2,  # spec 0.1.4 C5 round 9: "`grid_cols` 5 × `grid_rows` 2"
		"bees_per_swarm_level": 3, "visual_bee_cap": 60,
	}
	for k in table:
		var v: Variant = c.get(k)
		ck(v != null, "default_config.tres has no value '%s' (Values table)" % k)
		if v != null:
			near(float(v), float(table[k]), "default '%s'" % k)
	var zs: Variant = c.get("zoom_size")
	ck(zs != null, "default_config.tres has no value 'zoom_size' (Values table: Bob sets it)")
	if zs != null:
		ck(float(zs) > 0.0, "zoom_size is a positive ortho size (got %s)" % str(zs))
	for gone in ["taps_per_frame", "overflow_frames", "hold_taps_per_second", "hold_mode", "no_rapid_tap_mode", "bucket_visual_cap", "pile_visual_cap"]:
		ck(c.get(gone) == null, "'%s' must be gone from the config (replaced or removed)" % gone)
	var e: Node = _eco()
	eq(e.call("bee_count"), 20, "base swarm of 20 bees at level 0 (assumes no user dev_config override)")
	# derived numbers the Done-when list quotes, from the config
	eq(int(c.get("frames_per_hive")) * int(c.get("frame_jars")), 10, "a full hive is 10 jars")
	eq(int(c.get("grid_cols")) * int(c.get("grid_rows")), 10, "10 cells per frame")  # spec 0.1.4 C5 round 9: grid_cols 5 x grid_rows 2
	_fin()


# "Values": placeholders are marked `# PLACEHOLDER (GDD TBD)` in game_config.gd.
func t_config_placeholders_marked() -> void:
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd unreadable")
	if f == null:
		_fin()
		return
	var lines: PackedStringArray = f.get_as_text().split("\n")
	f.close()
	for name in ["taps_per_jar", "centrifuge_capacity_frames", "truck_capacity_jars", "truck_trip_seconds",
			"bottling_seconds_per_jar", "max_tap_rate", "hold_ramp_seconds"]:
		var found: bool = false
		var marked: bool = false
		for i in lines.size():
			if lines[i].contains("var %s" % name):
				found = true
				if lines[i].contains("PLACEHOLDER (GDD TBD)") or (i > 0 and lines[i - 1].contains("PLACEHOLDER (GDD TBD)")):
					marked = true
		ck(found, "game_config.gd declares no 'var %s'" % name)
		ck(not found or marked, "'%s' is not marked # PLACEHOLDER (GDD TBD) on its line or the line above" % name)
	# every value of the Values table is an @export var (adjustable in Dev mode)
	var text: String = "\n".join(lines)
	for name in ["frames_per_hive", "frame_jars", "overflow_hives", "zoom_seconds", "lid_drop_seconds", "frame_rise",
			"cell_fly_seconds", "icon_visual_px", "min_cell_px", "zoom_size"]:
		ck(text.contains("@export var %s" % name), "game_config.gd has no '@export var %s' (Dev mode lists exported values)" % name)
	_fin()


# "Contract": take_frame() goes; the hive owns the frames.
func t_retired_api_gone() -> void:
	var h: Object = await _mk_hive()
	if h == null:
		_fin()
		return
	ck(not h.has_method("take_frame"), "hive.take_frame() goes (spec: Contract, hive.gd)")
	for meth in ["is_full", "is_paused", "has_capped_cells", "next_frame_to_harvest", "frame_cells", "scrape", "raise_frame",
			"lower_frame", "open_lid", "close_lid", "fill_now", "advance", "cell_value"]:
		ck(h.has_method(meth), "hive.gd has no %s() (spec: Contract)" % meth)
	for sig in ["storage_changed", "became_full", "lid_moved", "frame_raised", "frame_lowered"]:
		ck(h.has_signal(sig), "hive.gd has no signal %s (spec: Contract)" % sig)
	_fin()


# ---------------------------------------------------------------- hive

func t_node_contract_011() -> void:
	var ps: Variant = load("res://scenes/props/jar.tscn")
	ck(ps != null, "jar.tscn loads")
	if ps != null:
		var j: Node = (ps as PackedScene).instantiate()
		_to_free.append(j)
		ck(j is Node3D and not (j is MeshInstance3D), "the jar's root is a plain Node3D (was a MeshInstance3D in 0.1.0): %s" % j.get_class())
		eq(String(j.name), "Jar", "the jar's root is named Jar")
		for nm in ["JarGlass", "JarHoney", "JarHoneyBottom", "JarHoneyTop", "JarLid"]:
			ck(j.find_child(nm, true, false) != null, "jar.tscn has %s" % nm)
		for nm in ["JarHoneyBottom", "JarHoneyTop"]:
			ck(j.find_child(nm, true, false) is Marker3D, "%s is a Marker3D" % nm)
		var g: Node = j.find_child("JarGlass", true, false)
		var hn: Node = j.find_child("JarHoney", true, false)
		var ld: Node = j.find_child("JarLid", true, false)
		if g is MeshInstance3D:
			ck(_mat_path(g as MeshInstance3D).ends_with("glass.tres"), "JarGlass uses glass.tres (%s)" % _mat_path(g as MeshInstance3D))
		if hn is MeshInstance3D:
			ck(_mat_path(hn as MeshInstance3D).ends_with("honey_level.tres"), "JarHoney uses honey_level.tres (%s)" % _mat_path(hn as MeshInstance3D))
		if ld != null:
			var lm: MeshInstance3D = ld as MeshInstance3D
			if lm == null:
				var lms: Array = ld.find_children("*", "MeshInstance3D", true, false)
				lm = lms[0] as MeshInstance3D if lms.size() > 0 else null
			ck(lm != null and _mat_path(lm).ends_with("steel.tres"), "JarLid is steel (steel.tres)")
		if j.find_child("JarHoneyBottom", true, false) != null and j.find_child("JarHoneyTop", true, false) != null:
			ck((j.find_child("JarHoneyTop", true, false) as Node3D).position.y > (j.find_child("JarHoneyBottom", true, false) as Node3D).position.y, "JarHoneyTop is above JarHoneyBottom")
	var m: Node = await _mk_main()
	if m != null:
		var c: Node = _nn(m, "Centrifuge")
		var sj: Node = c.find_child("SpigotJar", true, false) if c != null else null
		ck(sj != null and sj.scene_file_path.ends_with("jar.tscn"), "SpigotJar is a jar.tscn instance")
		var zf: Node = _nn(m, "ZoomFraming")
		if zf != null:
			ck(zf.has_meta("zoom_size"), "ZoomFraming carries the zoom_size metadata")
			var d: Variant = load(DEFAULT_CFG)
			if zf.has_meta("zoom_size") and d != null:
				near(float(zf.get_meta("zoom_size")), float(d.get("zoom_size")), "the config default zoom_size equals ZoomFraming's metadata (Bob's value)", 0.01)
	_fin()


# Config table of 0.1.1: new values, the retired caps are absent from the defaults file and from game_config.gd.
func t_config_011() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres loads")
	if c == null:
		_fin()
		return
	near(float(c.get("lid_lift_height")), 0.6, "default lid_lift_height")
	near(float(c.get("lid_lift_seconds")), 0.25, "default lid_lift_seconds")
	near(float(c.get("lid_drop_seconds")), 0.4, "default lid_drop_seconds (now the fall after the lift)")
	ck(c.get("zoom_size") != null and float(c.get("zoom_size")) > 0.0, "zoom_size is Bob's positive value")
	ck(c.get("frame_rise") != null and float(c.get("frame_rise")) > 0.0, "frame_rise is Bob's positive value")
	for gone in ["bucket_visual_cap", "pile_visual_cap"]:
		ck(c.get(gone) == null, "'%s' is removed from the config (every cell shows)" % gone)
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd readable")
	if f != null:
		var text: String = f.get_as_text()
		f.close()
		for gone in ["bucket_visual_cap", "pile_visual_cap"]:
			ck(not text.contains("var %s" % gone), "game_config.gd no longer declares %s" % gone)
		for nm in ["lid_lift_height", "lid_lift_seconds"]:
			ck(text.contains("@export var %s" % nm), "game_config.gd has @export var %s (Dev mode lists exported values)" % nm)
	# no script reads a removed value
	var d := DirAccess.open("res://scripts")
	if d != null:
		for fn in d.get_files():
			if fn.ends_with(".gd"):
				var sf := FileAccess.open("res://scripts/" + fn, FileAccess.READ)
				var src: String = sf.get_as_text()
				sf.close()
				ck(not src.contains("bucket_visual_cap") and not src.contains("pile_visual_cap"), "%s does not mention a removed cap" % fn)
	_fin()


func t_node_contract_012() -> void:
	var ps: Variant = load("res://scenes/props/jar_crate.tscn")
	ck(ps != null, "jar_crate.tscn loads")
	if ps != null:
		var cr: Node = (ps as PackedScene).instantiate()
		_to_free.append(cr)
		for nm in ["CrateEmpties", "CrateFulls"]:
			var n: Node = cr.find_child(nm, true, false)
			ck(n != null and n is Node3D, "jar_crate.tscn has a Node3D marker %s" % nm)
		var e: Node = cr.find_child("CrateEmpties", true, false)
		var f: Node = cr.find_child("CrateFulls", true, false)
		if e is Node3D and f is Node3D:
			ck((e as Node3D).position.distance_to((f as Node3D).position) >= 0.2, "the two groups are apart (markers %.2f apart)" % (e as Node3D).position.distance_to((f as Node3D).position))
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	for nm in ["SummaryModal", "SummaryJarsLabel", "SummaryValueLabel", "SummaryTotalLabel", "SummaryOkButton", "CrateEmpties", "CrateFulls", "BucketMouth", "ZoomFraming"]:
		_nn(m, nm)
	ck(m.find_child("SummaryBonusLabel", true, false) == null, "SummaryBonusLabel is removed (spec change 7)")
	ck(m.find_child("ContinueButton", true, false) == null, "ContinueButton is removed (spec change 6)")
	_fin()


func t_config_012() -> void:
	var c: Variant = load(DEFAULT_CFG)
	ck(c != null, "default_config.tres loads")
	if c == null:
		_fin()
		return
	for pair in [["jar_fly_seconds", 0.5], ["crate_empty_jars_shown", 10.0]]:
		var v: Variant = c.get(pair[0])
		ck(v != null, "default_config.tres has '%s'" % pair[0])
		if v != null:
			near(float(v), float(pair[1]), "default %s" % pair[0])
	ck(float(c.get("zoom_size")) > 0.0 and float(c.get("frame_rise")) > 0.0, "zoom_size and frame_rise are Bob's positive values")
	var f := FileAccess.open(_script_path("game_config.gd"), FileAccess.READ)
	ck(f != null, "game_config.gd readable")
	if f != null:
		var text: String = f.get_as_text()
		f.close()
		for nm in ["jar_fly_seconds", "crate_empty_jars_shown"]:
			ck(text.contains("@export var %s" % nm), "game_config.gd has @export var %s (Dev mode lists exported values)" % nm)
	_set_dev_mode(true)
	var panel: Node = await _mk_panel()
	if panel != null:
		for nm in ["jar_fly_seconds", "crate_empty_jars_shown", "zoom_size", "frame_rise"]:
			ck(_row_spin(panel, nm) != null, "the Dev panel has a row for %s" % nm)
	_fin()


# ---------------------------------------------------------------- the crate and the jar flights (spec change 5)
