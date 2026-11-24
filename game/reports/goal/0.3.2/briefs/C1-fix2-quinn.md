Goal agent run `0.3.2`, fix round 2 for goal C1 of `game/specs/0.3.2-tests-and-quick-buy.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. You alone work this round: Patricia put the fault in tests/. Check each failing test against the spec text: if it expects what the spec does not say (a wrong expectation, or state left over from an earlier run in the same scene), fix the test and quote the spec line beside it; if the game breaks the spec, change nothing and say which file and line: the next round goes to the code owners. Where the spec does not say what the game should do, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
FAIL    unit      14 passed, 1 failed  (godot exit 1, 30 noise lines dropped)  game/reports/_runs/20261124-020852/unit.log
    FAIL  t_hint_steps_follow_state_in_order_twice  walk: first sale made but still at the second stop: no bubble (hint_shop is for the farm view) | diag: key=hint_shop money=30: expected  got hint_shop | walk: first sale made but still at the 

Patricia (last round):
The fix is in, but I haven't run any tests, as instructed, so it is unconfirmed.

**Cause (scripts/):** `Truck.sell()` credits the money at once. The truck only leaves (`departed`) after the jars still flying to its bed have landed. `hint.gd` set `_sold` on `departed`, so for a few frames after the money rose, the bubble still showed `hint_sell`. That is the test's failure at the second stop.

**Changes:**
- `scripts/truck.gd`: added `signal sold`, emitted in `sell()` once the money is credited.
- `scripts/hint.gd`: `_sold` is now set from `truck.sold` instead of `truck.departed`.

**Placeholders:** none. No touch targets or fonts changed.

**For Quinn:** re-run `t_hint_steps_follow_state_in_order_twice`. The `hint_shop` step now appears on the farm view as soon as the sale is made. It no longer waits for the truck to leave. If the walk still hangs on `SellIcon`, say `diag needed`: print `_flying_to_bed` and `_departure_pending` after the crank.

Spec text:
1. **The hint walk test hangs.** `t_hint_steps_follow_state_in_order_twice` (0.3.1 item 4) hangs after the crank: its `_until` for `SellIcon` never returns (WALK markers in `test_helpers_4.gd` `_hi_walk`), and it is set aside in `run_tests.gd`. Find why the test clock stops after bottling: if the game is at fault (bottling or the truck never finishing with `show_hint = true`), it is a bug for Patricia; if the helper is at fault, Quinn fixes the helper. The test goes back in the suite, green, without a longer timeout as the fix.

Reply in at most 150 words.