---
author: orchestrator
type: spec
status: draft
decided:
milestone: M3 (Assignment 5, due 2026-11-15, target 2026-11-14)
description: The goal-oriented coding agent: finds what the specs ask for that the game lacks, scores and orders it, and runs the game/CONTEXT.md build process step by step with fresh agent contexts, its reasoning on a blackboard
---
# M3: Goal-oriented coding agent (Assignment 5)

**The assignment** (MILESTONES.md, M3): a goal-oriented coding agent that "reads the GDD and the specs, scans `game/`, lists the missing features, scores them (value, dependencies, cost), picks an order, and runs the build process of `game/CONTEXT.md` (steps, contract check, parallel start, visual checks, snapshot tests, checkpoint commits) with fresh agent contexts, its reasoning on a blackboard." The course's own wording still needs pasting in (open question 1).

**Shape** (same pattern as M2): scripts for the deterministic parts, one new agent for the judgement, and the existing crew for the work. Rule from `game/CONTEXT.md` Process 8: scripts before tokens.

## What gets built

1. **`_tools/goal_scan.py` (script, no tokens): what's missing.**
   - Reads the approved specs in `game/specs/`. Each numbered Change and each Quinn contract line becomes a goal.
   - For each goal, it checks the game for evidence that it's done: config keys in `scripts/default_config.tres`, node names in the scenes (as `contract_check.py` finds them), test names registered in `tests/run_tests.gd`, and the last `godot_run.py` summary.
   - Writes `game/reports/goal/<run>/gaps.json`. Each goal gets a status of done, partial or missing, plus the evidence for it.
   - Its fixtures cover one done, one partial and one missing goal, tested like `test_generate.py`.

2. **A new agent, the planner (hired by Martin; Sonnet), to score and order.**
   - Reads `gaps.json`, the spec sections it names, and the cost averages from `_meta/agent-runs.md`.
   - Scores each missing goal: value (the spec's priority or the designer's word), dependencies (node contract, config, the order of the GDD flow), cost (owner, lines, past runs of the same kind), and risk.
   - Groups the goals into green-and-playable steps (Process 4) and orders them. The plan goes on the blackboard: scores, order and why, and the questions it can't answer. An ambiguous spec stops the run (Process 1).

3. **`_tools/goal_run.py` (script): the build loop.**
   For each step, it:
   - creates or reuses the worktree and branch;
   - briefs Patricia's handoff (Process 5), then Patricia and Bob in parallel, and Quinn from the spec. Each runs as a fresh headless `claude -p` with only its spec slice, as `generate.py` does;
   - runs `contract_check.py`, then the style loop or `ui_shots.py` for visual checks, then `godot_run.py`, the snapshot suite and `mutate.py --since`;
   - sends failures to the folder's owner (Process 9) with at most 2 fix rounds before it stops for the designer;
   - makes a checkpoint commit when the step is green.
   Every call is logged by the run log hooks. `budget_guard.py` is honoured, and a blocked agent pauses the loop, never skips it.

4. **The blackboard: `game/reports/goal/<run>/blackboard.md`.**
   - It records the goal, the gap list, scores and order, each step's briefs (by reference), results and fix rounds, and the designer stops.
   - It is the A5 write-up's evidence, like `STYLE_LOOP.md` for A6.

5. **Demo run.** The agent builds **0.1.4** (`game/specs/0.1.4-ui-placement.md`) once that spec is approved, so the next real build is the demo (open question 2). Before/after shots go on Design Votes via `ui_shots.py`.

6. **Write-up: `GOAL_LOOP.md`.** It covers how the loop works, the demo run, what it got right and wrong, and its cost from `agent-runs.csv`, for submission as a demo link (D: demo-link submissions).

## Order

1. `goal_scan.py` and its fixtures. It's cheap and needs no Godot.
2. Martin hires the planner. The orchestrator runs one planning pass on 0.1.4 and the designer reads the plan.
3. `goal_run.py`, run first with `--dry-run` (prints briefs and commands, spends nothing), then for real on step 1 only.
4. The full 0.1.4 run, then `GOAL_LOOP.md`.

## Done when

- `goal_scan.py` marks 0.1.3's changes as done and 0.1.4's as missing, with evidence for each.
- The planner's order for 0.1.4 respects the node contract (handoff before scenes) and gives a reason per step.
- `goal_run.py` builds at least one 0.1.4 step to green with a checkpoint commit and no hand edits by the orchestrator, or stops with a clear question when it can't.
- The blackboard and `GOAL_LOOP.md` show the whole run, including its cost.

## Open questions for the designer

1. **The course's A5 wording:** paste it in, so the spec matches what's graded.
2. **Demo target:** is 0.1.4 (UI placement) the demo, or should the agent wait for the M4 upgrades (0.2.x, Tree A and B, self-driving truck)? 0.1.4 is smaller and lands before 11/15. M4 is what MILESTONES.md says the agent builds; it would be the second run.
3. **Autonomy:** may the agent make checkpoint commits on its own (milestone branch only), or should it stop before each one?
4. **Planner model:** Sonnet (judgement, ~100–200k tokens a plan) or Haiku (cheaper, riskier ordering)?
