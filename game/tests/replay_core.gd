# Quinn: the replay engine shared by tests/replay.gd (CB_REPLAY=<file>) and the unit test t_replay_fill_and_back (test_replay.gd).
# Loads a recording through InputRecorder (scripts/input_recorder.gd), puts its config and seed in place, starts main.tscn, feeds each
# event at its GAME time (a Node's _process delta, scaled by Engine.time_scale exactly like the recorder's clock), scaled to the current
# viewport when the recorded one differed, and collects one "STATE t=<s> ..." line whenever the camera stop, zoom, bucket/pile counts or
# the shown icons change. Events go in as window pixels through root.push_input, as a real mouse sends them.
extends RefCounted

const ICONS: Array[String] = ["ForkIcon", "CentrifugeIcon", "SellIcon", "BackButton"]

var lines: Array[String] = []
var states: Array[Dictionary] = []   # one per STATE line: {t, stop, zoom, bucket, pile, icons}
var delivered: int = 0               # events pushed / in the recording, set when play() ends
var total_events: int = 0
var echo: bool = false             # print each STATE line as it is made


class Clock extends Node:
	var game_time: float = 0.0
	func _process(delta: float) -> void:
		game_time += delta


func _find(m: Node, n: String) -> Node:
	return m.find_child(n, true, false)


func _snapshot(m: Node, t: float) -> Dictionary:
	var zoom_names: Array = (m.get_script() as Script).get_script_constant_map().get("Zoom", {}).keys()
	var z: int = int(m.get("zoom"))
	var second: bool = bool(m.call("at_second_stop"))
	var cen: Node = _find(m, "Centrifuge")
	var pile: Node = _find(m, "Pile")
	var shown: Array[String] = []
	for n in ICONS:
		var c: Node = _find(m, n)
		if c != null and (c as CanvasItem).is_visible_in_tree():
			shown.append(n.trim_suffix("Icon").trim_suffix("Button"))
	return {
		"t": t,
		"stop": "second" if second else ("zoom" if z != 0 else "farm"),
		"zoom": zoom_names[z] if z < zoom_names.size() else str(z),
		"bucket": int(cen.get("cells")) if cen != null else -1,
		"pile": int(pile.get("cells")) if pile != null else -1,
		"icons": shown,
	}


func _key(s: Dictionary) -> String:
	return "%s|%s|%d|%d|%s" % [s["stop"], s["zoom"], s["bucket"], s["pile"], ",".join(s["icons"])]


func _line(s: Dictionary) -> String:
	return "STATE t=%.2f stop=%s zoom=%s bucket=%d pile=%d icons=%s" % [s["t"], s["stop"], s["zoom"], s["bucket"], s["pile"], ",".join(s["icons"])]


## Replays `path` (a user:// or absolute path) in `tree`. `tail` = game seconds to keep running after the last event (the pan must finish).
## Returns the last state ({} if the recording is missing). The live config is restored afterwards.
func play(tree: SceneTree, path: String, tail: float = 4.0) -> Dictionary:
	var rec: Dictionary = InputRecorder.load_recording(path)
	if rec.is_empty():
		push_error("replay: cannot read recording '%s'" % path)
		return {}
	var cfg: GameConfig = GameConfig.live()
	var saved: Dictionary = {}
	for n in GameConfig.value_names(cfg):
		saved[n] = cfg.get(n)
	InputRecorder.apply(rec, cfg)
	var root: Window = tree.root
	var evs: Array = InputRecorder.events(rec)
	var view: Vector2 = Vector2(root.get_visible_rect().size)
	var rv: Vector2 = InputRecorder.recorded_viewport(rec)
	var scale := Vector2(view.x / rv.x, view.y / rv.y)
	var to_window: Vector2 = Vector2(root.size) / view
	var m: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	var clock := Clock.new()
	root.add_child(clock)   # added right after main, like the recorder inside the Dev panel: both clocks start together
	var end_t: float = tail if evs.is_empty() else 1.0e12   # moved to (game time of the last event fed) + tail once every event is in: the replay may run late (one motion per frame)
	var i: int = 0
	var fed_all: bool = evs.is_empty()
	var last_key: String = ""
	var last: Dictionary = {}
	while clock.game_time < end_t:
		await tree.process_frame
		while i < evs.size() and float((evs[i] as Dictionary)["t"]) <= clock.game_time:
			var e: InputEvent = InputRecorder.decode_event(evs[i] as Dictionary, scale * to_window)
			if e != null:
				root.push_input(e)
			i += 1
			# a motion event ends the frame: a drag is one motion per frame in the game, and several motions folded into one frame
			# would skip cells between them (the replay then falls behind the recording and catches up on still moments)
			if e is InputEventMouseMotion or e is InputEventScreenDrag:
				break
		if i >= evs.size() and not fed_all:
			fed_all = true
			end_t = clock.game_time + tail
		last =_snapshot(m, clock.game_time)
		if _key(last) != last_key:
			last_key = _key(last)
			states.append(last)
			lines.append(_line(last))
			if echo:
				print(lines[lines.size() - 1])
	delivered = i
	total_events = evs.size()
	root.remove_child(clock)
	clock.free()
	root.remove_child(m)
	m.free()
	for n in saved:
		cfg.set(n, saved[n])
	return last
