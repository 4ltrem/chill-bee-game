# Implements GDD 2 (Phase 1 extraction and bottling, on the farm) and 8 (Accessibility: holding is built in).
# State machine EMPTY -> FULL -> CRANKING -> DONE -> BOTTLING -> EMPTY. Counted turns obey the tap cap
# (max_tap_rate); a hold counts one turn on press, then max_tap_rate per second. Crank input arrives only
# through _unhandled_input while CRANKING. Visuals: barrel, lid, crank and spigot built from primitives.
# Every tunable is read from the config when used (Dev mode edits apply at once).
class_name Centrifuge
extends Node3D

enum State { EMPTY, FULL, CRANKING, DONE, BOTTLING }

signal state_changed(state: int)
signal extraction_progress(done: int, total: int)
signal turn_counted(turns: int)
signal extraction_done
signal jar_bottled(count: int)
signal bottling_done(jars: int)

@export var config: GameConfig = GameConfig.live()

var state: int = State.EMPTY
var jars_total: int = 0
var jars_extracted: int = 0
var jars_bottled: int = 0
var turns_counted: int = 0
var holding: bool = false
var spin_speed: float = 0.0

var _clock: float = 0.0
var _last_turn: float = -1.0e9
var _hold_turns: float = 0.0
var _hold_time: float = 0.0
var _bottle_timer: float = 0.0
var _hold_source: String = ""

var _barrel: MeshInstance3D
var _spigot_jar: MeshInstance3D


## True when the centrifuge can take another frame.
func has_room() -> bool:
	var held: int = 0 if state == State.EMPTY else 1
	return held < config.centrifuge_capacity_frames


## Loads a frame's honey. Closed and full: nothing spins until begin_crank().
func fill(jars: int) -> void:
	if not has_room() or jars <= 0:
		return
	jars_total = jars
	jars_extracted = 0
	jars_bottled = 0
	turns_counted = 0
	_reset_crank()
	_set_state(State.FULL)


## The centrifuge icon was tapped: start cranking.
func begin_crank() -> void:
	if state != State.FULL:
		return
	_reset_crank()
	_set_state(State.CRANKING)
	extraction_progress.emit(jars_extracted, jars_total)


## One crank turn. Counted only in CRANKING and only if at least 1 / max_tap_rate s passed since the last
## counted turn. Returns true if it counted.
func tap() -> bool:
	if state != State.CRANKING:
		return false
	if _clock - _last_turn < 1.0 / maxf(config.max_tap_rate, 0.001) - 0.000001:
		return false
	_count_turn()
	return true


## Press and release. Turns accrue at max_tap_rate while held. The press's own turn is counted by the input
## handler calling tap(); set_holding(true) itself does not count a turn.
func set_holding(value: bool) -> void:
	if value:
		if state != State.CRANKING:
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
	var held: bool = holding and state == State.CRANKING
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
	while _bottle_timer >= per_jar and jars_bottled < jars_total:
		_bottle_timer -= per_jar
		jars_bottled += 1
		jar_bottled.emit(jars_bottled)
	if jars_bottled >= jars_total:
		_bottle_timer = 0.0
		var jars: int = jars_total
		_set_state(State.EMPTY)
		bottling_done.emit(jars)


func _count_turn() -> void:
	_last_turn = _clock
	turns_counted += 1
	spin_speed = minf(spin_speed + config.spin_impulse, config.spin_max)
	var per_jar: float = float(config.taps_per_frame) / float(maxi(config.frame_jars, 1))
	var extracted: int = mini(jars_total, floori(float(turns_counted) / per_jar + 0.000001))
	if extracted != jars_extracted:
		jars_extracted = extracted
		extraction_progress.emit(jars_extracted, jars_total)
	turn_counted.emit(turns_counted)
	if jars_extracted >= jars_total:
		holding = false
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


# --- input: crank turns come only through _unhandled_input while CRANKING ---

func _unhandled_input(event: InputEvent) -> void:
	if state != State.CRANKING or not is_visible_in_tree():
		return
	# Touch and mouse are emulated into each other, so one press can arrive as both. A second press while already
	# holding is a no-op in set_holding, and a release of either ends the hold, so a press never counts twice.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_press(event.pressed, "mouse")
	elif event is InputEventScreenTouch:
		_press(event.pressed, "touch")


func _press(pressed: bool, source: String) -> void:
	if pressed:
		if holding or state != State.CRANKING:
			return   # the emulated twin of a press already being held
		_hold_source = source
		tap()
		set_holding(true)
	else:
		set_holding(false)


# --- visuals ---

func _ready() -> void:
	_barrel = MeshInstance3D.new()
	_barrel.name = "Barrel"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	cylinder.height = 1.4
	cylinder.material = _flat(Color(0.6, 0.66, 0.74))
	_barrel.mesh = cylinder
	_barrel.position = Vector3(0.0, 0.7, 0.0)
	add_child(_barrel)
	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 1.05
	lid_mesh.bottom_radius = 1.05
	lid_mesh.height = 0.15
	lid_mesh.material = _flat(Color(0.45, 0.5, 0.58))
	lid.mesh = lid_mesh
	lid.position = Vector3(0.0, 0.78, 0.0)
	_barrel.add_child(lid)
	# The crank: an arm across the lid with a handle at its end; both turn with the barrel.
	var arm := MeshInstance3D.new()
	arm.name = "CrankArm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.0, 0.12, 0.14)
	arm_mesh.material = _flat(Color(0.3, 0.3, 0.33))
	arm.mesh = arm_mesh
	arm.position = Vector3(0.5, 0.92, 0.0)
	_barrel.add_child(arm)
	var handle := MeshInstance3D.new()
	handle.name = "CrankHandle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.18, 0.4, 0.18)
	handle_mesh.material = _flat(Color(0.95, 0.5, 0.2))
	handle.mesh = handle_mesh
	handle.position = Vector3(1.0, 1.1, 0.0)
	_barrel.add_child(handle)
	# The spigot: a short cylinder low on the side, lying along +Z, with a jar that grows under it while bottling.
	var spigot := MeshInstance3D.new()
	spigot.name = "Spigot"
	var spigot_mesh := CylinderMesh.new()
	spigot_mesh.top_radius = 0.12
	spigot_mesh.bottom_radius = 0.12
	spigot_mesh.height = 0.5
	spigot_mesh.material = _flat(Color(0.35, 0.35, 0.4))
	spigot.mesh = spigot_mesh
	spigot.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	spigot.position = Vector3(0.0, 0.3, 1.15)
	add_child(spigot)
	_spigot_jar = MeshInstance3D.new()
	_spigot_jar.name = "SpigotJar"
	var jar_mesh := CylinderMesh.new()
	jar_mesh.top_radius = 0.2
	jar_mesh.bottom_radius = 0.2
	jar_mesh.height = 0.35
	jar_mesh.material = _flat(Color(0.95, 0.65, 0.1))
	_spigot_jar.mesh = jar_mesh
	_spigot_jar.position = Vector3(0.0, 0.18, 1.5)
	_spigot_jar.visible = false
	add_child(_spigot_jar)


func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func _process(delta: float) -> void:
	# A release over a button never reaches _unhandled_input: stop holding when the mouse is up.
	if holding and _hold_source == "mouse" and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		set_holding(false)
	advance(delta)
	if _barrel != null and spin_speed > 0.0:
		_barrel.rotate_y(spin_speed * delta)
	if _spigot_jar != null:
		var filling: bool = state == State.BOTTLING and jars_bottled < jars_total
		_spigot_jar.visible = filling
		if filling:
			var grow: float = clampf(_bottle_timer / maxf(config.bottling_seconds_per_jar, 0.001), 0.05, 1.0)
			_spigot_jar.scale = Vector3(1.0, grow, 1.0)
			_spigot_jar.position.y = 0.18 * grow
