Goal agent run `0.3.2`, spec `game/specs/0.3.2-tests-and-quick-buy.md`, goal C8. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (Patricia). These existing tests read names it touches:
- `tests/play_loop.gd` [play]: `_run` (CentrifugeLabel, HintLabel)
- `tests/test_base.gd` [unit]: `_mk_main` (show_hint)
- `tests/test_bottling.gd` [unit]: `t_no_continue_button` (farm_ui)
- `tests/test_camera.gd` [unit]: `t_camera_second_stop_hud_clear` (CentrifugeLabel), `t_camera_back_from_second_stop` (farm_ui)
- `tests/test_crank_pause.gd` [unit]: `t_crank_pauses_on_back_and_resumes_on_spin` (CentrifugeLabel)
- `tests/test_economy.gd` [unit]: `t_node_contract` (HintLabel)
- `tests/test_helpers_1.gd` [unit]: `_node` (HintLabel)
- `tests/test_helpers_4.gd` [unit]: `_hi_setup` (show_hint), `_hi_label` (hint_bubble), `_hi_key` (hint_bubble), `_hi_tip` (hint_bubble), `_hi_problems` (hint_bubble), `_hi_covers` (hint_bubble), `_hi_walk` (hint_crank)
- `tests/test_helpers_5.gd` [unit]: `_tl_place_problems` (CentrifugeLabel, HintLabel, hint_bubble, hint_crank, hint_uncap)
- `tests/test_hint.gd` [unit]: `t_hint_shop_only_plant_above_sheet_ends_on_patch` (hint_bubble), `t_hint_leaving_shows_step_that_fits_twice` (hint_crank, hint_uncap)
- `tests/test_shop.gd` [unit]: `t_shop_no_row_overlaps_other_controls` (HintLabel), `t_shop_seven_rows_on_screen_no_scroll` (HintLabel)
- `tests/test_shop_zoom.gd` [unit]: `_zs_clear` (HintLabel)
- `tests/test_ui_placement.gd` [unit]: `_hud_rects` (HintLabel), `_measure_label` (CentrifugeLabel), `_back_hint_rects` (HintLabel)
- `tests/test_zoom.gd` [unit]: `t_zoom_ui_and_camera` (CentrifugeLabel, HintLabel, farm_ui)
- `tests/test_zoom2.gd` [unit]: `t_resume_pending_pile_loads_while_zoom_open` (HintLabel)

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
8. **No hint said twice** (designer, 2026-11-24: "there's redundant hint messages now, keep the bubble hint versions"). Two instructions repeat a hint bubble line (0.3.1 item 4). The zoom's `HintLabel` (`harvest_ui.gd`) shows `zoom_uncap_hint` ("Drag across the cells to uncap them") while the bubble shows `hint_uncap`. `CentrifugeLabel` (`farm_ui.gd` `HINT_TEXT`, English only) adds "Tap or hold to spin" under the jar count before the first crank turn while the bubble shows `hint_crank`. Both repeats go. Today `HintLabel` shows `zoom_uncap_hint` from the zoom's start; after this change it is hidden while cells are left to uncap and shows only `zoom_all_uncapped` ("All cells uncapped!") once none is left (designer: keep it), with Back as today. `CentrifugeLabel` shows only the jar count. `HINT_TEXT` and the `zoom_uncap_hint` row go. The bubble's lines don't change. With `show_hint` off these steps have no instruction (designer: keep the bubble versions).

Reply in at most 150 words: files changed, node names used, open questions.