---
name: flower-patch-followup
description: "After 0.1.3 merges: flower patch y 0.15→0 in main.tscn, register t_flower_patch_b, merge m2/flower-patch"
metadata:
  node_type: memory
  type: project
  originSessionId: 1f6110f3-2e32-4646-b45d-481e3317ccea
  modified: 2026-11-05T19:16:42.047Z
---

Flower-patch B is committed on branch `m2/flower-patch` (fe2f237, worktree `.claude/worktrees/flower-patch`), not merged yet. Unit 110/110 and snapshot 12/12 pass.

**Why:** the other session (maigd-62) owns `main.tscn` and `run_tests.gd` while it builds 0.1.3 (said 2026-11-05).

**How to apply:** once 0.1.3 is reported merged into `milestone/0.1`:
1. Merge `m2/flower-patch`.
2. Set the three FlowerPatch instances in `main.tscn` from y = 0.15 to 0. The prop's origin is now on the ground, so until then they float.
3. Register `t_flower_patch_b` in `run_tests.gd` and delete the `await _fp_all(m)` hook line in `t_node_contract`.
4. Have Bob render the shots.

Only then export an exe. See [[session-handoff]].
