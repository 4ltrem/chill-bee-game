Goal agent run `0.3.2`, fix round 1 for goal C6 of `game/specs/0.3.2-tests-and-quick-buy.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scenes/ and materials/

You alone work this round. If the cause is in Patricia (scripts/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. STYLE_GUIDE minimums are approved values, not votes: raise a touch target below 120 px to 120 and a font below 28 px to 28 without asking, and say so in your reply. Where a panel sits, how it opens and what fits on screen come from the designer's Claude Design canvas: read `UI_DESIGN.md` and the matching board in `proposals/design/ui-screens-mockup/project/` for the look and placement of what the spec item asks for. Build only what the spec asks (a board part it does not name, like tabs, waits for a later revision); where the spec text differs, the spec wins. Before writing any `(designer)` row, look for the answer in `UI_DESIGN.md`, the canvas boards, `README.md` (Outstanding TBDs), `proposals/design/ui-screens.md` and `_meta/sessions/*/decisions.md`: if one answers it, apply that answer and cite the file. If the topic is already a listed TBD, build the placeholder, name the TBD and go on; it is not a question. Ask only when none of them covers it. This spec's visuals are placeholders (front matter `visuals: placeholder`): you may set a size, offset, font size or margin when a failing row needs it. Keep it close to the canvas board, change only the numbers the row needs, and list each as `placeholder: <file>: <old> -> <new>`; the designer confirms them at play-test. A `pick match` row means the live prop must match the designer's picked variant: open both shots and the variant's .tscn, and rebuild what differs. A style row whose Fix ends `(designer)` is not yours: leave it and list it in your reply.

style:
Style board `game/reports/style/0.3.2-goal-c6/run-1/blackboard.md`, Result:

Still FAIL after round 1 (max rounds 1 or the token cap). Open rows:

| # | Rule | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | V12 | `scenes/main.tscn:766` | Button `QuickBuyButton` font size 28 px < 32 | set `theme_override_font_sizes/font_size = 32` or more |

The game was not changed, and the sandbox has no changes to propose.

Transcripts: `_meta/sessions/runs/2026-11-24-style-0.3.2-goal-c6-run-1/`

|---|---|---|---|---|

(7 older row(s) about files this step did not change were left out: not yours this round, change nothing for them.)

Spec text:
6. **Bottom slot A: quick-buy, with a Dev switch** (`ui-screens.md` §3 option A; designer 2026-11-23: "A only, B-D later"). Config `bottom_slot` (int, default 1): 0 = nothing at the bottom (today), 1 = A; 2–4 stay free for B–D. With `shop_layout = 1` and `bottom_slot = 1`, a `QuickBuy` bar under `FarmUI` sits at the bottom of the farm view, left of the `ShopButton`: the next upgrade's name, its price and a Buy button (`QuickBuyButton`, at least 120 px tall, V11; 28 px text, V12). The next upgrade is the Shop row (the eight, in Shop order) that is unlocked, not at its max and has the lowest price; a tie goes to the earlier row. The name, price and Buy text are the Shop row's own (the same `tr()` keys and the French price order, no new key). Buy runs the Shop's own purchase code (money, level, effects, toasts, the patch's Health and thriving), and the bar then shows the next upgrade. The bar shows only on the uncovered farm view, so a toast its purchase queues (`toast_patch_planted`, `toast_bumble_visitor`) shows at once through the 0.3.1 queue. Buy is greyed when you can't afford it. When no row is left, the bar hides. It shows on the farm view only: hidden in both zooms, while `any_panel_open()` (0.3.1 item 7), under the welcome and victory overlays. It clears the `ShopButton`, the `JournalButton`, the Sell anchor, the hive count, the toasts' place and the hint bubble. A patch planted from the bar ends the hint as one planted from the Shop. With `shop_layout = 0` the compact panel stays and the bar never shows. Dev button "Bottom slot" switches between 0 and 1 and shows the current value. Size and position are placeholders the designer confirms at play-test.

Reply in at most 150 words.