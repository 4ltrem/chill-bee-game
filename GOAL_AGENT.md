---
author: orchestrator
type: write-up
status: draft
milestone: M3 (Assignment 5)
description: The goal-oriented coding agent (goal_agent.py): how it finds what the 0.1.4 spec asks for that the game lacks, why it built each feature in the order it did, and the manual changes made before accepting the code
---
# The goal-oriented coding agent (Assignment 5)

**The assignment:** "build a goal-oriented coding agent that reads a Game Design Document (GDD), scans your existing codebase, and automatically generates missing features. [...] your primary objective is to build and understand the reasoning layer—how the agent decides what to build and in what order."

**The agent:** [`_tools/goal_agent.py`](_tools/goal_agent.py), tests in [`_tools/test_goal_agent.py`](_tools/test_goal_agent.py), plan in [game/specs/m3-goal-agent.md](game/specs/m3-goal-agent.md). Its demo run built **0.1.4** from [game/specs/0.1.4-ui-placement.md](game/specs/0.1.4-ui-placement.md), the designer's play-test fixes to the UI. The run's record is the blackboard [game/reports/goal/0.1.4/blackboard.md](game/reports/goal/0.1.4/blackboard.md).

## How it decides: the reasoning layer is code

The GDD reaches the game through approved specs (one per build). The agent reads a spec, not the whole GDD. Everything up to "what to build next" is plain Python that spends no tokens, so the order can be read and tested.

```
   game/specs/<spec>.md ──► parse_spec() ──► goals: H (node handoff), C1..Cn (changes), T<item>.<k> (Quinn's test lines)
                                                │
   game/ ──► scan() ── config keys, scene nodes, tests by group comment, last unit.log, handoff, ledger
                                                │
                                gaps() ──► done | partial | missing, with the evidence
                                                │
                       priority_score() ──► ready × (3·unblocks + 2·value − 1·cost)
                                                │
               top goal ──► agents (fresh `claude -p`, spec slice only) ──► checks ──► fix rounds ≤ 2
                                                │                                        │
                                   checkpoint commit + ledger ◄──── green ───────────────┘
                                                │
                                            re-scan (loop)
```

1. **Goals** (`parse_spec()`). Each numbered Change of the spec is a goal (C1–C7 for 0.1.4), and so is each line of Quinn's test contract (T1.1 is item 1's first line). Patricia's line "She writes any node-name changes first, as a handoff" adds a handoff goal H. Dependencies follow the project's build process (`game/CONTEXT.md`, Process 5): a change with scene work waits on the handoff, and a test line waits on the change it tests. A test line names its item, or is matched to the change it shares the most words with. The mutations line covers every change.
2. **Gap detection** (`scan()`, `gaps()`). For each goal, the agent looks for evidence in the game:
   - the config keys the spec names (`@export var` in `game_config.gd`);
   - the node names it names, in the scenes (or their absence, when the spec removes one);
   - the tests registered in `tests/run_tests.gd` under a group comment naming the spec, and their PASS or FAIL in the newest `unit.log`;
   - the handoff file, and the ledger of goals this agent built to green.

   A goal is **done** when its tests are green and its evidence is present. It is **partial** when some evidence is there, and **missing** when none is. Run on the specs already built, it marks 0.1.2's 8 goals and 0.1.3's 14 goals done. On 0.1.4 it found all 17 missing.
3. **Scoring** (`priority_score()`): a weighted sum, with every weight in one table at the top of the file.
   - **unblocks**: how many unfinished goals wait on this one. This is what puts the node contract first.
   - **value**: 3 for a play-test fix, 2 for a designer feature, 1 for housekeeping.
   - **cost**: the owners' average 5-hour plan usage per run, from `_meta/agent-runs.csv`. Lower is better.
   - **ready**: 0 while a dependency is missing.

   Each score is written to the blackboard with its factors: in full at the first pass, then only the rows that changed. The board follows the format all three loops share (`_templates/blackboard.md`), and `--plan` and `--dry-run` leave it untouched.
4. **Ambiguity** (Process 1: "if the spec is ambiguous, stop and list the questions"). A goal whose text holds a TBD, or that an open question in the node handoff points to, is not scored. The rest are built, and then the run stops with the question.
5. **The code-writing step.** Only this step calls agents:
   - Patricia (scripts) and Bob (scenes) run in parallel for a change, Quinn for test lines (one call per item). Each is a fresh headless `claude -p` given only its spec slice.
   - Then come the checks: `contract_check.py`, the Godot unit and start suites (`godot_run.py`), `ui_shots.py` after scene work, and `mutate.py --since` after new tests.
   - Failures go back to the folder's owner, for at most 2 fix rounds. When an older test fails after a change, Quinn is asked too, because the spec may have replaced what that test pins.
   - A green step writes the ledger and makes a checkpoint commit on `milestone/0.1.4`, never on `main` and never pushed.
   - Before every agent call, `budget_guard.decide()` runs. The hook only sees the Agent tool, so the agent calls it itself, and a denial pauses the run.
6. **The iteration loop.** Re-scan, re-score and build the top goal. It stops when nothing is left, when only ambiguous or blocked goals remain, after 2 failed fix rounds, or when the budget guard pauses it.

The tests (`python -I _tools/test_goal_agent.py`, 17 cases) pin all of this on a fixture game with one done, one partial and one missing change. They cover the order (handoff before scenes, scenes before their tests), the fix rounds, the budget pause and ambiguity. The loop runs with fake agents and fake commands.

## What it built, and why

_The first run is rows 1–8 (it stopped at 15:09). The second run (20:24–21:40) is rows 9–14. It was started after the designer play-tested the build, answered the C5 question (Design Votes round 9) and added items 9 and 10, and it paused at C5's fix round. Still to build: C5's fix round and Quinn's ten test lines._

| # | Goal | Why it came next (score) | Agents | Outcome | Checkpoint |
|---|---|---|---|---|---|
| 1 | H Node handoff | 5 goals wait on it (16.17) | Patricia | handoff written; it raised the C5 frame-size question | `c31bbb8` |
| 2 | C2 Buttons anchored to props | top play-test fix, 3 goals wait on it (13.85) | Patricia, Bob; Quinn in both fix rounds | 11 failures went down to 1 over 2 fix rounds, then the run stopped. Accepted by hand (see below) | `90e03c6` |
| 3 | C4 Speed tag clear of top info | cheapest play-test fix, Bob only (11.63) | Bob | green first try | `fb94e04` |
| 4 | C7 Pile loads on its own | play-test fix (11.27) | Patricia | **no code change**: she found no path where the pile needs Spin and asked what the designer saw. The checks were already green, so the step committed | `90b18b9` |
| 5 | C3 Back in one fixed place | play-test fix (10.9) | Patricia, Bob; Quinn in fix round 1 | Back's new corner overlapped the hive at the second stop. Bob and Patricia asked for a decision; Quinn exempted Back from the test | `747a5a1` |
| 6 | C1 Harvest button is the honey meter | designer feature (8.9) | Patricia, Bob; Quinn in fix round 1 | 12 tests still named the removed `FillLabel`. Quinn updated them, quoting the spec | `b431c26` |
| 7 | C6 Housekeeping (test recordings out of `user://recordings`) | housekeeping, the last change ready (7.27) | Patricia | green first try | `287bdd0` |
| 8 | T2.1 + T2.2 Quinn's item 2 tests (one call for both) | the first test lines, now that C2 was built (5.38) | Quinn; Bob and Patricia in 2 fix rounds | 5 new tests. The overlap test found 2 real bugs: the count label sat 12 px over Harvest, and Back sat over the instruction text, which the designer had reported the same hour. Tests green after 2 rounds (138/138), but one of the 5 mutations was missed, so the run stopped. Accepted by hand (see below) | `b65f5e1`, `2c464bc` |
| - | C5 Bigger frames (first run) | not scored: ambiguous | - | held for the designer: 2.15× frames don't fit the hive body (1.35× with 5 columns, or a wider body) | - |
| 9 | C1 rebuild: the meter fill clipped to the button | play-test fix; the orchestrator cleared C1's ledger row so it would be redone | Bob, Patricia | Bob changed nothing, since the scene already matched. Patricia's `farm_ui.gd` clips the fill inside the button's border. Green (150/150), but nobody looked at the fill in a shot | `a32b0be` |
| 10 | C8 Instruction text below Back | designer feature from the first run (item 8) | Bob | `HintLabel` moved 138 px down, 8 px below Back. Not rendered | `485190a` |
| 11 | C7 rebuild: spin mode stays on while the pile reloads | play-test fix, with the designer's answer in the spec | Patricia; Patricia and Quinn in fix round 1 | One test still expected the old "tap Spin again". Quinn updated it to the new spec. The "no pile, so spin exits" branch has no test yet | `f6f153a` |
| 12 | C9 "Production paused" above the upgrades | new play-test item 9, Bob only | Bob | `PausedLabel` moved out of the top info, above the shop. Not rendered | `1169483` |
| 13 | C10 Combs shown in the hive | new play-test item 10 | Bob, Patricia | Bob lowered the hive's front wall. Patricia shows the comb cells before a frame rises (hidden since 0.1). Green (150/150) | `2d2ffb4` |
| 14 | C5 Bigger frames (round 9 variant a: 5×2) | unheld by the designer's answer; 1 test line waits on it (6.03) | Bob, Patricia | Bigger frames and smaller hexes, and the pile and bucket cells now match the frame cells. 7 unit tests still assume 7×5 (cell 17, 35 cells per frame). **Paused** by the budget guard before fix round 1 (5-hour usage 74%) | - |

What the order shows:
- **The handoff went first** because every scene change waited on it (unblocks).
- **Play-test fixes came before designer features** (value 3 vs 2).
- **Among equal-value goals, the cheaper ones went first.** C4 (Bob only) beat C7 and C3.
- **Changes before their tests.** No test line was ready until its change was built (ready = 0), so the test goals came last.
- **C5 was held, not guessed.** The question in the node handoff kept it out of the scoring, and the rest was built around it.
- **In the second run, the cheap changes went before C5.** C1, C8, C7, C9 and C10 cost 1.1M tokens together. C5 alone cost 1.4M before its fix round. With the question answered, C5 was scored like any other goal.
- **The budget guard paused the run twice.** The first pause came at the start (weekly usage ahead of pace) and the designer allowed 60 minutes. The second came before C5's fix round (5-hour usage). Each time the run stopped cleanly and can resume.

## Manual changes before accepting the code

1. **C2, test relaxed by the orchestrator** (`--accept C2 --note`, checkpoint `90e03c6`). After 2 fix rounds, one test still failed: `_open_zoom` expected Harvest exactly at its anchor. A probe showed that Spin's anchor meets Harvest's on the way back from the second stop, so Harvest is nudged 86 px up. Spec item 2 allows that ("nudged clear"), so the check now accepts a nudged button. Full checks were then green (133/133, contract, ui_shots). Whether the designer likes the nudge goes to Design Votes.
2. **T2.1 and T2.2, accepted by the orchestrator** (`--accept`, checkpoints `b65f5e1`, `2c464bc`). The orchestrator also regenerated `tests/fixtures/recording_fill_and_back.json` with `make_recording_fixture.gd`. The recorded play-test tapped Harvest where 0.1.3 had it (450, 321), so both real-time replay tests failed at ×1; they pass again. Still open: the mutation "buttons are not nudged clear of each other" is missed, so Quinn's nudge test proves too little. The agent sent both fix rounds to Bob and Patricia when the failure was in Quinn's folder. **Fixed after this run:** a failure that is only a missed mutation now goes to Quinn.
3. **Spec item 8 added by the designer mid-run** (`c7261e7`, 14:02): "back button overlaps instruction text at top". The instruction text moves below Back.
4. **To review, accepted by the loop rather than by hand:**
   - **C3:** Quinn exempted `BackButton` from the second-stop hive-overlap test, although Bob and Patricia both said the designer should decide. Design Votes asks: accept the overlap, move Back lower or make it smaller, or reframe the second stop.
   - **C8:** Bob already narrowed `HintLabel` in T2's fix round, so C8 may need no further change; its test T8.1 will tell.
   - **Two gap-detection fixes after the designer's item 8:** a node that already exists (`HintLabel`) made C8 look built, so now only the ledger marks a change built. A test line whose words tie between changes now covers only the tied changes, not all of them.
   - **C7:** committed with no code change, and Patricia's two questions are unanswered. "Green with nothing changed" counted as built. **Fixed after this run:** the agent now compares the game folders before and after a step. If nothing changed, it holds the goal like an open question instead of committing it, builds the rest, and then waits. The hold lifts when the spec item is edited, or with `--accept` (tests: `test_green_with_no_change_is_held_not_committed`, `test_a_held_goal_waits_until_its_spec_text_changes`).
5. **Second run, before starting:** the orchestrator removed C1 and C7 from `ledger.json` so the play-test rebuilds would run. It also marked the node handoff's two C5 questions answered (round 9 variant a) and fixed four unit tests and the play suite for the Round 8 offsets (`578b761`).
6. **Second run, to review:** Bob never saw his scenes. The render command starts with environment variables (`SCENE=… OUT=…`), and the permission check blocked it in C10 and in C5. C1, C8, C9, C10 and C5 are all checked by tests and the contract only, with no shot. Quinn's test lines and `ui_shots.py` have to cover that.

## Cost

_The whole run so far, from the blackboard and `_meta/agent-runs.csv` (table "Goal agent")._

| Goal | Agent calls | Tokens | Agent time |
|---|---|---|---|
| H | 1 | 221,991 | 42 s |
| C2 | 8 (2 fix rounds) | 2,855,348 | 57 min |
| C4 | 1 | 100,407 | 18 s |
| C7 | 1 | 491,165 | 20 min |
| C3 | 5 (1 fix round) | 465,514 | 106 s |
| C1 | 5 (1 fix round) | 753,666 | 9 min |
| C6 | 1 | 154,687 | 9.5 min |
| T2.1 + T2.2 | 5 (2 fix rounds) | 1,067,430 | 33.5 min |
| *First run* | *27* | *6,110,208* | |
| C1 rebuild | 2 | 292,042 | 44 s |
| C8 | 1 | 58,280 | 13 s |
| C7 rebuild | 3 (1 fix round) | 352,293 | 78 s |
| C9 | 1 | 92,562 | 14 s |
| C10 | 2 | 272,799 | 41 s |
| C5 (paused before its fix round) | 2 | 1,387,781 | 13 min |
| **Total** | **38** | **8,565,965** | |

The reasoning layer (scan, gaps, scores) costs no tokens; every token above is an agent writing or fixing code. In the first run, C2 alone is 47% of the tokens. Most of it is Quinn's first fix round (928k) and Patricia's first build (533k), spent untangling tests that pinned the 0.1.3 layout. In the second run, C5 is 57% of the tokens (1.39M of 2.46M): Bob and Patricia each took around 40 turns rescaling the hive, the pile and the bucket. Plan-usage % per call is in `_meta/agent-runs.csv`.
