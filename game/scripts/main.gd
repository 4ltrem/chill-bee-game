# Implements GDD 1 (Primary Game Loop) for Prototype 0: switches between the farm view and the harvest
# scene and owns the flow harvest -> uncap -> centrifuge -> summary -> sell -> upgrade -> round again.
extends Node3D

const HARVEST_SCENE_PATH := "res://scenes/harvest.tscn"

var _hive: Hive
var _farm_world: Node3D
var _farm_ui: FarmUI
var _farm_camera: Camera3D
var _harvest: Node
var _honeycomb: Honeycomb
var _centrifuge: Centrifuge
var _harvest_ui: HarvestUI
var _batch_jars: int = 0


func _ready() -> void:
	_hive = find_child("Hive", true, false) as Hive
	_farm_world = find_child("FarmWorld", true, false) as Node3D
	_farm_ui = find_child("FarmUI", true, false) as FarmUI
	_farm_camera = find_child("Camera3D", false, false) as Camera3D
	if _hive == null or _farm_ui == null:
		push_error("main.gd: Hive or FarmUI node missing (see Node paths for Bob).")
		return
	_farm_ui.setup(_hive)
	_farm_ui.harvest_requested.connect(_start_harvest)


func _start_harvest() -> void:
	if _harvest != null:
		return
	var packed: PackedScene = load(HARVEST_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("main.gd: %s not found." % HARVEST_SCENE_PATH)
		return
	_batch_jars = _hive.take_frame()
	if _batch_jars <= 0:
		return
	_harvest = packed.instantiate()
	add_child(_harvest)
	_honeycomb = _harvest.find_child("Honeycomb", true, false) as Honeycomb
	_centrifuge = _harvest.find_child("Centrifuge", true, false) as Centrifuge
	_harvest_ui = _harvest.find_child("HarvestUI", true, false) as HarvestUI
	var harvest_camera: Camera3D = _harvest.find_child("Camera3D", true, false) as Camera3D
	if harvest_camera != null:
		harvest_camera.make_current()
	if _farm_world != null:
		_farm_world.visible = false
	_farm_ui.visible = false
	_honeycomb.reset()
	_honeycomb.active = true
	_honeycomb.visible = true
	_centrifuge.visible = false
	_harvest_ui.setup(_centrifuge)
	_harvest_ui.show_stage1()
	_honeycomb.all_cells_uncapped.connect(_on_all_uncapped)
	_centrifuge.batch_done.connect(_on_batch_done)
	_harvest_ui.continue_pressed.connect(_end_harvest)


func _on_all_uncapped() -> void:
	_honeycomb.active = false
	_honeycomb.visible = false
	_centrifuge.visible = true
	_harvest_ui.show_stage2(_batch_jars)
	_centrifuge.start(_batch_jars)


func _on_batch_done(jars: int) -> void:
	Economy.add_jars(jars)
	_honeycomb.extract_all()
	_honeycomb.visible = true
	_centrifuge.visible = false
	_harvest_ui.show_summary(jars, Economy.jar_value(), jars * Economy.jar_value())


func _end_harvest() -> void:
	if _harvest == null:
		return
	_harvest.queue_free()
	_harvest = null
	_honeycomb = null
	_centrifuge = null
	_harvest_ui = null
	if _farm_world != null:
		_farm_world.visible = true
	_farm_ui.visible = true
	if _farm_camera != null:
		_farm_camera.make_current()
