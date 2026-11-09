# Quinn: windowed touch test for the crank (spec L61-L62), added in the r3 run, updated for 0.1 Harvest (the centrifuge is the one of main.tscn;
# the bucket is loaded with add_cells() and closed with close_lid(), fill() is gone).
#   Godot --path game --script res://tests/touch_windowed.gd
# Sends ScreenTouch events through Input.parse_input_event + flush, so the engine's touch->mouse emulation runs too
# (the headless run_tests.gd cannot: headless, Input.parse_input_event dispatches nothing). One press arrives as a
# touch AND its emulated mouse twin; it must count ONE turn, and a hold must count 1 + T x max_tap_rate turns.
# Expected numbers come from the live config. Exit 0 only if no check failed AND "COMPLETED" printed.
extends SceneTree

var fails: int = 0
var checks: int = 0


func _initialize() -> void:
	_run()


func ck(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL  ", msg)
	else:
		print("PASS  ", msg)


func _to_window() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func _touch(pressed: bool, vp_pos: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	t.position = vp_pos * _to_window()
	Input.parse_input_event(t)
	Input.flush_buffered_events()


var _main: Node


func _mk() -> Node:
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)   # _process runs, as in the game
	var c: Node = _main.find_child("Centrifuge", true, false)
	var cfg: Object = root.get_node("Economy").get("config")
	var cpf: int = int(cfg.get("grid_cols")) * int(cfg.get("grid_rows"))
	var n: int = cpf * int(cfg.get("centrifuge_capacity_frames"))   # a full bucket: enough turns for the 2 s hold
	c.call("add_cells", n, float(n * int(cfg.get("frame_jars"))) / float(cpf))
	c.call("close_lid")
	c.call("begin_crank")
	return c


func _run() -> void:
	await process_frame
	var stale: bool = load("res://tests/farm_input.gd").call("reset_dev_config")
	print("Dev config reset: a stale user://dev_config.tres was ", "FOUND and removed" if stale else "not present")
	var cfg: Object = load("res://scripts/game_config.gd").call("live")
	var rate: float = float(cfg.get("max_tap_rate"))
	var spot := Vector2(360.0, 640.0)
	# --- N touch taps spaced past the cap count exactly N turns
	var c := _mk()
	var n: int = 6
	var gap_ms: int = int((1.0 / rate + 0.08) * 1000.0)
	for i in n:
		_touch(true, spot)
		await process_frame
		_touch(false, spot)
		var until: int = Time.get_ticks_msec() + gap_ms
		while Time.get_ticks_msec() < until:
			await process_frame
	ck(int(c.get("turns_counted")) == n, "%d touch taps spaced past the cap count exactly %d turns (got %d)" % [n, n, int(c.get("turns_counted"))])
	_main.queue_free()
	await process_frame
	# --- a touch hold of T s counts 1 + T x max_tap_rate turns (+-1 frame), never more
	c = _mk()
	var hold_s: float = 2.0
	var t0: int = Time.get_ticks_msec()
	_touch(true, spot)
	while float(Time.get_ticks_msec() - t0) / 1000.0 < hold_s:
		await process_frame
	var held: float = float(Time.get_ticks_msec() - t0) / 1000.0
	_touch(false, spot)
	await process_frame
	var got: int = int(c.get("turns_counted"))
	var expect: float = 1.0 + held * rate
	ck(absf(float(got) - expect) <= 1.5, "touch hold of %.2f s counts about 1 + T x rate = %.1f turns (got %d)" % [held, expect, got])
	var after_release: int = got
	var until2: int = Time.get_ticks_msec() + 600
	while Time.get_ticks_msec() < until2:
		await process_frame
	ck(int(c.get("turns_counted")) == after_release, "releasing the touch stops the counting (%d -> %d)" % [after_release, int(c.get("turns_counted"))])
	ck(not bool(c.get("holding")), "not holding after release")
	_main.queue_free()
	await process_frame
	print("---- %d checks, %d failed" % [checks, fails])
	if fails == 0:
		print("COMPLETED")
	quit(1 if fails > 0 else 0)
