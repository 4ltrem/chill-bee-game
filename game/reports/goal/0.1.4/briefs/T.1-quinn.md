Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal T.1, T.2, T8.1, T.3. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Write the tests for these contract lines, from the spec, not the code (Process 2): every expected number read from the config. Register them in `tests/run_tests.gd` under one group comment that starts `# 0.1.4 items 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 (written from game/specs/0.1.4-ui-placement.md before the code)` (the goal agent finds them by it). Add a mutation per new test to `tests/mutations.json`. Run only your tests: `CB_ONLY=<names> CB_TIME_SCALE=6 python -I _tools/godot_run.py unit`. A failing test is a finding: report it, never bend the test to the code.

Contract lines:
- T.1: Back has the same screen rect in the first zoom and at the second stop;
- T.2: Back's rect is in the top-right quadrant, and the speed tag is below the money and bees labels without touching them;
- T8.1: item 8: the instruction text's rect lies wholly below Back's rect and does not touch it, in the first zoom and at the second stop;
- T.3: mutations in `tests/mutations.json` prove the new tests.

Spec text:
3. **Back in one fixed place** (play-test: "the back button isn't consistent"). It is a screen-space button in the **top-right** corner in the first zoom and at the second stop, not found by a scan (designer, 2026-11-06: "top right to not interfear with the labels").

8. **Instruction text below Back** (designer's review of the 0.1.4 build, 2026-11-07: "back button overlaps instruction text at top, can fix by lowering instruction test below the back button").
   - The instruction text at the top of the zoom (`HintLabel`) moves down so it sits below Back's top-right rect, in the first zoom and at the second stop. Back stays where item 3 puts it.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).


Reply in at most 150 words: files changed, node names used, open questions.