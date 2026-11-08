---
name: one-folder-rule
description: "Work in the main folder on the milestone branch; a worktree only for parallel work on the same files, removed the day its branch merges (game/CONTEXT.md Process 10)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 49ba7bdd-dbda-4adf-93f8-abf4c4364924
  modified: 2026-11-08T19:56:41.018Z
---

Before dispatching agents, decide where they work. The default is the main folder, on the milestone branch. Create a worktree only when two sessions or agents must change the same files at once, or when a long run must keep going while other work changes its files. Name the folder in the brief. Remove the worktree the day its branch merges, and keep the branch.

**Why:** the designer, 2026-11-06: "it's difficult to navigate the workspace with this worktree stuff". On 11/6 there were four worktrees, the playable exe lived in a worktree, and the main folder sat on an old branch. All of them were removed that day, and the main folder moved to `milestone/0.1`.

**While a goal run is live** (designer, 2026-11-08): the main session never edits the files the run works on in the main folder; it makes the edit in a worktree under `.claude/worktrees/`, commits there, and merges after the run. `guard_shell.py` rule 6 enforces it via `_meta/usage/goal-run.lock`.

**How to apply:** this is `game/CONTEXT.md` Process 10. The M3 goal agent follows it too. Related: [[session-handoff]], [[end-of-day-routine]].
