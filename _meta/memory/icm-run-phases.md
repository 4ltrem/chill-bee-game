---
name: icm-run-phases
description: Agent runs in _meta/agent-runs.md are tagged pre-ICM / post-ICM; every new run is post-ICM
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5878844a-7908-4da4-b92d-771ab2ccd17c
  modified: 2026-10-26T23:30:19.673Z
---

The repo was restructured into an ICM workspace on 2026-10-26 (commit 4af8e88, branch worktree-icm-architect). Every run in `_meta/agent-runs.md` carries a Phase column: all runs before the restructure are `pre-ICM`, every run logged after it is `post-ICM`.

**Why:** the user wants to compare token cost before and after the ICM restructure.
**How to apply:** when logging any agent run, set Phase `post-ICM`; average pre- and post-ICM runs separately. Related: [[gdd-review-decisions]].
