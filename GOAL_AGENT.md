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

   Each score is written to the blackboard with its factors.
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

RESULTS

## Manual changes before accepting the code

MANUAL

## Cost

COST
