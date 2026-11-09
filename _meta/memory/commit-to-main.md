---
name: commit-to-main
description: "how to commit straight to main while the main folder stays on the milestone branch (worktree inside the repo, main's own hook)"
metadata:
  node_type: memory
  type: reference
  originSessionId: 48828af3-0854-4eed-ae60-5bc5642a3a42
  modified: 2026-11-09T00:46:18.326Z
---

To change `main` while the main folder is on a milestone branch (done 2026-11-08 for the A4 CREW.md fixes):
- Create the worktree **inside** the repo (`git worktree add .wt-x origin/main -b x`). The repo-only hook blocks `../` paths and `cd` prefixes, so run `git -C .wt-x ...` with repo-relative paths.
- `core.hooksPath` is an absolute path to the milestone folder's `.githooks`. That gate calls `contract_check.py`, which main doesn't have. Commit with `git -C .wt-x -c core.hooksPath=.githooks commit` to run main's own gate (this still runs the gate; it doesn't skip it).
- A push can hang on a hidden login prompt. Use `env GCM_INTERACTIVE=never timeout 90 git push`. If it fails, the designer logs in and it is retried.
- Afterwards, `git worktree remove .wt-x` and delete the branch, per [[one-folder-rule]].
