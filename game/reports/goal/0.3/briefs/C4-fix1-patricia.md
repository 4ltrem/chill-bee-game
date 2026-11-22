Goal agent run `0.3`, fix round 1 for goal C4 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. tests:
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