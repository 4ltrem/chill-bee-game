# Implements GDD 1 (Primary Game Loop: sell by truck) and 2 (bottling onto the truck) for Prototype 0.
# Holds the truck's load, the jar crate beside the centrifuge, and the trip. Jars bottled while the truck
# is away go to the crate (no limit); when the truck returns, crate jars load onto it up to its capacity.
# Visual (0.1 Harvest, game/specs/0.1-harvest.md): the pickup comes from truck.tscn (wheels WheelFL/FR/RL/RR, marker BedJars); one jar
# (jar.tscn) per loaded jar on the bed, crate jars on the JarCrate node's CrateJars marker. The wheels roll from the truck's real
# movement, so the roll always matches the direction of travel.
# Every tunable is read from the config when used. Never name a member `load` (it shadows the global).
class_name Truck
extends Node3D

signal load_changed(loaded_jars: int, crate_jars: int)
signal departed
signal returned

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


func is_full() -> bool:
	return loaded_jars >= capacity


## Full and home: the Sell icon may show.
func can_sell() -> bool:
	return not away and is_full()


## What the load is worth at the current jar value.
func load_value() -> int:
	return loaded_jars * config.sale_value_per_jar


## A bottled jar: onto the truck if it is home and not full, else into the crate.
func receive_jar() -> void:
	if not away and loaded_jars < capacity:
		loaded_jars += 1
	else:
		crate_jars += 1
	_changed()


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
		return
	trip_elapsed += delta
	if trip_elapsed >= config.truck_trip_seconds:
		away = false
		trip_elapsed = 0.0
		var moved: int = mini(crate_jars, maxi(capacity - loaded_jars, 0))
		loaded_jars += moved
		crate_jars -= moved
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
		marker.add_child(jar)
		_bed_jars.append(jar)


func _build_crate_jars() -> void:
	var crate: Node3D = get_node_or_null(crate_path) as Node3D
	if crate == null:
		return
	var marker: Node3D = crate.find_child("CrateJars", true, false) as Node3D
	if marker == null:
		CellFlight.warn_once("CrateJars", "truck.gd: no CrateJars marker on the crate (see game/specs/0.1-harvest.md, jar_crate.tscn).")
	else:
		for i in CRATE_JARS_SHOWN:
			var jar: Node3D = _new_jar()
			if jar == null:
				break
			jar.name = "CrateJar%d" % i
			jar.position = Vector3(0.4 * float(i % 3), 0.0, 0.3 * float(i / 3))
			jar.visible = false
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
	for i in _bed_jars.size():
		_bed_jars[i].visible = i < loaded_jars
	for i in _crate_jar_meshes.size():
		_crate_jar_meshes[i].visible = i < crate_jars
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
