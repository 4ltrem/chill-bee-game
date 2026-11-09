# Implements GDD 2 (Stage 1 uncapping) and Engine Integration (PhysicsDirectSpaceState3D raycasts onto cell collision shapes;
# cell state as a byte array). Cells differ in height as well as colour (GDD 8). 0.1 Harvest (game/specs/0.1-harvest.md): shows ONE
# frame of the hive (hive.frame_cells), writes each scrape back through hive.scrape(), and after the untouched pop flies the cell to the
# target main.gd assigned. The cell models come from res://scenes/props/honey_cell.tscn; the four cell materials from game/materials/.
# `_apply_visual` and `_pop` are exactly as in revision 3 (designer: "DO NOT change the comb animations").
class_name Honeycomb
extends Node3D

signal all_cells_uncapped
signal slid_out
## Every cell has been scraped and has left the frame (after its pop): the frame is done.
signal frame_done
## A cell was scraped: its index, the jars it was worth (0 with no hive) and where it is in the world.
signal cell_scraped(cell: int, jar_value: float, world_position: Vector3)

const CAPPED: int = 0
const UNCAPPED: int = 1
const EXTRACTED: int = 2

const CELL_HEIGHT: float = 0.3
const CELL_YAW: float = 0.0   # the cell's 30 degree turn is built into hex_cell_mesh.gd (corners on x, flats on z, so columns stack along z); nothing else turns it
const DEFAULT_CELL_PITCH: float = 1.85   # PLACEHOLDER: 1.95 overshot the inner rect and touched the bars (T14.4); within 15% of r9-a's proportion
const STATE_Y: Array[float] = [0.12, 0.0, -0.12]   # capped raised, uncapped flush, extracted recessed
const SWEEP_STEP_PX: float = 16.0                   # fast drags are sampled at this screen spacing
const RAY_LENGTH: float = 200.0
## The pop's length in `_pop` below. A cell leaves the frame this long after its scrape. Must match `_pop`.
const POP_SECONDS: float = 0.18

@export var config: GameConfig = GameConfig.live()
@export var cell_radius: float = 0.46
@export var cell_pitch: float = DEFAULT_CELL_PITCH   # frame-local units; 1.865 fills Bob's 9 x 4.82 frame edge to edge (item 14)
## Drags only uncap while true (hive.gd turns it on while a frame is risen).
@export var active: bool = true

## One byte per cell: 0 Capped, 1 Uncapped, 2 Extracted.
var cells: PackedByteArray = PackedByteArray()
## The hive and frame this node shows (null when standalone).
var hive: Hive
var frame_index: int = -1

var _cell_meshes: Array[MeshInstance3D] = []
var _cell_roots: Array[Node3D] = []
var _materials: Array[StandardMaterial3D] = []
var _home: Vector3 = Vector3.ZERO
var _rise_dir: Vector3 = Vector3.UP
var _rise_t: float = 0.0
var _bar: Node3D
var _bar_home: Vector3 = Vector3.ZERO
var _slide: Tween
var _dragging: bool = false
var _last_pos: Vector2 = Vector2.ZERO
var _departures: Array = []        # {cell, t}: cells popping, about to fly
var _flights: Dictionary = {}      # cell -> {to, to_scale, land}
var _done_emitted: bool = false


func _init() -> void:
	_alloc()


func _alloc() -> void:
	cells.resize(config.grid_cols * config.grid_rows)
	cells.fill(CAPPED)


# --- the rise: a frame stands upright and slides up out of the hive body, and back down (config.frame_rise) ---

## Sets where this frame's slot is (hive-local transform) and the wooden frame bar that moves with it. Called by hive.gd.
func place(slot_transform: Transform3D, bar_node: Node3D) -> void:
	_kill_slide()
	transform = slot_transform
	_home = slot_transform.origin
	_rise_dir = (-slot_transform.basis.z).normalized()
	_rise_t = 0.0
	_bar = bar_node
	if _bar != null:
		_bar.transform = slot_transform
		_bar_home = slot_transform.origin


## Rises by frame_rise over slide_seconds. Drags may uncap as soon as it starts: the colliders move with the node.
func slide_in() -> void:
	_kill_slide()
	_set_rise(0.0)
	if not is_inside_tree():
		_set_rise(1.0)
		return
	_slide = create_tween()
	_slide.tween_method(_set_rise, 0.0, 1.0, config.slide_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Sinks the same way, then emits slid_out.
func slide_out() -> void:
	_kill_slide()
	if not is_inside_tree():
		_set_rise(0.0)
		slid_out.emit()
		return
	_slide = create_tween()
	_slide.tween_method(_set_rise, _rise_t, 0.0, config.slide_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_slide.tween_callback(func() -> void: slid_out.emit())


func _set_rise(t: float) -> void:
	_rise_t = t
	var offset: Vector3 = _rise_dir * config.frame_rise * t
	position = _home + offset
	if _bar != null and is_instance_valid(_bar):
		_bar.position = _bar_home + offset


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


## Standalone use (no hive): every cell Capped again.
func reset() -> void:
	_dragging = false
	_departures.clear()
	_flights.clear()
	_done_emitted = false
	cells.fill(CAPPED)
	_refresh_all()


## Shows one frame of the hive. Cells still popping from the previous frame leave first.
func load_frame(hive_node: Hive, index: int) -> void:
	_flush_departures()
	_dragging = false
	hive = hive_node
	frame_index = index
	_done_emitted = false
	var states: PackedByteArray = hive.frame_cells(index)
	if states.size() == cells.size():
		cells = states
	_refresh_all()


## Uncaps one cell (Capped to Uncapped), pops it, moves its jar value out of the hive. It leaves the frame after the pop.
## Returns true if it changed.
func uncap_at(cell: int) -> bool:
	if cell < 0 or cell >= cells.size() or cells[cell] != CAPPED:
		return false
	cells[cell] = UNCAPPED
	_apply_visual(cell)
	_pop(cell)
	_set_collider(cell, false)   # a scraped slot's collider is off from now on
	var jar_value: float = 0.0
	if hive != null:
		jar_value = hive.scrape(frame_index, cell)
	cell_scraped.emit(cell, jar_value, _cell_world_position(cell))
	_departures.append({"cell": cell, "t": POP_SECONDS})
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
	_refresh_all()


## Where a scraped cell flies after its pop. Call from the cell_scraped handler. on_land draws the landing (visual only).
func assign_flight(cell: int, to: Vector3, to_scale: float, on_land: Callable) -> void:
	_flights[cell] = {"to": to, "to_scale": to_scale, "land": on_land}


## Per-frame logic, separate from _process so it can be tested headless: popping cells leave the frame.
func advance(delta: float) -> void:
	var i: int = _departures.size() - 1
	while i >= 0:
		var entry: Dictionary = _departures[i]
		entry["t"] = float(entry["t"]) - delta
		if float(entry["t"]) <= 0.0:
			_departures.remove_at(i)
			_depart(int(entry["cell"]))
		i -= 1
	_check_frame_done()


func _process(delta: float) -> void:
	if not _departures.is_empty():
		advance(delta)


func _flush_departures() -> void:
	while not _departures.is_empty():
		var entry: Dictionary = _departures.pop_front()
		_depart(int(entry["cell"]))


## The cell leaves its slot: the slot is empty (no mesh) from now on, and a copy flies on to its target.
func _depart(cell: int) -> void:
	if cell < 0 or cell >= cells.size():
		return
	var from: Vector3 = _cell_world_position(cell)
	var from_scale: float = (global_transform.basis.get_scale().x if is_inside_tree() else 1.0) * config.frame_scale
	cells[cell] = EXTRACTED
	_apply_visual(cell)
	if cell < _cell_meshes.size():
		_cell_meshes[cell].visible = false
		_cell_meshes[cell].scale = Vector3.ONE
	var flight: Dictionary = _flights.get(cell, {})
	_flights.erase(cell)
	if not flight.is_empty():
		CellFlight.launch(self, from, flight["to"], config.cell_fly_seconds, config.cell_fly_arc, 0.0,
				from_scale, float(flight["to_scale"]), flight["land"])
	_check_frame_done()


func _check_frame_done() -> void:
	if _done_emitted or not _departures.is_empty():
		return
	for i in cells.size():
		if cells[i] != EXTRACTED:
			return
	_done_emitted = true
	frame_done.emit()


func _set_collider(cell: int, enabled: bool) -> void:
	if cell < 0 or cell >= _cell_roots.size():
		return
	var shape: CollisionShape3D = _cell_roots[cell].find_child("Shape", true, false) as CollisionShape3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
	if shape != null:
		shape.set_deferred("disabled", not enabled)


func _cell_world_position(cell: int) -> Vector3:
	if cell >= 0 and cell < _cell_roots.size() and _cell_roots[cell].is_inside_tree():
		return _cell_roots[cell].global_position
	return position + _cell_position(cell)


# --- visuals ---

func _build_materials() -> void:
	_materials.clear()
	for file_name in ["cell_capped", "cell_uncapped", "cell_extracted"]:
		var loaded: StandardMaterial3D = CellFlight.material(file_name) as StandardMaterial3D
		if loaded == null:
			_materials.clear()   # without the shared palette the cells stay unpainted (one warning logged)
			return
		_materials.append(loaded)


func _cell_position(index: int) -> Vector3:
	return cell_position(index, config.grid_cols, config.grid_rows, cell_pitch)


## A cell's frame-local position (shared with hive_comb_view.gd so the resting frames match the risen one).
static func cell_position(index: int, cols: int, rows: int, cell_pitch: float) -> Vector3:
	# 0.1.4 item 14 (round 9 variant a): columns run across the frame, each with `rows` cells; odd columns sit half a cell higher
	# (hex tiling). cell_pitch is the spacing within a column; columns are 0.866 of it apart. Index = col * rows + row.
	var col: int = index / rows
	var row: int = index % rows
	var x: float = (float(col) - float(cols - 1) * 0.5) * cell_pitch * 0.866
	var z: float = (float(row) - float(rows - 1) * 0.5 + 0.5 * float(col % 2) - 0.25) * cell_pitch
	return Vector3(x, 0.0, z)


func _build_cells() -> void:
	for child in get_children():
		if child.name.begins_with("Cell_"):
			child.queue_free()
	_cell_meshes.clear()
	_cell_roots.clear()
	if not ResourceLoader.exists(CellFlight.CELL_SCENE_PATH):
		CellFlight.warn_once(CellFlight.CELL_SCENE_PATH, "%s not found (Bob builds it): the frame has no cells." % CellFlight.CELL_SCENE_PATH)
		return
	var packed: PackedScene = load(CellFlight.CELL_SCENE_PATH) as PackedScene
	for i in cells.size():
		var root: Node3D = packed.instantiate() as Node3D
		root.name = "Cell_%d" % i
		root.position = _cell_position(i)
		var body: Node = root.find_child("Body", true, false)  # contract: optional (inside a prop scene instanced at run time, or numbered)
		if body != null:
			body.set_meta("cell_index", i)
		add_child(root)
		_cell_roots.append(root)
		_cell_meshes.append(root.find_child("Mesh", true, false) as MeshInstance3D)  # contract: optional (inside a prop scene instanced at run time, or numbered)
		_apply_visual(i)
	_refresh_all()


## Applies every cell's state to its mesh; an empty slot (Extracted) shows no mesh.
func _refresh_all() -> void:
	for i in _cell_meshes.size():
		_apply_visual(i)
		_cell_meshes[i].scale = Vector3.ONE * config.frame_scale
		var body: Node3D = _cell_roots[i].find_child("Body", true, false) as Node3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
		if body != null:
			body.scale = Vector3.ONE * config.frame_scale   # collider covers the drawn hex (uniform scale; the shared shape is untouched)
		_cell_meshes[i].visible = cells[i] != EXTRACTED
		_set_collider(i, cells[i] == CAPPED)


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
	var rest: Vector3 = Vector3.ONE * config.frame_scale
	visual.scale = Vector3(1.3, 1.0, 1.3) * config.frame_scale
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", rest, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
