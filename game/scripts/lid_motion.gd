# Implements GDD 2 (Stage 1: the hive lid and the centrifuge lid) for 0.1.1 (game/specs/0.1.1-playtest-fixes.md, change 2).
# One lid's path: it lifts straight up by config.lid_lift_height over lid_lift_seconds, then falls over lid_drop_seconds to the open
# transform (the lid spot marker, position and, if `rotate_fall`, rotation). Closing plays the same path backwards, so a lid that is
# interrupted mid-way carries on from where it is. The path is one progress value `s` (0 closed, 1 open); `apply(s)` is a pure pose
# for it, so tests can sample the path without tweens. The fall moves sideways early and drops late, so a lid clears the body it left.
# Logic never waits on the tween: callers set their own state at the call; this only draws it.
class_name LidMotion
extends RefCounted

var config: GameConfig
## Progress along the path: 0 closed, 1 open.
var progress: float = 0.0

var _lid: Node3D
var _spot: Node3D
var _rotate_fall: bool
var _closed_pos: Vector3
var _closed_quat: Quaternion
var _tween: Tween


## `rotate_fall` false keeps the lid's own rotation (the centrifuge lid spins while it is on and lands flat).
func _init(lid: Node3D, spot: Node3D, cfg: GameConfig, rotate_fall: bool) -> void:
	_lid = lid
	_spot = spot
	config = cfg
	_rotate_fall = rotate_fall
	_closed_pos = lid.position
	_closed_quat = lid.quaternion


## Seconds of the whole path, lift then fall (config read when used).
static func total_seconds(cfg: GameConfig) -> float:
	return maxf(cfg.lid_lift_seconds, 0.0) + maxf(cfg.lid_drop_seconds, 0.0)


## The lid's pose at progress s (0 to 1), written onto the lid.
func apply(s: float) -> void:
	progress = clampf(s, 0.0, 1.0)
	var lift_s: float = maxf(config.lid_lift_seconds, 0.0)
	var drop_s: float = maxf(config.lid_drop_seconds, 0.0)
	var total: float = lift_s + drop_s
	var split: float = lift_s / total if total > 0.0 else 0.0
	var lifted: Vector3 = _closed_pos + Vector3.UP * config.lid_lift_height
	var open_pos: Vector3 = _spot.position if _spot != null else _closed_pos
	if progress <= split and split > 0.0:
		var k: float = progress / split
		_lid.position = _closed_pos.lerp(lifted, 1.0 - (1.0 - k) * (1.0 - k))   # ease out: rises fast, slows at the top
		return
	var f: float = (progress - split) / (1.0 - split) if split < 1.0 else 1.0
	var across: float = 1.0 - (1.0 - f) * (1.0 - f)   # sideways first
	var down: float = f * f                            # then down
	_lid.position = Vector3(lerpf(lifted.x, open_pos.x, across), lerpf(lifted.y, open_pos.y, down), lerpf(lifted.z, open_pos.z, across))
	if _rotate_fall and _spot != null:
		_lid.quaternion = _closed_quat.slerp(_spot.quaternion, f)


## Plays the path to open or closed, starting after `delay` seconds. Without a tree the lid jumps there.
func play(open: bool, delay: float = 0.0) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target: float = 1.0 if open else 0.0
	if not _lid.is_inside_tree():
		apply(target)
		return
	var seconds: float = total_seconds(config) * absf(target - progress)
	_tween = _lid.create_tween()
	if delay > 0.0:
		_tween.tween_interval(delay)
	if seconds <= 0.0:
		_tween.tween_callback(apply.bind(target))
		return
	_tween.tween_method(apply, progress, target, seconds)
