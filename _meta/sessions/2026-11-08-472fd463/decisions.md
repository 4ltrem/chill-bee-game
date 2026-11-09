---
session: 472fd463-d58d-41f5-abb3-fb73c957a854
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: lid close before/after vote, the lid suite, scripts delegated to Rex, hold for the usage reset
---
# Decisions: session 472fd463 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D179 · 2026-11-08 · Records & deliverables · Lid close before/after goes to Design Votes; comb size approved
- Decided: "also take before and after of the lid animation not sure which one I like best. the comb size looks good". New section "Lid close: before or after?" (0, 40, 70, 90%); the comb size stays.
- Files: `game/reports/_look/lid-before/`, `game/reports/_look/lid-now/`, `_tools/compare_page.py`

### D180 · 2026-11-08 · Workspace & agents · Delegate all script runs to Rex to keep the session slim
- Decided: "delegate any scripts to rex to keep this session slim"; the rule also covers shot follow-ups (contact sheets, votes page builds); the orchestrator only views final images and publishes.
- Files: `_meta/memory/rex-runs-scripts.md`

### D181 · 2026-11-08 · Workspace & agents · A `lid` suite in `godot_run.py`
- Decided: "yes add the lid suite": `python -I _tools/godot_run.py lid` runs `lid_shots.gd`; not part of `all`.
- Files: `_tools/godot_run.py`, `_tools/test_generate.py`

### D182 · 2026-11-08 · Game build · Lid vote round 1: the old open pose, fix only the closed landing
- Decided: votes: open pose Before yes / After no; 40% and 70% yes both; 90% After yes. The lid returns to the pose before the fix rounds; only the end of the close changes so it lands flat with no clip; comb size stays.
- Files: `game/reports/_look/lid-close-r1-votes.json`, `game/scenes/hive.tscn`

### D183 · 2026-11-08 · Cost & structure · Hold the Patricia/Bob run until the 5-hour reset; checkpoint commit
- Decided: "wait until after the reset" (5-hour window at 66%), then "checkpoint commit": `e77235a` on `milestone/0.1.4`; `ONBOARDING.md` and `game/reports/_look/votes/` left out on purpose.
- Files: `_meta/memory/session-handoff.md`

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
