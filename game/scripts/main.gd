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
var _crate: Node3D
var _closing_to_second: bool = false   # the zoom now closing ends at the second stop (bucket full) instead of the farm view
var _at_second_stop: bool = false
var _spin_mode: bool = false          # 0.1.4 item 7: the crank was started and the pile has not run out
var _auto_spin: bool = false          # the pile is reloading after a pour in spin mode: crank again when the bucket is full
var _spin_pending: bool = false       # Spin was tapped in the first zoom: the crank starts when the camera reaches the second stop
var _filled_in_zoom: bool = false    # the bucket became full while this zoom was open: the zoom ends after its frame and pans to the second stop


func _ready() -> void:
	_hive = find_child("Hive", true, false) as Hive
	_farm_world = find_child("FarmWorld", true, false) as Node3D
	_farm_ui = find_child("FarmUI", true, false) as FarmUI
	_farm_camera = find_child("Camera3D", false, false) as Camera3D
	_centrifuge = find_child("Centrifuge", true, false) as Centrifuge
	_truck = find_child("Truck", true, false) as Truck
	_crate = find_child("JarCrate", true, false) as Node3D
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
		_centrifuge_icon.pressed.connect(spin_tapped)
	if _sell_icon != null:
		_sell_icon.pressed.connect(sell)
	_refresh_icons()


func _process(delta: float) -> void:
	advance(delta)
	if _fork_icon != null:
		_fork_icon.disabled = not fork_available()   # the hive fills between state changes


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
		# 0.1.4 item 1: always shown on the farm view (the button is the honey meter); pressable only when the fork rule holds
		_fork_icon.set_wanted(on_farm and not _at_second_stop)   # hidden at the second stop (designer 2026-11-06)
		_fork_icon.disabled = not fork_available()
	if _centrifuge_icon != null:
		# 0.1.3 play-test (c): also shown during the first zoom (not while it closes: the second stop shows it itself)
		_centrifuge_icon.set_wanted((on_farm or zoom != Zoom.CLOSING) and _centrifuge.state == Centrifuge.State.FULL)
	if _sell_icon != null:
		var can_sell: bool = on_farm and _truck.can_sell()
		_sell_icon.set_wanted(can_sell)
		if can_sell:
			_sell_icon.text = "Sell $%d" % _truck.load_value()


func _on_centrifuge_state(state_now: int) -> void:
	if state_now == Centrifuge.State.FULL and zoom != Zoom.NONE and zoom != Zoom.CLOSING and zoom != Zoom.BACK_LOWERING:
		_filled_in_zoom = true
	if state_now == Centrifuge.State.CRANKING:
		_auto_spin = false
		_set_spin_text_kept(false)
	elif state_now == Centrifuge.State.FULL and _auto_spin and zoom == Zoom.NONE:
		_auto_spin = false
		_centrifuge.begin_crank.call_deferred()   # spin mode: the reloaded bucket spins on its own
	_refresh_icons()


## An empty jar flies from the crate to the spigot, fills and gets its lid there (visual; the centrifuge's own timer waits for it).
func _on_jar_requested(delay: float) -> void:
	var config: GameConfig = Economy.config
	var jar: Node3D = JarFlight.fetch(self, _truck.empties_position(), _centrifuge.spigot_position(), config.jar_fly_seconds,
			config.cell_fly_arc, delay, _centrifuge.spigot_jar_scale(), maxf(config.bottling_seconds_per_jar - config.jar_fly_seconds, 0.001))
	if jar != null:
		_trips.append(jar)


## A jar is bottled: the jar at the spigot flies on to the truck or the crate (the truck counts it at once).
func _on_jar_bottled(_n: int) -> void:
	var carrier: Node3D = _trips.pop_front() if not _trips.is_empty() else null
	_truck.receive_jar(_centrifuge.spigot_position(), 0.0, carrier)


## Sell (icon): credits the money, sends the truck off, and the summary shows jars sold, price per jar and the total. Returns the total.
func sell() -> int:
	var jars: int = _truck.loaded_jars
	var total: int = _truck.sell()
	if total > 0:
		_farm_ui.show_summary(jars, Economy.jar_value(), total)
	return total


## Bottling finished: the bucket is empty and open (centrifuge.gd lifted its lid), and the pile loads in.
func _on_bottling_done(_jars: int) -> void:
	# 0.1.4 item 7: in spin mode the reloaded bucket spins by itself (no "press Spin" prompt, the spin text stays); with no pile, spin mode exits.
	if _spin_mode:
		if _pile != null and not _pile.is_empty() and _centrifuge.room_cells() > 0:
			_auto_spin = true
			_set_spin_text_kept(true)
		else:
			_exit_spin_mode()
	load_pile()


func _set_spin_text_kept(kept: bool) -> void:
	if _farm_ui != null:
		_farm_ui.keep_spin_text = kept


func _exit_spin_mode() -> void:
	_spin_mode = false
	_auto_spin = false
	_set_spin_text_kept(false)
	if _at_second_stop:
		leave_second_stop()


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
	_leave_second_stop_hud()
	_filled_in_zoom = false
	_spin_pending = false
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


## The Spin icon. On the farm or at the second stop it starts the crank. In the first zoom (0.1.3c) it ends the zoom like Back (frames not yet
## uncapped stay), pans to the second stop and starts the crank there (_finish_zoom).
func spin_tapped() -> void:
	if zoom == Zoom.NONE:
		_spin_mode = true
		_centrifuge.begin_crank()
	elif zoom != Zoom.CLOSING and zoom != Zoom.BACK_LOWERING and _centrifuge.state == Centrifuge.State.FULL:
		_spin_pending = true
		back()   # a zoom already closing on its own (CLOSE_DELAY) needs nothing more: it pans because the bucket is full


## Back: the risen frame sinks keeping its state, the hive lid goes back on and the camera zooms out.
## The fork stays available while any frame has Capped cells (resume_pending).
func back() -> void:
	match zoom:
		Zoom.NONE:
			leave_second_stop()
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
			elif not _raise_next():   # a bucket that fills mid-zoom does not end it: finish every frame (the extra cells go to the pile), then pan
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
	resume_pending = not on_own or (_filled_in_zoom and _hive.has_capped_cells())   # all frames done: nothing left to resume
	_hive.close_lid()
	_centrifuge.close_lid()
	_closing_to_second = _bucket_is_full() or _spin_pending   # 0.1.3 play-test: a bucket already full when the zoom opened (Back, then Harvest again) pans too
	if _closing_to_second:
		_timer = maxf(Economy.config.camera_pan_seconds, Economy.config.lid_move_seconds())
		_move_camera_to(second_stop_pose(), Economy.config.camera_pan_seconds)
	else:
		_move_camera(false)
	_refresh_icons()


func _finish_zoom() -> void:
	zoom = Zoom.NONE
	_going_back = false
	_queue.clear()
	_farm_ui.visible = true
	if _bees != null:
		_bees.clear_avoid()
	_centrifuge.crank_enabled = true
	if _closing_to_second:
		_closing_to_second = false
		_enter_second_stop_hud()
	elif _harvest_ui != null:
		_harvest_ui.hide_zoom()
	_refresh_icons()
	if _spin_pending:
		_spin_pending = false
		_spin_mode = true
		_centrifuge.begin_crank()


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
	_move_camera_to({"position": zoom_position() if zoom_in else _cam_home_pos, "size": zoom_size() if zoom_in else _cam_home_size},
			Economy.config.zoom_seconds)


## Tweens the farm camera to a pose ({position, size}) over `seconds` (the tween runs on the engine clock, so Engine.time_scale speeds it).
func _move_camera_to(pose: Dictionary, seconds: float) -> void:
	if _farm_camera == null:
		return
	var target_pos: Vector3 = pose["position"]
	var target_size: float = pose["size"]
	if _cam_tween != null and _cam_tween.is_valid():
		_cam_tween.kill()
	if not is_inside_tree():
		_farm_camera.global_position = target_pos
		_farm_camera.size = target_size
		return
	_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_farm_camera, "global_position", target_pos, seconds)
	_cam_tween.tween_property(_farm_camera, "size", target_size, seconds)


# --- the second camera stop (0.1.3 item 2): centrifuge, crate and truck framed at pan_zoom_size, the hive partly in the upper-right ---

## True when the bucket holds a full load. This one function is the trigger: a zoom that ends with a full bucket pans to the second stop.
func _bucket_is_full() -> bool:
	return _centrifuge != null and _centrifuge.state == Centrifuge.State.FULL and _centrifuge.cells >= _centrifuge.capacity_cells()


func at_second_stop() -> bool:
	return _at_second_stop


## Back at the second stop: the camera returns to the farm view.
func leave_second_stop() -> void:
	if not _at_second_stop or zoom != Zoom.NONE:
		return
	_leave_second_stop_hud()
	if _harvest_ui != null:
		_harvest_ui.hide_zoom()
	_move_camera(false)


func _view_px() -> Vector2:
	return get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(720.0, 1280.0)


## World box of every visible mesh under `node`, moved by `shift`.
func _mesh_box(node: Node3D, shift: Vector3 = Vector3.ZERO) -> AABB:
	var box := AABB()
	var first: bool = true
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = found as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var b: AABB = mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return AABB(node.global_position, Vector3.ZERO)
	box.position += shift
	return box


## The box's footprint on the camera plane: x along the camera's right, y along its up (world units).
func _plane_rect(box: AABB, right: Vector3, up: Vector3) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var p: Vector3 = box.get_endpoint(i)
		var q := Vector2(p.dot(right), p.dot(up))
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	return Rect2(lo, hi - lo)


## The second stop's camera, from the objects' rects (no marker): {position, size, plane_x, plane_y, fits}. The framed rect (centrifuge, crate
## and the truck at home) grows by config.pan_margin of the view, sits at the view's lower-left above the shop panel, and the rest of
## the view (upper-right) shows the hive. `fits` is false when pan_zoom_size is too small for the rect (warns once).
func second_stop_pose() -> Dictionary:
	var config: GameConfig = Economy.config
	var size: float = config.pan_zoom_size
	if _farm_camera == null or _centrifuge == null or _truck == null:
		return {"position": _cam_home_pos, "size": size, "plane_x": 0.0, "plane_y": 0.0, "fits": false}
	var right: Vector3 = _farm_camera.global_basis.x
	var up: Vector3 = _farm_camera.global_basis.y
	var view: Vector2 = _view_px()
	var aspect: float = view.x / view.y
	var rect: Rect2 = _plane_rect(_mesh_box(_centrifuge), right, up)
	if _crate != null:
		rect = rect.merge(_plane_rect(_mesh_box(_crate), right, up))
	rect = rect.merge(_plane_rect(_mesh_box(_truck, _truck.home_global_position() - _truck.global_position), right, up))
	rect = rect.grow_individual(config.pan_margin * size * aspect, config.pan_margin * size, config.pan_margin * size * aspect, config.pan_margin * size)
	var shop: Control = find_child("ShopPanel", true, false) as Control
	var shop_share: float = clampf((view.y - shop.global_position.y) / view.y, 0.0, 0.9) if shop != null else 0.0
	var width: float = size * aspect
	var fits: bool = rect.size.x <= width and rect.size.y <= size * (1.0 - shop_share)
	if not fits:
		CellFlight.warn_once("pan_zoom_size", "main.gd: pan_zoom_size %.3f is too small for the centrifuge, crate and truck plus pan_margin (needs %.3f)." % [size, maxf(rect.size.x / aspect, rect.size.y / (1.0 - shop_share))])
	var plane_x: float = rect.position.x + width * 0.5                       # view centre on the camera plane
	var plane_y: float = rect.position.y - shop_share * size + size * 0.5
	var home_x: float = _cam_home_pos.dot(right)
	var home_y: float = _cam_home_pos.dot(up)
	return {"position": _cam_home_pos + right * (plane_x - home_x) + up * (plane_y - home_y), "size": size,
			"plane_x": plane_x, "plane_y": plane_y, "fits": fits}


## Where a world point lands on screen (px) when the camera sits at `pose`.
func _pose_screen(point: Vector3, pose: Dictionary) -> Vector2:
	var view: Vector2 = _view_px()
	var size: float = pose["size"]
	var u: float = point.dot(_farm_camera.global_basis.x) - float(pose["plane_x"])
	var v: float = point.dot(_farm_camera.global_basis.y) - float(pose["plane_y"])
	return Vector2((u / (size * view.x / view.y) + 0.5) * view.x, (0.5 - v / size) * view.y)


func _screen_rect(box: AABB, pose: Dictionary) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var q: Vector2 = _pose_screen(box.get_endpoint(i), pose)
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	return Rect2(lo, hi - lo)


## The camera has arrived at the second stop: Back shows, the Hive bar stops left of the hive, Harvest sits below the hive and Spin left of the
## centrifuge (every position from the objects' screen rects, so nothing covers either).
func _enter_second_stop_hud() -> void:
	_at_second_stop = true
	_refresh_icons()   # hides Harvest here
	if _harvest_ui != null:
		_harvest_ui.show_pan()
	var pose: Dictionary = second_stop_pose()
	var view: Vector2 = _view_px()
	var gap: float = Economy.config.pan_margin * view.y
	var screen := Rect2(Vector2.ZERO, view)
	var hive_rect: Rect2 = _screen_rect(_mesh_box(_hive), pose).intersection(screen)
	var cen_rect: Rect2 = _screen_rect(_mesh_box(_centrifuge), pose)
	_farm_ui.fit_top_info([hive_rect, cen_rect] as Array[Rect2], gap)
	# Back stays where the scene puts it: top-right, fixed (0.1.4 item 3); nothing moves it here.


func _leave_second_stop_hud() -> void:
	_at_second_stop = false
	_refresh_icons()   # Harvest was hidden at the second stop; the state table shows it again
	if _farm_ui != null:
		_farm_ui.restore_top_info()
