# Quinn: the test runner. Tests live in test_*.gd, one file per area (each extends the one before it, test_base.gd first).
#   Godot --headless --path game --script res://tests/run_tests.gd
# See test_base.gd for the rules. Exit 0 only if every test passed AND "RAN n of n" printed with n == the number of tests.
extends "res://tests/test_replay.gd"


# Tests that stay at x1 (they read the wall clock on purpose, own Engine.time_scale through the Dev speed row, or measure wall seconds
# of a motion at a chosen speed). The ONE place; every other test runs at CB_TIME_SCALE.
const X1_TESTS: Array[String] = [
	"t_speed_jar_cycle", "t_speed_lid_lift", "t_speed_cell_flight", "t_speed_hotkeys", "t_speed_tag", "t_speed_reset",
	"t_camera_pan_follows_time_scale",   # measures the pan in wall seconds at x5 and x0.5
	"t_dev_actions",                      # presses the Dev speed button and reads Engine.time_scale
	"t_pop_tween_unchanged",              # samples a 0.18 s tween: too few frames at x6 (0.042 vs 0.04 tolerance)
	"t_jar_fills_then_lid",               # samples a 1.0 s honey rise per frame: missed at x6
	"t_replay_fill_and_back", "t_replay_without_back_stays_in_zoom",   # a replay feeds one drag motion per frame: at x6 each frame is 0.1 s of game time
]


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame   # root has finished setting up its children; add_child is safe from here
	fi = FarmInput.new(self)
	var tests: Array[String] = [
		# economy (unchanged)
		"t_cost_formula", "t_cost_max_level", "t_buy_deducts_and_levels", "t_buy_blocked_unaffordable",
		"t_fill_multiplier", "t_bee_count", "t_fill_multiplier_is_bees_over_base", "t_economy_removed_jars",
		"t_earn_and_jar_value", "t_drawn_count_capped",
		# contract and config (new values, retired values, retired scene)
		"t_node_contract", "t_config_values", "t_config_placeholders_marked", "t_retired_api_gone",
		# hive: fill by frames and slots, risen frame, overflow of one hive, scrape
		"t_fill_time_level0", "t_fill_time_with_levels", "t_hive_rate_is_live", "t_fill_in_order_slot_by_slot",
		"t_risen_frame_never_fills", "t_overflow_one_hive_then_pause", "t_became_full_once_while_filling",
		"t_became_full_count_full_overflow", "t_scrape_value", "t_scrape_rules", "t_next_frame_to_harvest",
		# centrifuge: bucket, lid, turns, floor bottling
		"t_bucket_capacity_and_states", "t_lid_close_and_signal", "t_turns_per_jar", "t_crank_enabled_flag",
		"t_hold_at_cap", "t_hold_ramp_is_visual_only", "t_hold_never_slower", "t_hold_release_stops",
		"t_tap_cap", "t_tap_cap_is_live", "t_crank_ignored_outside_cranking", "t_real_mouse_taps_crank",
		"t_real_touch_taps_crank", "t_button_press_is_not_a_crank",
		"t_bottling_timing", "t_bottling_time_is_live", "t_bottling_floor_and_leftover_carry", "t_leftover_adds_no_turns",
		"t_bottling_35_single_cells_is_2_jars", "t_pile_unit",
		# truck (unchanged) and the wheels
		"t_truck_full_and_can_sell", "t_truck_sell_credits_at_once", "t_truck_crate_while_away",
		"t_truck_return_loads_crate", "t_truck_trip_time_is_live", "t_truck_wheels_roll_with_travel",
		# the zoom, through real input
		"t_zoom_ui_and_camera", "t_zoom_bucket_lid_pile_flow", "t_back_after_one_frame", "t_back_keeps_half_frame",
		"t_fork_rules", "t_fork_shows_while_cranking_and_state_table", "t_no_crank_during_zoom",
		"t_zoom_fill_and_bottling_keep_running",
		"t_scrape_then_back_in_pop_window_bucket", "t_scrape_then_back_in_pop_window_pile", "t_resume_pending_pile_loads_while_zoom_open",
		"t_pop_tween_unchanged", "t_focus_styles",
		# floating icons (unchanged) and icon sizes
		"t_icon_follows_anchor", "t_icon_hidden_behind_camera", "t_icon_touch_area_in_scene",
		# dev mode
		"t_dev_mode_setting", "t_dev_no_panel_when_off",
		"t_dev_panel_when_on", "t_dev_max_tap_rate", "t_dev_bottling_seconds", "t_dev_save_reset_roundtrip",
		"t_dev_user_file_ignored_when_off", "t_dev_backquote_opens", "t_dev_three_finger_opens", "t_dev_actions",
		"t_dev_show_ui_bounds",
		# 0.1.1 play-test fixes
		"t_dev_ui_bounds_collects_controls", "t_overlap_helper_can_fail", "t_rim_measure_can_fail", "t_config_011", "t_dev_panel_has_lid_values",
		"t_node_contract_011", "t_hive_footprint_and_frames", "t_hive_lid_open_path", "t_hive_lid_close_path", "t_hive_lid_leaning_pose",
		"t_centrifuge_lid_paths", "t_barrel_eases_to_stop", "t_heap_shows_every_cell", "t_pile_shows_every_cell", "t_jar_fills_then_lid",
		"t_truck_and_crate_jars_full_with_lids", "t_wheel_rims", "t_cell_width_at_zoom",
			# 0.1.2 bottling and sale (written from game/specs/0.1.2-bottling-and-sale.md before the code)
			"t_zoom_view_option_a", "t_hive_size_vs_truck", "t_centrifuge_lid_rests_clear", "t_flight_judge_can_fail", "t_start_helper_can_fail",
			"t_continue_finder_can_fail", "t_node_contract_012", "t_config_012", "t_crate_shows_empties", "t_jar_flights_to_spigot_and_truck",
			"t_jar_lands_in_crate_when_truck_away", "t_crate_fulls_fly_to_truck_on_return", "t_bottling_starts_by_itself", "t_no_continue_button",
			"t_summary_after_sell",
			# 0.1.3a speed (written from game/specs/0.1.3-next-revision.md before the code)
			"t_speed_jar_cycle", "t_speed_lid_lift", "t_speed_cell_flight", "t_speed_hotkeys", "t_speed_tag", "t_speed_reset",
			"t_no_wall_clock_in_scripts",
			# 0.1.3b layout (written from game/specs/0.1.3-next-revision.md before the code)
			"t_layout_no_jar_outside_crate", "t_layout_truck_wheels_on_ground", "t_layout_hive_scale_follows_config", "t_layout_objects_on_cells",
			# 0.1.3c camera (written from game/specs/0.1.3-next-revision.md before the code)
			"t_camera_first_zoom_cells", "t_camera_first_zoom_in_frame", "t_camera_first_zoom_v7", "t_camera_second_stop_in_frame",
			"t_camera_second_stop_hive_share", "t_camera_second_stop_hud_clear", "t_camera_back_from_second_stop", "t_camera_pan_seconds",
			"t_camera_pan_follows_time_scale", "t_camera_helpers_can_fail", "t_camera_lid_lean_matches_hive", "t_camera_lid_component_shared",
			# 0.1.3c second-stop input paths (real taps)
			"t_second_stop_back_tap", "t_second_stop_spin_icon_tap", "t_second_stop_fork_icon_tap",
			"t_icons_never_overlap",
			# 0.1.3 play-test (2026-11-06)
			"t_pan_after_all_frames_uncapped", "t_pan_after_back_then_harvest_again", "t_icons_above_props", "t_spin_icon_in_first_zoom",
			# input-recorder replay
			"t_replay_fill_and_back", "t_replay_without_back_stays_in_zoom",
	]
	var only: String = OS.get_environment("CB_ONLY")   # a comma list of test names: run just those (the broken-copy runs use it); empty = all
	if only != "":
		var keep: Array[String] = []
		for t in tests:
			if (",%s," % only).contains(",%s," % t):
				keep.append(t)
		tests = keep
		print("CB_ONLY: running ", tests.size(), " test(s): ", tests)
	_selfcheck()
	_backup_user_cfg()
	# the equivalent of the Dev panel's "Reset to defaults": a stale user://dev_config.tres (backed up above, and removed) must not skew the run
	print("Dev config: a user://dev_config.tres was ", "FOUND (backed up, removed for the run, restored at the end)" if _user_cfg_existed else "not present", "; the live config is reset to default_config.tres")
	FarmInput.reset_dev_config()
	var sc: String = OS.get_environment("CB_TIME_SCALE")
	_run_scale = maxf(float(sc), 0.01) if sc != "" else 1.0
	print("Test speed: CB_TIME_SCALE x", _run_scale, " (tests in X1_TESTS run at x1: ", X1_TESTS.size(), ")")
	if OS.get_environment("CB_SKIP_X1") == "1":   # designer, 2026-11-06: real-time checks are played by hand; routine runs skip them
		var rt: Array[String] = []
		for t in tests:
			if not X1_TESTS.has(t):
				rt.append(t)
		tests = rt
		print("CB_SKIP_X1: the ", X1_TESTS.size(), " real-time tests are skipped (played by the designer)")
	process_frame.connect(_clk_tick)
	var ran: int = 0
	for t in tests:
		_wall_clock = X1_TESTS.has(t)
		_clk_tick()
		Engine.time_scale = 1.0 if _wall_clock else _run_scale
		var t_start: int = Time.get_ticks_msec()
		_eco_reset()
		_cur_ok = true
		_cur_msgs.clear()
		_checks = 0
		_finished = false
		await call(t)
		if not _finished:
			_cur_ok = false
			_cur_msgs.append("test stopped before its final line (script error or missing method; see the engine error above)")
		if _checks == 0:
			_cur_ok = false
			_cur_msgs.append("test made no checks")
		_cleanup()
		ran += 1
		print("TIME  ", t, "  ", Time.get_ticks_msec() - t_start, " ms wall")
		if _cur_ok:
			_passed += 1
			print("PASS  ", t, "  (", _checks, " checks)")
		else:
			_failed += 1
			print("FAIL  ", t, "  ", " | ".join(_cur_msgs))
	_restore_user_cfg()
	print("---- %d passed, %d failed" % [_passed, _failed])
	print("RAN %d of %d" % [ran, tests.size()])
	quit(1 if (_failed > 0 or ran != tests.size()) else 0)
