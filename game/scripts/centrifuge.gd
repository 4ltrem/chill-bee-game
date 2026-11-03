# Implements GDD 2 (Phase 1 Extraction minigame, stage 2) and 8 (Accessibility: No-Rapid-Tap Mode).
# Tap counting and jar output are plain logic (advance/crank); the barrel visual is built from a cylinder.
class_name Centrifuge
extends Node3D

signal jar_filled(count: int)
signal batch_done(jars: int)

@export var config: GameConfig = GameConfig.load_default()
## Visual tuning only (not balance): spin impulse per tap, decay, cap, and the steady spin in hold mode (rad/s).
@export var spin_impulse: float = 5.0
@export var spin_decay: float = 3.0
@export var spin_max: float = 18.0
@export var spin_hold: float = 8.0

## No-Rapid-Tap Mode: holding the button cranks at a steady rate; crank() taps are ignored.
var hold_mode: bool = false
var running: bool = false
var holding: bool = false
var jars_total: int = 0
var jars_filled: int = 0
var taps_done: float = 0.0
var spin_speed: float = 0.0

var _barrel: MeshInstance3D


func taps_per_jar() -> float:
	return float(config.taps_per_frame) / float(config.frame_jars)


func taps_needed() -> float:
	return taps_per_jar() * float(jars_total)


## Begins extracting a batch of jars.
func start(jars: int) -> void:
	jars_total = maxi(jars, 0)
	jars_filled = 0
	taps_done = 0.0
	spin_speed = 0.0
	holding = false
	running = jars_total > 0
	if not running:
		batch_done.emit(0)


## One tap of the Crank button (ignored in hold mode or when not running).
func crank() -> void:
	if not running or hold_mode:
		return
	spin_speed = minf(spin_speed + spin_impulse, spin_max)
	_add_taps(1.0)


## Hold mode: the UI calls this on button down/up.
func set_holding(value: bool) -> void:
	holding = value


## Per-frame logic, separate from _process so it can be tested headless.
func advance(delta: float) -> void:
	if running and hold_mode and holding:
		spin_speed = spin_hold
		_add_taps(config.hold_taps_per_second * delta)
	else:
		spin_speed = maxf(spin_speed - spin_decay * delta, 0.0)


func _add_taps(amount: float) -> void:
	taps_done += amount
	var per_jar: float = taps_per_jar()
	while running and jars_filled < jars_total and taps_done + 0.00001 >= per_jar * float(jars_filled + 1):
		jars_filled += 1
		jar_filled.emit(jars_filled)
		if jars_filled >= jars_total:
			running = false
			holding = false
			batch_done.emit(jars_total)


func _ready() -> void:
	_barrel = MeshInstance3D.new()
	_barrel.name = "Barrel"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.4
	cylinder.bottom_radius = 1.4
	cylinder.height = 1.8
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(0.6, 0.66, 0.74)
	cylinder.material = body
	_barrel.mesh = cylinder
	var stripe := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 1.9, 0.3)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.95, 0.5, 0.2)
	box.material = stripe_mat
	stripe.mesh = box
	stripe.position = Vector3(1.3, 0.0, 0.0)
	_barrel.add_child(stripe)
	add_child(_barrel)


func _process(delta: float) -> void:
	advance(delta)
	if _barrel != null and spin_speed > 0.0:
		_barrel.rotate_y(spin_speed * delta)
