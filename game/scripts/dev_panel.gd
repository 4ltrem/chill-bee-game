# Implements the Prototype 0 spec "Dev mode" (game/specs/prototype-0.md): a developer panel for tuning while playing.
# Open with the backquote key (desktop) or a three-finger tap (phone). One row per exported value in GameConfig,
# generated from the resource's property list, so a new config value appears here without UI work.
# main.gd adds this node only when the project setting chill_bee/dev_mode is true. It builds its own controls in code.
class_name DevPanel
extends CanvasLayer

const OPEN_KEY: int = KEY_QUOTELEFT
const OPEN_TOUCHES: int = 3
## The seven game speeds (0.1.3 spec, item 1), fixed by the spec and not a tunable; never saved.
const SPEEDS: Array[float] = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0]
const SPEED_TAG_NODE: String = "DevSpeedTag"   # Bob's Label in main.tscn; shown while the speed is not x1

var config: GameConfig
var hive: Hive
var truck: Truck

var _panel: PanelContainer
var _rows: Dictionary = {}          # value name -> SpinBox or CheckBox
var _touches: Dictionary = {}       # screen-touch index -> true while down
var _defaults: GameConfig
var _building: bool = false
var _bounds: UiBoundsOverlay
var _speed_buttons: Array[Button] = []
var _speed_group := ButtonGroup.new()
var _speed_tag: Control
var recorder: InputRecorder          # the input recorder (0.1.3 spec); F8 or the Record button toggles it
var _recording_label: Label


func _init() -> void:
	layer = 100
	visible = false


## Gives the panel the nodes its actions use. Called by main.gd right after add_child.
func setup(hive_node: Hive, truck_node: Truck) -> void:
	hive = hive_node
	truck = truck_node


func _ready() -> void:
	if not GameConfig.dev_mode_enabled():
		queue_free()
		return
	if config == null:
		config = GameConfig.live()
	_defaults = GameConfig.fresh_default()
	recorder = InputRecorder.new()
	recorder.name = "InputRecorder"
	recorder.config = config
	add_child(recorder)
	_build()
	recorder.recording_changed.connect(_on_recording_changed)
	if config.record_from_launch:
		recorder.start()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if _speed_tag != null and is_instance_valid(_speed_tag):
		_speed_tag.visible = false


# --- the code path the tests use ---

## Sets one config value as an edit in the panel would, and updates its row.
func set_value(value_name: String, value: Variant) -> void:
	config.set(value_name, value)
	var row: Control = _rows.get(value_name) as Control
	if row == null:
		return
	_building = true
	if row is SpinBox:
		(row as SpinBox).value = float(value)
	elif row is CheckBox:
		(row as CheckBox).button_pressed = bool(value)
	_building = false


## Writes the edited values to user://dev_config.tres; they load over the defaults at the next start.
func save_values() -> void:
	var copy: GameConfig = config.duplicate() as GameConfig
	ResourceSaver.save(copy, GameConfig.DEV_PATH)


## Deletes the saved file and puts every value back to its default.
func reset_to_defaults() -> void:
	if FileAccess.file_exists(GameConfig.DEV_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameConfig.DEV_PATH))
	GameConfig.apply_from(config, _defaults)
	_set_speed(1.0)
	for value_name in _rows:
		set_value(value_name, config.get(value_name))


## Every value that differs from its default, as "name = value" lines (also printed to the console).
func changed_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for value_name in GameConfig.value_names(config):
		if config.get(value_name) != _defaults.get(value_name):
			lines.append("%s = %s" % [value_name, str(config.get(value_name))])
	return lines


func print_values() -> void:
	var lines: PackedStringArray = changed_lines()
	print("--- Dev mode: changed values ---")
	for line in lines:
		print(line)
	if lines.is_empty():
		print("(none changed)")


# --- actions ---

func _fill_hive_now() -> void:
	if hive != null:
		hive.fill_now()


func _empty_truck() -> void:
	if truck != null:
		truck.reset_home()


func _economy_call(method: String, arg: Variant = null) -> void:
	var economy: Node = get_node_or_null("/root/Economy")   # by path so the script also compiles in --script test runs
	if economy == null:
		return
	if arg == null:
		economy.call(method)
	else:
		economy.call(method, arg)


## "Show UI bounds": outlines every visible Control, the icons' touch rects and anchor points (0.1 Harvest, Dev mode).
func set_ui_bounds(on: bool) -> void:
	if on and _bounds == null:
		_bounds = UiBoundsOverlay.new()
		var host: Node = get_parent() if get_parent() != null else self
		host.add_child(_bounds)
	if not on and _bounds != null:
		_bounds.queue_free()   # a hidden CanvasLayer's Control child still counts as visible in the tree
		_bounds = null


func ui_bounds_shown() -> bool:
	return _bounds != null and _bounds.visible


## Sets the game speed (Engine.time_scale), marks its button and updates the corner tag. Never saved.
func _set_speed(scale: float) -> void:
	Engine.time_scale = scale
	_refresh_speed_ui()


## One step along the speed row: -1 slower, +1 faster; stops at the ends.
func step_speed(direction: int) -> void:
	var index: int = _speed_index(Engine.time_scale)
	if index < 0:
		# Off the row (a test or another script set it): start from the nearest step at or below.
		index = 0
		for i in SPEEDS.size():
			if SPEEDS[i] <= Engine.time_scale:
				index = i
	_set_speed(SPEEDS[clampi(index + direction, 0, SPEEDS.size() - 1)])


func _speed_index(scale: float) -> int:
	for i in SPEEDS.size():
		if is_equal_approx(SPEEDS[i], scale):
			return i
	return -1


func _refresh_speed_ui() -> void:
	var index: int = _speed_index(Engine.time_scale)
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(i == index)
	if _speed_tag == null or not is_instance_valid(_speed_tag):
		var host: Node = get_parent() if get_parent() != null else self
		_speed_tag = host.find_child(SPEED_TAG_NODE, true, false) as Control
	if _speed_tag != null:
		_speed_tag.visible = not is_equal_approx(Engine.time_scale, 1.0)
		if _speed_tag is Label:
			(_speed_tag as Label).text = _speed_text(Engine.time_scale)


static func _speed_text(scale: float) -> String:
	return "×" + String.num(scale)


# --- input ---

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == OPEN_KEY:
		var focus: Control = get_viewport().gui_get_focus_owner()
		if not (focus is LineEdit):
			toggle()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_BRACKETLEFT or event.keycode == KEY_BRACKETRIGHT):
		# Active only while Dev mode is on (checked per key: a panel left in the tree must not step the speed once it is off).
		if GameConfig.dev_mode_enabled() and not (get_viewport().gui_get_focus_owner() is LineEdit):
			step_speed(-1 if event.keycode == KEY_BRACKETLEFT else 1)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = true
			if _touches.size() == OPEN_TOUCHES:
				toggle()
		else:
			_touches.erase(event.index)


func toggle() -> void:
	visible = not visible


# --- building the panel ---

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 20.0
	_panel.offset_right = -20.0
	_panel.offset_top = 60.0
	_panel.offset_bottom = -60.0
	add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	var title := Label.new()
	title.text = "Dev mode  (` or three-finger tap closes)"
	column.add_child(title)
	column.add_child(_actions_row())
	column.add_child(_file_row())
	_recording_label = Label.new()
	_recording_label.name = "RecordingLabel"
	_recording_label.text = "Recording: off (F8)"
	column.add_child(_recording_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for value_name in GameConfig.value_names(config):
		list.add_child(_make_row(value_name))


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	return button


func _actions_row() -> Control:
	var flow := HFlowContainer.new()
	flow.add_child(_button("Fill hive", _fill_hive_now))
	flow.add_child(_button("+$100", func() -> void: _economy_call("earn", 100)))
	flow.add_child(_button("Truck home", _empty_truck))
	flow.add_child(_button("Reset progress", func() -> void: _economy_call("reset")))
	var bounds_button := Button.new()
	bounds_button.text = "Show UI bounds"
	bounds_button.pressed.connect(func() -> void: set_ui_bounds(not ui_bounds_shown()))
	flow.add_child(bounds_button)
	for speed in SPEEDS:
		var button: Button = _button(_speed_text(speed), func() -> void: _set_speed(speed))
		button.toggle_mode = true
		button.button_group = _speed_group
		_speed_buttons.append(button)
		flow.add_child(button)
	_refresh_speed_ui()
	return flow


func _file_row() -> Control:
	var flow := HFlowContainer.new()
	flow.add_child(_button("Save", save_values))
	flow.add_child(_button("Reset to defaults", reset_to_defaults))
	flow.add_child(_button("Print values", print_values))
	flow.add_child(_button("Record (F8)", func() -> void: recorder.toggle()))
	return flow


func _on_recording_changed(name_now: String) -> void:
	if _recording_label != null:
		_recording_label.text = "Recording: " + name_now if name_now != "" else "Recording: off (F8)"


func _make_row(value_name: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Row_" + value_name
	var label := Label.new()
	label.text = value_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)
	var current: Variant = config.get(value_name)
	if typeof(current) == TYPE_BOOL:
		var check := CheckBox.new()
		check.button_pressed = bool(current)
		check.toggled.connect(func(on: bool) -> void:
			if not _building:
				config.set(value_name, on))
		row.add_child(check)
		_rows[value_name] = check
	else:
		var spin := SpinBox.new()
		var is_int: bool = typeof(current) == TYPE_INT
		spin.allow_greater = true
		spin.min_value = -100000.0 if value_name.ends_with("_anchor_offset") else 0.0
		spin.max_value = 100000.0
		# The step stays fine so no value is rounded; the arrows use a coarser step.
		spin.step = 1.0 if is_int else 0.01
		if not is_int:
			spin.custom_arrow_step = _float_step(float(current))
		spin.value = float(current)
		spin.value_changed.connect(func(v: float) -> void:
			if _building:
				return
			if is_int:
				config.set(value_name, int(roundf(v)))
			else:
				config.set(value_name, v))
		row.add_child(spin)
		_rows[value_name] = spin
	var default_label := Label.new()
	default_label.text = "(" + str(_defaults.get(value_name)) + ")"
	row.add_child(default_label)
	return row


func _float_step(value: float) -> float:
	var magnitude: float = absf(value)
	if magnitude < 1.0:
		return 0.01
	if magnitude < 10.0:
		return 0.1
	return 0.5
