# Implements GDD 1 (Primary Game Loop: hive storage, overflow buffer) and 2 (Stage 1: the hive is a body of frames under a lid;
# frames rise one at a time). See game/specs/0.1-harvest.md.
# The hive owns the frames: `frames` holds one byte per cell (0 Capped, 1 Uncapped, 2 Extracted = empty slot). Storage in jars is
# derived (capped cells x cell value); an empty slot becomes Capped when enough honey arrives, in frame order, skipping the risen
# frame. Honey with no slot to go to waits in the overflow buffer (one hive) and pours back as slots empty. Full is decided from slot
# counts, never from a float. Every state change happens at the call; tweens (lid lift and fall, frame rise) only draw it.
class_name Hive
extends Node3D

signal storage_changed(storage: float, overflow: float)
signal became_full
signal lid_moved(open: bool)
signal frame_raised(index: int)
signal frame_lowered(index: int)

const CAPPED: int = 0
const UNCAPPED: int = 1
const EXTRACTED: int = 2
const EPS: float = 1.0e-6   # float slack: summed deltas can land one ulp short of a cell's value

@export var config: GameConfig = GameConfig.live()

## One PackedByteArray per frame (built when the hive is created; frames_per_hive and the grid are read then).
var frames: Array = []
var overflow: float = 0.0
## Index of the risen frame, -1 when every frame is down. A risen frame never fills.
var risen: int = -1
var lid_open: bool = false

var _pending: float = 0.0          # honey waiting to become the next cell
var _capped: int = 0
var _empty: int = 0
var _full_announced: bool = false
var _honeycomb: Honeycomb
var _lid: Node3D
var _lid_spot: Node3D
var _lid_motion: LidMotion

## Jars in the hive: capped cells x the cell value.
var storage: float:
	get:
		return float(_capped) * config.cell_value()

## Jars the frames hold when full (the fill bar's maximum).
var capacity: int:
	get:
		return frames.size() * config.frame_jars

var overflow_capacity: float:
	get:
		return float(capacity * config.overflow_hives)


func _init() -> void:
	_alloc()


func _alloc() -> void:
	frames.clear()
	var per_frame: int = config.cells_per_frame()
	for i in config.frames_per_hive:
		var cells := PackedByteArray()
		cells.resize(per_frame)
		cells.fill(EXTRACTED)
		frames.append(cells)
	_capped = 0
	_empty = config.frames_per_hive * per_frame


func _ready() -> void:
	apply_scale()
	_honeycomb = find_child("Honeycomb", true, false) as Honeycomb
	_lid = find_child("HiveLid", true, false) as Node3D
	_lid_spot = find_child("HiveLidSpot", true, false) as Node3D
	if _lid != null:
		_lid_motion = LidMotion.new(_lid, _lid_spot, config, true, true)
	else:
		CellFlight.warn_once("HiveLid", "hive.gd: no HiveLid node (see game/specs/0.1-harvest.md, hive.tscn).")
	if _honeycomb != null:
		_honeycomb.slid_out.connect(_on_slid_out)
		_honeycomb.visible = false
		_honeycomb.active = false


## Sets the hive node's uniform scale from config.hive_scale (read when used, so a Dev mode edit shows at once). Everything under the hive
## (frame slide, lid lift and lean, cell start points) is in hive-local or global terms and follows.
func apply_scale() -> void:
	var target := Vector3.ONE * maxf(config.hive_scale, 0.01)
	if not scale.is_equal_approx(target):
		scale = target


func cell_value() -> float:
	return config.cell_value()


func frame_count() -> int:
	return frames.size()


func is_full() -> bool:
	return _empty == 0


## True when the hive and the overflow buffer are both full.
func is_paused() -> bool:
	return is_full() and overflow + EPS >= overflow_capacity


func has_capped_cells() -> bool:
	return _capped > 0


func frame_capped_count(index: int) -> int:
	if index < 0 or index >= frames.size():
		return 0
	var count: int = 0
	var cells: PackedByteArray = frames[index]
	for state in cells:
		if state == CAPPED:
			count += 1
	return count


## The first frame with a Capped cell, or -1.
func next_frame_to_harvest() -> int:
	for i in frames.size():
		if frame_capped_count(i) > 0:
			return i
	return -1


## A copy of one frame's cell states.
func frame_cells(index: int) -> PackedByteArray:
	if index < 0 or index >= frames.size():
		return PackedByteArray()
	var cells: PackedByteArray = frames[index]
	return cells.duplicate()


## One cell scraped: its slot is empty from now on. Returns the jars it was worth (0 if it was not Capped).
func scrape(frame: int, cell: int) -> float:
	if frame < 0 or frame >= frames.size():
		return 0.0
	var cells: PackedByteArray = frames[frame]
	if cell < 0 or cell >= cells.size() or cells[cell] != CAPPED:
		return 0.0
	cells[cell] = EXTRACTED
	frames[frame] = cells
	_capped -= 1
	_empty += 1
	_full_announced = false
	_pour()   # overflow honey pours back at once (never into the risen frame)
	storage_changed.emit(storage, overflow)
	return config.cell_value()


## Production by delta seconds at the given fill-rate multiplier.
func advance(delta: float, multiplier: float = 1.0) -> void:
	var changed: bool = _pour()
	if is_paused():
		if changed:
			storage_changed.emit(storage, overflow)
		return
	_pending += delta / config.base_seconds_per_jar * multiplier
	var value: float = config.cell_value()
	while _pending + EPS >= value:
		var slot: Vector2i = _next_empty()
		if slot.x < 0:
			break
		_fill_slot(slot)
		_pending = maxf(_pending - value, 0.0)
		changed = true
	if _next_empty().x < 0:
		# No slot can take honey (every empty slot is the risen frame's, or none): it goes to the overflow buffer.
		var room: float = maxf(overflow_capacity - overflow, 0.0)
		var moved: float = minf(_pending, room)
		overflow += moved
		_pending = 0.0
		changed = changed or moved > 0.0
	_announce_if_full()
	if changed:
		storage_changed.emit(storage, overflow)


## Dev mode: fills every empty slot (but the risen frame's) at once.
func fill_now() -> void:
	var slot: Vector2i = _next_empty()
	while slot.x >= 0:
		_fill_slot(slot)
		slot = _next_empty()
	_pending = 0.0
	_announce_if_full()
	storage_changed.emit(storage, overflow)


# --- lid and frames ---

func open_lid() -> void:
	_move_lid(true)


func close_lid() -> void:
	_move_lid(false)


func _move_lid(open: bool) -> void:
	if lid_open == open:
		return
	lid_open = open
	if _lid_motion != null:
		_lid_motion.play(open)   # lifts, then tips and falls to the HiveLidSpot transform; closing is the same path backwards
	lid_moved.emit(open)


## Raises one frame: the Honeycomb shows its cells at that slot and rises by frame_rise. Ignored if a frame is already up.
func raise_frame(index: int) -> void:
	if index < 0 or index >= frames.size() or risen >= 0:
		return
	risen = index
	if _honeycomb != null:
		var slot: Node3D = find_child("Slot" + str(index + 1), true, false) as Node3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
		var bar: Node3D = find_child("FrameBar" + str(index + 1), true, false) as Node3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
		if slot == null:
			CellFlight.warn_once("Slot", "hive.gd: no Slot%d node (see game/specs/0.1-harvest.md, hive.tscn)." % (index + 1))
		var xf: Transform3D = slot.transform if slot != null else Transform3D.IDENTITY
		_honeycomb.place(xf, bar)
		_honeycomb.load_frame(self, index)
		_honeycomb.visible = true
		_honeycomb.active = true
		_honeycomb.slide_in()
	frame_raised.emit(index)


## Sinks the risen frame, keeping its state (scrapes are already in `frames`). The frame may fill again from now on.
func lower_frame() -> void:
	if risen < 0:
		return
	var index: int = risen
	risen = -1
	if _honeycomb != null:
		_honeycomb.active = false
		_honeycomb.slide_out()
	frame_lowered.emit(index)
	if _pour():
		_announce_if_full()
		storage_changed.emit(storage, overflow)


func _on_slid_out() -> void:
	if risen < 0 and _honeycomb != null:
		_honeycomb.visible = false


# --- fill internals ---

func _next_empty() -> Vector2i:
	for f in frames.size():
		if f == risen:
			continue
		var cells: PackedByteArray = frames[f]
		for c in cells.size():
			if cells[c] == EXTRACTED:
				return Vector2i(f, c)
	return Vector2i(-1, -1)


func _fill_slot(slot: Vector2i) -> void:
	var cells: PackedByteArray = frames[slot.x]
	cells[slot.y] = CAPPED
	frames[slot.x] = cells
	_capped += 1
	_empty -= 1


## Overflow honey pours back into empty slots. Returns true if anything moved.
func _pour() -> bool:
	var moved: bool = false
	var value: float = config.cell_value()
	while overflow > 0.0 and overflow + EPS >= value:
		var slot: Vector2i = _next_empty()
		if slot.x < 0:
			break
		_fill_slot(slot)
		overflow = maxf(overflow - value, 0.0)
		moved = true
	if overflow < EPS:
		overflow = 0.0
	return moved


func _announce_if_full() -> void:
	if is_full() and not _full_announced:
		_full_announced = true
		became_full.emit()


func _process(delta: float) -> void:
	apply_scale()
	var multiplier: float = 1.0
	var economy: Node = get_node_or_null("/root/Economy")
	if economy != null:
		multiplier = economy.fill_multiplier()
	advance(delta, multiplier)
