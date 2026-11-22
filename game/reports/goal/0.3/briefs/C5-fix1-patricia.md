Goal agent run `0.3`, fix round 1 for goal C5 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. tests:
FAIL    unit      193 passed, 3 failed  (godot exit 1, 312 noise lines dropped)  game/reports/_runs/20261122-151408/unit.log
    FAIL  t_crank_pauses_on_back_and_resumes_on_spin  a real tap on Spin starts the crank at the second stop: expected 3 got 2  (4497 ms)
    FAIL  t_shop_buttons_disabled_unaffordable_maxed_locked  one row per upgrade: expected 7 got 8  (1087 ms)
    FAIL  t_shop_rows_order_and_level_text  six rows: expected 7 got 8  (1163 ms)

Spec text:
5. **Victory screen.** After `thriving`, the victory is queued: it shows the next time the player is on the farm view with no zoom, sheet or drag in progress, after `victory_delay_seconds` (4.0). It never interrupts a harvest. An overlay over the live farm, dimmed, with the new patches visible behind it: `victory_title`, `victory_body`, and one button, `victory_button` ("Keep playing"), which closes it. No summary, timer or record. It shows once per farm. After it, play continues unchanged (honey, upgrades, truck), the pill stays at 100 and the row stays maxed. Strings through `tr()` from the approved `content/course-ending-text.md` rows, exported to a translation CSV by script, not retyped.

Reply in at most 150 words.