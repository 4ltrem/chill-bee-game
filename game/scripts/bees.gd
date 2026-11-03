# Implements the Prototype 0 spec "Look: colorbox": small yellow spheres orbiting between the hive and the flowers.
# Added beyond the contract table (visual only). One MultiMeshInstance3D; no per-frame allocations beyond Transform3D values.
# Finds the hive via group "bee_home" and the flower patches via group "flower_patch".
class_name Bees
extends MultiMeshInstance3D

@export var bee_count: int = 12
@export var bee_radius: float = 0.09
@export var speed: float = 0.6        # trips per second, visual only
@export var bob_height: float = 0.6   # visual only

var _home: Vector3 = Vector3.ZERO
var _targets: Array[Vector3] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = bee_radius
	sphere.height = bee_radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.88, 0.1)
	sphere.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sphere
	mm.instance_count = bee_count
	multimesh = mm
	for node in get_tree().get_nodes_in_group("bee_home"):
		_home = to_local((node as Node3D).global_position)
		break
	for node in get_tree().get_nodes_in_group("flower_patch"):
		_targets.append(to_local((node as Node3D).global_position))
	if _targets.is_empty():
		_targets.append(_home + Vector3(2.0, 0.0, 2.0))
	_phases.resize(bee_count)
	for i in bee_count:
		_phases[i] = float(i) / float(bee_count) * TAU


func _process(delta: float) -> void:
	_time += delta * speed * TAU
	var mm: MultiMesh = multimesh
	for i in bee_count:
		var target: Vector3 = _targets[i % _targets.size()]
		var t: float = 0.5 + 0.5 * sin(_time + _phases[i])
		var pos: Vector3 = _home.lerp(target, t)
		pos.y += 0.5 + bob_height * sin(_time * 2.0 + _phases[i] * 3.0) * 0.5
		pos.x += 0.25 * cos(_time * 3.0 + _phases[i])
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
