# Quinn: headless replay of an input recording (0.1.3 Input recorder).
#   CB_REPLAY=<recording .json> [CB_TIME_SCALE=6] [CB_REPLAY_TAIL=4] godot --headless --path game --script res://tests/replay.gd
# Prints one "STATE t=<s> stop=.. zoom=.. bucket=.. pile=.. icons=.." line per change, then "REPLAY done". Engine in tests/replay_core.gd.
extends SceneTree


func _initialize() -> void:
	_go()


func _go() -> void:
	await process_frame
	var path: String = OS.get_environment("CB_REPLAY")
	if path == "":
		print("REPLAY failed: set CB_REPLAY=<recording .json>")
		quit(2)
		return
	root.size = Vector2i(720, 1280)   # the portrait window the game is played in (the tests do the same)
	var sc: String = OS.get_environment("CB_TIME_SCALE")
	if sc != "":
		Engine.time_scale = maxf(float(sc), 0.01)
	var tail: String = OS.get_environment("CB_REPLAY_TAIL")
	var core = load("res://tests/replay_core.gd").new()
	core.echo = true
	var last: Dictionary = await core.play(self, path, float(tail) if tail != "" else 4.0)
	if last.is_empty():
		print("REPLAY failed: cannot read ", path)
		quit(2)
		return
	print("REPLAY events fed %d of %d" % [core.delivered, core.total_events])
	print("REPLAY done")
	quit(0)
