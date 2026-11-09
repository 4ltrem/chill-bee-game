# Implements GDD 1 (Primary Game Loop: sell by truck) and 2 (bottling onto the truck) for Prototype 0.
# Holds the truck's load, the jar crate beside the centrifuge, and the trip. Jars bottled while the truck
# is away go to the crate (no limit); when the truck returns, crate jars load onto it up to its capacity.
# 0.1.2 (game/specs/0.1.2-bottling-and-sale.md): the crate shows empty jars on CrateEmpties (config crate_empty_jars_shown, unlimited supply)
# and full jars on CrateFulls. Counts change at once; the jars' flights (spigot to truck or crate, crate to truck on return) are visual:
# a jar still in the air is not drawn at its destination until it lands.
# Visual (0.1 Harvest, game/specs/0.1-harvest.md): the pickup comes from truck.tscn (wheels WheelFL/FR/RL/RR, marker BedJars); one jar
# (jar.tscn) per loaded jar on the bed, crate jars on the JarCrate node's CrateJars marker. The wheels roll from the truck's real
# movement, so the roll always matches the direction of travel.
# Every tunable is read from the config when used. Never name a member `load` (it shadows the global).
class_name Truck
extends Node3D

signal load_changed(loaded_jars: int, crate_jars: int)
signal departed
signal returned

const JarFlight := preload("res://scripts/jar_flight.gd")
const JAR_STEP: float = 0.34        # spacing of the crate's jars (a jar is 0.34 wide), 3 per row
const CRATE_JARS_SHOWN: int = 10   # the crate shows at most 10 jars, a count label shows the rest (spec)
const BED_JARS_SHOWN: int = 30     # most jar meshes built on the bed (the truck capacity can be raised in Dev mode)
const JAR_SCENE_PATH := "res://scenes/props/jar.tscn"
const WHEEL_NAMES: Array[String] = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]

@export var config: GameConfig = GameConfig.live()
## The crate node (a sibling) that shows the waiting jars.
@export var crate_path: NodePath = ^"../JarCrate"
## Direction the truck drives off along the ground, in the truck's parent space.
@export var exit_direction: Vector3 = Vector3(1.0, 0.0, 0.0)

var loaded_jars: int = 0
var crate_jars: int = 0
var away: bool = false
var trip_elapsed: float = 0.0

var capacity: int:
	get:
		return config.truck_capacity_jars

var _home: Vector3 = Vector3.ZERO
var _bed_jars: Array[Node3D] = []
var _crate_jar_meshes: Array[Node3D] = []
var _crate_label: Label3D
var _jar_scene: PackedScene
var _wheels: Array[Node3D] = []
var _last_global: Vector3 = Vector3.ZERO
var _crate_empty_meshes: Array[Node3D] = []
var _flying_to_bed: int = 0      # jars counted on the truck whose flight has not landed yet
var _flying_to_crate: int = 0    # jars counted in the crate whose flight has not landed yet
var _empties_marker: Node3D


## Where the truck stands at home, in world space (for framing the camera while it is away).
func home_global_position() -> Vector3:
	var parent: Node3D = get_parent() as Node3D
	if parent != null and parent.is_inside_tree():
		return parent.global_transform * _home
	return _home


func is_full() -> bool:
	return loaded_jars >= capacity


## Full and home: the Sell icon may show.
func can_sell() -> bool:
	return not away and is_full()


## What the load is worth at the current jar value.
func load_value() -> int:
	return loaded_jars * config.sale_value_per_jar


## A bottled jar: onto the truck if it is home and not full, else into the crate. With `from` (world space, the spigot) the jar
## flies there after `delay`; without it the jar simply appears. `carrier` is the jar already at the spigot (JarFlight.fetch), which
## is the one that flies on; without one a new jar is drawn.
func receive_jar(from: Variant = null, delay: float = 0.0, carrier: Node3D = null) -> void:
	var to_bed: bool = not away and loaded_jars < capacity
	if to_bed:
		loaded_jars += 1
	else:
		crate_jars += 1
	var slot: int = (loaded_jars if to_bed else crate_jars) - 1
	var target: Node3D = _slot_node(_bed_jars if to_bed else _crate_jar_meshes, slot)
	if from is Vector3 and target != null and is_inside_tree():
		if to_bed:
			_flying_to_bed += 1
		else:
			_flying_to_crate += 1
		_fly(from as Vector3, target.global_position, delay, target, to_bed, carrier)
	elif carrier != null:
		carrier.queue_free()
	_changed()


## Where empty jars leave the crate (world space): the CrateEmpties marker, else the truck itself.
func empties_position() -> Vector3:
	if _empties_marker != null and _empties_marker.is_inside_tree():
		return _empties_marker.global_position
	return global_position if is_inside_tree() else position


func _slot_node(list: Array[Node3D], slot: int) -> Node3D:
	if slot < 0 or slot >= list.size():
		return null
	return list[slot]


## Flies one full jar to `target` (a hidden slot jar); the slot shows when it lands.
func _fly(from: Vector3, to: Vector3, delay: float, target: Node3D, to_bed: bool, carrier: Node3D = null) -> void:
	var jar_scale: float = target.global_transform.basis.get_scale().x
	var landed: Callable = func() -> void:
		if to_bed:
			_flying_to_bed = maxi(_flying_to_bed - 1, 0)
		else:
			_flying_to_crate = maxi(_flying_to_crate - 1, 0)
		_refresh_jars()
	if carrier != null:
		JarFlight.send(self, carrier, to, config.jar_fly_seconds, config.cell_fly_arc, delay, jar_scale, landed)
	else:
		JarFlight.launch(self, from, to, config.jar_fly_seconds, config.cell_fly_arc, delay, true, jar_scale, landed)


## Sells the load: credits the money at once, empties the truck and sends it off. Returns the amount (0 if it cannot sell).
func sell() -> int:
	if not can_sell():
		return 0
	var amount: int = load_value()
	var economy: Node = get_node_or_null("/root/Economy")   # looked up by path so the script also compiles in --script test runs
	if economy != null:
		economy.earn(amount)
	loaded_jars = 0
	away = true
	trip_elapsed = 0.0
	departed.emit()
	_changed()
	return amount


## Dev mode: empties the truck and brings it home (the crate is kept).
func reset_home() -> void:
	loaded_jars = 0
	away = false
	trip_elapsed = 0.0
	position = _home
	_changed()


## Per-frame logic, separate from _process so it can be tested headless.
func advance(delta: float) -> void:
	if not away:
		# 0.1.4 item 21: a home truck with room takes every waiting crate jar (Dev reset_home or a raised capacity left them behind)
		var room: int = mini(crate_jars, maxi(capacity - loaded_jars, 0))
		if room > 0:
			_load_crate_jars(room)
			_changed()
		return
	trip_elapsed += delta
	if trip_elapsed >= config.truck_trip_seconds:
		away = false
		trip_elapsed = 0.0
		var moved: int = mini(crate_jars, maxi(capacity - loaded_jars, 0))
		_load_crate_jars(moved)
		returned.emit()
		_changed()


## 0 at home, 1 fully off-screen: drives off over the first slice of the trip and back over the last.
func away_fraction() -> float:
	if not away:
		return 0.0
	var trip: float = maxf(config.truck_trip_seconds, 0.001)
	var slice: float = clampf(config.truck_slide_fraction, 0.01, 0.5)
	var p: float = clampf(trip_elapsed / trip, 0.0, 1.0)
	if p < slice:
		return p / slice
	if p > 1.0 - slice:
		return (1.0 - p) / slice
	return 1.0


## The truck is home: `moved` crate jars go onto it (counted at once; each flies from its crate slot to its bed slot).
func _load_crate_jars(moved: int) -> void:
	for k in moved:
		var crate_slot: int = crate_jars - 1
		var bed_slot: int = loaded_jars
		loaded_jars += 1
		crate_jars -= 1
		var from_node: Node3D = _slot_node(_crate_jar_meshes, crate_slot)
		var target: Node3D = _slot_node(_bed_jars, bed_slot)
		if from_node != null and target != null and is_inside_tree():
			_flying_to_bed += 1
			_fly(from_node.global_position, target.global_position, config.pile_load_stagger_seconds * float(k), target, true)


func _changed() -> void:
	_refresh_jars()
	load_changed.emit(loaded_jars, crate_jars)


# --- visuals ---

func _ready() -> void:
	_home = position
	if ResourceLoader.exists(JAR_SCENE_PATH):
		_jar_scene = load(JAR_SCENE_PATH) as PackedScene
	else:
		CellFlight.warn_once(JAR_SCENE_PATH, "%s not found (Bob builds it): no jars are drawn." % JAR_SCENE_PATH)
	for wheel_name in WHEEL_NAMES:
		var wheel: Node3D = find_child(wheel_name, true, false) as Node3D
		if wheel != null:
			_wheels.append(wheel)
	if _wheels.is_empty():
		CellFlight.warn_once("TruckWheels", "truck.gd: no WheelFL/FR/RL/RR nodes (see game/specs/0.1-harvest.md, truck.tscn).")
	_build_bed_jars()
	_build_crate_jars()
	_refresh_jars()
	_last_global = global_position if is_inside_tree() else position


func _new_jar() -> Node3D:
	if _jar_scene == null:
		return null
	return _jar_scene.instantiate() as Node3D


func _build_bed_jars() -> void:
	var marker: Node3D = find_child("BedJars", true, false) as Node3D
	if marker == null:
		CellFlight.warn_once("BedJars", "truck.gd: no BedJars marker (see game/specs/0.1-harvest.md, truck.tscn).")
		return
	for i in BED_JARS_SHOWN:
		var jar: Node3D = _new_jar()
		if jar == null:
			return
		jar.name = "BedJar%d" % i
		var col: int = i % 5
		var row: int = (i / 5) % 2
		var layer: int = i / 10
		jar.position = Vector3(0.4 * float(col), 0.3 * float(layer), 0.6 * float(row))
		jar.visible = false
		JarFill.set_full(jar)
		marker.add_child(jar)
		_bed_jars.append(jar)


func _build_crate_jars() -> void:
	var crate: Node3D = get_node_or_null(crate_path) as Node3D
	if crate == null:
		return
	_empties_marker = crate.find_child("CrateEmpties", true, false) as Node3D
	if _empties_marker == null:
		CellFlight.warn_once("CrateEmpties", "truck.gd: no CrateEmpties marker on the crate (see game/specs/0.1.2-bottling-and-sale.md, jar_crate.tscn): no empty jars are drawn.")
	else:
		for i in maxi(config.crate_empty_jars_shown, 0):
			var empty: Node3D = _new_jar()
			if empty == null:
				break
			empty.name = "CrateEmpty%d" % i
			empty.position = Vector3(JAR_STEP * float(i % 3), 0.0, JAR_STEP * float(i / 3))
			JarFill.set_fraction(empty, 0.0)
			_empties_marker.add_child(empty)
			_crate_empty_meshes.append(empty)
	var marker: Node3D = crate.find_child("CrateFulls", true, false) as Node3D
	if marker == null:
		marker = crate.find_child("CrateJars", true, false) as Node3D   # 0.1's name, until the 0.1.2 crate scene is in
	if marker == null:
		CellFlight.warn_once("CrateFulls", "truck.gd: no CrateFulls marker on the crate (see game/specs/0.1.2-bottling-and-sale.md, jar_crate.tscn).")
	else:
		for i in CRATE_JARS_SHOWN:
			var jar: Node3D = _new_jar()
			if jar == null:
				break
			jar.name = "CrateJar%d" % i
			jar.position = Vector3(JAR_STEP * float(i % 3), 0.0, JAR_STEP * float(i / 3))
			jar.visible = false
			JarFill.set_full(jar)
			marker.add_child(jar)
			_crate_jar_meshes.append(jar)
	_crate_label = Label3D.new()
	_crate_label.name = "CrateCountLabel"
	_crate_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_crate_label.pixel_size = 0.02
	_crate_label.position = Vector3(0.0, 1.4, 0.0)
	_crate_label.visible = false
	crate.add_child(_crate_label)


func _refresh_jars() -> void:
	var bed_shown: int = maxi(loaded_jars - _flying_to_bed, 0)
	var crate_shown: int = maxi(crate_jars - _flying_to_crate, 0)
	for i in _bed_jars.size():
		_bed_jars[i].visible = i < bed_shown
	for i in _crate_jar_meshes.size():
		_crate_jar_meshes[i].visible = i < crate_shown
	var empties: int = maxi(config.crate_empty_jars_shown, 0)
	for i in _crate_empty_meshes.size():
		_crate_empty_meshes[i].visible = i < empties
	if _crate_label != null:
		var extra: int = crate_jars - CRATE_JARS_SHOWN
		_crate_label.visible = extra > 0
		_crate_label.text = "+%d" % extra


## Places the truck for its trip and rolls the wheels by the distance it actually moved since the last call.
## Called every frame from _process; tests call it after advance().
func update_pose() -> void:
	if not is_inside_tree():
		return
	position = _home + exit_direction.normalized() * config.truck_slide_distance * away_fraction()
	roll_wheels(global_position - _last_global)
	_last_global = global_position


## Rolls every wheel for a world-space displacement of the truck. A wheel rolling without slipping turns with
## angular velocity (up x velocity) / radius; the wheel spins about its own axle (local +Y), so forward, reverse and turning
## all roll the right way.
func roll_wheels(displacement: Vector3) -> void:
	if displacement.length_squared() < 1.0e-12:
		return
	var roll: Vector3 = Vector3.UP.cross(displacement)
	for wheel in _wheels:
		var mesh_instance: MeshInstance3D = wheel as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var base_radius: float = 0.0
		if mesh_instance.mesh is CylinderMesh:
			base_radius = (mesh_instance.mesh as CylinderMesh).top_radius   # exact, and the headless renderer cannot give an AABB
		else:
			base_radius = mesh_instance.mesh.get_aabb().size.x * 0.5        # an asset-pack wheel mesh
		var radius: float = base_radius * wheel.global_transform.basis.get_scale().x
		var axle: Vector3 = wheel.global_transform.basis.y.normalized()
		wheel.rotate_object_local(Vector3.UP, roll.dot(axle) / maxf(radius, 0.001))


func _process(delta: float) -> void:
	advance(delta)
	update_pose()
