Goal agent run `0.3.2`, spec `game/specs/0.3.2-tests-and-quick-buy.md`, goal C1. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (Patricia). These existing tests read names it touches:
- `tests/play_loop.gd` [play]: `_run` (SellIcon)
- `tests/test_base.gd` [unit]: `_mk_main` (show_hint)
- `tests/test_economy.gd` [unit]: `t_node_contract` (SellIcon)
- `tests/test_habitat.gd` [unit]: `t_habitat_pill_order_plus_opens_shop_twice` (SellIcon)
- `tests/test_helpers_4.gd` [unit]: `_hi_setup` (show_hint), `_hi_walk` (SellIcon, _hi_walk)
- `tests/test_hint.gd` [unit]: `t_hint_steps_follow_state_in_order_twice` (_hi_walk, t_hint_steps_follow_state_in_order_twice)
- `tests/test_icons.gd` [unit]: `t_icon_touch_area_in_scene` (SellIcon)
- `tests/test_second_stop.gd` [unit]: `t_icons_never_overlap` (SellIcon)
- `tests/test_truck.gd` [unit]: `t_summary_after_sell` (SellIcon)
- `tests/test_ui_placement.gd` [unit]: `_hud_rects` (SellIcon), `t_hud_no_overlap_no_cutoff` (SellIcon), `t_spin_placed_by_scene` (SellIcon)
- `tests/test_welcome.gd` [unit]: `_wl_idle_world` (SellIcon)
- `tests/test_zoom.gd` [unit]: `t_zoom_ui_and_camera` (SellIcon), `t_zoom_bucket_lid_pile_flow` (SellIcon)
- `tests/test_zoom2.gd` [unit]: `t_fork_shows_while_cranking_and_state_table` (SellIcon), `t_focus_styles` (SellIcon)

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
1. **The hint walk test hangs.** `t_hint_steps_follow_state_in_order_twice` (0.3.1 item 4) hangs after the crank: its `_until` for `SellIcon` never returns (WALK markers in `test_helpers_4.gd` `_hi_walk`), and it is set aside in `run_tests.gd`. Find why the test clock stops after bottling: if the game is at fault (bottling or the truck never finishing with `show_hint = true`), it is a bug for Patricia; if the helper is at fault, Quinn fixes the helper. The test goes back in the suite, green, without a longer timeout as the fix.

Reply in at most 150 words: files changed, node names used, open questions.