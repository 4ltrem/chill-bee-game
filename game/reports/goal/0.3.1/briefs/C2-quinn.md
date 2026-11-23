Goal agent run `0.3.1`, spec `game/specs/0.3.1-playtest-fixes.md`, goal C2. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (Patricia). These existing tests read names it touches:
- `tests/test_bottling.gd` [unit]: `t_no_continue_button` (farm_ui)
- `tests/test_camera.gd` [unit]: `t_camera_back_from_second_stop` (farm_ui)
- `tests/test_dev.gd` [unit]: `t_dev_no_panel_when_off` (dev_panel), `t_dev_panel_when_on` (dev_panel)
- `tests/test_habitat.gd` [unit]: `t_bumble_visitor_toast_journal_unlock_twice` (JournalPanel, ToastLabel, phase_toast, toast_bumble_visitor), `t_patch_plant_steps_group_health_twice` (PatchSlots), `t_skip_icon_reaches_thriving_free_twice` (PatchSlots, reaches_thriving, victory_delay_seconds), `t_skip_icon_farm_view_only` (PatchSlots)
- `tests/test_helpers_1.gd` [unit]: `_find_dev_panel` (dev_panel), `_mk_panel` (dev_panel)
- `tests/test_journal.gd` [unit]: `t_journal_panel_text_matches_csv_twice` (JournalPanel)
- `tests/test_phase.gd` [unit]: `t_phase2_auto_sell_sets_once_toast_once` (ToastLabel, phase_toast)
- `tests/test_victory.gd` [unit]: `t_victory_delay_show_close_once_per_farm` (victory_delay_seconds), `t_victory_waits_for_farm_view` (victory_delay_seconds)
- `tests/test_zoom.gd` [unit]: `t_zoom_ui_and_camera` (farm_ui)
- `tests/ui_bounds_pixels.gd` [ui]: `_run` (dev_panel)

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
2. **Toasts wait for the Shop to close; the patch toast shows.** The thriving toast `toast_bumble_visitor` showed under the full-height Shop sheet's dim (the last patch is bought inside the Shop) and hid after 4 s, before the Shop closed; `toast_patch_planted` never showed (`PatchSlots` emits `toast_requested` and nothing connects it). Toasts (`PhaseToast` / `ToastLabel`) now go through one queue in `farm_ui.gd`: while the Shop sheet or the `JournalPanel` is open, or a zoom is up, a toast waits; it shows on the farm view once they close, for `toast_seconds` (config, 4.0, replacing the `PHASE_TOAST_SECONDS` literal), one at a time in the order queued. `toast_patch_planted` joins the queue from `PatchSlots.toast_requested`. The planting that reaches thriving queues only `toast_bumble_visitor`, not both. The Phase 2 toast (0.2 item 7) uses the same queue. The victory (0.3 item 5) waits until the bumble toast has finished, then `victory_delay_seconds` as before. "Reset habitat" clears the queue and hides a showing toast.

Reply in at most 150 words: files changed, node names used, open questions.