# Quinn: makes tests/fixtures/recording_fill_and_back.json by DRIVING the game with real input while an InputRecorder records:
# open the zoom with the Harvest icon, fill the bucket by dragging across the cells of the first frames, press Back.
# The hive is made to fill quickly (base_seconds_per_jar 0.05, a recorded config value) so the recording starts from an empty farm.
#   godot --headless --path game --script res://tests/make_recording_fixture.gd
extends "res://tests/test_second_stop.gd"

const OUT: String = "res://tests/fixtures/recording_fill_and_back.json"


func _initialize() -> void:
	_gen()


func _gen() -> void:
	await process_frame
	fi = FarmInput.new(self)
	process_frame.connect(_clk_tick)
	_portrait()
	Engine.time_scale = 1.0
	var cfg: GameConfig = GameConfig.live()
	cfg.base_seconds_per_jar = 0.05
	GameRng.set_seed(12345)
	var m: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	var rec := InputRecorder.new()
	rec.config = cfg
	root.add_child(rec)   # the replay starts its clock the same way: right after main
	rec.start()
	var p: Dictionary = _parts(m)
	var tr: Dictionary = _track(p["Hive"])
	var full: bool = await _until(func() -> bool: return bool(m.call("fork_available")), 20.0)
	await _frames(10)
	print("fork available: ", full)
	var opened: bool = await _open_zoom(m, p, tr)
	print("zoom opened: ", opened)
	var frames: int = int(ceil(float(_bucket_cells()) / float(_cpf())))
	for k in frames:
		var f: int = await _scrape_risen(m, p["Hive"], tr)
		await _next_frame(tr, f)
	await _wait(float(cv("cell_fly_seconds")) + _lid_t() + 0.3)
	print("bucket cells: ", (p["Centrifuge"] as Node).get("cells"))
	await fi.tap_at((p["BackButton"] as Control).get_global_rect().get_center())
	await _wait(float(cv("camera_pan_seconds")) + _zoom_settle())
	print("at second stop: ", m.call("at_second_stop"))
	var saved: String = rec.stop()
	print("saved: ", saved)
	var data: String = FileAccess.get_file_as_string(saved)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/fixtures"))
	var f2 := FileAccess.open(OUT, FileAccess.WRITE)
	f2.store_string(data)
	f2.close()
	print("wrote ", OUT, " (", data.length(), " bytes)")
	quit(0)
