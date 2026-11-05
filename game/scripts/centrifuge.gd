# Implements GDD 2 (Stage 1 end and Stage 2 extraction and bottling, on the farm) and 8 (Accessibility: holding is built in).
# 0.1 Harvest (game/specs/0.1-harvest.md): the centrifuge is a glass bucket with a spigot and a steel lid that carries the crank.
# State machine EMPTY -> LOADING -> FULL -> CRANKING -> DONE -> BOTTLING -> EMPTY. Cells scraped from the frames arrive while the lid is
# off (EMPTY, LOADING); the lid goes on when the bucket holds its capacity in cells or main.gd closes it. Counted turns obey the tap cap
# (max_tap_rate); a hold counts one turn on press, then max_tap_rate per second. Crank input arrives only through _unhandled_input while
# CRANKING and crank_enabled (false during the zoom). Honey is tracked in jars (float): turns needed = ceil(jars x taps_per_jar), a part-full
# bucket bottles floor(jars) jars and the leftover carries into the next batch. Logic changes state at the call; tweens only draw it.
# Every tunable is read from the config when used (Dev mode edits apply at once). The model comes from centrifuge.tscn (names below).
class_name Centrifuge
extends Node3D

enum State { EMPTY, LOADING, FULL, CRANKING, DONE, BOTTLING }

signal state_changed(state: int)
signal extraction_progress(done: float, total: float)
signal turn_counted(turns: int)
signal extraction_done
signal jar_bottled(count: int)
signal bottling_done(jars: int)
signal lid_moved(open: bool)

const EPS: float = 1.0e-6          # float slack for jars x taps and floor(jars)
const HEAP_RADIUS: float = 3.4     # the heap's layers fill a disc of this radius, in HeapRoot units (inside the glass: 1.0 / HeapRoot's 0.25 = 4.0, less a cell's 0.46)
const HEAP_LAYER: float = 0.3      # one heap layer's height (a cell's height), in HeapRoot units
const HEAP_PER_LAYER: int = 40     # cells per layer, spread over the disc (a 5-frame bucket is 5 layers)
const GOLDEN_ANGLE: float = 2.39996

@export var config: GameConfig = GameConfig.live()

var state: int = State.EMPTY
## Cells in the bucket, and the honey in the bucket in jars (cells' honey plus the leftover carried from the last batch).
var cells: int = 0
var leftover_jars: float = 0.0
var lid_open: bool = true
## False during the zoom: no crank input counts.
var crank_enabled: bool = true:
	set(value):
		crank_enabled = value
		if not value:
			holding = false
## Honey in jars (floats): the batch total and how much is extracted so far. Bottled jars are whole.
var jars_total: float = 0.0
var jars_extracted: float = 0.0
var jars_bottled: int = 0
var _bottle_count: int = 0
var turns_counted: int = 0
var holding: bool = false
var spin_speed: float = 0.0

var _clock: float = 0.0
var _last_turn: float = -1.0e9
var _hold_turns: float = 0.0
var _hold_time: float = 0.0
var _bottle_timer: float = 0.0
var _hold_source: String = ""
var _landed: int = 0               # cells whose flight finished (drawn in the heap)

var _spinner: Node3D
var _lid: Node3D
var _lid_spot: Node3D
var _lid_motion: LidMotion
var _mouth: Node3D
var _heap_root: Node3D
var _heap: Array[Node3D] = []
var _heap_melting: bool = false
var _melt_material: StandardMaterial3D
var _last_melt: float = -1.0
var _last_shown: int = -1
var _honey_level: MeshInstance3D
var _honey_bottom: Node3D
var _honey_top: Node3D
var _spigot_jar: Node3D
var _lid_hold: float = 0.0         # seconds the spigot jar still shows full with its lid after a jar finishes (visual only)


# --- the bucket ---

## Honey in the bucket in jars, from the integer cell count (never summed per cell): cells x frame_jars / cells_per_frame, plus the leftover.
var jars: float:
	get:
		return float(cells * config.frame_jars) / float(maxi(config.cells_per_frame(), 1)) + leftover_jars

## Cells the bucket holds when full.
func capacity_cells() -> int:
	return config.bucket_capacity_cells()


## Jars the bucket holds when full (the honey level's maximum).
func capacity_jars() -> float:
	return float(config.centrifuge_capacity_frames * config.frame_jars)


## True when scraped cells can go into the bucket: lid off, not yet full.
func accepts_cells() -> bool:
	return lid_open and (state == State.EMPTY or state == State.LOADING) and cells < capacity_cells()


## Same as accepts_cells (revision 3's name).
func has_room() -> bool:
	return accepts_cells()


func room_cells() -> int:
	if not accepts_cells():
		return 0
	return capacity_cells() - cells


## n cells worth `jar_amount` jars arrive (counted now; drawn when `land_cells` is called). Takes only what fits, scaling the honey.
## The lid goes on when the bucket is full. Returns the cells taken.
func add_cells(n: int, jar_amount: float, close_delay: float = -1.0) -> int:
	var taken: int = mini(n, room_cells())
	if taken <= 0:
		return 0
	cells += taken   # jar_amount is informational: the jars derive from the cell count
	if state == State.EMPTY:
		_set_state(State.LOADING)
	if cells >= capacity_cells():
		close_lid(close_delay)
	return taken


## A flying cell arrived: draw it in the heap.
func land_cells(n: int = 1) -> void:
	_landed = mini(_landed + n, cells)


## The lid goes on a bucket that has cells in it and is not closed yet. Returns true if it closed.
func close_lid(delay: float = -1.0) -> bool:
	if not lid_open or cells <= 0 or not (state == State.EMPTY or state == State.LOADING):
		return false
	lid_open = false
	if delay < 0.0:
		delay = config.cell_fly_seconds if _landed < cells else 0.0   # wait for cells still in flight
	_move_lid_visual(false, delay)
	_set_state(State.FULL)
	lid_moved.emit(false)
	return true


func _open_lid() -> void:
	lid_open = true
	_move_lid_visual(true, 0.0)
	lid_moved.emit(true)


## Where flying cells aim (world space): the bucket's mouth.
func bucket_mouth_position() -> Vector3:
	if _mouth != null and _mouth.is_inside_tree():
		return _mouth.global_position
	return global_position + Vector3.UP * 1.5 if is_inside_tree() else position


## The drawn size of one heap cell (HeapRoot's scale).
func heap_cell_scale() -> float:
	if _heap_root != null and _heap_root.is_inside_tree():
		return _heap_root.global_transform.basis.get_scale().x
	return 1.0


# --- crank ---

## Counted crank turns the bucket needs: ceil(jars x taps_per_jar) for the honey in its CELLS. The carried leftover was extracted
## in an earlier batch, so it needs no turns again (it still counts in `jars` and is bottled).
func turns_needed() -> int:
	var cell_jars: float = float(cells * config.frame_jars) / float(maxi(config.cells_per_frame(), 1))
	return maxi(ceili(cell_jars * float(config.taps_per_jar) - EPS), 0)


## The centrifuge icon was tapped: start cranking.
func begin_crank() -> void:
	if state != State.FULL:
		return
	_reset_crank()
	turns_counted = 0
	jars_extracted = leftover_jars
	jars_bottled = 0
	jars_total = jars
	_bottle_count = floori(jars + EPS)
	_set_state(State.CRANKING)
	extraction_progress.emit(jars_extracted, jars_total)
	if turns_needed() <= 0:
		_finish_extraction()


## One crank turn. Counted only in CRANKING with crank_enabled, and only if at least 1 / max_tap_rate s passed since the last
## counted turn. Returns true if it counted.
func tap() -> bool:
	if state != State.CRANKING or not crank_enabled:
		return false
	if _clock - _last_turn < 1.0 / maxf(config.max_tap_rate, 0.001) - 0.000001:
		return false
	_count_turn()
	return true


## Press and release. Turns accrue at max_tap_rate while held. The press's own turn is counted by the input
## handler calling tap(); set_holding(true) itself does not count a turn.
func set_holding(value: bool) -> void:
	if value:
		if state != State.CRANKING or not crank_enabled:
			return
		if not holding:
			holding = true
			_hold_turns = 0.0
			_hold_time = 0.0
	else:
		holding = false
		_hold_turns = 0.0
		_hold_time = 0.0


## Continue was pressed: open the spigot and start bottling.
func open_spigot() -> void:
	if state != State.DONE:
		return
	_bottle_timer = 0.0
	_set_state(State.BOTTLING)


## Per-frame logic, separate from _process so it can be tested headless.
func advance(delta: float) -> void:
	_clock += delta
	var held: bool = holding and state == State.CRANKING and crank_enabled
	if held:
		_hold_time += delta
		_hold_turns += delta * config.max_tap_rate
		while _hold_turns >= 1.0 and state == State.CRANKING:
			_hold_turns -= 1.0
			_count_turn()
	spin_speed = maxf(spin_speed - config.spin_decay * delta, 0.0)
	if held:
		var ramp: float = clampf(_hold_time / maxf(config.hold_ramp_seconds, 0.001), 0.0, 1.0)
		spin_speed = maxf(spin_speed, config.spin_max * ramp)
	if state == State.BOTTLING:
		_advance_bottling(delta)


func _advance_bottling(delta: float) -> void:
	_bottle_timer += delta
	var per_jar: float = maxf(config.bottling_seconds_per_jar, 0.001)
	while _bottle_timer >= per_jar and jars_bottled < _bottle_count:
		_bottle_timer -= per_jar
		jars_bottled += 1
		_lid_hold = config.jar_lid_seconds
		jar_bottled.emit(jars_bottled)
	if jars_bottled >= _bottle_count:
		_bottle_timer = 0.0
		var bottled: int = _bottle_count
		# The leftover fraction stays in the bucket for the next batch; the combs are gone and the lid lifts off.
		var rest: float = jars_total - float(bottled)
		leftover_jars = rest if rest > EPS else 0.0
		cells = 0
		_landed = 0
		_open_lid()
		_set_state(State.EMPTY)
		bottling_done.emit(bottled)


func _count_turn() -> void:
	_last_turn = _clock
	turns_counted += 1
	spin_speed = minf(spin_speed + config.spin_impulse, config.spin_max)
	var extracted: float = minf(jars_total, leftover_jars + float(floori(float(turns_counted) / float(maxi(config.taps_per_jar, 1)) + EPS)))
	if extracted != jars_extracted:
		jars_extracted = extracted
		extraction_progress.emit(jars_extracted, jars_total)
	turn_counted.emit(turns_counted)
	if turns_counted >= turns_needed():
		_finish_extraction()


func _finish_extraction() -> void:
	holding = false
	jars_extracted = jars_total
	_set_state(State.DONE)
	extraction_done.emit()


func _reset_crank() -> void:
	holding = false
	_hold_turns = 0.0
	_hold_time = 0.0
	_last_turn = -1.0e9


func _set_state(new_state: int) -> void:
	state = new_state
	if state != State.CRANKING:
		holding = false
	state_changed.emit(state)


# --- what the glass shows (pure functions of the logic, so they are testable) ---

## 0 until the first turn, 1 when the combs are fully melted: turns counted over turns needed.
func melt_fraction() -> float:
	match state:
		State.CRANKING:
			return clampf(float(turns_counted) / float(maxi(turns_needed(), 1)), 0.0, 1.0)
		State.DONE, State.BOTTLING:
			return 1.0
	return 0.0


## Honey in the bucket in jars: the leftover, plus the combs' honey as they melt, then dropping jar by jar while bottling.
func honey_jars() -> float:
	if state == State.BOTTLING:
		var frac: float = 0.0
		if jars_bottled < _bottle_count:
			frac = clampf(_bottle_timer / maxf(config.bottling_seconds_per_jar, 0.001), 0.0, 1.0)
		return maxf(jars_total - float(jars_bottled) - frac, 0.0)
	return leftover_jars + maxf(jars - leftover_jars, 0.0) * melt_fraction()


## The honey level as a fraction of the bucket's capacity (0 to 1).
func honey_level_fraction() -> float:
	return clampf(honey_jars() / maxf(capacity_jars(), 0.001), 0.0, 1.0)


# --- input: crank turns come only through _unhandled_input while CRANKING ---

func _unhandled_input(event: InputEvent) -> void:
	if state != State.CRANKING or not crank_enabled or not is_visible_in_tree():
		return
	# Touch and mouse are emulated into each other, so one press can arrive as both. A second press while already
	# holding is a no-op in set_holding, and a release of either ends the hold, so a press never counts twice.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_press(event.pressed, "mouse")
	elif event is InputEventScreenTouch:
		_press(event.pressed, "touch")


func _press(pressed: bool, source: String) -> void:
	if pressed:
		if holding or state != State.CRANKING or not crank_enabled:
			return   # the emulated twin of a press already being held
		_hold_source = source
		tap()
		set_holding(true)
	else:
		set_holding(false)


# --- visuals: the parts come from centrifuge.tscn by name ---

func _ready() -> void:
	_spinner = find_child("Spinner", true, false) as Node3D
	_lid = find_child("Lid", true, false) as Node3D
	_lid_spot = find_child("CentrifugeLidSpot", true, false) as Node3D
	_mouth = find_child("BucketMouth", true, false) as Node3D
	_heap_root = find_child("HeapRoot", true, false) as Node3D
	_honey_level = find_child("HoneyLevel", true, false) as MeshInstance3D
	_honey_bottom = find_child("HoneyBottom", true, false) as Node3D
	_honey_top = find_child("HoneyTop", true, false) as Node3D
	_spigot_jar = find_child("SpigotJar", true, false) as Node3D
	if _spigot_jar != null:
		_spigot_jar.visible = false
	if _lid != null:
		_lid_motion = LidMotion.new(_lid, _lid_spot, config, false)   # position only: the lid keeps its spin and lands flat
		if _lid_spot != null:
			_lid_motion.apply(1.0)   # starts EMPTY: the lid sits on the ground beside the bucket
	else:
		CellFlight.warn_once("CentrifugeLid", "centrifuge.gd: no Lid node (see game/specs/0.1-harvest.md, centrifuge.tscn).")
	var melting: Material = CellFlight.material("comb_melting")
	if melting != null:
		_melt_material = (melting as StandardMaterial3D).duplicate() as StandardMaterial3D


func _move_lid_visual(open: bool, delay: float) -> void:
	if _lid_motion != null:
		_lid_motion.play(open, delay)   # lifts clear of the bucket first, then falls (closing: the same path backwards)


func _process(delta: float) -> void:
	# A release over a button never reaches _unhandled_input: stop holding when the mouse is up.
	if holding and _hold_source == "mouse" and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		set_holding(false)
	advance(delta)
	if spin_speed > 0.0:
		if _spinner != null:
			_spinner.rotate_y(spin_speed * delta)
		if _lid != null and not lid_open:
			_lid.rotate_y(spin_speed * delta)
	_update_heap()
	_update_honey_level()
	_update_spigot_jar(delta)


func _update_heap() -> void:
	if _heap_root == null:
		return
	var shown: int = _landed   # every landed cell is drawn, up to the bucket's capacity (cells never exceeds it)
	var melt: float = melt_fraction()
	if shown == _last_shown and is_equal_approx(melt, _last_melt):
		return
	_last_shown = shown
	_last_melt = melt
	while _heap.size() < shown:
		var cell: Node3D = CellFlight.make_cell(CellFlight.material("cell_capped"))
		if cell == null:
			break
		var i: int = _heap.size()
		var layer: int = i / HEAP_PER_LAYER
		var k: int = i % HEAP_PER_LAYER
		var radius: float = sqrt((float(k) + 0.5) / float(HEAP_PER_LAYER)) * HEAP_RADIUS   # even spread over the disc
		var angle: float = float(k) * GOLDEN_ANGLE + float(layer) * 1.3
		cell.position = Vector3(cos(angle) * radius, HEAP_LAYER * (float(layer) + 0.5), sin(angle) * radius)
		_heap_root.add_child(cell)
		_heap.append(cell)
	var melting: bool = melt > 0.0 and _melt_material != null
	if melting:
		_melt_material.albedo_color.a = 1.0 - melt
	var cell_scale: float = maxf(1.0 - melt, 0.001)
	for i in _heap.size():
		var cell: Node3D = _heap[i]
		cell.visible = i < shown and melt < 1.0
		cell.scale = Vector3.ONE * cell_scale
		if melting != _heap_melting:
			var mesh: MeshInstance3D = cell.find_child("Mesh", true, false) as MeshInstance3D  # contract: optional (inside a prop scene instanced at run time, or numbered)
			if mesh != null:
				mesh.material_override = _melt_material if melting else CellFlight.material("cell_capped")
	_heap_melting = melting


func _update_honey_level() -> void:
	if _honey_level == null or _honey_bottom == null or _honey_top == null:
		return
	var level: float = honey_level_fraction()
	_honey_level.visible = level > 0.001
	if not _honey_level.visible:
		return
	var height: float = maxf(level * (_honey_top.position.y - _honey_bottom.position.y), 0.001)
	_honey_level.scale.y = height
	_honey_level.position.y = _honey_bottom.position.y + height * 0.5


## How full the jar at the spigot looks (0 to 1), or -1 when no jar is there: it fills over bottling_seconds_per_jar, then shows
## full with its lid for jar_lid_seconds (pure function of the logic, so it is testable).
func spigot_jar_fraction() -> float:
	if _lid_hold > 0.0:
		return 1.0
	if state == State.BOTTLING and jars_bottled < _bottle_count:
		return clampf(_bottle_timer / maxf(config.bottling_seconds_per_jar, 0.001), 0.0, 0.999)
	return -1.0


func _update_spigot_jar(delta: float) -> void:
	_lid_hold = maxf(_lid_hold - delta, 0.0)
	if _spigot_jar == null:
		return
	var fraction: float = spigot_jar_fraction()
	_spigot_jar.visible = fraction >= 0.0
	if fraction >= 0.0:
		JarFill.set_fraction(_spigot_jar, fraction)
