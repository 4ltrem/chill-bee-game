# Implements 0.1.4 item 10 (game/specs/0.1.4-ui-placement.md): the comb cells of every frame show while the frame sits in the hive,
# filling as the hive fills. Display only: no colliders, no input. hive.gd builds it at run time; the one Honeycomb still draws the
# risen frame, so that slot is hidden here until the frame has sunk back. Updates on storage_changed, never per frame.
class_name HiveCombView
extends Node3D

var _hive: Hive
var _holders: Array[Node3D] = []        # one per frame, placed at that frame's Slot marker
var _meshes: Array = []                  # per frame: Array[MeshInstance3D], one per cell
var _slots: Array[Node3D] = []
var _materials: Array[Material] = []
var _hidden: int = -1


## Builds the cell meshes for every frame of `hive` (reads the Slot1..N markers under it).
func setup(hive: Hive) -> void:
	_hive = hive
	for file_name in ["cell_capped", "cell_uncapped", "cell_extracted"]:
		var loaded: Material = CellFlight.material(file_name)
		if loaded == null:
			_materials.clear()
			break
		_materials.append(loaded)
	if not ResourceLoader.exists(CellFlight.CELL_SCENE_PATH):
		CellFlight.warn_once(CellFlight.CELL_SCENE_PATH, "%s not found (Bob builds it): the hive frames show no cells." % CellFlight.CELL_SCENE_PATH)
		return
	var packed: PackedScene = load(CellFlight.CELL_SCENE_PATH) as PackedScene
	var sample: Node3D = packed.instantiate() as Node3D
	var mesh_node: MeshInstance3D = sample.find_child("Mesh", true, false) as MeshInstance3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
	var mesh: Mesh = mesh_node.mesh if mesh_node != null else null
	sample.free()
	if mesh == null:
		return
	var cols: int = hive.config.grid_cols
	var rows: int = hive.config.grid_rows
	var per_frame: int = hive.config.cells_per_frame()
	for f in hive.frame_count():
		var holder := Node3D.new()
		holder.name = "FrameCells%d" % (f + 1)
		add_child(holder)
		_holders.append(holder)
		var slot: Node3D = hive.find_child("Slot" + str(f + 1), true, false) as Node3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
		_slots.append(slot)
		var row: Array[MeshInstance3D] = []
		for c in per_frame:
			var instance := MeshInstance3D.new()
			instance.mesh = mesh
			instance.position = Honeycomb.cell_position(c, cols, rows, Honeycomb.DEFAULT_CELL_PITCH)
			instance.scale = Vector3.ONE * hive.config.frame_scale
			holder.add_child(instance)
			row.append(instance)
		_meshes.append(row)
	refresh(-1)


## Redraws every frame's cells from the hive. `hidden` is the slot the Honeycomb is drawing (-1 for none).
func refresh(hidden: int) -> void:
	_hidden = hidden
	if _hive == null:
		return
	for f in _holders.size():
		var holder: Node3D = _holders[f]
		holder.visible = f != _hidden
		if f == _hidden:
			continue
		var slot: Node3D = _slots[f]
		if slot != null and not holder.transform.is_equal_approx(slot.transform):
			holder.transform = slot.transform
		var states: PackedByteArray = _hive.frames[f]
		var row: Array = _meshes[f]
		for c in row.size():
			var instance: MeshInstance3D = row[c]
			var state: int = states[c] if c < states.size() else Hive.EXTRACTED
			instance.visible = state != Hive.EXTRACTED and not _materials.is_empty()
			if instance.visible:
				instance.material_override = _materials[state]
				instance.position.y = Honeycomb.STATE_Y[state]
