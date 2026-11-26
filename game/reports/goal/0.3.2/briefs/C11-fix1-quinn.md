Goal agent run `0.3.2`, fix round 1 for goal C11 of `game/specs/0.3.2-tests-and-quick-buy.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
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