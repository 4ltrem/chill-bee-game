# Implements GDD 2 Stage 1 (cells that arrive while the bucket is closed pile up beside the centrifuge) for 0.1 Harvest
# (game/specs/0.1-harvest.md). Holds the piled cells and their honey in jars. Counts change at the call; the drawn cells follow
# when a flying cell lands (`land`). Draws every landed cell (honey_cell.tscn, Mesh only) in layers, with a count label above the top.
class_name Pile
extends Node3D

const COLUMNS: int = 4         # layout of the stacked cells: columns per row, rows per layer
const ROWS: int = 3
const SPACING_X: float = 0.95
const SPACING_Z: float = 0.85
const LAYER_HEIGHT: float = 0.3
const LABEL_HEIGHT: float = 1.4

@export var config: GameConfig = GameConfig.live()

## Cells in the pile, and the honey they hold in jars.
var cells: int = 0

## Honey in the pile in jars, from the integer cell count: cells x frame_jars / cells_per_frame.
var jars: float:
	get:
		return float(cells * config.frame_jars) / float(maxi(config.cells_per_frame(), 1))

var _landed: int = 0           # cells whose flight has finished (drawn)
var _meshes: Array[Node3D] = []
var _label: Label3D


func _ready() -> void:
	_label = Label3D.new()
	_label.name = "CountLabel"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.02
	_label.position = Vector3(0.0, LABEL_HEIGHT, 0.0)
	_label.visible = false
	add_child(_label)
	_refresh()


## n cells (worth `jar_amount` jars in all) join the pile. Their drawing waits for `land`.
func add(n: int, jar_amount: float) -> void:
	if n <= 0:
		return
	cells += n   # jar_amount is informational: the jars derive from the cell count


## A flying cell arrived: draw it.
func land(n: int = 1) -> void:
	_landed = mini(_landed + n, cells)
	_refresh()


## Takes up to n cells out of the pile and returns the jars they hold.
func take(n: int) -> float:
	n = mini(n, cells)
	if n <= 0:
		return 0.0
	var taken: float = float(n * config.frame_jars) / float(maxi(config.cells_per_frame(), 1))
	cells -= n
	_landed = mini(_landed, cells)
	_refresh()
	return taken


## How many cells are drawn right now.
func visible_count() -> int:
	return _landed


func is_empty() -> bool:
	return cells <= 0


## Where a flying cell should end up (world space).
func landing_position() -> Vector3:
	return global_position + Vector3.UP * LAYER_HEIGHT if is_inside_tree() else position


## The drawn size of one cell: the pile's own scale (set the Pile node's scale in the scene).
func cell_scale() -> float:
	return global_transform.basis.get_scale().x if is_inside_tree() else 1.0


func _refresh() -> void:
	var shown: int = visible_count()
	while _meshes.size() < shown:
		var cell: Node3D = CellFlight.make_cell(CellFlight.material("cell_capped"))
		if cell == null:
			break
		var i: int = _meshes.size()
		var layer: int = i / (COLUMNS * ROWS)
		var slot: int = i % (COLUMNS * ROWS)
		cell.position = Vector3((float(slot % COLUMNS) - float(COLUMNS - 1) * 0.5) * SPACING_X + 0.4 * float(layer % 2),
				LAYER_HEIGHT * (float(layer) + 0.5),
				(float(slot / COLUMNS) - float(ROWS - 1) * 0.5) * SPACING_Z)
		add_child(cell)
		_meshes.append(cell)
	for i in _meshes.size():
		_meshes[i].visible = i < shown
	if _label != null:
		_label.visible = cells > 0
		_label.text = "x%d" % cells
		var top: float = LAYER_HEIGHT * (float((maxi(shown, 1) - 1) / (COLUMNS * ROWS)) + 1.0)
		_label.position.y = maxf(LABEL_HEIGHT, top + 0.5)
