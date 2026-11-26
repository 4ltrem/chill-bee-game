Goal agent run `0.3.2`, fix round 1 for goal C11 of `game/specs/0.3.2-tests-and-quick-buy.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. STYLE_GUIDE minimums are approved values, not votes: raise a touch target below 120 px to 120 and a font below 28 px to 28 without asking, and say so in your reply. Where a panel sits, how it opens and what fits on screen come from the designer's Claude Design canvas: read `UI_DESIGN.md` and the matching board in `proposals/design/ui-screens-mockup/project/` for the look and placement of what the spec item asks for. Build only what the spec asks (a board part it does not name, like tabs, waits for a later revision); where the spec text differs, the spec wins. Before writing any `(designer)` row, look for the answer in `UI_DESIGN.md`, the canvas boards, `README.md` (Outstanding TBDs), `proposals/design/ui-screens.md` and `_meta/sessions/*/decisions.md`: if one answers it, apply that answer and cite the file. If the topic is already a listed TBD, build the placeholder, name the TBD and go on; it is not a question. Ask only when none of them covers it. This spec's visuals are placeholders (front matter `visuals: placeholder`): you may set a size, offset, font size or margin when a failing row needs it. Keep it close to the canvas board, change only the numbers the row needs, and list each as `placeholder: <file>: <old> -> <new>`; the designer confirms them at play-test. tests:
FAIL    play      254 passed, 8 failed  (godot exit 1, 0 noise lines dropped)  game/reports/_runs/20261126-183443/play.log
    FAIL  round 1 batch 1: the reloaded bucket is CRANKING by itself (expected 3, got 2)
    FAIL  round 1 batch 1: no Spin prompt for the reloaded bucket
    FAIL  round 1 batch 2: the reloaded bucket is CRANKING by itself (expected 3, got 2)
    FAIL  round 1 batch 2: no Spin prompt for the reloaded bucket
    FAIL  round 2 batch 1: the reloaded bucket is CRANKING by itself (expected 3, got 2)
    FAIL  round 2 batch 1: no Spin prompt for the reloaded bucket
    FAIL  round 2 batch 2: the reloaded bucket is CRANKING by itself (expected 3, got 2)
    FAIL  round 2 batch 2: no Spin prompt for the reloaded bucket
FAIL    touch     2 passed, 2 failed  (godot exit 1, 0 noise lines dropped)  game/reports/_runs/20261126-183443/touch.log
    FAIL  6 touch taps spaced past the cap count exactly 6 turns (got 2)
    FAIL  touch hold of 2.00 s counts about 1 + T x rate = 11.0 turns (got 0)

Spec text:
11. **No spinning with the lid off** (designer, 2026-11-26, play-test: "you can spin the centrifuge when the lid is off and the liquid rises, makes no sense"). Today `close_lid()` (`centrifuge.gd`) sets `FULL` at once while the lid's visual is still lifting (after bottling with a pile) or still closing, and `begin_crank()`, `tap()` and a hold check only the state, so the crank turns, the barrel spins and the honey rises with the lid off. After this change cranking starts only once the lid's visual is fully on: before that a Spin tap, a crank tap or a hold counts no turn and the barrel and honey don't move; the turn after the lid lands counts as usual. Spin mode's own crank (`main.gd`, the reloaded bucket) waits for the lid the same way.

Reply in at most 150 words.