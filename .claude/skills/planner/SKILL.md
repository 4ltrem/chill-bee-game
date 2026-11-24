---
name: planner
description: Turn an agreed goal for Chill Bee Game's tooling (a `_tools/` script, a skill, an agent definition, a loop) into one plan file - goal and done, read-first list, tasks cut by file, checkpoints, how it runs, proof by breaking changes - for a fresh session to build. No code is written while planning. Use when the designer says "plan this", "make a plan", or runs /planner on tooling work. Not for game features - those are specs in game/specs/ built by goal_agent.py.
---

# Planner

Step two of: agree the goal → **plan** → clear the context → run the plan in a fresh session. Adapted from a third-party planner skill (designer, 2026-11-23: tooling work only; repo rules for running it).

**Scope.** Tooling only: `_tools/`, `.claude/skills/`, `.claude/agents/`, `_templates/`, hooks, loops. A game feature (anything in `game/`) is a spec in `game/specs/`, fact-checked by `spec_factcheck.py` and built by `goal_agent.py`; if the goal is a game feature, say so and stop.

**Output.** One file, `_meta/drafts/<version>/plan-<slug>.md` (the current version from the handoff; [[drafts-folder]] rule), with frontmatter `author: orchestrator`, `type: plan`, `status: draft`, `description:`, and these sections in order: **Goal and done**, **Read first**, **Tasks**, **Checkpoints**, **How to run it**, **Proof**, **Progress** (empty). Sections 4-6 are instructions for the session that runs the plan, so they are written into the plan itself. Write no code and change no other file while planning.

## 1. Start from the agreed goal

Write the goal as a user story ("As the designer, I want … so that …") with numbered acceptance criteria, each one checkable. Anything unclear goes to the designer in AskUserQuestion before planning ([[ask-with-quiz-tool]]); first look it up in the GDD, `_meta/learnings.md`, the decision logs and the handoff ([[look-up-before-asking]]).

## 2. Read before you write

Read the code, docs and patterns the change touches: `_tools/CONTEXT.md` (what each script does), `_meta/learnings.md` (what broke before and the check that now prevents it), the affected `CONTEXT.md` files. For each change, find what uses it and what depends on it (Grep the callers, the pre-commit gate in `.githooks/pre-commit`, the tests). Ask the designer when that can't be found.

**Read first** lists files with line numbers and why, exact doc sections, and the existing code to copy (file:line). A new session that has never seen the repo must be able to build from it.

## 3. Cut the work for subagents

Split tasks by file: no file is owned by two tasks in the same checkpoint. Each task gives the change, its file(s), the code to copy (file:line), the pitfalls (from learnings where one applies) and the one command that proves it. Mark which tasks run in parallel; say why any task must wait. Maximise parallel work.

Pick the cheapest owner that fits ([[model-routing]], [[cost-rules]]): a general-purpose subagent for script work, the roster agent when the file is its own (Martin for agent definitions). Briefs are sliced: only that task's rows.

## 4. Set the checkpoints

Group tasks into checkpoints that each work on their own, each with a named check (a command and its expected result). Built one at a time: run the check, commit, write the result and evidence into **Progress**, then the next. A single-step change needs no checkpoints.

## 5. Write how it runs (goes into the plan)

- The lead (main session) reads the whole plan and writes no code.
- At each checkpoint, launch every parallel task as a subagent in one message. Each brief names its task, its files only, the quality bar ([[edit-lines-only]]: change only the needed lines), a reply of at most 150 words with the files changed and the command result, and forbids git.
- Only the lead runs the check, commits and updates **Progress**. Commits go on `main` ([[one-folder-rule]]), through the pre-commit gate, never `--no-verify`; stage by path or glob.
- Godot test, build, mutation and shot runs go to Rex ([[rex-runs-scripts]]) with `--time-scale 6` ([[test-speed-fixes]]); tooling tests (`test_goal_agent.py`, `test_generate.py`, `links.py`, `consistency.py`) the lead runs by path with `python -I`, never inline Python ([[no-inline-python]]).
- Anything unplanned is written into the plan before anyone builds it. Something that broke gets an L-number in `_meta/learnings.md`.
- If the context is half full after a checkpoint, write the next checkpoint into **Progress** and stop for a fresh session.

## 6. Define the proof (goes into the plan)

- For each acceptance criterion: the test that proves it, and a one-line breaking edit that must make that test fail.
- The whole-build commands: the affected test files, `python -I _tools/links.py`, `python -I _tools/consistency.py`, and any manual step (for a skill: run it once).
- At the end: apply each breaking edit, confirm the failure, then revert it with the exact inverse Edit (never `git checkout` or a reset).
- Before each commit, check the actual files, not the subagents' reports; send mismatches back or fix them. Commit only when every check passes ([[fix-needs-commit]]).
- Finally, use the result through its real entry point (the command or slash command the designer will type) and confirm normal use still works.

## 7. Check the plan, then hand it over

Give the finished plan file to a fresh general-purpose subagent (give it the path, not your conclusions) to read and answer four questions: does it serve the goal, is it complete, is it safe, can it be built right the first time. Write every finding into the plan. Then tell the designer, in two lines: the plan's path, and to run `/clear` and then "run the plan at <path>" in the fresh session.
