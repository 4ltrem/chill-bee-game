# Implements GDD 2 (Phase 1 Uncapping minigame) and Engine Integration (PhysicsDirectSpaceState3D raycasts
# onto cell collision shapes; cell state as a byte array). Cells differ in height as well as colour (GDD 8).
class_name Honeycomb
extends Node3D

signal all_cells_uncapped
signal slid_out

const CAPPED: int = 0
const UNCAPPED: int = 1
const EXTRACTED: int = 2

const CELL_HEIGHT: float = 0.3
const STATE_Y: Array[float] = [0.12, 0.0, -0.12]   # capped raised, uncapped flush, extracted recessed
const SWEEP_STEP_PX: float = 16.0                   # fast drags are sampled at this screen spacing
const RAY_LENGTH: float = 200.0

@export var config: GameConfig = GameConfig.live()
@export var cell_radius: float = 0.46
@export var cell_pitch: float = 1.0
## Drags only uncap while true (main.gd turns it off outside stage 1).
@export var active: bool = true
## Where the frame comes from and goes to, relative to its home (screen top of the close-up: -Z).
@export var slide_offset: Vector3 = Vector3(0.0, 0.0, -12.0)

## One byte per cell: 0 Capped, 1 Uncapped, 2 Extracted.
var cells: PackedByteArray = PackedByteArray()

var _cell_meshes: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _home: Vector3 = Vector3.ZERO
var _slide: Tween
var _dragging: bool = false
var _last_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	_alloc()


func _alloc() -> void:
	cells.resize(config.grid_cols * config.grid_rows)
	cells.fill(CAPPED)


## Slides the frame in from the top of the close-up (GDD 2, colorbox: a position tween, config.slide_seconds).
## Drags may uncap as soon as it starts: the colliders move with the node.
func slide_in() -> void:
	_kill_slide()
	position = _home + slide_offset
	_slide = create_tween()
	_slide.tween_property(self, "position", _home, config.slide_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Slides the uncapped frame away the same way, then emits slid_out.
func slide_out() -> void:
	_kill_slide()
	_slide = create_tween()
	_slide.tween_property(self, "position", _home + slide_offset, config.slide_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_slide.tween_callback(func() -> void: slid_out.emit())


func _kill_slide() -> void:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = null


func _ready() -> void:
	_home = position
	_alloc()
	_build_materials()
	_build_cells()


func cell_count() -> int:
	return cells.size()


func get_state(cell: int) -> int:
	return cells[cell]


func reset() -> void:
	_dragging = false
	cells.fill(CAPPED)
	for i in _cell_meshes.size():
		_apply_visual(i)


## Uncaps one cell (Capped to Uncapped). Returns true if it changed.
func uncap_at(cell: int) -> bool:
	if cell < 0 or cell >= cells.size() or cells[cell] != CAPPED:
		return false
	cells[cell] = UNCAPPED
	_apply_visual(cell)
	_pop(cell)
	if all_uncapped():
		all_cells_uncapped.emit()
	return true


## True when no cell is still Capped.
func all_uncapped() -> bool:
	for i in cells.size():
		if cells[i] == CAPPED:
			return false
	return true


func extract_all() -> void:
	cells.fill(EXTRACTED)
	for i in _cell_meshes.size():
		_apply_visual(i)


# --- visuals ---

func _build_materials() -> void:
	_materials.clear()
	var capped := StandardMaterial3D.new()
	capped.albedo_color = Color(0.85, 0.68, 0.18)
	capped.roughness = 1.0
	var uncapped := StandardMaterial3D.new()
	uncapped.albedo_color = Color(1.0, 0.8, 0.15)
	uncapped.emission_enabled = true
	uncapped.emission = Color(1.0, 0.7, 0.1)
	uncapped.emission_energy_multiplier = 1.6
	var extracted := StandardMaterial3D.new()
	extracted.albedo_color = Color(0.96, 0.92, 0.8)
	extracted.roughness = 1.0
	_materials.append(capped)
	_materials.append(uncapped)
	_materials.append(extracted)


func _cell_position(index: int) -> Vector3:
	var cols: int = config.grid_cols
	var rows: int = config.grid_rows
	var col: int = index % cols
	var row: int = index / cols
	var x: float = (float(col) - float(cols - 1) * 0.5 + 0.5 * float(row % 2) - 0.25) * cell_pitch
	var z: float = (float(row) - float(rows - 1) * 0.5) * cell_pitch * 0.9
	return Vector3(x, 0.0, z)


func _build_cells() -> void:
	for child in get_children():
		if child.name.begins_with("Cell_"):
			child.queue_free()
	_cell_meshes.clear()
	var mesh := CylinderMesh.new()
	mesh.top_radius = cell_radius
	mesh.bottom_radius = cell_radius
	mesh.height = CELL_HEIGHT
	mesh.radial_segments = 6
	mesh.rings = 1
	var shape := CylinderShape3D.new()
	shape.radius = cell_radius
	shape.height = 0.6
	for i in cells.size():
		var body := StaticBody3D.new()
		body.name = "Cell_%d" % i
		body.position = _cell_position(i)
		body.set_meta("cell_index", i)
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		var visual := MeshInstance3D.new()
		visual.name = "Mesh"
		visual.mesh = mesh
		body.add_child(visual)
		add_child(body)
		_cell_meshes.append(visual)
		_apply_visual(i)


func _apply_visual(index: int) -> void:
	if index >= _cell_meshes.size() or _materials.is_empty():
		return
	var state: int = cells[index]
	var visual: MeshInstance3D = _cell_meshes[index]
	visual.material_override = _materials[state]
	visual.position.y = STATE_Y[state]


func _pop(index: int) -> void:
	if index >= _cell_meshes.size() or not is_inside_tree():
		return
	var visual: MeshInstance3D = _cell_meshes[index]
	visual.scale = Vector3(1.3, 1.0, 1.3)
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- drag input ---

func _unhandled_input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		if _dragging:
			_last_pos = event.position
			_probe(event.position)
	elif event is InputEventScreenDrag:
		if _dragging:
			_sweep(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if _dragging:
				_last_pos = event.position
				_probe(event.position)
	elif event is InputEventMouseMotion:
		if _dragging and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_sweep(event.position)


func _sweep(to: Vector2) -> void:
	var distance: float = _last_pos.distance_to(to)
	var steps: int = maxi(1, ceili(distance / SWEEP_STEP_PX))
	for s in range(1, steps + 1):
		_probe(_last_pos.lerp(to, float(s) / float(steps)))
	_last_pos = to


## Raycasts from the screen point through the camera onto the cell collision shapes.
func _probe(screen_pos: Vector2) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * RAY_LENGTH
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty():
		return
	var collider: Object = hit["collider"]
	if collider != null and collider.has_meta("cell_index"):
		uncap_at(int(collider.get_meta("cell_index")))
