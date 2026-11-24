Goal agent run `0.3.2`, spec `game/specs/0.3.2-tests-and-quick-buy.md`, goal C2. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (). These existing tests read names it touches:
- `tests/play_loop.gd` [play]: `_run` (second_stop)
- `tests/test_camera.gd` [unit]: `_go_second_stop` (second_stop), `t_camera_second_stop_in_frame` (second_stop), `t_camera_second_stop_hive_share` (second_stop), `t_camera_second_stop_hud_clear` (second_stop), `t_camera_back_from_second_stop` (second_stop), `t_camera_pan_seconds` (second_stop), `t_camera_pan_follows_time_scale` (second_stop)
- `tests/test_crank_pause.gd` [unit]: `_cranking_at_second_stop` (second_stop), `t_crank_pauses_on_back_and_resumes_on_spin` (second_stop), `t_paused_crank_never_finishes_in_farm_view` (paused_crank, second_stop)
- `tests/test_dev.gd` [unit]: `t_dev_button_clear_of_hud` (second_stop)
- `tests/test_habitat.gd` [unit]: `t_habitat_pill_order_plus_opens_shop_twice` (habitat_pill), `t_skip_icon_farm_view_only` (second_stop)
- `tests/test_helpers_1.gd` [unit]: `_open_zoom` (second_stop), `_scrape_back_in_pop` (second_stop)
- `tests/test_helpers_4.gd` [unit]: `_hi_walk` (second_stop)
- `tests/test_helpers_5.gd` [unit]: `_tl_to_farm` (second_stop)
- `tests/test_hint.gd` [unit]: `t_hint_leaving_shows_step_that_fits_twice` (second_stop)
- `tests/test_motor.gd` [unit]: `_pour_in_farm_view` (second_stop), `t_no_spin_farm_view_without_motor` (second_stop)
- `tests/test_second_stop.gd` [unit]: `_second_stop_with_capped` (second_stop), `t_second_stop_back_tap` (second_stop), `t_second_stop_spin_icon_tap` (second_stop), `t_second_stop_fork_icon_tap` (second_stop), `_icons_state` (habitat_pill), `t_icons_never_overlap` (second_stop), `_pan_follows` (second_stop), `t_pan_after_back_then_harvest_again` (second_stop), `_ck_spin_ended_at_second_stop` (second_stop), `t_spin_from_farm_goes_to_second_stop` (second_stop), `t_spin_from_first_zoom_goes_to_second_stop` (second_stop)
- `tests/test_shop_zoom.gd` [unit]: `_zs_state` (second_stop), `_zs_same_state` (second_stop), `_zs_blocked` (second_stop), `_zs_back_with_sheet` (second_stop), `t_shop_in_first_zoom_buy_blocks_input_closes_on_exit` (second_stop), `t_shop_at_second_stop_buy_blocks_crank_closes_on_back` (second_stop)
- `tests/test_tools.gd` [unit]: `t_tools_icon_second_stop_place_and_farm_view_twice` (second_stop), `t_tools_second_stop_sheet_gearing_spigot_buy_blocks_exits_twice` (second_stop, t_tools_second_stop_sheet_gearing_spigot_buy_blocks_exits_twice)
- and 8 more functions

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
2. **Tests for what the 0.3.1 play-test found.** Each of the eleven rows below was fixed by hand on 2026-11-23 (commit named) and no test caught it. Each gets a test that fails on the code before the fix, and a mutation in `tests/mutations.json` that puts the old behaviour back and is CAUGHT by it. No game change is asked; a test that fails on today's code is a finding for Patricia or Bob.
   - Settings (`77f8c49`): `SettingsPanel` had no `ModalPanel` script, so the gear did nothing.
   - Coming soon (`77f8c49`): white text on the cream sheet.
   - Tab text (`77f8c49`): "Research" lost its "h" (equal-width tabs with `clip_text`).
   - Fork fill at full (`77f8c49`): the honey fill hid at full, leaving the white circle.
   - Smooth circles (`77f8c49`): StyleBoxFlat's 8 corner segments made the circles jagged.
   - Lid for the pile (`d42377f`, `77f8c49`): the close tween killed the open one.
   - Spin with a paused crank (`6131bfd`): Back mid-crank, uncap more, tap Spin did nothing.
   - Gear under sheets (`77f8c49`): the Shop sheet's Close sat on the Settings gear.
   - Gear placement (`37acad8`): the gear covered the Habitat pill and stayed over Back at the second stop.
   - Tools dim at the second stop (`47000ad`): already covered by `t_tools_second_stop_sheet_gearing_spigot_buy_blocks_exits_twice`; keep its mutation.
   - Spin size (`d42377f`, `064b241`): Spin drawn smaller or bigger by view; the glyph out of its circle.

Reply in at most 150 words: files changed, node names used, open questions.