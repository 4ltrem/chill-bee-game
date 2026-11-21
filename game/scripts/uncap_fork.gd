# Implements GDD 3 (Heated Uncapping Fork) look for 0.2 (game/specs/0.2-first-automation.md, item 3 look).
# On FarmWorld/UncapFork (scenes/props/uncapping_fork.tscn): follows the drag point over the combs, hidden when the drag ends.
# With Heated Fork >= 1 the shared head material's albedo goes steel -> crank orange -> steel once per fork_pulse_seconds
# (a colour tween only, emission stays off). Nodes used: Head (its meshes share one StandardMaterial3D), Handle.
class_name UncapFork
extends Node3D

## Peak colour: crank orange (STYLE_GUIDE Accent 0.95, 0.50, 0.20); Bob may override from fork-r4-c-hot's head material.
@export var hot_color: Color = Color(0.95, 0.50, 0.20)
## Pulse length when the config has no `fork_pulse_seconds` yet. PLACEHOLDER: the key belongs to the Heated Fork goal.
@export var fallback_pulse_seconds: float = 1.0

var config: GameConfig = GameConfig.live()
## Test hook: a level >= 0 replaces the Economy's Heated Fork level.
var heated_level_override: int = -1

var _head_material: StandardMaterial3D
var _steel: Color
var _pulse_t: float = 0.0
var _dragging: bool = false
var _return_tween: Tween
var _rest_scale: Vector3 = Vector3.ONE
var _has_rest_scale: bool = false


func _ready() -> void:
	visible = false
	var head: Node = find_child("Head", true, false)
	if head != null:
		for child in head.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = child as MeshInstance3D
			var m: Material = mesh.material_override if mesh.material_override != null else mesh.get_active_material(0)
			if m is StandardMaterial3D:
				_head_material = m as StandardMaterial3D
				break
	else:
		CellFlight.warn_once("ForkHead", "uncap_fork.gd: no Head node (see game/specs/0.2-node-handoff.md).")
	if _head_material != null:
		_steel = _head_material.albedo_color
		_head_material.emission_enabled = false


func heated_level() -> int:
	return heated_level_override if heated_level_override >= 0 else UpgradeLevel.of("heated_fork")


func pulse_seconds() -> float:
	var v: Variant = config.get("fork_pulse_seconds")
	return maxf(float(v) if v != null else fallback_pulse_seconds, 0.05)


## The fork follows the drag: shown at `world_position` (the drag point on the combs).
func follow(world_position: Vector3) -> void:
	if not _dragging:
		_cancel_return()
		_dragging = true
		_pulse_t = 0.0
		visible = true
	global_position = world_position


## The drag ended: the fork hides and the head returns to steel.
func release() -> void:
	_cancel_return()
	_dragging = false
	visible = false
	_pulse_t = 0.0
	_apply(0.0)


## 0.2 item 10: the zoom ended with the fork still shown: it moves to `world_target` (the Harvest icon's spot) and shrinks
## into it over fork_return_seconds, then hides. No-op when hidden.
func return_to(world_target: Vector3) -> void:
	if not visible:
		return
	_dragging = false
	_apply(0.0)
	if _return_tween != null:
		_return_tween.kill()
	var seconds: float = float(config.fork_return_seconds)
	if seconds <= 0.0:
		_finish_return()
		return
	if not _has_rest_scale:
		_rest_scale = scale
		_has_rest_scale = true
	_return_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_return_tween.tween_property(self, "global_position", world_target, seconds)
	_return_tween.tween_property(self, "scale", _rest_scale * 0.01, seconds)
	_return_tween.chain().tween_callback(_finish_return)


func _cancel_return() -> void:
	if _return_tween != null:
		_return_tween.kill()
		_return_tween = null
	if _has_rest_scale:
		scale = _rest_scale


func _finish_return() -> void:
	visible = false
	if _has_rest_scale:
		scale = _rest_scale


## 0 at the start, 1 at the peak (half the pulse), 0 at the end: the head's blend toward crank orange at pulse time t.
func pulse_blend(t: float) -> float:
	var u: float = fposmod(t / pulse_seconds(), 1.0)
	return 1.0 - absf(2.0 * u - 1.0)


func _process(delta: float) -> void:
	if not _dragging:
		return
	if heated_level() < 1:
		_apply(0.0)
		return
	_pulse_t += delta
	_apply(pulse_blend(_pulse_t))


func _apply(blend: float) -> void:
	if _head_material != null:
		_head_material.albedo_color = _steel.lerp(hot_color, blend)
