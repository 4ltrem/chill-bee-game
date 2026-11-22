Goal agent run `0.3`, fix round 2 for goal C3 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. You alone work this round: Patricia put the fault in tests/. Check each failing test against the spec text: if it expects what the spec does not say (a wrong expectation, or state left over from an earlier run in the same scene), fix the test and quote the spec line beside it; if the game breaks the spec, change nothing and say which file and line: the next round goes to the code owners. Where the spec does not say what the game should do, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
    SCRIPT ERROR: Parse Error: Could not find type "PatchSlots" in the current scope.
    ERROR: Failed to load script "res://scripts/flower_patch.gd" with error "Parse error".
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
    SCRIPT ERROR: Invalid get index 'refresh_patches' (on base: 'Nil').
FAIL    start     2 errors  (godot exit 1 (1 is normal here), 2 noise lines dropped)  game/reports/_runs/20261122-145227/start.log
    SCRIPT ERROR: Parse Error: Could not find type "PatchSlots" in the current scope.
    ERROR: Failed to load script "res://scripts/flower_patch.gd" with error "Parse error".

Patricia (last round):
`PatchSlots` is declared in `game/scripts/patch_slots.gd` line 6 (`class_name PatchSlots`), and the code is correct. I changed nothing.

The failure looks like a stale global class cache. The new `class_name` isn't registered, so `flower_patch.gd` line 16 can't resolve `PatchSlots`. The `refresh_patches` errors follow from that, because the script never loads.

The fix is to regenerate the cache with `python -I _tools/godot_run.py unit start --refresh`. A hook blocked me from running it, because that script has to go through Rex. The goal agent or Rex should run it.

If the parse error persists after the refresh, the cause is something else. In that case, `diag needed`: the first error lines from the refreshed `start.log`.

Spec text:
3. **Plant wildflower patch.** A new Shop row in its own Tree C group under the Tree A/B rows: "Plant wildflower patch", level "n / 6", cost `patch_base_cost × patch_cost_growth^planted` ($40 × 1.25^n, floored; $449 for all six), available from the start (no gate). A purchase shows the next of `patch_slots` (6) hidden patches placed in `main.tscn` (instances of `scenes/props/flower_patch.tscn`), with a grow-in (scale 0 → 1, the existing pop tween family), adds it to group `flower_patch` so the bees forage on it, adds `habitat_health_per_patch` (15) to Health, and shows the toast `toast_patch_planted`. At 6 / 6 the row shows "Thriving" in place of a price. Patches raise habitat only: no honey effect. The slots sit clear of both camera stops' framing and of the truck's path. With `shop_layout = 0` (compact panel) the row is the panel's eighth row and all eight rows still show at 720 × 1280 without scrolling (0.2 item 14).

Reply in at most 150 words.