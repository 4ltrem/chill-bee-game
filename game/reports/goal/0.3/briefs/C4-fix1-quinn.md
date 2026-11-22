Goal agent run `0.3`, fix round 1 for goal C4 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
FAIL    unit      43 passed, 3 failed  (godot exit 1, 74 noise lines dropped)  game/reports/_runs/20261122-150618/unit.log
    FAIL  t_shop_auto_sell_locked_until_delivery_1  seven rows expected, got 8  (996 ms)
    FAIL  t_shop_no_row_overlaps_other_controls  six rows: expected 7 got 8  (1136 ms)
    FAIL  t_shop_seven_rows_on_screen_no_scroll  all 7 rows are shown at once: expected 7 got 8  (1082 ms)
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').

Spec text:
4. **The bumble bee visitor.** On `thriving`, the toast `toast_bumble_visitor` shows and the Bee Journal (the 0.2 Bumble Bees entry, item 8) unlocks. Before thriving the Journal button is hidden; from thriving on it shows and opens the entry as in 0.2. No bee model.

Reply in at most 150 words.