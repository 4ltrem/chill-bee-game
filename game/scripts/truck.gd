# Implements GDD 1 (Primary Game Loop: sell by truck) and 2 (bottling onto the truck) for Prototype 0.
# Holds the truck's load, the jar crate beside the centrifuge, and the trip. Jars bottled while the truck
# is away go to the crate (no limit); when the truck returns, crate jars load onto it up to its capacity.
# Visual: a vintage pickup from boxes, one amber jar per loaded jar on the bed, crate jars on the JarCrate node.
# Every tunable is read from the config when used. Never name a member `load` (it shadows the global).
class_name Truck
extends Node3D

signal load_changed(loaded_jars: int, crate_jars: int)
signal departed
signal returned

const CRATE_JARS_SHOWN: int = 10   # the crate shows at most 10 jars, a count label shows the rest (spec)
const BED_JARS_SHOWN: int = 30     # most jar meshes built on the bed (the truck capacity can be raised in Dev mode)

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
var _bed_jars: Array[MeshInstance3D] = []
var _crate_jar_meshes: Array[MeshInstance3D] = []
var _crate_label: Label3D
var _jar_mesh: CylinderMesh


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
	_jar_mesh = CylinderMesh.new()
	_jar_mesh.top_radius = 0.17
	_jar_mesh.bottom_radius = 0.17
	_jar_mesh.height = 0.3
	var amber := StandardMaterial3D.new()
	amber.albedo_color = Color(0.95, 0.65, 0.1)
	_jar_mesh.material = amber
	_build_pickup()
	_build_crate_jars()
	_refresh_jars()


func _box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = pos
	parent.add_child(mesh_instance)


func _build_pickup() -> void:
	# The pickup faces +X: cab at the front, bed behind it.
	_box(self, "Chassis", Vector3(3.2, 0.2, 1.4), Vector3(0.0, 0.4, 0.0), Color(0.25, 0.25, 0.28))
	_box(self, "Cab", Vector3(1.0, 0.9, 1.3), Vector3(0.9, 0.95, 0.0), Color(0.75, 0.2, 0.2))
	_box(self, "Bed", Vector3(1.9, 0.12, 1.4), Vector3(-0.55, 0.56, 0.0), Color(0.55, 0.35, 0.2))
	_box(self, "BedSideL", Vector3(1.9, 0.35, 0.08), Vector3(-0.55, 0.78, 0.66), Color(0.55, 0.35, 0.2))
	_box(self, "BedSideR", Vector3(1.9, 0.35, 0.08), Vector3(-0.55, 0.78, -0.66), Color(0.55, 0.35, 0.2))
	var wheel_mesh := CylinderMesh.new()
	wheel_mesh.top_radius = 0.32
	wheel_mesh.bottom_radius = 0.32
	wheel_mesh.height = 0.2
	var tyre := StandardMaterial3D.new()
	tyre.albedo_color = Color(0.1, 0.1, 0.1)
	wheel_mesh.material = tyre
	var index: int = 0
	for wx in [1.0, -1.0]:
		for wz in [0.72, -0.72]:
			index += 1
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel%d" % index
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			wheel.position = Vector3(wx, 0.32, wz)
			add_child(wheel)
	for i in BED_JARS_SHOWN:
		var jar := MeshInstance3D.new()
		jar.name = "BedJar%d" % i
		jar.mesh = _jar_mesh
		var col: int = i % 5
		var row: int = (i / 5) % 2
		var layer: int = i / 10
		jar.position = Vector3(-1.2 + 0.4 * float(col), 0.78 + 0.3 * float(layer), -0.3 + 0.6 * float(row))
		jar.visible = false
		add_child(jar)
		_bed_jars.append(jar)


func _build_crate_jars() -> void:
	var crate: Node3D = get_node_or_null(crate_path) as Node3D
	if crate == null:
		return
	for i in CRATE_JARS_SHOWN:
		var jar := MeshInstance3D.new()
		jar.name = "CrateJar%d" % i
		jar.mesh = _jar_mesh
		jar.position = Vector3(-0.4 + 0.4 * float(i % 3), 0.55, -0.3 + 0.3 * float(i / 3))
		jar.visible = false
		crate.add_child(jar)
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
		var extra: int = crate_jars - _crate_jar_meshes.size()
		_crate_label.visible = extra > 0
		_crate_label.text = "+%d" % extra


func _process(delta: float) -> void:
	advance(delta)
	if is_inside_tree():
		position = _home + exit_direction.normalized() * config.truck_slide_distance * away_fraction()
