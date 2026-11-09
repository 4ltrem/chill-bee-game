# GOAL_AGENT.md: edits from C6 onward (APPLIED: first run in c782135, second run 2026-11-07 evening; kept as history)

Drafted 2026-11-07 14:40 from the blackboard (Pass 10, Step C6; Pass 11, Step T2.1/T2.2 in progress). Each block below says
where it goes. The test-line rows still need filling once the run ends.

## 1. "What it built" status line

Replace `_As of 2026-11-07 14:13, the run is still going (C6, then Quinn's test lines). Rows after C1 are still to fill in._` with:

_As of 2026-11-07 14:40, the run is on Quinn's test lines (T2.1, T2.2 in fix round 1). Rows after C6 are still to fill in._

## 2. New table row, after C1 (before the C5 row)

| 7 | C6 Housekeeping from 0.1.3 | 2 goals wait on it (7.27): the test lines T6.1 and T.1 | Patricia | `InputRecorder` writes to a temp folder when Godot runs a script, so test runs stop filling `user://recordings`. Green first try, though she did not check the folder herself and left that to T6.1 | `287bdd0` |

Then the test lines, one row per step, as they finish:

| 8 | T2.1, T2.2 HUD overlap, buttons in margin | the highest-scored test lines (5.38 each, play-test fix); built together because they test the same item | Quinn; Bob and Patricia in fix round 1 | _fill in_: 5 tests, 4 green at first; `t_hud_no_overlap_no_cutoff` found "7/10" 12 px inside Harvest's touch rect. Bob traced it to `farm_ui.gd` and named it a spec call | _fill in_ |

## 3. "What the order shows": add a bullet

- **Once the changes were built, the test lines went in score order.** Play-test fixes (T2–T4, T7, 5.38) came before the designer feature (T1.1, 3.38), and that came before housekeeping (T6.1, 1.38). T5.1 and the mutations line T.1 stay blocked behind C5.

## 4. Manual changes, under "3. To review": add two bullets

- **C6:** Patricia reported that `godot_run.py unit start` printed PASS but exited 1, and she did not look into it. The agent's own `tests` check then passed, so the step committed. Whether that exit code means anything is still unchecked.
- **T2.1 (the hive count over Harvest):** the test caught a real overlap, the label inside the touch rect but above the drawn button. Bob and Patricia (fix round 1) passed it back as a spec call, because either the label moves or the test compares visible shapes. It goes to Design Votes row 4 with the C5, C2 and C3 questions.

## 5. Cost

Replace `_To C1, from the blackboard. C6 and the test lines are still running._` with `_To C6, from the blackboard. The test lines are still running._`, and add, before the total:

| C6 | 1 | 154,687 | 9.5 min |

New total: **22** calls, **5,042,778** tokens.

The test-line rows so far, to finish once the step ends: T2.1/T2.2 has Quinn at 556,555 tokens and 142 s, Bob in fix round 1 at 92,164 tokens and 13 s, and Patricia's fix-round reply is still to come.

Update the sentence under the table: "C2 alone is 57% of the tokens" (2,855,348 / 5,042,778).
