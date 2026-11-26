Goal agent run `0.3.2`, spec `game/specs/0.3.2-tests-and-quick-buy.md`, goal C11. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (Patricia). These existing tests read names it touches:
- `tests/play_loop.gd` [play]: `_run` (FULL)
- `tests/r4_measure.gd` [measure]: `_run` (begin_crank, close_lid)
- `tests/test_base.gd` [unit]: `_st` (FULL)
- `tests/test_bottling.gd` [unit]: `t_bottling_35_single_cells_is_2_jars` (begin_crank, close_lid), `t_leftover_adds_no_turns` (begin_crank)
- `tests/test_camera.gd` [unit]: `t_camera_lid_lean_matches_hive` (begin_crank, close_lid)
- `tests/test_centrifuge.gd` [unit]: `t_lid_close_and_signal` (FULL, begin_crank, close_lid), `t_crank_ignored_outside_cranking` (FULL, begin_crank, close_lid)
- `tests/test_economy.gd` [unit]: `t_retired_api_gone` (close_lid)
- `tests/test_gearing.gd` [unit]: `t_gearing_turns_by_level` (begin_crank), `t_gearing_own_motor_cut` (begin_crank)
- `tests/test_helpers_1.gd` [unit]: `_load_bucket` (close_lid), `_to_cranking` (begin_crank), `_scrape_back_in_pop` (FULL, close_lid)
- `tests/test_helpers_3.gd` [unit]: `_crank_unaided` (begin_crank, close_lid)
- `tests/test_hive.gd` [unit]: `t_became_full_once_while_filling` (once_while)
- `tests/test_hive_model.gd` [unit]: `t_lid_closes_clear_of_walls` (close_lid)
- `tests/test_jars.gd` [unit]: `t_jar_fills_then_lid` (begin_crank, close_lid)
- `tests/test_lids.gd` [unit]: `t_hive_lid_close_path` (close_lid), `t_centrifuge_lid_paths` (begin_crank, close_lid), `t_barrel_eases_to_stop` (begin_crank, close_lid)
- `tests/test_motor.gd` [unit]: `_pour_in_farm_view` (FULL), `t_no_spin_farm_view_without_motor` (FULL), `t_no_spin_after_pour_farm_view` (FULL), `t_no_spin_first_zoom_without_motor` (FULL)
- `tests/test_second_stop.gd` [unit]: `_second_stop_with_capped` (FULL), `t_second_stop_spin_icon_tap` (FULL), `t_pan_after_all_frames_uncapped` (FULL), `t_spin_icon_in_first_zoom` (FULL), `t_spin_from_farm_goes_to_second_stop` (FULL), `t_spin_from_first_zoom_goes_to_second_stop` (FULL)
- `tests/test_speed.gd` [unit]: `_measure` (begin_crank, close_lid)
- `tests/test_ui_placement.gd` [unit]: `t_harvest_holds_anchor_spin_below` (FULL)
- `tests/test_zoom.gd` [unit]: `t_zoom_bucket_lid_pile_flow` (FULL)
- `tests/test_zoom2.gd` [unit]: `t_back_after_one_frame` (FULL), `t_fork_rules` (FULL, begin_crank, close_lid), `t_fork_shows_while_cranking_and_state_table` (FULL, begin_crank, close_lid), `t_resume_pending_pile_loads_while_zoom_open` (FULL)
- `tests/test_zoom_end.gd` [unit]: `_ck_zoom_stays_open` (FULL)
- `tests/touch_windowed.gd` [touch]: `_mk` (begin_crank, close_lid)

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
11. **No spinning with the lid off** (designer, 2026-11-26, play-test: "you can spin the centrifuge when the lid is off and the liquid rises, makes no sense"). Today `close_lid()` (`centrifuge.gd`) sets `FULL` at once while the lid's visual is still lifting (after bottling with a pile) or still closing, and `begin_crank()`, `tap()` and a hold check only the state, so the crank turns, the barrel spins and the honey rises with the lid off. After this change cranking starts only once the lid's visual is fully on: before that a Spin tap, a crank tap or a hold counts no turn and the barrel and honey don't move; the turn after the lid lands counts as usual. Spin mode's own crank (`main.gd`, the reloaded bucket) waits for the lid the same way.

Reply in at most 150 words: files changed, node names used, open questions.