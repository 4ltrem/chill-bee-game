Goal agent run `0.3.2`, spec `game/specs/0.3.2-tests-and-quick-buy.md`, goal C10. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (Patricia). These existing tests read names it touches:
- `tests/play_loop.gd` [play]: `_open_zoom` (BackButton), `_run` (BackButton)
- `tests/r4_measure.gd` [measure]: `_run` (BackButton)
- `tests/test_camera.gd` [unit]: `t_camera_second_stop_hud_clear` (BackButton), `t_camera_back_from_second_stop` (BackButton)
- `tests/test_crank_pause.gd` [unit]: `t_crank_pauses_on_back_and_resumes_on_spin` (BackButton), `t_paused_crank_never_finishes_in_farm_view` (BackButton)
- `tests/test_dev.gd` [unit]: `t_dev_ui_bounds_collects_controls` (BackButton)
- `tests/test_economy.gd` [unit]: `t_node_contract` (BackButton)
- `tests/test_helpers_1.gd` [unit]: `_open_zoom` (BackButton), `_scrape_back_in_pop` (BackButton)
- `tests/test_helpers_4.gd` [unit]: `_hi_walk` (BackButton)
- `tests/test_helpers_5.gd` [unit]: `_tl_place_problems` (BackButton), `_tl_open_check` (ShopCloseButton), `_tl_close_check` (ShopCloseButton)
- `tests/test_hint.gd` [unit]: `t_hint_skip_ends_for_good_twice` (ShopCloseButton), `t_hint_shop_only_plant_above_sheet_ends_on_patch` (ShopCloseButton), `t_hint_leaving_shows_step_that_fits_twice` (BackButton)
- `tests/test_lid_clip.gd` [unit]: `t_lid_close_never_clips_hive` (BackButton)
- `tests/test_second_stop.gd` [unit]: `_second_stop_with_capped` (BackButton), `t_second_stop_back_tap` (BackButton), `t_second_stop_fork_icon_tap` (BackButton), `_anchor_gap` (BackButton)
- `tests/test_shop.gd` [unit]: `t_shop_no_row_overlaps_other_controls` (BackButton), `t_shop_seven_rows_on_screen_no_scroll` (BackButton)
- `tests/test_shop_zoom.gd` [unit]: `_zs_clear` (BackButton), `_zs_buy` (ShopCloseButton), `t_shop_in_first_zoom_buy_blocks_input_closes_on_exit` (ShopCloseButton)
- `tests/test_tools.gd` [unit]: `t_tools_sheet_closes_when_zoom_ends_on_its_own_twice` (tools_sheet), `t_tools_leaves_shop_tab_alone_twice` (ShopCloseButton)
- `tests/test_ui_placement.gd` [unit]: `_hud_rects` (BackButton), `t_harvest_hidden_at_second_stop` (BackButton), `_measure_label` (BackButton), `_back_hint_rects` (BackButton)
- `tests/test_zoom.gd` [unit]: `t_zoom_ui_and_camera` (BackButton), `t_zoom_view_option_a` (BackButton)
- `tests/test_zoom2.gd` [unit]: `t_back_after_one_frame` (BackButton), `t_back_keeps_half_frame` (BackButton), `t_fork_shows_while_cranking_and_state_table` (BackButton), `t_no_crank_during_zoom` (BackButton)
- and 3 more functions

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
10. **A Close you can read on the Shop and Tools sheet** (designer, 2026-11-26, play-test: "what is the 2715 button in the tools screen?"). `shop_ui.gd` sets `ShopCloseButton`'s text to "✕" (U+2715); at the 2026-11-26 play-test it drew as a box reading "2715" (a missing glyph in the font used). After this change the button has no text: it shows an X drawn from two crossed ink strokes (primitives, as `BackButton`'s arrow, 0.3.1 item 6), centred in its 120 × 120 touch rect, and still closes the sheet. Stroke size is a placeholder the designer confirms at play-test.

Reply in at most 150 words: files changed, node names used, open questions.