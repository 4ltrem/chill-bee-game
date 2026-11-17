extends SceneTree
## Render a scene to a PNG so its look can be checked without a person at the screen.
##
##   Godot_v4.2.1-stable_win64_console.exe --path game --script res://tests/render.gd -- --scene res://scenes/harvest.tscn --out C:/path/shot.png
##
## Windowed (not --headless): the headless dummy renderer draws nothing. --scene defaults to the main scene,
## --out to user://render.png, --frames (frames to wait before the capture) to 60; `--name value` and `--name=value`
## both work. The env vars SCENE, OUT and FRAMES are still read when a flag is absent. A scene with its own Camera3D
## is made current, so harvest.tscn renders from its own camera. Exit code 1 if the scene fails to load.

var _frames := 0
var _wait := 60
var _out := "user://render.png"


func _initialize() -> void:
	var scene_path := _arg("scene", "SCENE")
	if scene_path.is_empty():
		scene_path = ProjectSettings.get_setting("application/run/main_scene")
	var out := _arg("out", "OUT")
	_out = out if not out.is_empty() else _out
	var frames := _arg("frames", "FRAMES")
	_wait = int(frames) if not frames.is_empty() else _wait
	print("render: scene ", scene_path, " -> ", _out, " after ", _wait, " frames")
	var packed: PackedScene = load(scene_path)
	if packed == null:
		printerr("render: cannot load ", scene_path)
		quit(1)
		return
	var node := packed.instantiate()
	root.add_child(node)
	var camera := node.get_node_or_null("Camera3D") as Camera3D
	if camera:
		camera.make_current()


## A user arg after `--` (`--name value` or `--name=value`), else the env var, else "".
func _arg(name: String, env: String) -> String:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i].begins_with("--%s=" % name):
			return args[i].substr(name.length() + 3)   # after "--name="
		if args[i] == "--" + name and i + 1 < args.size():
			return args[i + 1]
	return OS.get_environment(env)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == _wait:
		var err := root.get_viewport().get_texture().get_image().save_png(_out)
		print("render: ", "saved " if err == OK else "FAILED to save ", _out)
		quit(0 if err == OK else 1)
	return false
