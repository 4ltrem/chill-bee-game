# Implements GDD 2 Stage 1 (a scraped cell flies into the bucket or pile) for 0.1 Harvest (game/specs/0.1-harvest.md).
# Helper for the cell models: makes a visual-only honey cell from res://scenes/props/honey_cell.tscn (the collider is
# freed) and flies one along an arc. Visuals only: callers move the jar value at once and use on_land to draw the landing.
class_name CellFlight
extends RefCounted

const CELL_SCENE_PATH := "res://scenes/props/honey_cell.tscn"
const MATERIAL_DIR := "res://materials/"

static var _scene: PackedScene
static var _warned: Dictionary = {}


## Warns once per key, so a missing scene never floods the log.
static func warn_once(key: String, text: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning(text)


## Loads a shared material from game/materials/ by file name (without .tres); null (with one warning) if absent.
static func material(file_name: String) -> Material:
	var path: String = MATERIAL_DIR + file_name + ".tres"
	if not ResourceLoader.exists(path):
		warn_once(path, "Material %s not found (Bob builds game/materials/)." % path)
		return null
	return load(path) as Material


## A honey cell with no collider, or null when honey_cell.tscn is missing. The cell is not in the tree yet.
static func make_cell(cell_material: Material) -> Node3D:
	if _scene == null:
		if not ResourceLoader.exists(CELL_SCENE_PATH):
			warn_once(CELL_SCENE_PATH, "%s not found (Bob builds it)." % CELL_SCENE_PATH)
			return null
		_scene = load(CELL_SCENE_PATH) as PackedScene
	var cell: Node3D = _scene.instantiate() as Node3D
	var body: Node = cell.get_node_or_null("Body")
	if body != null:
		body.free()   # not in the tree yet, so freeing now is safe
	var mesh: MeshInstance3D = cell.get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null and cell_material != null:
		mesh.material_override = cell_material
	return cell


## Flies a cell from `from` to `to` (world space) on an arc after `delay`; on_land runs when it arrives.
## Without the cell scene the landing still fires on time.
static func launch(host: Node, from: Vector3, to: Vector3, seconds: float, arc: float, delay: float,
		from_scale: float, to_scale: float, on_land: Callable) -> void:
	if not host.is_inside_tree():
		if on_land.is_valid():
			on_land.call()
		return
	var cell: Node3D = make_cell(material("cell_uncapped"))
	if cell == null:
		var timer: SceneTreeTimer = host.get_tree().create_timer(maxf(delay + seconds, 0.001))
		timer.timeout.connect(func() -> void:
			if on_land.is_valid():
				on_land.call())
		return
	var tree: SceneTree = host.get_tree()
	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	parent.add_child(cell)
	cell.visible = false
	cell.global_position = from
	cell.scale = Vector3.ONE * from_scale
	var tween: Tween = cell.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(cell.show)
	tween.tween_method(func(t: float) -> void:
		cell.global_position = from.lerp(to, t) + Vector3.UP * (arc * 4.0 * t * (1.0 - t))
		cell.scale = Vector3.ONE * lerpf(from_scale, to_scale, t), 0.0, 1.0, maxf(seconds, 0.001))
	tween.tween_callback(func() -> void:
		if on_land.is_valid():
			on_land.call()
		cell.queue_free())
