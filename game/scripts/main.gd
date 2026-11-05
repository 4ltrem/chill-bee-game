# Implements GDD 1 (Primary Game Loop) and 2 (the whole harvest plays on the farm; for uncapping the camera zooms in on the hive and the
# centrifuge) for 0.1 Harvest (game/specs/0.1-harvest.md). Owns the flow: fork icon -> zoom (hive lid off, frames rise one at a time,
# scraped cells fly to the bucket or the pile, Back or all frames done) -> centrifuge icon -> crank -> bottling starts by itself (jars
# fly crate -> spigot -> truck or crate; the pile loads into the empty bucket) -> Sell icon -> summary (0.1.2) -> upgrade -> round again. The farm stays live through the whole
# harvest; only the farm UI hides during the zoom.
# Logic is synchronous or runs on timers in advance(delta) (headless-testable); tweens only draw the camera and lids.
extends Node3D

enum Zoom { NONE, OPENING, RISING, WORKING, LOWERING, CLOSE_DELAY, BACK_LOWERING, CLOSING }

const JarFlight := preload("res://scripts/jar_flight.gd")
const MAX_FLIGHTS: int = 40   # most cell flights launched at once when the pile loads (flight nodes, not cells drawn: every cell still lands)

var zoom: int = Zoom.NONE
## Set by Back, cleared when a zoom ends on its own: the fork icon shows while any frame still has a Capped cell.
var resume_pending: bool = false

var _hive: Hive
var _farm_world: Node3D
var _farm_ui: FarmUI
var _farm_camera: Camera3D
var _centrifuge: Centrifuge
var _truck: Truck
var _pile: Pile
var _zoom_framing: Node3D
var _fork_icon: FloatingIcon
var _centrifuge_icon: FloatingIcon
var _sell_icon: FloatingIcon
var _honeycomb: Honeycomb
var _bees: Bees
var _harvest_ui: HarvestUI
var _queue: Array[int] = []        # frames that had Capped cells when the zoom opened
var _timer: float = 0.0
var _trips: Array[Node3D] = []     # jars fetched to the spigot, in order, waiting for their bottled signal
var _going_back: bool = false
var _cam_home_pos: Vector3 = Vector3.ZERO
var _cam_home_size: float = 20.0
var _cam_tween: Tween


func _ready() -> void:
	_hive = find_child("Hive", true, false) as Hive
	_farm_world = find_child("FarmWorld", true, false) as Node3D
	_farm_ui = find_child("FarmUI", true, false) as FarmUI
	_farm_camera = find_child("Camera3D", false, false) as Camera3D
	_centrifuge = find_child("Centrifuge", true, false) as Centrifuge
	_truck = find_child("Truck", true, false) as Truck
	_pile = find_child("Pile", true, false) as Pile
	_bees = find_child("Bees", true, false) as Bees
	_zoom_framing = find_child("ZoomFraming", true, false) as Node3D
	_harvest_ui = find_child("HarvestUI", true, false) as HarvestUI
	_fork_icon = find_child("ForkIcon", true, false) as FloatingIcon
	_centrifuge_icon = find_child("CentrifugeIcon", true, false) as FloatingIcon
	_sell_icon = find_child("SellIcon", true, false) as FloatingIcon
	if GameConfig.dev_mode_enabled():
		var panel := DevPanel.new()
		panel.name = "DevPanel"
		panel.config = Economy.config
		add_child(panel)
		panel.setup(_hive, _truck)
	if _hive == null or _farm_ui == null or _centrifuge == null or _truck == null:
		push_error("main.gd: Hive, FarmUI, Centrifuge or Truck node missing (see Node paths for Bob).")
		return
	if _farm_camera != null:
		_cam_home_pos = _farm_camera.global_position
		_cam_home_size = _farm_camera.size
	_honeycomb = _hive.find_child("Honeycomb", true, false) as Honeycomb
	if _honeycomb != null:
		_honeycomb.cell_scraped.connect(_on_cell_scraped)
		_honeycomb.frame_done.connect(_on_frame_done)
	else:
		push_warning("main.gd: no Honeycomb node under Hive (see game/specs/0.1-harvest.md, Node paths for Bob).")
	if _pile == null:
		push_warning("main.gd: no Pile node (see game/specs/0.1-harvest.md, Node paths for Bob).")
	if _harvest_ui != null:
		_harvest_ui.back_pressed.connect(back)
	_farm_ui.setup(_hive, _centrifuge, _truck)
	_hive.storage_changed.connect(func(_s: float, _o: float) -> void: _refresh_icons())
	_hive.became_full.connect(_refresh_icons)
	_centrifuge.state_changed.connect(_on_centrifuge_state)
	_centrifuge.external_jars = true
	_centrifuge.jar_bottled.connect(_on_jar_bottled)
	_centrifuge.jar_requested.connect(_on_jar_requested)
	_centrifuge.bottling_done.connect(_on_bottling_done)
	_truck.load_changed.connect(func(_l: int, _c: int) -> void: _refresh_icons())
	_truck.departed.connect(_refresh_icons)
	_truck.returned.connect(_refresh_icons)
	if _fork_icon != null:
		_fork_icon.pressed.connect(open_zoom)
	if _centrifuge_icon != null:
		_centrifuge_icon.pressed.connect(func() -> void: _centrifuge.begin_crank())
	if _sell_icon != null:
		_sell_icon.pressed.connect(sell)
	_refresh_icons()


func _process(delta: float) -> void:
	advance(delta)


# --- the state table: which floating icons show right now ---

## The fork rule (spec step 2): the hive is full, whatever the centrifuge is doing; after a Back, also while any frame has a Capped cell.
func fork_available() -> bool:
	if _hive == null:
		return false
	return _hive.is_full() or (resume_pending and _hive.has_capped_cells())


## Cheap; called on every state change.
func _refresh_icons() -> void:
	if _centrifuge == null or _truck == null:
		return
	var on_farm: bool = zoom == Zoom.NONE
	if _fork_icon != null:
		_fork_icon.set_wanted(on_farm and fork_available())
	if _centrifuge_icon != null:
		_centrifuge_icon.set_wanted(on_farm and _centrifuge.state == Centrifuge.State.FULL)
	if _sell_icon != null:
		var can_sell: bool = on_farm and _truck.can_sell()
		_sell_icon.set_wanted(can_sell)
		if can_sell:
			_sell_icon.text = "Sell $%d" % _truck.load_value()


func _on_centrifuge_state(_state: int) -> void:
	_refresh_icons()


## An empty jar flies from the crate to the spigot, fills and gets its lid there (visual; the centrifuge's own timer waits for it).
func _on_jar_requested(delay: float) -> void:
	var config: GameConfig = Economy.config
	var jar: Node3D = JarFlight.fetch(self, _truck.empties_position(), _centrifuge.spigot_position(), config.jar_fly_seconds,
			config.cell_fly_arc, delay, _centrifuge.spigot_jar_scale(), config.bottling_seconds_per_jar)
	if jar != null:
		_trips.append(jar)


## A jar is bottled: the jar at the spigot flies on to the truck or the crate (the truck counts it at once).
func _on_jar_bottled(_n: int) -> void:
	var carrier: Node3D = _trips.pop_front() if not _trips.is_empty() else null
	_truck.receive_jar(_centrifuge.spigot_position(), Economy.config.jar_lid_seconds, carrier)


## Sell (icon): credits the money, sends the truck off, and the summary shows jars sold, price per jar and the total. Returns the total.
func sell() -> int:
	var jars: int = _truck.loaded_jars
	var total: int = _truck.sell()
	if total > 0:
		_farm_ui.show_summary(jars, Economy.jar_value(), total)
	return total


## Bottling finished: the bucket is empty and open (centrifuge.gd lifted its lid), and the pile loads in.
func _on_bottling_done(_jars: int) -> void:
	load_pile()


## Spec step 7: pile cells move into the empty, open bucket by themselves, up to its capacity. If that fills the bucket, or no zoom is
## open, the lid goes on; with a zoom open the bucket stays open for the cells still coming.
func load_pile() -> void:
	if _pile == null or _pile.is_empty():
		return
	var n: int = mini(_pile.cells, _centrifuge.room_cells())
	if n <= 0:
		return
	var config: GameConfig = Economy.config
	var flights: int = maxi(1, mini(n, MAX_FLIGHTS))
	var stagger: float = config.pile_load_stagger_seconds
	var closes_in: float = config.cell_fly_seconds + stagger * float(flights - 1)
	var from: Vector3 = _pile.landing_position()
	var from_scale: float = _pile.cell_scale()
	var jars: float = _pile.take(n)
	_centrifuge.add_cells(n, jars, closes_in)   # counted at once; closes the lid if it fills
	for j in flights:
		var share: int = n / flights + (1 if j < n % flights else 0)
		CellFlight.launch(self, from, _centrifuge.bucket_mouth_position(), config.cell_fly_seconds, config.cell_fly_arc,
				stagger * float(j), from_scale, _centrifuge.heap_cell_scale(), func() -> void: _centrifuge.land_cells(share))
	if zoom == Zoom.NONE:
		_centrifuge.close_lid(closes_in)
	_refresh_icons()


# --- stage 1: the zoom ---

## The fork was tapped: zoom in on the hive and the centrifuge. Returns false if the fork rule or the frame queue says no.
func open_zoom() -> bool:
	if zoom != Zoom.NONE or _hive == null or not fork_available():
		return false
	_queue.clear()
	for i in _hive.frame_count():
		if _hive.frame_capped_count(i) > 0:
			_queue.append(i)
	if _queue.is_empty():
		return false
	_going_back = false
	zoom = Zoom.OPENING
	_timer = Economy.config.lid_move_seconds()
	_farm_ui.visible = false
	if _harvest_ui != null:
		_harvest_ui.show_zoom()
	_centrifuge.set_holding(false)
	_centrifuge.crank_enabled = false
	_hive.open_lid()
	_move_camera(true)
	if _bees != null and _farm_camera != null:
		_bees.set_avoid(_farm_camera, _rack_box())
	_refresh_icons()
	return true


## Back: the risen frame sinks keeping its state, the hive lid goes back on and the camera zooms out.
## The fork stays available while any frame has Capped cells (resume_pending).
func back() -> void:
	match zoom:
		Zoom.OPENING:
			_going_back = true
			zoom = Zoom.BACK_LOWERING
			_timer = 0.0
		Zoom.RISING, Zoom.WORKING:
			_going_back = true
			_hive.lower_frame()
			zoom = Zoom.BACK_LOWERING
			_timer = Economy.config.slide_seconds
		Zoom.LOWERING:
			_going_back = true   # the frame is already sinking; the zoom ends when it is down


## Timers of the zoom sequence, separate from _process so a headless test can step them.
func advance(delta: float) -> void:
	if zoom == Zoom.NONE or zoom == Zoom.WORKING:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	match zoom:
		Zoom.OPENING:
			if not _raise_next():
				_begin_close_delay()
		Zoom.RISING:
			zoom = Zoom.WORKING
		Zoom.LOWERING:
			if _going_back:
				_start_closing(false)
			elif not _raise_next():
				_begin_close_delay()
		Zoom.CLOSE_DELAY:
			_start_closing(true)
		Zoom.BACK_LOWERING:
			_start_closing(false)
		Zoom.CLOSING:
			_finish_zoom()


## The hive's world box with room above for the risen frame (frame_rise, in hive units): what bees keep off while the zoom is open.
func _rack_box() -> AABB:
	var box := AABB()
	var first: bool = true
	for node in _hive.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var b: AABB = mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		box = AABB(_hive.global_position - Vector3(1.0, 0.0, 1.0), Vector3(2.0, 1.0, 2.0))
	var rise: float = Economy.config.frame_rise * _hive.global_transform.basis.get_scale().y
	box = box.merge(AABB(box.position + Vector3.UP * rise, box.size))
	return box


## Raises the next queued frame that still has Capped cells. False when the queue is exhausted.
func _raise_next() -> bool:
	while not _queue.is_empty():
		var index: int = _queue.pop_front()
		if _hive.frame_capped_count(index) > 0:
			_hive.raise_frame(index)
			zoom = Zoom.RISING
			_timer = Economy.config.slide_seconds
			return true
	return false


func _begin_close_delay() -> void:
	zoom = Zoom.CLOSE_DELAY
	_timer = Economy.config.close_delay_seconds
	if _harvest_ui != null:
		_harvest_ui.show_done()


## The last frame's cells have all left it: it sinks, then the next frame rises or the zoom closes.
func _on_frame_done() -> void:
	if zoom != Zoom.RISING and zoom != Zoom.WORKING:
		return
	_hive.lower_frame()
	zoom = Zoom.LOWERING
	_timer = Economy.config.slide_seconds


## Hive lid back on, camera out, and the bucket's lid on if it is open with cells in it (spec step 3, either way the zoom ends).
func _start_closing(on_own: bool) -> void:
	zoom = Zoom.CLOSING
	_timer = maxf(Economy.config.zoom_seconds, Economy.config.lid_move_seconds())
	resume_pending = not on_own
	_hive.close_lid()
	_centrifuge.close_lid()
	_move_camera(false)


func _finish_zoom() -> void:
	zoom = Zoom.NONE
	_going_back = false
	_queue.clear()
	_farm_ui.visible = true
	if _bees != null:
		_bees.clear_avoid()
	if _harvest_ui != null:
		_harvest_ui.hide_zoom()
	_centrifuge.crank_enabled = true
	_refresh_icons()


## A scraped cell: its jar value already left the hive. It goes to the bucket if the bucket is open with room, otherwise to the pile.
func _on_cell_scraped(cell: int, jar_value: float, _world_position: Vector3) -> void:
	if _honeycomb == null:
		return
	if _centrifuge.accepts_cells():
		_centrifuge.add_cells(1, jar_value)
		_honeycomb.assign_flight(cell, _centrifuge.bucket_mouth_position(), _centrifuge.heap_cell_scale(),
				func() -> void: _centrifuge.land_cells(1))
	elif _pile != null:
		_pile.add(1, jar_value)
		_honeycomb.assign_flight(cell, _pile.landing_position(), _pile.cell_scale(), func() -> void: _pile.land(1))


# --- the camera: the farm camera tweens its position and size to the framing and back; no panning ---

## Ortho size at the zoom: the config override if above 0, else the ZoomFraming marker's metadata "zoom_size" (Bob sets it).
func zoom_size() -> float:
	if Economy.config.zoom_size > 0.0:
		return Economy.config.zoom_size
	if _zoom_framing != null and _zoom_framing.has_meta("zoom_size"):
		return float(_zoom_framing.get_meta("zoom_size"))
	CellFlight.warn_once("zoom_size", "main.gd: no zoom_size (config 0 and no metadata on ZoomFraming): zooming to half the farm size.")
	return _cam_home_size * 0.5


## The camera position at the zoom: the farm camera's own angle, moved so ZoomFraming is where it looks.
func zoom_position() -> Vector3:
	if _zoom_framing == null or _farm_camera == null:
		return _cam_home_pos
	var forward: Vector3 = -_farm_camera.global_transform.basis.z
	var distance: float = (_zoom_framing.global_position - _cam_home_pos).dot(forward)
	return _zoom_framing.global_position - forward * distance


func _move_camera(zoom_in: bool) -> void:
	if _farm_camera == null:
		return
	var target_pos: Vector3 = zoom_position() if zoom_in else _cam_home_pos
	var target_size: float = zoom_size() if zoom_in else _cam_home_size
	if _cam_tween != null and _cam_tween.is_valid():
		_cam_tween.kill()
	if not is_inside_tree():
		_farm_camera.global_position = target_pos
		_farm_camera.size = target_size
		return
	_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_farm_camera, "global_position", target_pos, Economy.config.zoom_seconds)
	_cam_tween.tween_property(_farm_camera, "size", target_size, Economy.config.zoom_seconds)
