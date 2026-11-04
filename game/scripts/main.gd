# Implements GDD 1 (Primary Game Loop) and 2 (uncapping close-up, then extraction, bottling and selling on the farm)
# for Prototype 0. Owns the flow: fork icon -> close-up uncapping (Back, or all cells) -> centrifuge icon -> crank
# (tap or hold) -> Continue -> bottling onto the truck -> summary -> Sell icon -> upgrade -> round again.
# The farm stays live through the whole harvest; only the close-up hides it.
extends Node3D

const HARVEST_SCENE_PATH := "res://scenes/harvest.tscn"

var _hive: Hive
var _farm_world: Node3D
var _farm_ui: FarmUI
var _farm_camera: Camera3D
var _centrifuge: Centrifuge
var _truck: Truck
var _fork_icon: FloatingIcon
var _centrifuge_icon: FloatingIcon
var _sell_icon: FloatingIcon
var _harvest: Node
var _honeycomb: Honeycomb
var _harvest_ui: HarvestUI
var _closing: bool = false


func _ready() -> void:
	_hive = find_child("Hive", true, false) as Hive
	_farm_world = find_child("FarmWorld", true, false) as Node3D
	_farm_ui = find_child("FarmUI", true, false) as FarmUI
	_farm_camera = find_child("Camera3D", false, false) as Camera3D
	_centrifuge = find_child("Centrifuge", true, false) as Centrifuge
	_truck = find_child("Truck", true, false) as Truck
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
	_farm_ui.setup(_hive, _centrifuge, _truck)
	_farm_ui.continue_pressed.connect(_on_continue)
	_hive.storage_changed.connect(func(_s: float, _o: float) -> void: _refresh_icons())
	_hive.became_full.connect(_refresh_icons)
	_centrifuge.state_changed.connect(_on_centrifuge_state)
	_centrifuge.jar_bottled.connect(func(_n: int) -> void: _truck.receive_jar())
	_centrifuge.bottling_done.connect(_on_bottling_done)
	_truck.load_changed.connect(func(_l: int, _c: int) -> void: _refresh_icons())
	_truck.departed.connect(_refresh_icons)
	_truck.returned.connect(_refresh_icons)
	if _fork_icon != null:
		_fork_icon.pressed.connect(_open_harvest)
	if _centrifuge_icon != null:
		_centrifuge_icon.pressed.connect(func() -> void: _centrifuge.begin_crank())
	if _sell_icon != null:
		_sell_icon.pressed.connect(func() -> void: _truck.sell())
	_refresh_icons()


## The state table: which floating icons show right now. Cheap; called on every state change.
func _refresh_icons() -> void:
	if _centrifuge == null or _truck == null:
		return
	var on_farm: bool = _harvest == null
	if _fork_icon != null:
		_fork_icon.set_wanted(on_farm and _hive.is_full() and _centrifuge.state == Centrifuge.State.EMPTY)
	if _centrifuge_icon != null:
		_centrifuge_icon.set_wanted(on_farm and _centrifuge.state == Centrifuge.State.FULL)
	if _sell_icon != null:
		var can_sell: bool = on_farm and _truck.can_sell()
		_sell_icon.set_wanted(can_sell)
		if can_sell:
			_sell_icon.text = "Sell $%d" % _truck.load_value()


func _on_centrifuge_state(state: int) -> void:
	_farm_ui.show_continue(state == Centrifuge.State.DONE)
	_refresh_icons()


func _on_continue() -> void:
	_farm_ui.show_continue(false)
	_centrifuge.open_spigot()


func _on_bottling_done(jars: int) -> void:
	var per_jar: int = Economy.jar_value()
	_farm_ui.show_summary(jars, per_jar, jars * per_jar)


# --- stage 1: the close-up ---

## The fork was tapped: open the close-up with a fresh frame of capped cells.
func _open_harvest() -> void:
	if _harvest != null or _closing:
		return
	if not (_hive.is_full() and _centrifuge.has_room()):
		return
	var packed: PackedScene = load(HARVEST_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("main.gd: %s not found." % HARVEST_SCENE_PATH)
		return
	_harvest = packed.instantiate()
	add_child(_harvest)
	_honeycomb = _harvest.find_child("Honeycomb", true, false) as Honeycomb
	_harvest_ui = _harvest.find_child("HarvestUI", true, false) as HarvestUI
	var harvest_camera: Camera3D = _harvest.find_child("Camera3D", true, false) as Camera3D
	if harvest_camera != null:
		harvest_camera.make_current()
	if _farm_world != null:
		_farm_world.visible = false
	_farm_ui.visible = false
	_refresh_icons()
	_honeycomb.reset()
	_honeycomb.active = true
	_honeycomb.visible = true
	_honeycomb.slide_in()
	_harvest_ui.show_stage1()
	_honeycomb.all_cells_uncapped.connect(_on_all_uncapped)
	_harvest_ui.back_pressed.connect(_on_back)


## Back: the frame stays in the hive (take_frame has not run) and the uncapping progress is lost.
func _on_back() -> void:
	if _closing:
		return
	_close_harvest()


## Every cell is uncapped: the hive gives up the frame, the frame slides away, and after a short pause the close-up closes.
func _on_all_uncapped() -> void:
	if _closing or _honeycomb == null:
		return
	_closing = true
	_honeycomb.active = false
	_harvest_ui.show_stage1_done()
	var jars: int = _hive.take_frame()
	_honeycomb.slide_out()
	await get_tree().create_timer(Economy.config.slide_seconds + Economy.config.close_delay_seconds).timeout
	_close_harvest()
	_closing = false
	if jars > 0:
		_centrifuge.fill(jars)
	_maybe_queue_next()


## Frame queue (later): with room in the centrifuge and a full frame in the hive, the next close-up opens at once.
## With a centrifuge capacity of 1 frame there is never room, so this does nothing in the prototype.
func _maybe_queue_next() -> void:
	if _harvest == null and _centrifuge.has_room() and _hive.is_full():
		_open_harvest()


func _close_harvest() -> void:
	if _harvest == null:
		return
	_harvest.queue_free()
	_harvest = null
	_honeycomb = null
	_harvest_ui = null
	if _farm_world != null:
		_farm_world.visible = true
	_farm_ui.visible = true
	if _farm_camera != null:
		_farm_camera.make_current()
	_refresh_icons()
