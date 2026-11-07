# Implements the 0.1.3 "Input recorder" (game/specs/0.1.3-next-revision.md), Dev mode only. A child node of the Dev panel (dev_panel.gd
# creates it; it never exists outside Dev mode). Record toggle: the panel's button or F8. Captures every InputEvent (mouse, touch, keys)
# stamped with game time (seconds since this node entered the tree, scaled by Engine.time_scale like the game) and saves build version,
# viewport size, every config value and the GameRng seed to user://recordings/<date>-<n>.json when recording stops.
# The static API at the bottom is what tests/replay.gd uses: load_recording(), apply(), events().
class_name InputRecorder
extends Node

const DIR: String = "user://recordings"
const TOGGLE_KEY: int = KEY_F8
const TEST_DIR_NAME: String = "chill_bee_test_recordings"   # 0.1.4 item 6: under tests the recorder writes here, never to user://recordings

## Where recordings go. Under a test or shot script (launched with --script / -s) it is a folder in the OS cache dir, so the player's
## user://recordings stays untouched. Set it before start() to override.
var dir: String = _default_dir()

signal recording_changed(file_name: String)   # file name while recording, "" when stopped

var config: GameConfig
var recording: bool = false
var file_name: String = ""
var game_time: float = 0.0

var _events: Array = []
var _started_at: float = 0.0
var _seed: int = 0


func _process(delta: float) -> void:
	game_time += delta   # delta is already scaled by Engine.time_scale


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if recording:
		var data: Dictionary = encode_event(event)
		if not data.is_empty():
			data["t"] = game_time
			_events.append(data)


func toggle() -> void:
	if recording:
		stop()
	else:
		start()


## Starts a recording; the file name (<date>-<n>.json) is chosen now so the panel can show it. Returns it.
func start() -> String:
	if recording:
		return file_name
	_events = []
	_started_at = game_time
	_seed = GameRng.current_seed()
	file_name = _next_file_name()
	recording = true
	recording_changed.emit(file_name)
	return file_name


## Stops and writes the file. Returns its user:// path ("" if nothing was recording or the write failed).
func stop() -> String:
	if not recording:
		return ""
	recording = false
	var path: String = dir + "/" + file_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot(), "\t"))
		file.close()
	else:
		path = ""
		push_warning("input_recorder.gd: cannot write the recording.")
	file_name = ""
	recording_changed.emit("")
	return path


func event_count() -> int:
	return _events.size()


func _exit_tree() -> void:
	if recording:
		stop()


## The recording as a Dictionary: version, viewport, seed, config, started_at (game time) and events (each with "t", game time).
func snapshot() -> Dictionary:
	var cfg: GameConfig = config if config != null else GameConfig.live()
	var values: Dictionary = {}
	for value_name in GameConfig.value_names(cfg):
		values[value_name] = cfg.get(value_name)
	var view: Vector2 = get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(720.0, 1280.0)
	return {
		"version": str(ProjectSettings.get_setting("application/config/version", "")),
		"viewport": [view.x, view.y],
		"seed": _seed,
		"started_at": _started_at,
		"config": values,
		"events": _events,
	}


func _next_file_name() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	var stem: String = "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
	var n: int = 1
	while FileAccess.file_exists("%s/%s-%d.json" % [dir, stem, n]):
		n += 1
	return "%s-%d.json" % [stem, n]


static func _default_dir() -> String:
	var args: PackedStringArray = OS.get_cmdline_args()
	if args.has("--script") or args.has("-s"):
		return OS.get_cache_dir().path_join(TEST_DIR_NAME)
	return DIR


# --- event <-> Dictionary ---

## An InputEvent as plain data, or {} for kinds the game does not use.
static func encode_event(e: InputEvent) -> Dictionary:
	if e is InputEventMouseButton:
		return {"type": "mouse_button", "pos": [e.position.x, e.position.y], "button": e.button_index, "pressed": e.pressed,
				"double": e.double_click, "mask": e.button_mask}
	if e is InputEventMouseMotion:
		return {"type": "mouse_motion", "pos": [e.position.x, e.position.y], "rel": [e.relative.x, e.relative.y], "mask": e.button_mask}
	if e is InputEventScreenTouch:
		return {"type": "touch", "index": e.index, "pos": [e.position.x, e.position.y], "pressed": e.pressed}
	if e is InputEventScreenDrag:
		return {"type": "drag", "index": e.index, "pos": [e.position.x, e.position.y], "rel": [e.relative.x, e.relative.y]}
	if e is InputEventKey:
		return {"type": "key", "keycode": e.keycode, "physical": e.physical_keycode, "pressed": e.pressed, "echo": e.echo}
	return {}


## Builds the InputEvent for one recorded entry (positions scaled by `scale`, for a different window size). Null for an unknown type.
static func decode_event(d: Dictionary, scale: Vector2 = Vector2.ONE) -> InputEvent:
	var pos := Vector2.ZERO
	var rel := Vector2.ZERO
	if d.has("pos"):
		pos = Vector2(float(d["pos"][0]), float(d["pos"][1])) * scale
	if d.has("rel"):
		rel = Vector2(float(d["rel"][0]), float(d["rel"][1])) * scale
	match str(d.get("type", "")):
		"mouse_button":
			var b := InputEventMouseButton.new()
			b.position = pos
			b.global_position = pos
			b.button_index = int(d["button"]) as MouseButton
			b.pressed = bool(d["pressed"])
			b.double_click = bool(d.get("double", false))
			b.button_mask = int(d.get("mask", 0)) as MouseButtonMask
			return b
		"mouse_motion":
			var m := InputEventMouseMotion.new()
			m.position = pos
			m.global_position = pos
			m.relative = rel
			m.button_mask = int(d.get("mask", 0)) as MouseButtonMask
			return m
		"touch":
			var t := InputEventScreenTouch.new()
			t.index = int(d["index"])
			t.position = pos
			t.pressed = bool(d["pressed"])
			return t
		"drag":
			var g := InputEventScreenDrag.new()
			g.index = int(d["index"])
			g.position = pos
			g.relative = rel
			return g
		"key":
			var k := InputEventKey.new()
			k.keycode = int(d["keycode"]) as Key
			k.physical_keycode = int(d.get("physical", 0)) as Key
			k.pressed = bool(d["pressed"])
			k.echo = bool(d.get("echo", false))
			return k
	return null


# --- the API for tests/replay.gd ---

## Reads a recording (a user:// or absolute path). {} if missing or unreadable.
static func load_recording(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## Puts the recording's config values over `cfg` (default: the live config) and reseeds GameRng. Call before the scene starts.
static func apply(recording_data: Dictionary, cfg: GameConfig = null) -> void:
	var target: GameConfig = cfg if cfg != null else GameConfig.live()
	var values: Dictionary = recording_data.get("config", {})
	for value_name in values:
		var current: Variant = target.get(value_name)
		var v: Variant = values[value_name]
		match typeof(current):
			TYPE_INT:
				v = int(v)
			TYPE_FLOAT:
				v = float(v)
			TYPE_BOOL:
				v = bool(v)
		target.set(value_name, v)
	GameRng.set_seed(int(recording_data.get("seed", 0)))


## The recorded events, each a Dictionary with "t" (game time), in order.
static func events(recording_data: Dictionary) -> Array:
	return recording_data.get("events", [])


## The recorded viewport size, to scale positions to another window: replay_size / recorded_size.
static func recorded_viewport(recording_data: Dictionary) -> Vector2:
	var v: Array = recording_data.get("viewport", [720.0, 1280.0])
	return Vector2(float(v[0]), float(v[1]))
