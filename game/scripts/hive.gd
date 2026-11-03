# Implements GDD 1 (Primary Game Loop: hive storage, 10-jar frame, one-frame overflow buffer).
# Storage rises over time; overflow takes production once the frame is full; production pauses when both are full.
class_name Hive
extends Node3D

signal storage_changed(storage: float, overflow: float)
signal became_full

@export var config: GameConfig = GameConfig.load_default()

var storage: float = 0.0
var overflow: float = 0.0
var _full_announced: bool = false

var capacity: int:
	get:
		return config.frame_jars

var overflow_capacity: int:
	get:
		return config.frame_jars * config.overflow_frames


func is_full() -> bool:
	return storage >= float(capacity)


## True when the frame and the overflow buffer are both full.
func is_paused() -> bool:
	return is_full() and overflow >= float(overflow_capacity)


## Advances production by delta seconds at the given fill-rate multiplier.
func advance(delta: float, multiplier: float = 1.0) -> void:
	if is_paused():
		return
	var produced: float = delta / config.base_seconds_per_jar * multiplier
	var room: float = float(capacity) - storage
	if produced >= room:
		storage = float(capacity)
		overflow = minf(overflow + (produced - room), float(overflow_capacity))
	else:
		storage += produced
	if is_full() and not _full_announced:
		_full_announced = true
		became_full.emit()
	storage_changed.emit(storage, overflow)


## Removes one full frame and returns its jar count (0 if the hive is not full).
## The overflow buffer then refills the storage.
func take_frame() -> int:
	if not is_full():
		return 0
	var taken: int = capacity
	storage = minf(storage - float(taken) + overflow, float(capacity))
	overflow = 0.0
	_full_announced = false
	storage_changed.emit(storage, overflow)
	if is_full():
		_full_announced = true
		became_full.emit()
	return taken


func _process(delta: float) -> void:
	var multiplier: float = 1.0
	var economy: Node = get_node_or_null("/root/Economy")
	if economy != null:
		multiplier = economy.fill_multiplier()
	advance(delta, multiplier)
