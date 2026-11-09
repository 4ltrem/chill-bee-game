# Implements the Prototype 0 spec "Look: colorbox" and loop step 1: small yellow spheres orbiting between the hive
# and the flowers, one per bee in the swarm up to the visual cap (GDD Bee Rendering Plan: a capped crowd is drawn).
# Added beyond the contract table (visual only). One MultiMeshInstance3D; no per-frame allocations beyond Transform3D values.
# Finds the hive via group "bee_home" and the flower patches via group "flower_patch".
class_name Bees
extends MultiMeshInstance3D

@export var bee_radius: float = 0.09
@export var speed: float = 0.6        # trips per second, visual only; constant whatever the bee count
@export var bob_height: float = 0.6   # visual only

const BEE_MARGIN_PX: float = 24.0   # clear space kept around the rack on screen, in pixels (visual only)

var _home: Vector3 = Vector3.ZERO
var _targets: Array[Vector3] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0
var _drawn: int = 0
var _avoid_camera: Camera3D       # set during the zoom: no bee is drawn over the avoided box on screen (0.1.2 clarification)
var _avoid_box: AABB = AABB()


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


## While the zoom is open: bees keep flying but their paths are pushed (in the camera's plane, so depth is kept) out of the screen
## rectangle the world box covers. `box` is the risen rack in world space.
func set_avoid(camera: Camera3D, box: AABB) -> void:
	_avoid_camera = camera
	_avoid_box = box


func clear_avoid() -> void:
	_avoid_camera = null


## True while bees steer around the rack.
func is_avoiding() -> bool:
	return _avoid_camera != null


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
	var avoiding: bool = _avoid_camera != null and _avoid_camera.is_inside_tree()
	var rect := Rect2()
	var px_world: float = 0.0
	if avoiding:
		rect = _avoid_rect()
		px_world = _avoid_camera.size / maxf(get_viewport().get_visible_rect().size.y, 1.0)   # orthographic: world units per screen pixel
	for i in _drawn:
		var target: Vector3 = _targets[i % _targets.size()]
		var t: float = 0.5 + 0.5 * sin(_time + _phases[i])
		var pos: Vector3 = _home.lerp(target, t)
		pos.y += 0.5 + bob_height * sin(_time * 2.0 + _phases[i] * 3.0) * 0.5
		pos.x += 0.25 * cos(_time * 3.0 + _phases[i])
		if avoiding:
			pos = _steer_clear(pos, rect, px_world)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))


## The avoided box's screen rectangle, grown by a bee's size and a margin.
func _avoid_rect() -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for k in 8:
		var corner: Vector3 = _avoid_box.get_endpoint(k)
		var p: Vector2 = _avoid_camera.unproject_position(corner)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	return Rect2(lo, hi - lo).grow(BEE_MARGIN_PX)


## A bee whose screen point is inside the rectangle moves along the camera's plane to the nearest edge.
func _steer_clear(pos: Vector3, rect: Rect2, px_world: float) -> Vector3:
	var world: Vector3 = to_global(pos)
	var p: Vector2 = _avoid_camera.unproject_position(world)
	if not rect.has_point(p):
		return pos
	var to_left: float = p.x - rect.position.x
	var to_right: float = rect.end.x - p.x
	var to_top: float = p.y - rect.position.y
	var to_bottom: float = rect.end.y - p.y
	var shift := Vector2.ZERO
	var nearest: float = minf(minf(to_left, to_right), minf(to_top, to_bottom))
	if nearest == to_left:
		shift.x = -to_left
	elif nearest == to_right:
		shift.x = to_right
	elif nearest == to_top:
		shift.y = -to_top
	else:
		shift.y = to_bottom
	var basis: Basis = _avoid_camera.global_transform.basis
	var moved: Vector3 = world + (basis.x * shift.x - basis.y * shift.y) * px_world
	return to_local(moved)
