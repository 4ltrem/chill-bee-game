# Implements the Prototype 0 spec "Look: colorbox" and loop step 1: small yellow spheres orbiting between the hive
# and the flowers, one per bee in the swarm up to the visual cap (GDD Bee Rendering Plan: a capped crowd is drawn).
# Added beyond the contract table (visual only). One MultiMeshInstance3D; no per-frame allocations beyond Transform3D values.
# Finds the hive via group "bee_home" and the flower patches via group "flower_patch".
class_name Bees
extends MultiMeshInstance3D

@export var bee_radius: float = 0.09
@export var speed: float = 0.6        # trips per second, visual only; constant whatever the bee count
@export var bob_height: float = 0.6   # visual only

var _home: Vector3 = Vector3.ZERO
var _targets: Array[Vector3] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0
var _drawn: int = 0


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
	multimesh = mm
	for node in get_tree().get_nodes_in_group("bee_home"):
		_home = to_local((node as Node3D).global_position)
		break
	for node in get_tree().get_nodes_in_group("flower_patch"):
		_targets.append(to_local((node as Node3D).global_position))
	if _targets.is_empty():
		_targets.append(_home + Vector3(2.0, 0.0, 2.0))
	_resize_flock()
	Economy.swarm_level_changed.connect(func(_l: int) -> void: _resize_flock())


## Number of bees currently drawn: the swarm size, capped.
func drawn_count() -> int:
	return _drawn


## Sets the MultiMesh instance count to min(bee_count, visual_bee_cap) and extends the phases.
## Existing bees keep flying; the instance count only changes on a swarm level change, not per frame.
func _resize_flock() -> void:
	var n: int = mini(Economy.bee_count(), Economy.config.visual_bee_cap)
	if n == _drawn:
		return
	var old: int = mini(_drawn, n)
	_drawn = n
	multimesh.instance_count = n
	_phases.resize(n)
	# Golden-ratio spacing: existing bees keep their phase when the flock grows, so nothing jumps.
	for i in range(old, n):
		_phases[i] = fposmod(float(i) * 0.61803398875, 1.0) * TAU


func _process(delta: float) -> void:
	# Dev mode can change visual_bee_cap or the bee counts live: resize when the target differs (rare, not per bee).
	if mini(Economy.bee_count(), Economy.config.visual_bee_cap) != _drawn:
		_resize_flock()
	_time += delta * speed * TAU
	var mm: MultiMesh = multimesh
	for i in _drawn:
		var target: Vector3 = _targets[i % _targets.size()]
		var t: float = 0.5 + 0.5 * sin(_time + _phases[i])
		var pos: Vector3 = _home.lerp(target, t)
		pos.y += 0.5 + bob_height * sin(_time * 2.0 + _phases[i] * 3.0) * 0.5
		pos.x += 0.25 * cos(_time * 3.0 + _phases[i])
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
