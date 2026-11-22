Goal agent run `0.3`, spec `game/specs/0.3-course-build.md`, goal C4. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Patricia and Bob are building this change in parallel (Patricia). These existing tests read names it touches:
- `tests/test_journal.gd` [unit]: `t_journal_panel_text_matches_csv_twice` (journal_button)
- `tests/test_shop.gd` [unit]: `t_shop_no_row_overlaps_other_controls` (journal_button)

For each, compare what it expects with the spec text below. Update only a test whose expectation this change replaces (a flow step it now takes differently, a node it renames or removes, a value it changes), and quote the spec line in a comment beside it; most names on the list are only read, so leave those tests as they are. Change no expectation the spec does not change, and write no new tests (the contract lines do that). Do not run the tests: the goal agent runs them, with the windowed suites this list names, after the build. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

Spec text:
4. **The bumble bee visitor.** On `thriving`, the toast `toast_bumble_visitor` shows and the Bee Journal (the 0.2 Bumble Bees entry, item 8) unlocks. Before thriving the Journal button is hidden; from thriving on it shows and opens the entry as in 0.2. No bee model.

Reply in at most 150 words: files changed, node names used, open questions.