extends SceneTree
## Render a scene to a PNG so its look can be checked without a person at the screen.
##
##   SCENE=res://scenes/harvest.tscn OUT=C:/path/shot.png Godot_v4.2.1-stable_win64_console.exe --path game --script res://tests/render.gd
##
## Windowed (not --headless): the headless dummy renderer draws nothing. SCENE defaults to the main scene,
## OUT to user://render.png, FRAMES (frames to wait before the capture) to 60. A scene with its own Camera3D
## is made current, so harvest.tscn renders from its own camera. Exit code 1 if the scene fails to load.

var _frames := 0
var _wait := 60
var _out := "user://render.png"


func _initialize() -> void:
	var scene_path := OS.get_environment("SCENE")
	if scene_path.is_empty():
		scene_path = ProjectSettings.get_setting("application/run/main_scene")
	_out = OS.get_environment("OUT") if not OS.get_environment("OUT").is_empty() else _out
	_wait = int(OS.get_environment("FRAMES")) if not OS.get_environment("FRAMES").is_empty() else _wait
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


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == _wait:
		var err := root.get_viewport().get_texture().get_image().save_png(_out)
		print("render: ", "saved " if err == OK else "FAILED to save ", _out)
		quit(0 if err == OK else 1)
	return false
