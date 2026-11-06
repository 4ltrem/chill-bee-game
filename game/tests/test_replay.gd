extends "res://tests/test_second_stop.gd"

# Quinn: the input-recorder replay (0.1.3 spec, "Input recorder"; Clarifications 0.1.3c "Spin in the first zoom": closing the zoom with a
# full bucket, Back included, pans to the second stop). tests/fixtures/recording_fill_and_back.json was made by
# tests/make_recording_fixture.gd: it opens the zoom with Harvest, fills the bucket (70 cells) by dragging across the cells and presses Back.
# The replay (tests/replay_core.gd, the engine of tests/replay.gd) loads it through InputRecorder, starts main.tscn with its config and seed
# and feeds each event at its game time as window pixels.

const FIXTURE: String = "res://tests/fixtures/recording_fill_and_back.json"


func _replay(path: String) -> Object:
	_portrait()
	var core = load("res://tests/replay_core.gd").new()
	var last: Dictionary = await core.play(root.get_tree(), path, 4.0)
	ck(not last.is_empty(), "the recording '%s' was read and replayed" % path)
	return core


func t_replay_fill_and_back() -> void:
	var rec: Dictionary = InputRecorder.load_recording(FIXTURE)
	ck(not rec.is_empty(), "the fixture loads through InputRecorder.load_recording")
	ck(InputRecorder.events(rec).size() > 100, "the fixture holds drag events (%d)" % InputRecorder.events(rec).size())
	var core: Object = await _replay(FIXTURE)
	var states: Array = core.states
	ck(states.size() > 5, "the replay printed STATE lines (%d)" % states.size())
	eq(core.delivered, core.total_events, "every recorded event was fed")
	var seen: Dictionary = {}
	for s in states:
		seen[str((s as Dictionary)["stop"])] = true
	ck(seen.has("farm") and seen.has("zoom") and seen.has("second"), "the states went farm -> zoom -> second stop (%s)" % str(seen.keys()))
	if states.is_empty():
		_fin()
		return
	var last: Dictionary = states[states.size() - 1]
	eq(last["stop"], "second", "the replay ends at the second stop (bucket full, Back pressed)")
	eq(last["zoom"], "NONE", "the zoom is closed at the end")
	eq(last["bucket"], 70, "the bucket holds 2 frames (70 cells)")
	ck((last["icons"] as Array).has("Centrifuge"), "Spin shows at the end (icons %s)" % str(last["icons"]))
	var line: String = (core.lines[core.lines.size() - 1] as String)
	ck(line.begins_with("STATE t=") and line.contains("stop=second"), "the printed line has the STATE format (%s)" % line)
	_fin()


## The test can fail for the right reason: the same recording without its last two events (Back's press and release) must not end at the
## second stop; the camera stays on the first zoom (the bucket filled, the frames were not all done).
func t_replay_without_back_stays_in_zoom() -> void:
	var rec: Dictionary = InputRecorder.load_recording(FIXTURE)
	var evs: Array = InputRecorder.events(rec)
	var cut: Array = evs.slice(0, evs.size() - 2)
	ck(cut.size() == evs.size() - 2, "two events were cut")
	rec["events"] = cut
	var path: String = "user://replay_without_back.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(rec))
	f.close()
	var core: Object = await _replay(path)
	var states: Array = core.states
	if states.is_empty():
		ck(false, "no states")
		_fin()
		return
	var last: Dictionary = states[states.size() - 1]
	eq(last["stop"], "zoom", "without Back the replay stays in the first zoom")
	eq(last["bucket"], 70, "the bucket is still full")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_fin()
