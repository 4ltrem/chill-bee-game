Goal agent run `0.3.2`, fix round 2 for goal C11 of `game/specs/0.3.2-tests-and-quick-buy.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. You alone work this round: Patricia put the fault in tests/. Check each failing test against the spec text: if it expects what the spec does not say (a wrong expectation, or state left over from an earlier run in the same scene), fix the test and quote the spec line beside it; if the game breaks the spec, change nothing and say which file and line: the next round goes to the code owners. Where the spec does not say what the game should do, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
FAIL    unit      24 passed, 7 failed  (godot exit 1, 62 noise lines dropped)  game/reports/_runs/20261126-184107/unit.log
    FAIL  t_lid_close_and_signal  begin_crank -> CRANKING: expected 3 got 2  (327 ms)
    FAIL  t_leftover_adds_no_turns  batch 1 left a fractional carry (0.0000 jars) | batch 2 (8 cells, carry 0.000): ceil(jars of its cells x taps_per_jar) = 7 turns, the carry added none: expected 7 got 11 | turns_counted agrees: expected 7 got
    FAIL  t_bottling_35_single_cells_is_2_jars  35 single cells need ceil(2 x taps_per_jar) = 8 turns (float noise must not add one): expected 8 got 0 | 35 cells fed one by one bottle frame_jars (2) jars, not 1: expected [2] got []  (238 ms)
    FAIL  t_zoom_bucket_lid_pile_flow  round 1: reloaded, spin mode stays on (CRANKING): expected 3 got 2 | round 2: tapping Spin starts CRANKING: expected 3 got 2 | round 2: ceil(jars x 4) = 16 real clicks: expected 16 got 0 | round 2: DONE (s
    FAIL  t_fork_rules  precondition: CRANKING: expected 3 got 2 | precondition: DONE (state 2: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself) | precondition: BOTTLING: expected 5 got 2  (435 ms)
    FAIL  t_fork_shows_while_cranking_and_state_table  CRANKING: Spin hidden | after the extraction: Spin hidden (bottling starts by itself, no Continue) | BOTTLING: Spin hidden  (2254 ms)
    FAIL  t_gearing_turns_by_level  Gearing 0: real taps needed to finish the extraction: expected 16 got 0 | Gearing 1: real taps needed to finish the extraction: expected 14 got 0 | Gearing 2: real taps needed to finish the extraction: expect

Patricia (last round):
I changed nothing, and I haven't found the cause: `diag needed`.

The queue logic in `centrifuge.gd` reads correctly. `close_lid` sets `_lid_on_left` and `advance()` counts it down. `begin_crank` queues until `lid_is_on()`. `tap`, `set_holding` and `advance` all check `lid_is_on()`.

The symptoms look like the crank starting late. The reloaded bucket stays FULL (state 2). The touch test gets 2 of 6 turns and then 0 for the hold. I can't tell from the code whether that is a late start or the extraction ending early.

Please have Quinn print these in `touch_windowed.gd` `_mk()` (after `wait_lid_on`) and in the play-loop reload check:
- `lid_open`, `_lid_on_left`, `_crank_queued`, `state`, `lid_is_on()`.
- `_lid_motion.progress`, `LidMotion.total_seconds(config)`, `seconds_until_lid_open()`.
- `turns_counted` and `turns_needed()` after each tap.
- Whether the timer path in `close_lid` fired, meaning `opening > 0` at close.

No placeholders changed. No touch target or font changes.

Spec text:
11. **No spinning with the lid off** (designer, 2026-11-26, play-test: "you can spin the centrifuge when the lid is off and the liquid rises, makes no sense"). Today `close_lid()` (`centrifuge.gd`) sets `FULL` at once while the lid's visual is still lifting (after bottling with a pile) or still closing, and `begin_crank()`, `tap()` and a hold check only the state, so the crank turns, the barrel spins and the honey rises with the lid off. After this change cranking starts only once the lid's visual is fully on: before that a Spin tap, a crank tap or a hold counts no turn and the barrel and honey don't move; the turn after the lid lands counts as usual. Spin mode's own crank (`main.gd`, the reloaded bucket) waits for the lid the same way.

Reply in at most 150 words.