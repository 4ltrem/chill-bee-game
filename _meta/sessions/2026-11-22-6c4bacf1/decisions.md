---
session: 6c4bacf1
dates: 2026-11-22 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: operator obstacles and QoL fixes before the next feature round (checkpoint 3d94233); logged after the fact on 2026-11-23 from `_tools/session_digest.py`
---
# Decisions: session 6c4bacf1 (2026-11-22 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

Logged on 2026-11-23, after D269, so the ID is later than its date.

## Decisions

### D272 · 2026-11-22 · Workspace & agents · Operator obstacles and QoL fixes before the next feature round
- Decided: "fix operator obstacles and any qol fixes before implementing the next feature round". Built in `3d94233`: the `start` suite judged by its errors, not Godot 4.2.1's exit 1; `checkpoint.py` labels from each test's newest result (L47); fix-round briefs ask for a `diag:` line instead of a guess (L47); the goal scan counts nodes named in scripts and treats a node after "replaces/supersedes" as removed (obstacles item 23, 0.2 = 36/36); `run_tests.gd` reads `--set` overrides (item 7). The 11/22 end-of-day log still listed these as open; cleared 2026-11-23.
- Why: the tooling's known traps cost more than they take to fix before the 0.3 build.
- Files: `_tools/godot_run.py`, `_tools/checkpoint.py`, `_tools/goal_agent.py`, `game/tests/test_base.gd`, `_meta/drafts/operator/obstacles-2026-11-21.md`

## Still open

- None from this session (item 7's tail, the windowed suites and `--set`, was closed 2026-11-23 by refusing the combination).
