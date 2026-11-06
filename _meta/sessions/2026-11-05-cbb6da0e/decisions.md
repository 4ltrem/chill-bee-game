---
session: cbb6da0e-d437-4e4a-8094-be94d2d136c8
dates: 2026-11-05 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: Second shift: STYLE_LOOP approval, budget guard per agent and week pace, close-up variant shots, Rex the Script Runner (logged at the next end of day from commit c9a3667)
---
# Decisions: session cbb6da0e (2026-11-05 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own. This session ended without its own end-of-day run; these entries are reconstructed from its checkpoint commit c9a3667.

## Decisions

### D94 · 2026-11-05 · Records & deliverables · STYLE_LOOP.md approved
- Decided: the write-up of the two style loops is approved and serves A6; MILESTONES.md notes that every assignment is a demo link.
- Files: `STYLE_LOOP.md`, `MILESTONES.md`

### D95 · 2026-11-05 · Cost & structure · Budget guard per agent and week pace
- Decided: `budget_guard.py` denies a new agent when the 5-hour usage plus that agent's largest logged cost passes 95%, at 95% of the week, or (Bob, Patricia, Quinn) when the week runs 10 points ahead of pace; `statusline.py` saves the week's reset time.
- Why: the old flat 80% block stopped agents with 22% left.
- Files: `_tools/budget_guard.py`, `_tools/statusline.py`

### D96 · 2026-11-05 · Pipeline design · Variant shots on one grid, close up
- Decided: Milo's variants load once on one shared grid and each is shot close up.
- Files: `game/tests/model_shots.gd`

### D97 · 2026-11-05 · Workspace & agents · Rex, the Script Runner
- Decided: Martin hired Rex (`script-runner`, Haiku) to run test suites, builds, mutation and shot scripts and report their summaries; Quinn's definition was to change after 0.1.3 (applied 2026-11-06, D104).
- Files: `.claude/agents/script-runner.md`, `_meta/team.md`
