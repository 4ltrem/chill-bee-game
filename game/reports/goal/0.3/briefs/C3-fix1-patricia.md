Goal agent run `0.3`, fix round 1 for goal C3 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. tests:
    FAIL  t_shop_rows_order_and_level_text  six rows: expected 7 got 8  (1017 ms)
    FAIL  t_shop_auto_sell_locked_until_delivery_1  seven rows expected, got 8  (806 ms)
    FAIL  t_shop_no_row_overlaps_other_controls  six rows: expected 7 got 8  (1172 ms)
    FAIL  t_shop_seven_rows_on_screen_no_scroll  all 7 rows are shown at once: expected 7 got 8 | row 'Worker Swarm Count' overlaps ForkIcon  (1286 ms)
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Parse Error: Could not find type "PatchSlots" in the current scope.
    ERROR: Failed to load script "res://scripts/flower_patch.gd" with error "Parse error".
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
FAIL    start     2 errors  (godot exit 1 (1 is normal here), 2 noise lines dropped)  game/reports/_runs/20261122-133635/start.log
    SCRIPT ERROR: Parse Error: Could not find type "PatchSlots" in the current scope.
    ERROR: Failed to load script "res://scripts/flower_patch.gd" with error "Parse error".

Spec text:
3. **Plant wildflower patch.** A new Shop row in its own Tree C group under the Tree A/B rows: "Plant wildflower patch", level "n / 6", cost `patch_base_cost × patch_cost_growth^planted` ($40 × 1.25^n, floored; $449 for all six), available from the start (no gate). A purchase shows the next of `patch_slots` (6) hidden patches placed in `main.tscn` (instances of `scenes/props/flower_patch.tscn`), with a grow-in (scale 0 → 1, the existing pop tween family), adds it to group `flower_patch` so the bees forage on it, adds `habitat_health_per_patch` (15) to Health, and shows the toast `toast_patch_planted`. At 6 / 6 the row shows "Thriving" in place of a price. Patches raise habitat only: no honey effect. The slots sit clear of both camera stops' framing and of the truck's path. With `shop_layout = 0` (compact panel) the row is the panel's eighth row and all eight rows still show at 720 × 1280 without scrolling (0.2 item 14).

Reply in at most 150 words.