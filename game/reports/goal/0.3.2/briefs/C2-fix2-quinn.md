Goal agent run `0.3.2`, fix round 2 for goal C2 of `game/specs/0.3.2-tests-and-quick-buy.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
FAIL    play      245 passed, 1 failed  (godot exit 1, 0 noise lines dropped)  game/reports/_runs/20261123-233650/play.log
    FAIL  round 1 batch 1: ceil(jars x taps_per_jar) = 12 turns in all (diag: sent=12 tc0=1 cells=15 state=5 turns_counted_now=12) (expected 12, got 13)

Spec text:
2. **Tests for what the 0.3.1 play-test found.** Each of the eleven rows below was fixed by hand on 2026-11-23 (commit named) and no test caught it. Each gets a test that fails on the code before the fix, and a mutation in `tests/mutations.json` that puts the old behaviour back and is CAUGHT by it. No game change is asked; a test that fails on today's code is a finding for Patricia or Bob.
   - Settings (`77f8c49`): `SettingsPanel` had no `ModalPanel` script, so the gear did nothing.
   - Coming soon (`77f8c49`): white text on the cream sheet.
   - Tab text (`77f8c49`): "Research" lost its "h" (equal-width tabs with `clip_text`).
   - Fork fill at full (`77f8c49`): the honey fill hid at full, leaving the white circle.
   - Smooth circles (`77f8c49`): StyleBoxFlat's 8 corner segments made the circles jagged.
   - Lid for the pile (`d42377f`, `77f8c49`): the close tween killed the open one.
   - Spin with a paused crank (`6131bfd`): Back mid-crank, uncap more, tap Spin did nothing.
   - Gear under sheets (`77f8c49`): the Shop sheet's Close sat on the Settings gear.
   - Gear placement (`37acad8`): the gear covered the Habitat pill and stayed over Back at the second stop.
   - Tools dim at the second stop (`47000ad`): already covered by `t_tools_second_stop_sheet_gearing_spigot_buy_blocks_exits_twice`; keep its mutation.
   - Spin size (`d42377f`, `064b241`): Spin drawn smaller or bigger by view; the glyph out of its circle.

Reply in at most 150 words.