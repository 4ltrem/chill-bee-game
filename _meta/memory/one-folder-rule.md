---
name: one-folder-rule
description: "Work in the main folder on `main` (milestone branches dropped 2026-11-21; tags mark shipped states); a worktree only for parallel work on the same files, removed and its branch deleted the day it merges (game/CONTEXT.md Process 4, 10)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: cf44f0d9-ea3d-41b5-a628-12e39e761cca
  modified: 2026-11-22T04:33:16.594Z
---

Before dispatching agents, decide where they work. The default is the main folder, on `main`. Create a worktree only when two sessions or agents must change the same files at once, or when a long run must keep going while other work changes its files. Name the folder in the brief. When its branch merges into `main`, remove the worktree and delete the branch the same day.

**One branch (designer, 2026-11-21, picked option A of the branch review):** no `milestone/<version>` branches. Checkpoints (`_tools/checkpoint.py`) and goal_agent commits go on `main`. Origin gets a push only when the full suite is green and the designer says yes. Shipped states (a played milestone, an assignment's demo build) get a tag such as `v0.2.1` or `a6-demo`, with the designer's yes. `commit_main.py` was retired because there is nothing left to commit around.

**Why:** the designer, 2026-11-06: "it's difficult to navigate the workspace with this worktree stuff". On 11/6 there were four worktrees, the playable exe lived in a worktree, and the main folder sat on an old branch. The milestone split then cost a big two-machine merge (11/20), a commit-to-main workaround script, and two different commit gates.

**While a goal run is live** (designer, 2026-11-08): the main session never edits the files the run works on in the main folder; it makes the edit in a worktree under `.claude/worktrees/`, commits there, and merges after the run. `guard_shell.py` rule 6 enforces it via `_meta/usage/goal-run.lock`.

**How to apply:** this is `game/CONTEXT.md` Process 4 and 10; the end-of-day skill tags and pushes. The goal agent follows it too. Two machines: pull before working, push at end-of-day. Related: [[session-handoff]], [[end-of-day-routine]].
