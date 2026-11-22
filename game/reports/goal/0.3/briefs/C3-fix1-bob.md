Goal agent run `0.3`, fix round 1 for goal C3 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scenes/ and materials/

You alone work this round. If the cause is in Patricia (scripts/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. A `pick match` row means the live prop must match the designer's picked variant: open both shots and the variant's .tscn, and rebuild what differs. A style row whose Fix ends `(designer)` is not yours: leave it and list it in your reply.

style:
Style board `game/reports/style/0.3-goal-c3/run-1/blackboard.md`, Result:

Still FAIL after round 1 (max rounds 1 or the token cap). Open rows:

| # | Rule | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | V4 | `scenes/main.tscn:25` | `GradientTexture2D` `GradientTexture2D_wildflower` is not a primitive mesh | use BoxMesh, CylinderMesh, SphereMesh, PlaneMesh, PrismMesh or CapsuleMesh |
| 2 | V11 | `scenes/main.tscn:370` | Button `HabitatPlusButton` touch area width 64, height 64 px < 120 | raise `custom_minimum_size` to at least 120 in each dimension |
| 3 | V11 | `scenes/main.tscn:451` | Button `BuyButton` touch area height 64 px < 120 | raise `custom_minimum_size` to at least 120 in each dimension |
| 4 | V11 | `scenes/main.tscn:469` | Button `JournalButton` touch area height 64 px < 120 | raise `custom_minimum_size` to at least 120 in each dimension |
| 5 | V12 | `scenes/main.tscn:431` | Label `NameLabel` font size 24 px < 28 | set `theme_override_font_sizes/font_size = 28` or more |
| 6 | V12 | `scenes/main.tscn:438` | Label `LevelLabel` font size 24 px < 28 | set `theme_override_font_sizes/font_size = 28` or more |

The game was not changed, and the sandbox has no changes to propose.

Transcripts: `_meta/sessions/runs/2026-11-22-style-0.3-goal-c3-run-1/`

|---|---|---|---|---|

(6 older row(s) about files this step did not change were left out: not yours this round, change nothing for them.)

Spec text:
3. **Plant wildflower patch.** A new Shop row in its own Tree C group under the Tree A/B rows: "Plant wildflower patch", level "n / 6", cost `patch_base_cost × patch_cost_growth^planted` ($40 × 1.25^n, floored; $449 for all six), available from the start (no gate). A purchase shows the next of `patch_slots` (6) hidden patches placed in `main.tscn` (instances of `scenes/props/flower_patch.tscn`, children of a `PatchSlots` node using `patch_slots.gd`, planted in child order; a hidden slot is not in group `flower_patch` until planted, so at start the group still holds only the three decorative patches), with a grow-in (scale 0 → 1, the existing pop tween family), adds it to group `flower_patch` so the bees forage on it, adds `habitat_health_per_patch` (15) to Health, and shows the toast `toast_patch_planted`. At 6 / 6 the row shows "Thriving" in place of a price. Patches raise habitat only: no honey effect. The slots sit clear of both camera stops' framing and of the truck's path. With `shop_layout = 0` (compact panel) the row is the panel's eighth row and all eight rows still show at 720 × 1280 without scrolling (0.2 item 14). The open Shop (panel or sheet) may cover the Harvest, Sell and Spin icons (designer, 2026-11-22: "the shop screen can overlap any harvest, sell or spin icons as it takes most of the screen"), so the panel grows taller for the eighth row rather than shrinking rows or scrolling; this replaces 0.2 item 14's "still clears the HUD". Its rows must not overlap each other, and every row stays on screen.

Reply in at most 150 words.